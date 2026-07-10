// lib/core/utils/auth_helper.dart

import 'package:rawasi_app_n/core/utils/pref_helper.dart';

/// تحقق مما إذا كان المستخدم مسجّل دخوله (يوجد token صالح)
Future<bool> isUserSignedIn() async {
  final token = await PrefHelper.getToken();
  return token != null && token.isNotEmpty;
}
