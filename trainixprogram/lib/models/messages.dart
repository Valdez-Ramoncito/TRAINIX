import 'package:flutter/material.dart';

class Message {
  //determines who sent the message
  //is it the Agent (user) ? or the Assistant (customer) ?
  String role;

  //the message of that role
  String message;

  //when this message was added. Used by the TESDA-grounded chat
  //evaluator to score reply latency or pacing (RESPONSE_CONSISTENCY_AND_PACE)
  final DateTime timestamp;

  Message({required this.role, required this.message, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}

class MessageProvider with ChangeNotifier {
  final List<Message> _messages = [];

  List<Message> get messages => _messages;

  void addMessage(String role, String message, {bool notify = true}) {
    _messages.add(Message(role: role, message: message));
    if (notify) notifyListeners();
  }

  void clearMessage({bool notify = true}) {
    _messages.clear();
    if (notify) notifyListeners();
  }

  void notifyNow() {
    notifyListeners();
  }
}
