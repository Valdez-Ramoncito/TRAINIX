import 'dart:math';
import 'package:flutter/material.dart';

//the sector picker
//so the agent does not get the same sector twice in a row
class SimulationProvider with ChangeNotifier {
  //list all the sectors
  static const List<String> _allSectors = [
    'Finance',
    'Healthcare',
    'Telco',
    'Tech Support',
  ];

  //a list for sectors that haven't been chosen
  List<String> _unusedSectors = [];

  //the current sector chosen
  String? _currentSector;

  //getter
  String? get currentSector => _currentSector;

  //this picks the next sector
  String pickNextSector() {
    //if its empty, generate a new list and shuffle that list
    if (_unusedSectors.isEmpty) {
      _unusedSectors = List.from(_allSectors)..shuffle(Random());

      //if there is a current sector and the last sector in the unused
      //sectors is the current sector and there are other more sectors
      //in the list, remove the last sector in the list and insert it
      //at the very front for it not to get chosen again
      if (_currentSector != null &&
          _unusedSectors.last == _currentSector &&
          _unusedSectors.length > 1) {
        final last = _unusedSectors.removeLast();
        _unusedSectors.insert(0, last);
      }
    }

    //if the unusedSectors is not empty, remove the last sector from
    //the list, and make that the current sector
    _currentSector = _unusedSectors.removeLast();
    notifyListeners();

    //return the current sector
    return _currentSector!;
  }
}
