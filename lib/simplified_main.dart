
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'core/utils/debug_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  DebugLogger.info('Firebase initialized successfully');
  
  runApp(const MySimplifiedApp());
}

class MySimplifiedApp extends StatelessWidget {
  const MySimplifiedApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) {
            DebugLogger.provider('Creating AuthProvider in simplified app');
            return AuthProvider();
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          DebugLogger.provider('Checking if AuthProvider is available: ${Provider.of<AuthProvider>(context, listen: false) != null}');
          
          return MaterialApp(
            title: 'Simplified Test App',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            initialRoute: '/login',
            routes: {
              '/login': (context) {
                DebugLogger.route('Building login route');
                try {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  DebugLogger.provider('AuthProvider is available in login route');
                  return const LoginScreen();
                } catch (e) {
                  DebugLogger.error('AuthProvider NOT available in login route', e);
                  return const Scaffold(body: Center(child: Text('Provider Error')));
                }
              },
              '/home': (context) => const HomeScreen(),
            },
          );
        }
      ),
    );
  }
}
