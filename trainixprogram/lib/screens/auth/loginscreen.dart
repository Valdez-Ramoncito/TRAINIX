import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/components/background.dart';
import 'package:trainixprogram/components/textfield.dart';
import 'package:trainixprogram/screens/menu_screen.dart';

//the login screen - no authentication yet
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 40),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "TRAINIX",
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontSize: 20),
                  ),
                ),
                Gap(100),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        SizedBox(
                          width: 500,
                          child: Column(
                            children: [
                              Text(
                                "Turn Practice Into Confidence.",
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontSize: 50, height: 1.2),
                              ),
                              Gap(20),
                              Text(
                                "Prepare for your BPO career through realistic AI-powered training simulations designed to build your communication, customer service, and professional skills.",
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontSize: 12, height: 1.2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          width: 400,
                          height: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            color: const Color.fromARGB(
                              255,
                              111,
                              109,
                              109,
                            ).withOpacity(0.03),
                            border: Border.all(
                              color: const Color.fromARGB(
                                255,
                                30,
                                29,
                                29,
                              ).withOpacity(0.5),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 20,
                              horizontal: 25,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  "Welcome!",
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontSize: 15),
                                ),
                                Gap(10),
                                Text(
                                  "Login your account and start your journey with us!",
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                                Gap(30),
                                AppTextField(label: 'Email'),
                                Gap(15),
                                AppTextField(
                                  label: 'Password',
                                  isPassword: true,
                                ),
                                Gap(20),
                                SizedBox(
                                  width: double.infinity,
                                  height: 40,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const MainMenuScreen(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(
                                        255,
                                        9,
                                        118,
                                        214,
                                      ),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      enabledMouseCursor:
                                          SystemMouseCursors.click,
                                    ),
                                    child: Text(
                                      "Login",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(fontSize: 13),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
