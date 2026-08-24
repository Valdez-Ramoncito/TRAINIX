import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:trainixprogram/models/messages.dart';
import 'package:trainixprogram/models/session_score.dart';

//the scre evaluator
class EvaluationAPIService {
  //build the transcript
  //we user a string buffer for better performance and memory efficiency
  String _buildTranscript(List<Message> messages) {
    final buffer = StringBuffer();
    for (final msg in messages) {
      if (msg.role == 'user') {
        final content = msg.message.replaceFirst('[AGENT]: ', '');
        buffer.writeln('AGENT: $content');
      } else if (msg.role == 'assistant') {
        buffer.writeln('CUSTOMER: ${msg.message}');
      }
    }
    return buffer.toString().trim();
  }

  //build the evaluation prompt
  String _buildEvaluationPrompt(
    String transcript,
    String sector,
    String customerEmotion,
    String customerProblem,
  ) {
    //the API is expected to a return a JSON like format
    return 'You are an experienced BPO call center trainer evaluating a trainee agent. '
        'The trainee handled a CHAT-based customer interaction in the $sector sector. '
        'The customer was $customerEmotion because $customerProblem. '
        '\n\nTRANSCRIPT:\n$transcript\n\n'
        'Evaluate the agent on each criterion and score from 0 to 10:\n'
        '- OPENING_SPIEL: proper greeting, name, company, offer of help\n'
        '- POSITIVE_SCRIPTING: positive language, avoiding negative phrasing\n'
        '- EMPATHY: acknowledging customer concern and emotional state\n'
        '- ACTIVE_LISTENING: correctly understanding and restating the problem\n'
        '- PROBLEM_IDENTIFICATION: correctly identifying the root issue\n'
        '- SOLUTION_DELIVERY: accuracy, clarity, completeness of the solution\n'
        '- COMMUNICATION_CLARITY: clear, concise, professional responses\n'
        '- TONE: appropriate, empathetic, professional tone throughout\n'
        '- SECTOR_KNOWLEDGE: demonstrated knowledge relevant to $sector\n'
        '- CLOSING_SPIEL: proper wrap-up, asking if there is anything else, sign-off\n\n'
        'Then identify 3 strengths, 3 areas for improvement, and provide one feedback paragraph.\n\n'
        'Respond in EXACTLY this format with no extra text before or after:\n'
        'OPENING_SPIEL: <0-10>\n'
        'POSITIVE_SCRIPTING: <0-10>\n'
        'EMPATHY: <0-10>\n'
        'ACTIVE_LISTENING: <0-10>\n'
        'PROBLEM_IDENTIFICATION: <0-10>\n'
        'SOLUTION_DELIVERY: <0-10>\n'
        'COMMUNICATION_CLARITY: <0-10>\n'
        'TONE: <0-10>\n'
        'SECTOR_KNOWLEDGE: <0-10>\n'
        'CLOSING_SPIEL: <0-10>\n'
        'STRENGTH_1: <strength>\n'
        'STRENGTH_2: <strength>\n'
        'STRENGTH_3: <strength>\n'
        'IMPROVEMENT_1: <area>\n'
        'IMPROVEMENT_2: <area>\n'
        'IMPROVEMENT_3: <area>\n'
        'FEEDBACK: <overall feedback paragraph>';
  }

