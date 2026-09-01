import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/customer.dart';
import 'package:trainixprogram/models/messages.dart';
import 'package:trainixprogram/services/open_router_api_service.dart';
import 'package:typecast_dart/typecast_dart.dart';

//Bridges between voice channel and the AI + TTS
//SoLoud for audio playback
class TypeCastAPIService {
  final String fixedSector;

  //a customer in a voice channel is a different customer from
  //the chat channel
  late final OpenRouterAPIService openRouterAPI;

  //accept a sector and pass it
  TypeCastAPIService({required this.fixedSector}) {
    openRouterAPI = OpenRouterAPIService(fixedSector: fixedSector);
  }

  //set the api key of typecast
  final client = TypecastClient(apiKey: dotenv.env['TYPECAST_API_KEY']);

  //initialize the audio playback
  final SoLoud _soLoud = SoLoud.instance;
  bool _isInitialized = false;

  //soundhandle for soloud
  SoundHandle? _currentHandle;

  //tracks the currently-active buffer source so it can be freed before
  //the next one is created
  //Typed dynamic rather than a specific flutter_soloud type since the
  //exact return type of setBufferStream()
  dynamic _currentSource;

  //clear messages
  void clearMessages(BuildContext context) {
    openRouterAPI.clearMessages(context);
  }

  //initialize soloud and set the initialized to true
  //this makes the initializer set only once
  Future<void> init() async {
    if (_isInitialized) return;
    await _soLoud.init();
    _isInitialized = true;
  }

  //set the emotion of the customer to the received emotion
  EmotionPreset _emotion(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'angry':
        return EmotionPreset.angry;
      case 'frustrated':
        return EmotionPreset.angry;
      case 'impatient':
        return EmotionPreset.toneup;
      case 'anxious':
        return EmotionPreset.sad;
      case 'concerned':
        return EmotionPreset.tonedown;
      case 'confused':
        return EmotionPreset.normal;
      default:
        return EmotionPreset.normal;
    }
  }

  //set the tone of the customer to the received emotion
  double _emotionIntensity(String emotion) {
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
      case 'confused':
        return 1.1;
      default:
        return 0.6;
    }
  }

  //get response of the customer
  Future<Customer> getResponse(BuildContext context, String spoke) async {
    //add the message of the agent in the messages list
    final provider = Provider.of<MessageProvider>(context, listen: false);
    provider.addMessage("user", "[AGENT]: $spoke");

    //wait for the response of the customer
    final Customer customerResponse = await openRouterAPI.getResponse(
      context,
      spoke,
    );

    //after getting the response, play their response with the set emotion
    playCustomerLine(customerResponse.reply, customerResponse.emotion);

    //then return the response
    return customerResponse;
  }

  //make the customer speak with emotion
  Future<void> playCustomerLine(String spoke, String emotion) async {
    print('[TTS] playCustomerLine called for: "$spoke"');
    try {
      //initialize the soloud
      await init();
      print('[TTS] soloud init complete (isInitialized=$_isInitialized)');

      //free the previous turn's buffer source before creating a new one
      if (_currentSource != null) {
        try {
          await _soLoud.disposeSource(_currentSource);
        } catch (e, stack) {
          print("Exception disposing previous TTS source: $e");
          print(stack);
        }
        _currentSource = null;
      }

      //wait for the stream
      final stream = await client.textToSpeechStream(
        TtsRequestStream(
          voiceId: 'tc_6763aa69e0158fa7fe2ecdd2',
          text: spoke,
          model: TtsModel.ssfmV30,
          output: OutputStream(audioFormat: AudioFormat.wav),
          prompt: PresetPrompt(
            emotionPreset: _emotion(emotion),
            emotionIntensity: _emotionIntensity(emotion),
          ),
        ),
      );

      //set the buffering rate of the sound to an appropriate level
      final soundStream = _soLoud.setBufferStream(
        bufferingType: BufferingType.released,
        sampleRate: 32000,
        channels: Channels.mono,
        format: BufferType.s16le,
      );
      _currentSource = soundStream;

      //with the handle, play the audio
      _currentHandle = _soLoud.play(soundStream);

      //set the first chunk to be true
      bool firstChunk = true;
      int chunkCount = 0;

      //for every chunks in the stream
      //make that chunk into a byte array and add it to the soloud PCM
      //to make it play without waiting for the entire audio file
      await for (final chunk in stream) {
        _soLoud.addAudioDataStream(soundStream, Uint8List.fromList(chunk));
        chunkCount++;

        //set this to false when the first chunk finally arrives
        if (firstChunk) {
          print('[TTS] first audio chunk received and streamed');
          firstChunk = false;
        }
      }

      //all chunks were received, soloud can finish
      _soLoud.setDataIsEnded(soundStream);
      print('[TTS] playback stream finished/ended  $chunkCount chunk(s) total');

      //diagnostic: zero chunks means Typecast's stream returned nothing
      //at all for this text. An API-side issue, not a SoLoud playback
      //issue. If the customer goes silent again, this specific log line
      //is the first thing to check.
      if (chunkCount == 0) {
        print(
          '[TTS] WARNING: stream ended with zero chunks  customer line '
          '"$spoke" produced no audio at all.',
        );
      }
    } catch (e, stack) {
      //previously unhandled, any exception anywhere in this method
      //(network hiccup, stream error, SoLoud error) used to fail
      //silently with no log and no fallback
      //this should tell us what actually happened instead of failing silently.
      print("Exception in playCustomerLine: $e");
      print(stack);
    }
  }

  //stop the audio
  void stop() {
    if (_currentHandle != null) {
      _soLoud.stop(_currentHandle!);
      _currentHandle = null;
    }
  }
}
