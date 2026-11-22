import 'package:flutter/material.dart';

class StartModuleTrainingScreen extends StatefulWidget {
  const StartModuleTrainingScreen({super.key});

  @override
  State<StartModuleTrainingScreen> createState() =>
      _StartModuleTrainingScreenState();
}

class _StartModuleTrainingScreenState extends State<StartModuleTrainingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(), body: Text("What is an Opening Spiel?"));
  }
}
