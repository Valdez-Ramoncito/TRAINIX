import 'package:flutter/material.dart';
import 'package:trainixprogram/screens/page/components/training/content/history/advance.dart';
import 'package:trainixprogram/screens/page/components/training/content/history/message.dart';

/// Content shown when "Calls" is selected in the left menu.
class CallsContent extends StatefulWidget {
  const CallsContent({super.key});

  @override
  State<CallsContent> createState() => _CallsContentState();
}

class _CallsContentState extends State<CallsContent> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Text("Hello Woeld"));
  }
}

/// Content shown when "Messages" is selected in the left menu.
class MessagesContent extends StatelessWidget {
  const MessagesContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Message());
  }
}

/// Content shown when "Typing" is selected in the left menu.
class AdvanceContent extends StatelessWidget {
  const AdvanceContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Advance());
  }
}
