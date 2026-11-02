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

  //minimum time a recording must actually run before stopListening()
  //is allowed to stop it
  static const Duration _minimumRecordingDuration = Duration(milliseconds: 700);

  bool _isAvailable = false;
  bool _isListening = false;
  String _currentTranscript = '';
  String? _recordingPath;
  DateTime? _recordingStartedAt;

  //getters
  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  String get lastWords => _currentTranscript;

  //initializer. Just checks mic permission
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

  //start listening  begins recording the agent's turn to a temporary
  //WAV file.
  Future<void> startListening({
    required void Function(String words) onResult,
  }) async {
    print(
      '[STT] startListening called  isAvailable=$_isAvailable isListening=$_isListening',
    );
    if (_isListening) return;

    //self-heal if initialize() hasn't resolved or wasn't awaited by
    //the caller yet
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
      _recordingStartedAt = DateTime.now();
      print('[STT] recording actually started at $_recordingPath');
    } catch (e, stack) {
      print("Exception starting recording: $e");
      print(stack);
      _isListening = false;
      _recordingStartedAt = null;
    }
  }

  //stop listening stops the recording, uploads it to AssemblyAI, and
  //waits for the transcript. This is where the real network round
  //trip happens, which is why mock_call_screen.dart now shows a
  //"Transcribing..." state while this runs.
  //Returns both the transcript AND the retained audio file path  the
  //TESDA voice evaluator needs the raw audio for pace, pronunciation,
  //filler, tone scoring
  Future<(String transcript, String? audioPath)> stopListening() async {
    if (!_isListening) return (_currentTranscript, null);
    _isListening = false;

    //if this turn's recording hasn't run for the minimum window yet,
    //wait out the remainder before actually stopping
    if (_recordingStartedAt != null) {
      final elapsed = DateTime.now().difference(_recordingStartedAt!);
      if (elapsed < _minimumRecordingDuration) {
        await Future.delayed(_minimumRecordingDuration - elapsed);
      }
    }
    _recordingStartedAt = null;

    String? filePath;
    try {
      final stoppedPath = await _recorder.stop();
      filePath = stoppedPath ?? _recordingPath;
      if (filePath == null) return ('', null);

      _currentTranscript = (await _transcribeFile(filePath)).trim();
      print('[STT] transcription result: "$_currentTranscript"');
    } catch (e, stack) {
      print("Exception stopping/transcribing recording: $e");
      print(stack);
      //something went wrong before a transcript came back. This
      //recording has no evaluation value either, clean it up now
      //rather than retaining a broken file
      await _deleteRecordingFile(filePath);
      _recordingPath = null;
      return ('', null);
    }

    _recordingPath = null;
    return (_currentTranscript, filePath);
  }

  //deletes a previous retained recording. Call this once a file
  //returned from stopListening() is no longer needed, after evaluation
  //runs, or if the interaction resets or ends without one
  Future<void> deleteRetainedFile(String? path) => _deleteRecordingFile(path);

  //delete never lets a cleanup failure affect the
  //transcript result itself, since that already returned or was set above
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
  //job, and polls until it's done
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

      //3. poll until completed or error
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
        //otherwise still "queued" or "processing"  keep polling
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
    _deleteRecordingFile(_recordingPath);
    _currentTranscript = '';
    _recordingPath = null;
    _recordingStartedAt = null;
  }

  void dispose() {
    cancel();
    _recorder.dispose();
  }
}
