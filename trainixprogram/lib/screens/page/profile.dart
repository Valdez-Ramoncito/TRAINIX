import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/components/button/back_button.dart';
import 'package:trainixprogram/components/button/logout_button.dart';
import 'package:trainixprogram/components/button/menu_button_training.dart';
import 'package:trainixprogram/components/button/profile_button.dart';
import 'package:trainixprogram/components/size.dart';
import 'package:trainixprogram/screens/home/homeScreen.dart';
import 'package:trainixprogram/screens/home/trainer/home_screen.dart';
import 'package:trainixprogram/screens/page/training.dart';
import 'package:trainixprogram/screens/dashboard.dart';
import 'package:trainixprogram/screens/settings_screen.dart';
import 'package:trainixprogram/screens/page/mini_training.dart';
import 'package:trainixprogram/screens/auth/loginscreen.dart';
import 'package:trainixprogram/models/trainix_debug.dart';
import 'package:trainixprogram/models/training/training_categories.dart';
import 'package:trainixprogram/services/auth_service.dart';
import 'package:trainixprogram/widgets/next_step_banner.dart';

enum AppRole { trainee, trainer, admin }

class AppUser {
  final String id;
  final String displayName;
  final String email;
  final AppRole role;
  final String phone;
  final String bio;
  final String preferredSector;
  final String gender;
  final String joinedLabel;
  final bool photoSet;

  const AppUser({
    required this.id,
    required this.displayName,
    required this.email,
    required this.role,
    this.phone = '',
    this.bio = '',
    this.preferredSector = 'Tech Support',
    this.gender = '',
    this.joinedLabel = 'Joined Since: Aug 15, 2026',
    this.photoSet = false,
  });

  AppUser copyWith({
    String? displayName,
    String? email,
    AppRole? role,
    String? phone,
    String? bio,
    String? preferredSector,
    String? gender,
    String? joinedLabel,
    bool? photoSet,
  }) {
    return AppUser(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      preferredSector: preferredSector ?? this.preferredSector,
      gender: gender ?? this.gender,
      joinedLabel: joinedLabel ?? this.joinedLabel,
      photoSet: photoSet ?? this.photoSet,
    );
  }
}

class ProfileData {
  static AppUser? _current;

  static final List<AppUser> users = [
    const AppUser(
      id: 'demo_trainer',
      displayName: 'Demo Trainer',
      email: 'trainer',
      role: AppRole.trainer,
    ),
    const AppUser(
      id: 'demo_trainee',
      displayName: 'Demo Trainee',
      email: 'trainee@trainix.local',
      role: AppRole.trainee,
    ),
  ];

  static AppUser get current {
    _current ??= users.firstWhere(
      (u) => u.role == AppRole.trainee,
      orElse: () => users.first,
    );
    return _current!;
  }

  static set current(AppUser user) {
    _current = user;
  }

  static void setCurrentByEmail(String email, {AppRole? role}) {
    final e = email.trim().toLowerCase();
    for (final u in users) {
      if (u.email.toLowerCase() == e) {
        if (role == null || u.role == role) {
          _current = u;
          return;
        }
      }
    }
    if (role == AppRole.trainer) {
      _current = AppUser(
        id: 'trainer_$e',
        displayName: 'Demo Trainer',
        email: email,
        role: AppRole.trainer,
      );
    } else {
      _current = AppUser(
        id: 'trainee_$e',
        displayName: email.isEmpty ? 'Demo Trainee' : email.split('@').first,
        email: email.isEmpty ? 'trainee@trainix.local' : email,
        role: AppRole.trainee,
      );
    }
  }

  static String get displayName => current.displayName;
  static set displayName(String v) {
    _current = current.copyWith(displayName: v);
    _syncList();
  }

  static String get email => current.email;
  static set email(String v) {
    _current = current.copyWith(email: v);
    _syncList();
  }

  static String get phone => current.phone;
  static set phone(String v) {
    _current = current.copyWith(phone: v);
    _syncList();
  }

  static String get bio => current.bio;
  static set bio(String v) {
    _current = current.copyWith(bio: v);
    _syncList();
  }

  static String get preferredSector => current.preferredSector;
  static set preferredSector(String v) {
    _current = current.copyWith(preferredSector: v);
    _syncList();
  }

  static String get gender => current.gender;
  static set gender(String v) {
    _current = current.copyWith(gender: v);
    _syncList();
  }

  static String get joinedLabel => current.joinedLabel;
  static set joinedLabel(String v) {
    _current = current.copyWith(joinedLabel: v);
    _syncList();
  }

  static bool get photoSet => current.photoSet;
  static set photoSet(bool v) {
    _current = current.copyWith(photoSet: v);
    _syncList();
  }

  static AppRole get role => current.role;
  static set role(AppRole v) {
    _current = current.copyWith(role: v);
  }

