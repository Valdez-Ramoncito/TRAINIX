import 'package:flutter/material.dart';

class SessionMessage extends StatelessWidget {
  const SessionMessage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> session = [];
    return session.isEmpty
        ? Column(
            mainAxisAlignment: .center,
            children: [
              Text("No Session Yet"),
              Text("Press add icon on the right side to start session"),
            ],
          )
        : ListView.builder(
            itemBuilder: (_, index) {
              return const SizedBox.shrink();
            },
          );
  }
}
