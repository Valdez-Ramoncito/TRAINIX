import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trainixprogram/screens/page/profile.dart';
import 'package:trainixprogram/models/training/training_categories.dart';
import 'package:trainixprogram/models/trainix_debug.dart';
import 'package:trainixprogram/services/notification_inbox_service.dart';
import 'package:trainixprogram/services/supabase_service.dart';
import 'package:trainixprogram/models/training/notifications/training_notification.dart';
import 'package:trainixprogram/components/class/live_training_session.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static String? lastError;

  static final RegExp _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  static String sanitizeEmail(String raw) {
    return raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
  }

  static String sanitizeDisplayName(String raw) {
    final cleaned = raw
        .replaceAll(RegExp(r'[\u0000-\u001F\u007F]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.length <= 48) return cleaned;
    return cleaned.substring(0, 48).trim();
  }

  static String? validateEmail(String email) {
    final e = sanitizeEmail(email);
    if (e.isEmpty) return 'Email is required.';
    if (e.length > 120) return 'Email is too long.';
    if (!_emailPattern.hasMatch(e)) return 'Enter a valid email address.';
    return null;
  }

  static String? validatePassword(
    String password, {
    bool forSignUp = false,
  }) {
    if (password.isEmpty) return 'Password is required.';
    if (password.length > 128) return 'Password is too long.';
    if (forSignUp) {
      if (password.length < 8) {
        return 'Password must be at least 8 characters.';
      }
      final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
      final hasDigit = RegExp(r'[0-9]').hasMatch(password);
      if (!hasLetter || !hasDigit) {
        return 'Password must include letters and numbers.';
      }
    } else if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  static String? validateDisplayName(String name, {bool required = false}) {
    final n = sanitizeDisplayName(name);
    if (n.isEmpty) {
      return required ? 'Display name is required.' : null;
    }
    if (n.length < 2) return 'Display name is too short.';
    return null;
  }

  bool get isSignedIn =>
      SupabaseService.isReady &&
      SupabaseService.client.auth.currentUser != null;

  User? get currentUser =>
      SupabaseService.isReady ? SupabaseService.client.auth.currentUser : null;

  static AppRole parseRole(
    dynamic value, {
    AppRole fallback = AppRole.trainee,
  }) {
    final s = value?.toString().trim().toLowerCase() ?? '';
    if (s == 'admin') return AppRole.admin;
    if (s == 'trainer') return AppRole.trainer;
    if (s == 'trainee') return AppRole.trainee;
    return fallback;
  }

  static AppRole resolveRole({
    dynamic profileRole,
    dynamic metadataRole,
    String? email,
  }) {
    final fromProfile = parseRole(profileRole, fallback: AppRole.trainee);
    final fromMeta = parseRole(metadataRole, fallback: AppRole.trainee);
    final e = (email ?? '').trim().toLowerCase();
    if (fromProfile == AppRole.admin ||
        fromMeta == AppRole.admin ||
        isKnownAdminEmail(e)) {
      return AppRole.admin;
    }
    if (isKnownTrainerEmail(e)) return AppRole.trainer;
    if (fromProfile == AppRole.trainer || fromMeta == AppRole.trainer) {
      return AppRole.trainer;
    }
    return AppRole.trainee;
  }

  static bool isKnownAdminEmail(String email) {
    final e = email.trim().toLowerCase();
    if (e.isEmpty) return false;
    if (e == 'admin@trainix.com') return true;
    if (e == 'admin1@trainix.com') return true;
    if (e.startsWith('admin') && e.contains('@trainix.com')) return true;
    return false;
  }

  static bool isKnownTrainerEmail(String email) {
    final e = email.trim().toLowerCase();
    if (e.isEmpty) return false;
    if (e == 'trainer@trainix.com') return true;
    if (e == 'josephine.lim@trainix.com') return true;
    if (e.startsWith('trainer') && e.contains('@')) return true;
    return false;
  }

  Future<bool> signIn({required String email, required String password}) async {
    lastError = null;
    final emailError = validateEmail(email);
    if (emailError != null) {
      lastError = emailError;
      return false;
    }
    final passwordError = validatePassword(password);
    if (passwordError != null) {
      lastError = passwordError;
      return false;
    }
    if (!SupabaseService.isReady) {
      lastError = 'Supabase is not ready';
      return false;
    }
    try {
      final res = await SupabaseService.client.auth.signInWithPassword(
        email: sanitizeEmail(email),
        password: password,
      );
      if (res.user == null) {
        lastError = 'Sign in failed';
        return false;
      }
      await loadProfileIntoApp();
      debugPrint(
        'auth signIn role=${ProfileData.role.name} email=${email.trim()}',
      );
      return true;
    } on AuthException catch (e) {
      lastError = e.message;
      debugPrint('auth signIn failed: ${e.message}');
      return false;
    } catch (e) {
      lastError = e.toString();
      debugPrint('auth signIn failed: $lastError');
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
    required AppRole role,
  }) async {
    lastError = null;
    final emailError = validateEmail(email);
    if (emailError != null) {
      lastError = emailError;
      return false;
    }
    final passwordError = validatePassword(password, forSignUp: true);
    if (passwordError != null) {
      lastError = passwordError;
      return false;
    }
    final nameError = validateDisplayName(displayName, required: true);
    if (nameError != null) {
      lastError = nameError;
      return false;
    }
    if (!SupabaseService.isReady) {
      lastError = 'Supabase is not ready';
      return false;
    }
    final safeName = sanitizeDisplayName(displayName);
    try {
      final res = await SupabaseService.client.auth.signUp(
        email: sanitizeEmail(email),
        password: password,
        data: {
          'display_name': safeName.isEmpty
              ? sanitizeEmail(email).split('@').first
              : safeName,
          'role': role.name,
        },
      );
      if (res.user == null) {
        lastError = 'Sign up failed';
        return false;
      }
      final uid = res.user!.id;
      final safeEmail = sanitizeEmail(email);
      final name = safeName.isEmpty
          ? safeEmail.split('@').first
          : safeName;

      ProfileData.current = AppUser(
        id: uid,
        displayName: name,
        email: safeEmail,
        role: role,
      );

      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          await SupabaseService.client.from('profiles').upsert({
            'id': uid,
            'email': safeEmail,
            'display_name': name,
            'role': role.name,
          });
          break;
        } catch (e) {
          debugPrint('signup profile role upsert failed ($attempt): $e');
          await Future.delayed(Duration(milliseconds: 250 * (attempt + 1)));
        }
      }

      await Future.delayed(const Duration(milliseconds: 350));
      await loadProfileIntoApp();
      if (ProfileData.role != role) {
        ProfileData.current = ProfileData.current.copyWith(role: role);
        try {
          await SupabaseService.client
              .from('profiles')
              .update({
                'role': role.name,
                'display_name': name,
                'email': email.trim(),
              })
              .eq('id', uid);
        } catch (e) {
          debugPrint('signup role force update failed: $e');
        }
      }
      debugPrint(
        'auth signUp role=${ProfileData.role.name} requested=${role.name}',
      );
      return true;
    } on AuthException catch (e) {
      lastError = e.message;
      debugPrint('auth signUp failed: ${e.message}');
      return false;
    } catch (e) {
      lastError = e.toString();
      debugPrint('auth signUp failed: $lastError');
      return false;
    }
  }

  static Future<bool> confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Sign out?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'You will need your email and password to sign back in.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sign out',
              style: TextStyle(color: Color(0xFFF87171)),
            ),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> signOut() async {
    MiniTrainingProgress.resetAll();
    TrainixDebug.resetForLogout();
    NotificationInboxService.instance.clearLocalOnly();
    NotificationInboxService.instance.stopRealtime();
    LiveSessionStore.instance.stopRealtime();
    LiveSessionStore.instance.clearLocal();
    TrainingNotificationCenter.clearToasts();
    if (!SupabaseService.isReady) return;
    try {
      await SupabaseService.client.auth.signOut();
    } catch (_) {}
  }

  Future<void> loadProfileIntoApp() async {
    if (!SupabaseService.isReady) return;
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return;

    final meta = user.userMetadata ?? {};
    try {
      final row = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (row != null) {
        final role = resolveRole(
          profileRole: row['role'],
          metadataRole: meta['role'],
          email: row['email'] as String? ?? user.email,
        );
        final displayName =
            row['display_name'] as String? ??
            meta['display_name']?.toString() ??
            user.email?.split('@').first ??
            'User';
        ProfileData.current = AppUser(
          id: user.id,
          displayName: displayName,
          email: row['email'] as String? ?? user.email ?? '',
          role: role,
          phone: row['phone'] as String? ?? '',
          bio: row['bio'] as String? ?? '',
          preferredSector: row['preferred_sector'] as String? ?? 'Tech Support',
          gender: row['gender'] as String? ?? '',
        );

        final dbRole = parseRole(row['role']);
        if (dbRole != role) {
          try {
            await SupabaseService.client
                .from('profiles')
                .update({'role': role.name})
                .eq('id', user.id);
            debugPrint('repaired profiles.role to ${role.name}');
          } catch (e) {
            debugPrint('role repair update failed: $e');
          }
        }
        debugPrint(
          'loadProfile role=${role.name} db=${row['role']} meta=${meta['role']}',
        );
        return;
      }
    } catch (e) {
      debugPrint('load profile failed: $e');
    }

    final role = resolveRole(
      profileRole: null,
      metadataRole: meta['role'],
      email: user.email,
    );
    ProfileData.current = AppUser(
      id: user.id,
      displayName:
          '${meta['display_name'] ?? user.email?.split('@').first ?? 'User'}',
      email: user.email ?? '',
      role: role,
    );

    try {
      await SupabaseService.client.from('profiles').upsert({
        'id': user.id,
        'email': user.email,
        'display_name': ProfileData.displayName,
        'role': role.name,
        'phone': ProfileData.phone,
        'bio': ProfileData.bio,
        'preferred_sector': ProfileData.preferredSector,
        'gender': ProfileData.gender,
      });
    } catch (e) {
      debugPrint('profile upsert failed: $e');
    }
  }

  static Future<bool> saveProfileDetails() async {
    lastError = null;
    if (!SupabaseService.isReady) return false;
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return false;
    try {
      await SupabaseService.client.from('profiles').upsert({
        'id': user.id,
        'email': user.email ?? ProfileData.email,
        'display_name': ProfileData.displayName,
        'role': ProfileData.role.name,
        'phone': ProfileData.phone,
        'bio': ProfileData.bio,
        'preferred_sector': ProfileData.preferredSector,
        'gender': ProfileData.gender,
      });
      return true;
    } catch (e) {
      lastError = e.toString();
      debugPrint('save profile failed: $lastError');
      return false;
    }
  }
}
