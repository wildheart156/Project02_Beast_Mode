import 'package:beast_mode_fitness/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> initializeFirebase() async {
  try {
    // Use the generated options when this platform was configured by FlutterFire
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on UnsupportedError {
    // Fall back to native Firebase config files on platforms without generated options
    await Firebase.initializeApp();
  }
}