  static String get shortName {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? displayName : parts.first;
  }

  static List<AppUser> get trainees =>
      users.where((u) => u.role == AppRole.trainee).toList();

  static List<AppUser> get trainers =>
      users.where((u) => u.role == AppRole.trainer).toList();

  static void _syncList() {
    final c = _current;
    if (c == null) return;
    final i = users.indexWhere((u) => u.id == c.id);
    if (i >= 0) {
      users[i] = c;
    }
  }
}

class Profile extends StatefulWidget {
  final bool requireCompletion;

  const Profile({super.key, this.requireCompletion = false});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with SingleTickerProviderStateMixin {
  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;

  late TabController tabController;
  int indexPage = 0;

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;
  String _sector = ProfileData.preferredSector;
  String _gender = ProfileData.gender;
  // Open in view mode when the profile was already completed/saved.
  // First-time trainees still land in edit mode until they finish the profile.
  bool _editing = ProfileData.role == AppRole.trainee
      ? !MiniTrainingProgress.isProfileComplete
      : false;

  static const _sectors = ['Tech Support', 'Healthcare', 'Finance', 'Telco'];

  static const _genders = ['Female', 'Male', 'Non-binary', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        setState(() => indexPage = tabController.index);
      }
    });
    _nameController = TextEditingController(text: ProfileData.displayName);
    _emailController = TextEditingController(text: ProfileData.email);
    _phoneController = TextEditingController(text: ProfileData.phone);
    _bioController = TextEditingController(text: ProfileData.bio);
  }

  @override
  void dispose() {
    tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _finishProfile({bool debug = false}) {
    if (debug) {
      MiniTrainingProgress.debugSkipProfile();
    } else {
      _saveLocal();
      MiniTrainingProgress.completeProfile();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          debug
              ? 'DEBUG: Profile completion skipped. Modes unlocked.'
              : 'Profile completed. Training modes are now available.',
        ),
      ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _saveLocal() async {
    ProfileData.displayName = _nameController.text.trim().isEmpty
        ? 'Trainee'
        : _nameController.text.trim();
    ProfileData.phone = _phoneController.text.trim();
    ProfileData.bio = _bioController.text.trim();
    ProfileData.preferredSector = _sector;
    ProfileData.gender = _gender;
    final wasComplete = MiniTrainingProgress.isProfileComplete;
    MiniTrainingProgress.completeProfile();
    setState(() {
      _editing = false;
    });
    await AuthService.saveProfileDetails();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasComplete
              ? 'Profile saved.'
              : 'Profile saved. Training areas are unlocked.',
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppColors.textMuted(context)),
      filled: true,
      fillColor: AppColors.elevated(context),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.borderStrong(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.primaryText()),
      ),
    );
  }

  void _openTraining() {
    if (!MiniTrainingProgress.isProfileComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complete your profile first before unlocking sessions.',
          ),
        ),
      );
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TrainingSession()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if ((widget.requireCompletion ||
                  !MiniTrainingProgress.isProfileComplete) &&
              ProfileData.role != AppRole.trainer &&
              ProfileData.role != AppRole.admin)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: AppColors.elevated(context),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Complete your profile before unlocking Mini Training and Simulation modes.',
                      style: TextStyle(
                          color: AppColors.textPrimary(context), fontSize: 13),
                    ),
                  ),
                  if (TrainixDebug.unlocked) ...[
                    TextButton(
                      onPressed: () => _finishProfile(debug: true),
                      child: const Text('DEBUG: Skip profile'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _finishProfile(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryText(),
                        foregroundColor: AppColors.onPrimary(context),
                      ),
                      child: const Text('DEBUG: Mark profile complete'),
                    ),
                  ],
                ],
              ),
            ),
          if (ProfileData.role != AppRole.trainer &&
              ProfileData.role != AppRole.admin)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: NextStepBanner(
                screen: TraineeNextStepScreen.profile,
                showSkipGuide: true,
              ),
            ),
          Expanded(
            child: Row(
              children: [
                if (ProfileData.role == AppRole.trainer)
                  SizedBox(
                    width: 260,
                    height: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 20,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Text(
                                'TRAINIX',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontSize: context.responsiveFont(7),
                                    ),
                              ),
                              const Gap(40),
                              MenuButton(
                                icon: Icons.home_outlined,
                                label: 'Trainer Home',
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const HomeScreenTrainer(),
                                    ),
                                  );
                                },
                              ),
                              MenuButton(
                                icon: Icons.settings_outlined,
                                label: 'Settings',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SettingsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          TrainingBackButton(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HomeScreenTrainer(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                else if (ProfileData.role != AppRole.admin)
                  SizedBox(
                    width: 260,
                    height: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 20,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Text(
                                'TRAINIX',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontSize: context.responsiveFont(7),
                                    ),
                              ),
                              const Gap(40),
                              MenuButton(
                                icon: Icons.school_outlined,
                                label: 'Mini Training',
                                onTap: () {
                                  if (!MiniTrainingProgress.isProfileComplete) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Complete or skip profile first.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const MiniTraining(),
                                    ),
                                  );
                                },
                              ),
                              MenuButton(
                                icon: Icons.computer_rounded,
                                label: 'Training Session',
                                onTap: _openTraining,
                              ),
                              MenuButton(
                                icon: Icons.bar_chart_rounded,
                                label: 'Progress Dashboard',
                                onTap: () {
                                  if (!MiniTrainingProgress.isProfileComplete) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Complete or skip profile first.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const DashboardScreen(),
                                    ),
                                  );
                                },
                              ),
                              MenuButton(
                                icon: Icons.settings_outlined,
                                label: 'Settings',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SettingsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          TrainingBackButton(
                            onTap: () {
                              if (!MiniTrainingProgress.isProfileComplete) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Complete or skip profile first before opening the main menu.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HomeScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                if (ProfileData.role != AppRole.admin)
                  VerticalDivider(
                    width: .5,
                    thickness: .3,
                    color: AppColors.textMuted(context),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 280,
                          width: double.infinity,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                height: 160,
                                child: Container(
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: _isDarkMode
                                        ? null
                                        : AppColors.surface(context),
                                    border: Border.all(
                                      color: _isDarkMode
                                          ? Colors.transparent
                                          : AppColors.border(context),
                                    ),
                                    image: _isDarkMode
                                        ? const DecorationImage(
                                            image: AssetImage(
                                              'assets/images/cover_photo.png',
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: _isDarkMode
                                      ? null
                                      : Align(
                                          alignment: Alignment.centerRight,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              right: 24,
                                            ),
                                            child: Icon(
                                              Icons.workspace_premium_outlined,
                                              size: 88,
                                              color: AppColors.primaryText()
                                                  .withValues(alpha: 0.12),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              Positioned(
                                top: 15,
                                right: 20,
                                child: LogoutButton(
                                  onImage: true,
                                  onTap: () async {
                                    await AuthService.instance.signOut();
                                    if (!context.mounted) return;
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const LoginScreen(),
                                      ),
                                      (_) => false,
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                top: 90,
                                left: 20,
                                right: 20,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Stack(
                                      children: [
                                        Container(
                                          width: 140,
                                          height: 140,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              28,
                                            ),
                                            border: Border.all(
                                              color: AppColors.border(context),
                                              width: 3,
                                            ),
                                            image: const DecorationImage(
                                              image: AssetImage(
                                                'assets/images/defaultProfile.png',
                                              ),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        const Positioned(
                                          bottom: 8,
                                          right: 8,
                                          child: ProfileCameraButton(),
                                        ),
                                      ],
                                    ),
                                    const Gap(16),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Container(
                                          padding: _isDarkMode
                                              ? EdgeInsets.zero
                                              : const EdgeInsets.symmetric(
                                                  horizontal: 14, vertical: 10),
                                          decoration: _isDarkMode
                                              ? null
                                              : BoxDecoration(
                                                  color: AppColors.card(context)
                                                      .withValues(alpha: 0.94),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                      color: AppColors.border(
                                                          context)),
                                                  boxShadow:
                                                      AppColors.cardShadow(
                                                          context),
                                                ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                ProfileData.displayName,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      color:
                                                          AppColors.textPrimary(
                                                              context),
                                                      fontSize: context
                                                          .responsiveFont(8),
                                                    ),
                                              ),
                                              Text(
                                                ProfileData.joinedLabel,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: AppColors
                                                          .textSecondary(
                                                              context),
                                                      fontSize: context
                                                          .responsiveFont(3),
                                                    ),
                                              ),
                                              if (ProfileData
                                                  .preferredSector.isNotEmpty)
                                                Text(
                                                  'Preferred sector: ${ProfileData.preferredSector}',
                                                  style: TextStyle(
                                                    color: AppColors.textMuted(
                                                        context),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          setState(() => _editing = !_editing),
                                      child: Text(
                                        _editing
                                            ? 'Cancel edit'
                                            : 'Edit profile',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: _editing
                              ? _buildEditForm()
                              : _buildReadOnlyTabs(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit profile',
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const Gap(6),
              Text(
                'Email comes from your login and cannot be changed here.',
                style: TextStyle(
                    color: AppColors.textMuted(context), fontSize: 12),
              ),
              const Gap(16),
              TextField(
                controller: _nameController,
                style: TextStyle(color: AppColors.textPrimary(context)),
                textInputAction: TextInputAction.next,
                decoration: _fieldDecoration('Display name'),
              ),
              const Gap(12),
              TextField(
                controller: _emailController,
                readOnly: true,
                enableInteractiveSelection: true,
                style: TextStyle(color: AppColors.textMuted(context)),
                decoration: _fieldDecoration('Email (from login)'),
              ),
              const Gap(12),
              Text(
                'Gender',
                style: TextStyle(
                    color: AppColors.textMuted(context), fontSize: 12),
              ),
              const Gap(8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _genders.map((g) {
                  final selected = _gender == g;
                  return ChoiceChip(
                    label: Text(g),
                    selected: selected,
                    onSelected: (_) => setState(() => _gender = g),
                    selectedColor: AppColors.nextTint(context),
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.textPrimary(context)
                          : AppColors.textSecondary(context),
                    ),
                    backgroundColor: AppColors.elevated(context),
                  );
                }).toList(),
              ),
              const Gap(12),
              TextField(
                controller: _phoneController,
                style: TextStyle(color: AppColors.textPrimary(context)),
                textInputAction: TextInputAction.next,
                decoration: _fieldDecoration('Phone (optional)'),
              ),
              const Gap(12),
              TextField(
                controller: _bioController,
                maxLines: 3,
                style: TextStyle(color: AppColors.textPrimary(context)),
                decoration: _fieldDecoration('Short bio / training goal'),
              ),
              const Gap(12),
              Text(
                'Preferred sector',
                style: TextStyle(
                    color: AppColors.textMuted(context), fontSize: 12),
              ),
              const Gap(8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _sectors.map((s) {
                  final selected = _sector == s;
                  return ChoiceChip(
                    label: Text(s),
                    selected: selected,
                    onSelected: (_) => setState(() => _sector = s),
                    selectedColor: AppColors.nextTint(context),
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.textPrimary(context)
                          : AppColors.textSecondary(context),
                    ),
                    backgroundColor: AppColors.elevated(context),
                  );
                }).toList(),
              ),
              const Gap(20),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _saveLocal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryText(),
                      foregroundColor: AppColors.onPrimary(context),
                    ),
                    child: const Text('Save profile'),
                  ),
                  if (TrainixDebug.unlocked) ...[
                    const Gap(12),
                    OutlinedButton(
                      onPressed: () => _finishProfile(debug: true),
                      child: const Text('DEBUG: Save and unlock modes'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyTabs() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderIdle(context)),
              ),
              child: TabBar(
                controller: tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: AppColors.cardShadow(
                    context,
                    blur: 8,
                    offset: const Offset(0, 2),
                  ),
                ),
                labelColor: AppColors.textPrimary(context),
                unselectedLabelColor: AppColors.textMuted(context),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(height: 36, text: 'Overview'),
                  Tab(height: 36, text: 'Training prefs'),
                ],
              ),
            ),
          ),
        ),
        const Gap(12),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: IndexedStack(
                index: indexPage,
                children: [
                  ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _infoRow('Name', ProfileData.displayName),
                      _infoRow(
                        'Email',
                        ProfileData.email.isEmpty ? ' - ' : ProfileData.email,
                      ),
                      _infoRow(
                        'Gender',
                        ProfileData.gender.isEmpty ? ' - ' : ProfileData.gender,
                      ),
                      _infoRow(
                        'Phone',
                        ProfileData.phone.isEmpty ? ' - ' : ProfileData.phone,
                      ),
                      _infoRow(
                        'Bio',
                        ProfileData.bio.isEmpty
                            ? 'No bio yet.'
                            : ProfileData.bio,
                      ),
                      _infoRow(
                        'Photo',
                        ProfileData.photoSet
                            ? 'Placeholder set'
                            : 'Default photo',
                      ),
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _infoRow('Preferred sector', ProfileData.preferredSector),
                      _infoRow(
                        'Profile status',
                        MiniTrainingProgress.isProfileComplete
                            ? 'Complete  -  modes unlocked'
                            : 'Incomplete  -  complete profile to unlock modes',
                      ),
                      const Gap(8),
                      Text(
                        'Recommendations and strengths from simulations will appear here after more sessions.',
                        style: TextStyle(
                          color: AppColors.textMuted(context),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static const Map<String, IconData> _infoIcons = {
    'Name': Icons.person_outline_rounded,
    'Email': Icons.alternate_email_rounded,
    'Gender': Icons.wc_rounded,
    'Phone': Icons.phone_outlined,
    'Bio': Icons.notes_rounded,
    'Photo': Icons.photo_outlined,
    'Preferred sector': Icons.business_center_outlined,
    'Profile status': Icons.verified_outlined,
  };

  Widget _infoRow(String label, String value) {
    final icon = _infoIcons[label] ?? Icons.info_outline_rounded;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderIdle(context), width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(9),
            ),
            child:
                Icon(icon, size: 17, color: AppColors.textSecondary(context)),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textMuted(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(3),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
