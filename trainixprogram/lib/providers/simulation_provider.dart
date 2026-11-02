import 'dart:math';
import 'package:flutter/material.dart';

class SimulationProvider with ChangeNotifier {
  static const List<String> allSectors = [
    'Finance',
    'Healthcare',
    'Telco',
    'Tech Support',
  ];

  List<String> _unusedSectors = [];
  String? _currentSector;

  String? get currentSector => _currentSector;

  String pickNextSector() {
    if (_unusedSectors.isEmpty) {
      _unusedSectors = List.from(allSectors)..shuffle(Random());

      if (_currentSector != null &&
          _unusedSectors.last == _currentSector &&
          _unusedSectors.length > 1) {
        final last = _unusedSectors.removeLast();
        _unusedSectors.insert(0, last);
      }
    }

    _currentSector = _unusedSectors.removeLast();
    notifyListeners();
    return _currentSector!;
  }

  String selectSector(String sector) {
    _currentSector = sector;
    _unusedSectors.remove(sector);
    notifyListeners();
    return sector;
  }
}
