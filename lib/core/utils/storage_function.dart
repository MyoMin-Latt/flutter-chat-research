import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/models/user.dart';

Future<void> saveInLocal(User user) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('userId', user.id);
}

Future<String?> readInLocal() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('userId');
}
