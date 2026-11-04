import 'package:flutter/material.dart';
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

class DemoTraineeDirectory {
  static List<String> get names => const [];
}

class Profile extends StatefulWidget {
  final bool requireCompletion;

  const Profile({super.key, this.requireCompletion = false});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with SingleTickerProviderStateMixin {
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
  bool _savedOnce =
      MiniTrainingProgress.isProfileComplete ||
      ProfileData.role != AppRole.trainee;

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
      _savedOnce = true;
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
      labelStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF70BD8A)),
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
              color: const Color(0xFF1E293B),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Complete your profile before unlocking Mini Training and Simulation modes.',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  if (TrainixDebug.unlocked) ...[
                    TextButton(
                      onPressed: () => _finishProfile(debug: true),
                      child: const Text('DEBUG: Skip profile'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _finishProfile(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF166534),
                        foregroundColor: Colors.white,
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
                                style: Theme.of(context).textTheme.titleMedium
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
                                style: Theme.of(context).textTheme.titleMedium
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
                  const VerticalDivider(
                    width: .5,
                    thickness: .3,
                    color: Color.fromARGB(255, 105, 106, 106),
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
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    image: const DecorationImage(
                                      image: AssetImage(
                                        'assets/images/cover_photo.png',
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 15,
                                right: 20,
                                child: LogoutButton(
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
                                              color: const Color(0xFF2A2A2A),
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
                                        Positioned(
                                          bottom: 8,
                                          right: 8,
                                          child: ProfileCameraButton(
                                            onTap: () {
                                              setState(() {
                                                ProfileData.photoSet = true;
                                              });
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Photo picker will connect to storage later. Placeholder marked as set.',
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Gap(16),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
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
                                                    fontSize: context
                                                        .responsiveFont(3),
                                                  ),
                                            ),
                                            if (ProfileData
                                                .preferredSector
                                                .isNotEmpty)
                                              Text(
                                                'Preferred sector: ${ProfileData.preferredSector}',
                                                style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12,
                                                ),
                                              ),
                                          ],
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
              const Text(
                'Edit profile',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const Gap(6),
              const Text(
                'Email comes from your login and cannot be changed here.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const Gap(16),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                textInputAction: TextInputAction.next,
                decoration: _fieldDecoration('Display name'),
              ),
              const Gap(12),
              TextField(
                controller: _emailController,
                readOnly: true,
                enableInteractiveSelection: true,
                style: const TextStyle(color: Colors.white54),
                decoration: _fieldDecoration('Email (from login)'),
              ),
              const Gap(12),
              const Text(
                'Gender',
                style: TextStyle(color: Colors.white54, fontSize: 12),
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
                    selectedColor: const Color(0xFF166534),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                    ),
                    backgroundColor: const Color(0xFF1A1A1A),
                  );
                }).toList(),
              ),
              const Gap(12),
              TextField(
                controller: _phoneController,
                style: const TextStyle(color: Colors.white),
                textInputAction: TextInputAction.next,
                decoration: _fieldDecoration('Phone (optional)'),
              ),
              const Gap(12),
              TextField(
                controller: _bioController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration('Short bio / training goal'),
              ),
              const Gap(12),
              const Text(
                'Preferred sector',
                style: TextStyle(color: Colors.white54, fontSize: 12),
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
                    selectedColor: const Color(0xFF166534),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                    ),
                    backgroundColor: const Color(0xFF1A1A1A),
                  );
                }).toList(),
              ),
              const Gap(20),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _saveLocal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF166534),
                      foregroundColor: Colors.white,
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
        TabBar(
          controller: tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF4A4B54), width: 1),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFFA5A6AD),
          tabs: const [
            Tab(height: 38, text: 'Overview'),
            Tab(height: 38, text: 'Training prefs'),
          ],
        ),
        const Gap(12),
        Expanded(
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
                    ProfileData.bio.isEmpty ? 'No bio yet.' : ProfileData.bio,
                  ),
                  _infoRow(
                    'Photo',
                    ProfileData.photoSet ? 'Placeholder set' : 'Default photo',
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
                  const Text(
                    'Recommendations and strengths from simulations will appear here after more sessions.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const Gap(4),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
