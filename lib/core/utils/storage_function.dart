import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/models/user.dart';

void saveInLocal(User user) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('userId', user.id);
}

Future<String?> readInLocal() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  print('readInLocal : ${prefs.getString('userId')}');
  return prefs.getString('userId');
}
