import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/customer_account.dart';
import 'package:trainixprogram/models/messages.dart';
import 'package:trainixprogram/models/simulation_history.dart';
import 'package:trainixprogram/providers/simulation_provider.dart';
import 'package:trainixprogram/screens/auth/loginscreen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

//Start of the program

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint(
      "Notice: .env file not found or could not be loaded ($e). Using fallback environment.",
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        //This is where conversations are stored by Voice and Chat channels
        ChangeNotifierProvider(create: (_) => MessageProvider()),

        //Where generated accounts are generated as well as the 'Issue resolved' created
        ChangeNotifierProvider(create: (_) => AccountProvider()),

        //Where history of all evaluations + multitasking scores are stored (still no memory persistence.)
        //Then gets sent into Dashboard and sector Match
        ChangeNotifierProvider(create: (_) => SimulationHistoryProvider()),

        //This is the sector picker. So the agent does not get the same sector twice in a row until all sectors are covered
        ChangeNotifierProvider(create: (_) => SimulationProvider()),
      ],
      child: MaterialApp(
        title: 'TRAINIX',
        theme: ThemeData(
          colorScheme: const ColorScheme.dark(
            onSurface: Colors.white,
            onPrimary: Colors.white,
          ),
          textTheme: GoogleFonts.poppinsTextTheme().apply().copyWith(
            titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.w800),
            titleMedium: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            titleSmall: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            bodyLarge: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            bodyMedium: GoogleFonts.poppins(fontWeight: FontWeight.w400),
            bodySmall: GoogleFonts.poppins(fontWeight: FontWeight.w100),
          ),
        ),
        debugShowCheckedModeBanner: false,

        //The program starts first in the Login Screen (no auth yet)
        home: const LoginScreen(),
      ),
    );
  }
}
