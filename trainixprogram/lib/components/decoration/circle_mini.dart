import 'package:flutter/material.dart';

Widget node(bool isComplete, bool isNext) {
  if (isComplete) {
    return Container(
      width: 10,
      decoration: BoxDecoration(
        shape: .circle,
        color: const Color.fromARGB(255, 130, 174, 240),
      ),
    );
  } else if (isNext) {
    return Stack(
      children: [
        Container(
          width: 30,
          decoration: BoxDecoration(
            shape: .circle,
            color: const Color.fromARGB(255, 21, 21, 21),
            border: Border.all(color: Color.fromARGB(255, 41, 70, 51)),
          ),
        ),

        Positioned(
          child: Center(
            child: Container(
              width: 10,
              decoration: BoxDecoration(
                shape: .circle,
                color: Color.fromARGB(255, 112, 189, 138),
              ),
            ),
          ),
        ),
      ],
    );
  } else {
    return Container(
      width: 10,
      decoration: BoxDecoration(
        shape: .circle,
        color: Color.fromARGB(180, 41, 40, 40),
      ),
    );
  }
}
