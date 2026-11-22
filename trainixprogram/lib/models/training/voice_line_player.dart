import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:typecast_dart/typecast_dart.dart';

class VoiceLinePlayer {
  VoiceLinePlayer._();
  static final VoiceLinePlayer instance = VoiceLinePlayer._();

  final TypecastClient _client = TypecastClient(
    apiKey: dotenv.env['TYPECAST_API_KEY'] ?? '',
  );
  final SoLoud _soLoud = SoLoud.instance;
  bool _initialized = false;
  SoundHandle? _handle;
  dynamic _source;
  bool _busy = false;

  bool get isBusy => _busy;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    await _soLoud.init();
    _initialized = true;
  }

  EmotionPreset _emotion(String emotion) {
    final e = emotion.toLowerCase();
    if (e.contains('angry') || e.contains('upset') || e.contains('frustrat')) {
      return EmotionPreset.angry;
    }
    if (e.contains('impatient') || e.contains('annoy')) {
      return EmotionPreset.toneup;
    }
    if (e.contains('anxious') || e.contains('sad')) {
      return EmotionPreset.sad;
    }
    if (e.contains('concern') || e.contains('worried')) {
      return EmotionPreset.tonedown;
    }
    if (e.contains('calm') || e.contains('polite') || e.contains('professional')) {
      return EmotionPreset.normal;
    }
    return EmotionPreset.normal;
  }

  double _intensity(String emotion) {
    final e = emotion.toLowerCase();
    if (e.contains('angry') || e.contains('upset')) {
      return 1.6;
    }
    if (e.contains('frustrat') || e.contains('impatient') || e.contains('annoy')) {
      return 1.25;
    }
    if (e.contains('anxious')) {
      return 0.9;
    }
    if (e.contains('concern') || e.contains('worried')) {
      return 0.8;
    }
    if (e.contains('calm') || e.contains('polite') || e.contains('professional')) {
      return 0.5;
    }
    return 0.7;
  }

  Future<void> stop() async {
    try {
      if (_handle != null) {
        _soLoud.stop(_handle!);
        _handle = null;
      }
      if (_source != null) {
        await _soLoud.disposeSource(_source);
        _source = null;
      }
    } catch (_) {}
  }

  Future<void> playText(String text, {String emotion = 'normal'}) async {
    final line = text.trim();
    if (line.isEmpty || _busy) return;
    if ((_client.apiKey as String?)?.isEmpty ?? true) {
      final key = dotenv.env['TYPECAST_API_KEY'] ?? '';
      if (key.isEmpty) return;
    }
    _busy = true;
    try {
      await stop();
      await _ensureInit();
      final stream = await _client.textToSpeechStream(
        TtsRequestStream(
          voiceId: 'tc_6763aa69e0158fa7fe2ecdd2',
          text: line,
          model: TtsModel.ssfmV30,
          output: OutputStream(audioFormat: AudioFormat.wav),
          prompt: PresetPrompt(
            emotionPreset: _emotion(emotion),
            emotionIntensity: _intensity(emotion),
          ),
        ),
      );
      final soundStream = _soLoud.setBufferStream(
        bufferingType: BufferingType.released,
        sampleRate: 32000,
        channels: Channels.mono,
        format: BufferType.s16le,
      );
      _source = soundStream;
      _handle = _soLoud.play(soundStream);
      await for (final chunk in stream) {
        _soLoud.addAudioDataStream(soundStream, Uint8List.fromList(chunk));
      }
      _soLoud.setDataIsEnded(soundStream);
    } catch (e) {
      print('VoiceLinePlayer.playText: $e');
    } finally {
      _busy = false;
    }
  }

  Future<void> playFile(String path) async {
    if (path.isEmpty || _busy) return;
    final file = File(path);
    if (!file.existsSync()) return;
    _busy = true;
    try {
      await stop();
      await _ensureInit();
      final source = await _soLoud.loadFile(path);
      _source = source;
      _handle = _soLoud.play(source);
    } catch (e) {
      print('VoiceLinePlayer.playFile: $e');
    } finally {
      _busy = false;
    }
  }
}
