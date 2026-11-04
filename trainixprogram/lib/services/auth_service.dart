import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trainixprogram/screens/page/profile.dart';
import 'package:trainixprogram/models/training/training_categories.dart';
import 'package:trainixprogram/models/trainix_debug.dart';
import 'package:trainixprogram/services/notification_inbox_service.dart';
import 'package:trainixprogram/services/supabase_service.dart';
import 'package:trainixprogram/models/training/notifications/training_notification.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static String? lastError;

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
    if (!SupabaseService.isReady) {
      lastError = 'Supabase is not ready';
      return false;
    }
    try {
      final res = await SupabaseService.client.auth.signInWithPassword(
        email: email.trim(),
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
    if (!SupabaseService.isReady) {
      lastError = 'Supabase is not ready';
      return false;
    }
    try {
      final res = await SupabaseService.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'display_name': displayName.trim().isEmpty
              ? email.trim().split('@').first
              : displayName.trim(),
          'role': role.name,
        },
      );
      if (res.user == null) {
        lastError = 'Sign up failed';
        return false;
      }
      final uid = res.user!.id;
      final name = displayName.trim().isEmpty
          ? email.trim().split('@').first
          : displayName.trim();

      ProfileData.current = AppUser(
        id: uid,
        displayName: name,
        email: email.trim(),
        role: role,
      );

      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          await SupabaseService.client.from('profiles').upsert({
            'id': uid,
            'email': email.trim(),
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

  Future<void> signOut() async {
    MiniTrainingProgress.resetAll();
    TrainixDebug.resetForLogout();
    NotificationInboxService.instance.clearLocalOnly();
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
    final metaRole = parseRole(meta['role']);

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
