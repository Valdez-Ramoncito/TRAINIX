import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

//this turns speech into text using AssemblyAI
class SpeechToTextService {
  static final String _assemblyAiApiKey = dotenv.env['ASSEMBLY_API_KEY']!;

  //captures raw mic audio to a temporary WAV file per turn
  final AudioRecorder _recorder = AudioRecorder();

  bool _isAvailable = false;
  bool _isListening = false;
  String _currentTranscript = '';
  String? _recordingPath;

  //getters
  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  String get lastWords => _currentTranscript;

  //initializer — just checks mic permission. Nothing to download or
  //load ahead of time, unlike the whisper_ggml attempt.
  Future<bool> initialize() async {
    if (_isAvailable) return true;
    try {
      _isAvailable = await _recorder.hasPermission();
    } catch (e, stack) {
      print("Exception checking mic permission: $e");
      print(stack);
      _isAvailable = false;
    }
    return _isAvailable;
  }

  //start listening — begins recording the agent's turn to a temporary
  //WAV file.
  //
  //NOTE: onResult is kept in the signature for compatibility with the
  //existing call site in mock_call_screen.dart, but it's never
  //actually invoked here. AssemblyAI's batch endpoint only returns a
  //transcript once the whole recording is uploaded and processed —
  //there's no live growing transcript anymore (see step notes).
  Future<void> startListening({
    required void Function(String words) onResult,
  }) async {
    print(
      '[STT] startListening called — isAvailable=$_isAvailable isListening=$_isListening',
    );
    if (_isListening) return;

    //self-heal if initialize() hasn't resolved (or wasn't awaited by
    //the caller) yet — this is exactly what let the very first mic tap
    //silently do nothing: the UI treats the mic as usable as soon as
    //the call goes active, independent of whether this permission
    //check has actually finished
    if (!_isAvailable) {
      final ready = await initialize();
      if (!ready) return;
    }

    _isListening = true;
    _currentTranscript = '';

    try {
      final dir = await getTemporaryDirectory();
      _recordingPath =
          '${dir.path}/trainix_turn_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: _recordingPath!,
      );
      print('[STT] recording actually started at $_recordingPath');
    } catch (e, stack) {
      print("Exception starting recording: $e");
      print(stack);
      _isListening = false;
    }
  }

  //stop listening — stops the recording, uploads it to AssemblyAI, and
  //waits for the transcript. This is where the real network round
  //trip happens, which is why mock_call_screen.dart now shows a
  //"Transcribing..." state while this runs.
  Future<String> stopListening() async {
    if (!_isListening) return _currentTranscript;
    _isListening = false;

    String? filePath;
    try {
      final stoppedPath = await _recorder.stop();
      filePath = stoppedPath ?? _recordingPath;
      if (filePath == null) return '';

      _currentTranscript = (await _transcribeFile(filePath)).trim();
      print('[STT] transcription result: "$_currentTranscript"');
    } catch (e, stack) {
      print("Exception stopping/transcribing recording: $e");
      print(stack);
    } finally {
      //clean up the temp recording now that we're done with it —
      //whether transcription succeeded, failed, or threw, there's no
      //reason to keep piling up .wav files in the OS temp directory
      await _deleteRecordingFile(filePath);
      _recordingPath = null;
    }

    return _currentTranscript;
  }

  //best-effort delete — never lets a cleanup failure affect the
  //transcript result itself, since that already returned/was set above
  Future<void> _deleteRecordingFile(String? path) async {
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e, stack) {
      print("Exception deleting temp recording file: $e");
      print(stack);
    }
  }

  //uploads the recorded file to AssemblyAI, starts a transcription
  //job, and polls until it's done. Uses AssemblyAI's documented,
  //stable async v2/upload + v2/transcript flow (not the newer Sync
  //API — that one's exact request shape wasn't confirmable against
  //current docs when I researched this, so going with the flow that's
  //known to work rather than guessing).
  Future<String> _transcribeFile(String filePath) async {
    try {
      final fileBytes = await File(filePath).readAsBytes();

      //1. upload the raw audio bytes
      final uploadResponse = await http.post(
        Uri.parse('https://api.assemblyai.com/v2/upload'),
        headers: {'authorization': _assemblyAiApiKey},
        body: fileBytes,
      );
      if (uploadResponse.statusCode != 200) {
        print("AssemblyAI upload failed: ${uploadResponse.statusCode}");
        return '';
      }
      final uploadUrl =
          jsonDecode(uploadResponse.body)['upload_url'] as String?;
      if (uploadUrl == null) return '';

      //2. start the transcription job
      final startResponse = await http.post(
        Uri.parse('https://api.assemblyai.com/v2/transcript'),
        headers: {
          'authorization': _assemblyAiApiKey,
          'content-type': 'application/json',
        },
        body: jsonEncode({'audio_url': uploadUrl}),
      );
      if (startResponse.statusCode != 200) {
        print(
          "AssemblyAI transcript job failed to start: ${startResponse.statusCode}",
        );
        return '';
      }
      final transcriptId = jsonDecode(startResponse.body)['id'] as String?;
      if (transcriptId == null) return '';

      //3. poll until completed or error. A single short turn should
      //resolve within a handful of polls — capped at 20 tries (~40s)
      //so a stuck job can't hang the UI forever.
      for (int attempt = 0; attempt < 20; attempt++) {
        await Future.delayed(const Duration(seconds: 2));

        final pollResponse = await http.get(
          Uri.parse('https://api.assemblyai.com/v2/transcript/$transcriptId'),
          headers: {'authorization': _assemblyAiApiKey},
        );
        if (pollResponse.statusCode != 200) continue;

        final data = jsonDecode(pollResponse.body) as Map<String, dynamic>;
        final status = data['status'];

        if (status == 'completed') {
          return (data['text'] as String?) ?? '';
        }
        if (status == 'error') {
          print("AssemblyAI transcription error: ${data['error']}");
          return '';
        }
        //otherwise still "queued" or "processing" — keep polling
      }

      print("AssemblyAI transcription timed out waiting for a result");
      return '';
    } catch (e, stack) {
      print("Exception in AssemblyAI transcription: $e");
      print(stack);
      return '';
    }
  }

  //cancels the current turn without waiting for a transcript
  void cancel() {
    _isListening = false;
    _recorder.cancel();
    //best-effort, not awaited — cancel() is synchronous by design,
    //same as it was in the original speech_to_text-backed version of
    //this service, so this cleanup fires and forgets rather than
    //making cancel() async just for this
    _deleteRecordingFile(_recordingPath);
    _currentTranscript = '';
    _recordingPath = null;
  }

  void dispose() {
    cancel();
    _recorder.dispose();
  }
}
