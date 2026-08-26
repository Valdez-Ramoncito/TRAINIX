import 'package:flutter/material.dart';

class Message {
  //determines who sent the message
  //is it the Agent (user) ? or the Assistant (customer) ?
  String role;

  //the message of that role
  String message;
  Message({required this.role, required this.message});
}

class MessageProvider with ChangeNotifier {
  final List<Message> _messages = [];

  //getter for _messages
  List<Message> get messages => _messages;

  //add a message, store it in the _messages list
  void addMessage(String role, String message) {
    messages.add(Message(role: role, message: message));

    notifyListeners();
  }

  void clearMessage() {
    messages.clear();

    notifyListeners();
  }
}
