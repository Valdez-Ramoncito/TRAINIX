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
    switch (emotion.toLowerCase()) {
      case 'angry':
      case 'frustrated':
        return EmotionPreset.angry;
      case 'impatient':
        return EmotionPreset.toneup;
      case 'anxious':
      case 'sad':
        return EmotionPreset.sad;
      case 'concerned':
        return EmotionPreset.tonedown;
      case 'calm':
      case 'polite':
      case 'professional':
        return EmotionPreset.normal;
      default:
        return EmotionPreset.normal;
    }
  }

  double _intensity(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'angry':
        return 1.5;
      case 'frustrated':
      case 'impatient':
        return 1.2;
      case 'anxious':
        return 0.9;
      case 'concerned':
        return 0.8;
      case 'calm':
      case 'polite':
      case 'professional':
        return 0.5;
      default:
        return 0.7;
    }
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
