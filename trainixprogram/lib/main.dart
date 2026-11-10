import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/components/app_theme.dart';
import 'package:trainixprogram/models/customer_account.dart';
import 'package:trainixprogram/models/messages.dart';
import 'package:trainixprogram/models/simulation_history.dart';
import 'package:trainixprogram/providers/simulation_provider.dart';
import 'package:trainixprogram/screens/auth/loginscreen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:trainixprogram/services/supabase_service.dart';
import 'package:trainixprogram/services/app_navigator.dart';
import 'package:trainixprogram/screens/page/components/notification_bell.dart';
import 'package:trainixprogram/screens/settings_screen.dart';
import 'package:trainixprogram/models/training/notifications/training_notification.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await SupabaseService.initialize();
  await AppSettings.load();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => SimulationHistoryProvider()),
        ChangeNotifierProvider(create: (_) => SimulationProvider()),
      ],
      child: MaterialApp(
        title: 'TRAINIX',
        theme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        debugShowCheckedModeBanner: false,
        navigatorKey: AppNavigator.key,
        builder: (context, child) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final overlay = AppNavigator.key.currentState?.overlay;
            if (overlay != null) {
              TrainingNotificationCenter.attachOverlay(overlay);
            }
          });
          return Stack(
            children: [
              child ?? const SizedBox.shrink(),
              const Positioned(
                right: 16,
                bottom: 20,
                child: SafeArea(child: NotificationBellAnchor()),
              ),
            ],
          );
        },
        home: const LoginScreen(),
      ),
    );
  }
}