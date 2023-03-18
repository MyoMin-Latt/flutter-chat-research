import 'dart:math';

String generateRandomString(int lengthOfString) {
  final random = Random();
  const allChars = 'ABCDEFGabcdefghijklmnopqrstuvwxyz';

  final randomString = List.generate(
          lengthOfString, (index) => allChars[random.nextInt(allChars.length)])
      .join();
  return randomString;
}
