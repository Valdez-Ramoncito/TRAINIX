import 'package:trainixprogram/services/auth_service.dart';
import 'package:trainixprogram/screens/auth/loginscreen.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trainixprogram/screens/home/homeScreen.dart';
import 'package:trainixprogram/screens/page/profile.dart';
import 'package:trainixprogram/models/training/training_categories.dart';
import 'package:trainixprogram/models/trainix_debug.dart';

class AppSettings {
  static bool notificationsEnabled = true;
  static bool coachTipsEnabled = true;
  static bool ahtAlertsEnabled = true;
  static bool soundEffectsEnabled = true;
  static bool autoScriptGuideExpanded = true;
  static bool reduceMotion = false;
  static String preferredLanguage = 'English';
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    notificationsEnabled = prefs.getBool('settings_notifications') ?? true;
    coachTipsEnabled = prefs.getBool('settings_coach_tips') ?? true;
    ahtAlertsEnabled = prefs.getBool('settings_aht_alerts') ?? true;
    soundEffectsEnabled = prefs.getBool('settings_sound') ?? true;
    autoScriptGuideExpanded =
        prefs.getBool('settings_script_guide_expanded') ?? true;
    reduceMotion = prefs.getBool('settings_reduce_motion') ?? false;
    preferredLanguage = prefs.getString('settings_language') ?? 'English';
    _loaded = true;
  }

  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_notifications', notificationsEnabled);
    await prefs.setBool('settings_coach_tips', coachTipsEnabled);
    await prefs.setBool('settings_aht_alerts', ahtAlertsEnabled);
    await prefs.setBool('settings_sound', soundEffectsEnabled);
    await prefs.setBool(
      'settings_script_guide_expanded',
      autoScriptGuideExpanded,
    );
    await prefs.setBool('settings_reduce_motion', reduceMotion);
    await prefs.setString('settings_language', preferredLanguage);
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileReady = MiniTrainingProgress.isProfileComplete;
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        foregroundColor: Colors.white,
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F26),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF70BD8A).withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              profileReady
                  ? 'These choices stay on this device for now. Account progress and guide status are saved to your login.'
                  : 'Finish your profile to change training aids. You can still sign out or open your profile from here.',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
                height: 1.35,
              ),
            ),
          ),
          const Gap(18),
          _sectionTitle('Training aids'),
          _card([
            _switchTile(
              icon: Icons.tips_and_updates_outlined,
              title: 'Coach tips',
              subtitle: 'Show live coaching notes during simulations.',
              value: AppSettings.coachTipsEnabled,
              onChanged: profileReady
                  ? (v) => setState(() {
                      AppSettings.coachTipsEnabled = v;
                      AppSettings.save();
                    })
                  : null,
            ),
            _switchTile(
              icon: Icons.menu_book_outlined,
              title: 'Expand Script Guide by default',
              subtitle: 'Open the Script Guide panel when a session starts.',
              value: AppSettings.autoScriptGuideExpanded,
              onChanged: profileReady
                  ? (v) => setState(() {
                      AppSettings.autoScriptGuideExpanded = v;
                      AppSettings.save();
                    })
                  : null,
            ),
            _switchTile(
              icon: Icons.timer_outlined,
              title: 'AHT time alerts',
              subtitle: 'Reminders at 2, 5, 7, and 10 minutes per customer.',
              value: AppSettings.ahtAlertsEnabled,
              onChanged: profileReady
                  ? (v) => setState(() {
                      AppSettings.ahtAlertsEnabled = v;
                      AppSettings.save();
                    })
                  : null,
            ),
          ]),
          const Gap(18),
          _sectionTitle('Notifications and sound'),
          _card([
            _switchTile(
              icon: Icons.notifications_outlined,
              title: 'In-app notifications',
              subtitle: 'Unlock notices and session reminders.',
              value: AppSettings.notificationsEnabled,
              onChanged: (v) => setState(() {
                AppSettings.notificationsEnabled = v;
                AppSettings.save();
              }),
            ),
            _switchTile(
              icon: Icons.volume_up_outlined,
              title: 'Sound effects',
              subtitle: 'UI sounds for session events (visual toggle for now).',
              value: AppSettings.soundEffectsEnabled,
              onChanged: (v) => setState(() {
                AppSettings.soundEffectsEnabled = v;
                AppSettings.save();
              }),
            ),
          ]),
          const Gap(18),
          _sectionTitle('Display'),
          _card([
            _switchTile(
              icon: Icons.animation_outlined,
              title: 'Reduce motion',
              subtitle: 'Prefer simpler transitions when available.',
              value: AppSettings.reduceMotion,
              onChanged: (v) => setState(() {
                AppSettings.reduceMotion = v;
                AppSettings.save();
              }),
            ),
            ListTile(
              leading: const Icon(Icons.language, color: Colors.white70),
              title: const Text(
                'Language',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                AppSettings.preferredLanguage,
                style: const TextStyle(color: Colors.white54),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white38),
              onTap: () async {
                final next = await showModalBottomSheet<String>(
                  context: context,
                  backgroundColor: const Color(0xFF1A1A1A),
                  builder: (ctx) {
                    return SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final lang in ['English', 'Filipino'])
                            ListTile(
                              title: Text(
                                lang,
                                style: const TextStyle(color: Colors.white),
                              ),
                              onTap: () => Navigator.pop(ctx, lang),
                            ),
                        ],
                      ),
                    );
                  },
                );
                if (next != null) {
                  setState(() => AppSettings.preferredLanguage = next);
                  _toast('Language set to $next (UI language wiring later).');
                }
              },
            ),
          ]),
          const Gap(18),
          _sectionTitle('Account'),
          _card([
            ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.white70),
              title: Text(
                ProfileData.displayName,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                ProfileData.email.isEmpty ? 'No email set' : ProfileData.email,
                style: const TextStyle(color: Colors.white54),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white38),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Profile()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.work_outline, color: Colors.white70),
              title: const Text(
                'Preferred sector',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                ProfileData.preferredSector,
                style: const TextStyle(color: Colors.white54),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFF87171)),
              title: const Text(
                'Sign out',
                style: TextStyle(color: Color(0xFFF87171)),
              ),
              onTap: () async {
                await AuthService.instance.signOut();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
            ),
          ]),
          const Gap(18),
          _sectionTitle('About'),
          _card([
            const ListTile(
              leading: Icon(Icons.info_outline, color: Colors.white70),
              title: Text('TRAINIX', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                'Contact Center simulation trainer. Scores align to TESDA-style competencies.',
                style: TextStyle(color: Colors.white54, height: 1.35),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.restore, color: Colors.white70),
              title: const Text(
                'Reset local settings',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                setState(() {
                  AppSettings.notificationsEnabled = true;
                  AppSettings.coachTipsEnabled = true;
                  AppSettings.ahtAlertsEnabled = true;
                  AppSettings.soundEffectsEnabled = true;
                  AppSettings.autoScriptGuideExpanded = true;
                  AppSettings.reduceMotion = false;
                  AppSettings.preferredLanguage = 'English';
                });
                _toast('Settings reset to defaults.');
              },
            ),
          ]),

          const Gap(28),
          Center(
            child: GestureDetector(
              onTap: () {
                final was = TrainixDebug.unlocked;
                TrainixDebug.onVersionTap();
                if (TrainixDebug.unlocked != was) {
                  setState(() {});
                  _toast(
                    TrainixDebug.unlocked
                        ? 'Developer tools unlocked'
                        : 'Developer tools locked',
                  );
                }
              },
              child: Text(
                TrainixDebug.unlocked
                    ? 'Trainix · developer tools on'
                    : 'Trainix · v1',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Material(
      color: const Color(0xFF161616),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    ValueChanged<bool>? onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      value: value,
      activeColor: const Color(0xFF70BD8A),
      onChanged: onChanged,
    );
  }
}
