import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/simulation_history.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/components/background.dart';
import 'package:trainixprogram/components/decoration/text_field.dart';
import 'package:trainixprogram/screens/home/homeScreen.dart';
import 'package:trainixprogram/screens/home/trainer/home_screen.dart';
import 'package:trainixprogram/screens/home/admin/admin_home_screen.dart';
import 'package:trainixprogram/screens/page/profile.dart';
import 'package:trainixprogram/components/class/trainee_activity_log.dart';
import 'package:trainixprogram/services/supabase_service.dart';
import 'package:trainixprogram/services/auth_service.dart';
import 'package:trainixprogram/services/training_progress_repository.dart';
import 'package:trainixprogram/services/notification_inbox_service.dart';
import 'package:trainixprogram/components/class/live_training_session.dart';
import 'package:trainixprogram/models/training/notifications/training_notification.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static bool isActive = false;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _busy = false;
  AppRole _signUpRole = AppRole.trainee;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    LoginScreen.isActive = true;
    NotificationInboxService.instance.clearLocalOnly();
    TrainingNotificationCenter.clearToasts();
    LiveSessionStore.instance.clearLocal();
    _checkDatabase();
  }

  Future<void> _checkDatabase() async {
    await SupabaseService.smokeTest();
  }

  @override
  void dispose() {
    LoginScreen.isActive = false;
    NotificationInboxService.instance.refreshUi();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _afterAuthNavigate() async {
    LoginScreen.isActive = false;
    await TrainingProgressRepository.instance.load();
    await NotificationInboxService.instance.loadFromRemote();
    NotificationInboxService.instance.startRealtime();
    NotificationInboxService.instance.refreshUi();
    LiveSessionStore.instance.clearLocal();
    await LiveSessionStore.instance.loadFromRemote();
    LiveSessionStore.instance.startRealtime();
    await TraineeActivityLogStore.instance.loadFromRemote();
    if (mounted) {
      final history = Provider.of<SimulationHistoryProvider>(
        context,
        listen: false,
      );
      history.clear();
      await history.loadFromRemote();
    }
    if (!mounted) return;

    // Re-load profile then hard-force trainer routing from session + profile.
    await AuthService.instance.loadProfileIntoApp();
    final sessionUser = AuthService.instance.currentUser;
    final sessionEmail = (sessionUser?.email ?? '').trim().toLowerCase();
    final sessionMetaRole = '${sessionUser?.userMetadata?['role'] ?? ''}'
        .trim()
        .toLowerCase();
    final email =
        (ProfileData.email.trim().isEmpty
                ? sessionEmail
                : ProfileData.email.trim())
            .toLowerCase();
    final name = ProfileData.displayName.trim().toLowerCase();
    final forceTrainer =
        AuthService.isKnownTrainerEmail(email) ||
        AuthService.isKnownTrainerEmail(sessionEmail) ||
        ProfileData.role == AppRole.trainer ||
        sessionMetaRole == 'trainer' ||
        name.contains('josephine') ||
        email.startsWith('trainer') ||
        sessionEmail.startsWith('trainer');
    if (forceTrainer) {
      ProfileData.role = AppRole.trainer;
      if (ProfileData.email.trim().isEmpty && sessionEmail.isNotEmpty) {
        ProfileData.email = sessionEmail;
      }
      try {
        await AuthService.saveProfileDetails();
      } catch (_) {}
    }
    final forceAdmin =
        AuthService.isKnownAdminEmail(email) ||
        AuthService.isKnownAdminEmail(sessionEmail) ||
        ProfileData.role == AppRole.admin ||
        sessionMetaRole == 'admin' ||
        email.startsWith('admin') ||
        sessionEmail.startsWith('admin') ||
        name.contains('admin');
    if (forceAdmin) {
      ProfileData.role = AppRole.admin;
      if (ProfileData.email.trim().isEmpty && sessionEmail.isNotEmpty) {
        ProfileData.email = sessionEmail;
      }
      try {
        await AuthService.saveProfileDetails();
      } catch (_) {}
    }
    final isAdmin = forceAdmin || ProfileData.role == AppRole.admin;
    final isTrainer =
        !isAdmin && (forceTrainer || ProfileData.role == AppRole.trainer);
    if (isAdmin) {
      ProfileData.role = AppRole.admin;
    }
    debugPrint(
      'afterAuth role=${ProfileData.role.name} isAdmin=$isAdmin isTrainer=$isTrainer email=$email sessionEmail=$sessionEmail meta=$sessionMetaRole name=$name',
    );
    TraineeActivityLogStore.instance.log(
      actorName: ProfileData.displayName,
      actorRole: isAdmin ? 'admin' : (isTrainer ? 'trainer' : 'trainee'),
      category: TraineeLogCategory.auth,
      action: 'Login',
      detail: isAdmin
          ? 'Admin signed in'
          : (isTrainer ? 'Trainer signed in' : 'Trainee signed in'),
    );

    if (isAdmin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
      );
    } else if (isTrainer) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreenTrainer()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<void> _handleAuth() async {
    if (_busy) return;
    final email = AuthService.sanitizeEmail(_emailController.text);
    final password = _passwordController.text;
    final displayName = AuthService.sanitizeDisplayName(_nameController.text);

    final emailError = AuthService.validateEmail(email);
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(emailError)),
      );
      return;
    }
    final passwordError = AuthService.validatePassword(
      password,
      forSignUp: _isSignUp,
    );
    if (passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(passwordError)),
      );
      return;
    }
    if (_isSignUp) {
      final nameError = AuthService.validateDisplayName(
        displayName,
        required: true,
      );
      if (nameError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(nameError)),
        );
        return;
      }
    }

    setState(() => _busy = true);

    bool ok;
    if (_isSignUp) {
      ok = await AuthService.instance.signUp(
        email: email,
        password: password,
        displayName: displayName,
        role: _signUpRole,
      );
    } else {
      ok = await AuthService.instance.signIn(email: email, password: password);
    }

    if (!mounted) return;

    if (!ok) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.lastError ?? 'Authentication failed.'),
        ),
      );
      return;
    }

    await _afterAuthNavigate();
    if (mounted) setState(() => _busy = false);
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
                              vertical: 18,
                              horizontal: 25,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
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
                                if (_isSignUp) ...[
                                  AppTextField(
                                    label: 'Display name',
                                    controller: _nameController,
                                  ),
                                  const Gap(12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ChoiceChip(
                                          label: const Text('Trainee'),
                                          selected:
                                              _signUpRole == AppRole.trainee,
                                          onSelected: (_) => setState(
                                            () => _signUpRole = AppRole.trainee,
                                          ),
                                        ),
                                      ),
                                      const Gap(8),
                                      Expanded(
                                        child: ChoiceChip(
                                          label: const Text('Trainer'),
                                          selected:
                                              _signUpRole == AppRole.trainer,
                                          onSelected: (_) => setState(
                                            () => _signUpRole = AppRole.trainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Gap(12),
                                ],
                                Gap(16),
                                AppTextField(
                                  label: 'Email',
                                  controller: _emailController,
                                  textInputAction: TextInputAction.next,
                                ),
                                Gap(15),
                                AppTextField(
                                  label: 'Password',
                                  controller: _passwordController,
                                  isPassword: true,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) {
                                    if (!_busy) _handleAuth();
                                  },
                                ),
                                Gap(12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 40,
                                  child: ElevatedButton(
                                    onPressed: _busy ? null : _handleAuth,
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
                                      _busy
                                          ? 'Please wait...'
                                          : (_isSignUp ? 'Sign up' : 'Login'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(fontSize: 13),
                                    ),
                                  ),
                                ),
                                const Gap(6),
                                TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => setState(
                                          () => _isSignUp = !_isSignUp,
                                        ),
                                  child: Text(
                                    _isSignUp
                                        ? 'Already have an account? Login'
                                        : 'Need an account? Sign up',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white54,
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
