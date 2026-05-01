import 'package:beast_mode_fitness/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on UnsupportedError {
    await Firebase.initializeApp();
  }
}