  //parse the evaluation
  SessionEvaluation _parseEvaluation(String raw, String sector) {
    String cleaned = raw.trim();

    //if the text contains backticks, remove those backticks
    if (cleaned.contains('```')) {
      cleaned = cleaned.replaceAll(RegExp(r'```'), '').trim();
    }

    //find the last index of this text
    final lastBlockIdx = cleaned.lastIndexOf('\nOPENING_SPIEL:');

    //then start from there
    //last block index returns a -1 if it cannot find \nOPENING_SPIEL:
    if (lastBlockIdx >= 0) {
      cleaned = cleaned.substring(lastBlockIdx).trim();

      //if its less than zero, do this instead
    } else {
      //find the very first index of this text
      final startIdx = cleaned.indexOf('OPENING_SPIEL:');

      //then start from there
      if (startIdx >= 0) cleaned = cleaned.substring(startIdx);
    }

    //store here the feedbacks
    String feedback = '';

    //find the index of the FEEDBACK:
    final feedbackIdx = cleaned.indexOf('FEEDBACK:');

    //then start from there
    if (feedbackIdx >= 0) {
      //get the contents of the feedback
      feedback = cleaned.substring(feedbackIdx + 9).trim();

      //then get the text before the feedback text
      cleaned = cleaned.substring(0, feedbackIdx);
    }

    //set a list of validkeys
    const validKeys = {
      'OPENING_SPIEL',
      'POSITIVE_SCRIPTING',
      'EMPATHY',
      'ACTIVE_LISTENING',
      'PROBLEM_IDENTIFICATION',
      'SOLUTION_DELIVERY',
      'COMMUNICATION_CLARITY',
      'TONE',
      'SECTOR_KNOWLEDGE',
      'CLOSING_SPIEL',
      'STRENGTH_1',
      'STRENGTH_2',
      'STRENGTH_3',
      'IMPROVEMENT_1',
      'IMPROVEMENT_2',
      'IMPROVEMENT_3',
    };

    //set a map of fields
    final fields = <String, String>{};

    //for every lines in the cleaned text do this
    for (final line in cleaned.split('\n')) {
      //get the index of the lines where you can find :
      final idx = line.indexOf(':');

      //if the index is greater than 0 do this
      if (idx > 0) {
        //get the key by starting at index 0 up to the idx value
        final key = line.substring(0, idx).trim().toUpperCase();

        //get the value startind at idx value to the rest
        final value = line.substring(idx + 1).trim();

        //if the key is in the list of validkeys, then set the fields
        //key to the value
        if (validKeys.contains(key)) fields[key] = value;
      }
    }

    //lastly, set the fields feedback to the feedback
    fields['FEEDBACK'] = feedback;

    //if the fields has the key OPENING_SPIEL, then send the sector
    //and fields to the session evaluation to get the result
    //and then return that session evaluation
    if (fields.containsKey('OPENING_SPIEL')) {
      return SessionEvaluation.fromParsed(sector: sector, fields: fields);
    }

    //if the above checks failed, return the fallback
    return SessionEvaluation.fallback(sector);
  }

  //send the request to the API
  Future<String?> _sendRequest(String prompt) async {
    //try three attemps to send the request
    //send in the prompt to the API
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await http.post(
          Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization':
                'Bearer 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',
          },
          body: jsonEncode({
            "model": "openrouter/free",
            "messages": [
              {"role": "user", "content": prompt},
            ],
            "temperature": 0.3,
            "max_tokens": 800,
          }),
        );

        //if status is not ok, return the error
        if (response.statusCode != 200) {
          print("Evaluation error ${response.statusCode}");
          return null;
        }

        //get the response body
        final data = jsonDecode(response.body);

        //get the content inside of that body
        final content = data['choices']?[0]?['message']?['content'];

        print("Evaluation Status: ${response.statusCode}");
        print("Evaluation Response: $content");

        //if its not string or its empty, return retrying attempt
        if (content == null || content is! String || content.trim().isEmpty) {
          print(
            "Null evaluation content — retrying (attempt ${attempt + 1}/3)",
          );
          continue;
        }

        //if it does contain something, return the content
        return content;

        //if an error arises, print the error
      } catch (e, stack) {
        print("Exception in evaluation _sendRequest: $e");
        print(stack);
      }
    }

    //return null if it didnt arise an error, but all attempts are used
    return null;
  }

  //evaluate the chats
  Future<SessionEvaluation> evaluateChat({
    required List<Message> messages,
    required String sector,
    required String customerEmotion,
    required String customerProblem,
  }) async {
    //send the messages to build the transcript
    final transcript = _buildTranscript(messages);

    //if the transcript is empty, there is nothing to evaluate.
    //return the fallback
    if (transcript.isEmpty) return SessionEvaluation.fallback(sector);

    //send the needed datas to build the prompt
    final prompt = _buildEvaluationPrompt(
      transcript,
      sector,
      customerEmotion,
      customerProblem,
    );

    //wait for the response
    final content = await _sendRequest(prompt);

    //if the response is empty, return the fallback
    if (content == null) return SessionEvaluation.fallback(sector);

    //if its not, return the evaluation
    return _parseEvaluation(content, sector);
  }
}
