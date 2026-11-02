import 'dart:math';

String roomGenerate() {
  final random = Random();
  const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz@#';

  String letterPart = "";

  for (int i = 0; i < 5; i++) {
    letterPart += letters[random.nextInt(letters.length)];
  }

  String numberPart = "";
  for (int i = 0; i < 3; i++) {
    numberPart += random.nextInt(10).toString();
  }
  return "$letterPart-$numberPart";
}
