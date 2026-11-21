import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/screens/page/profile.dart';
import 'package:trainixprogram/services/auth_service.dart';
import 'package:trainixprogram/services/supabase_service.dart';
import 'package:trainixprogram/screens/auth/loginscreen.dart';
import 'package:trainixprogram/screens/trainer_page/log_monitoring_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _tab = 0;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _profiles = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (!SupabaseService.isReady) {
        setState(() {
          _loading = false;
          _error = 'Supabase is not connected.';
          _profiles = [];
        });
        return;
      }
      final rows = await SupabaseService.client
          .from('profiles')
          .select('id, email, display_name, role, created_at')
          .order('created_at', ascending: false)
          .limit(200);
      final list = (rows as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (!mounted) return;
      setState(() {
        _profiles = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _profiles;
    return _profiles.where((p) {
      final email = '${p['email'] ?? ''}'.toLowerCase();
      final name = '${p['display_name'] ?? ''}'.toLowerCase();
      final role = '${p['role'] ?? ''}'.toLowerCase();
      return email.contains(q) || name.contains(q) || role.contains(q);
    }).toList();
  }

  Future<void> _logout() async {
    final ok = await AuthService.confirmSignOut(context);
    if (!ok || !mounted) return;
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _setRole(String id, String role) async {
    try {
      await SupabaseService.client
          .from('profiles')
          .update({'role': role}).eq('id', id);
      await _loadProfiles();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Role updated to $role')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  Future<void> _openEditUser(Map<String, dynamic> profile) async {
    final id = '${profile['id'] ?? ''}';
    final nameCtrl = TextEditingController(
      text: '${profile['display_name'] ?? ''}',
    );
    var role = '${profile['role'] ?? 'trainee'}';
    if (role != 'admin' && role != 'trainer' && role != 'trainee') {
      role = 'trainee';
    }
    var busy = false;
    String? formError;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              backgroundColor: AppColors.card(context),
              title: Text(
                'Edit account',
                style: TextStyle(color: AppColors.textPrimary(context)),
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${profile['email'] ?? ''}',
                      style: TextStyle(color: AppColors.textMuted(context)),
                    ),
                    const Gap(12),
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: AppColors.textPrimary(context)),
                      decoration: InputDecoration(
                        labelText: 'Display name',
                        labelStyle:
                            TextStyle(color: AppColors.textMuted(context)),
                      ),
                    ),
                    const Gap(10),
                    DropdownButtonFormField<String>(
                      value: role,
                      dropdownColor: AppColors.card(context),
                      style: TextStyle(color: AppColors.textPrimary(context)),
                      decoration: InputDecoration(
                        labelText: 'Role',
                        labelStyle:
                            TextStyle(color: AppColors.textMuted(context)),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'trainee',
                          child: Text('trainee'),
                        ),
                        DropdownMenuItem(
                          value: 'trainer',
                          child: Text('trainer'),
                        ),
                        DropdownMenuItem(value: 'admin', child: Text('admin')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setLocal(() => role = v);
                      },
                    ),
                    if (formError != null) ...[
                      const Gap(12),
                      Text(
                        formError!,
                        style: TextStyle(color: AppColors.errorText()),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: busy ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: busy
                      ? null
                      : () async {
                          setLocal(() {
                            busy = true;
                            formError = null;
                          });
                          try {
                            if (id.isEmpty) {
                              throw Exception('Missing account id');
                            }
                            await SupabaseService.client
                                .from('profiles')
                                .update({
                              'display_name': nameCtrl.text.trim().isEmpty
                                  ? (profile['email'] ?? 'User')
                                  : nameCtrl.text.trim(),
                              'role': role,
                            }).eq('id', id);
                            if (ctx.mounted) Navigator.pop(ctx);
                            await _loadProfiles();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Account updated')),
                            );
                          } catch (e) {
                            setLocal(() {
                              busy = false;
                              formError = e.toString();
                            });
                          }
                        },
                  child: Text(busy ? 'Saving...' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> profile) async {
    final id = '${profile['id'] ?? ''}';
    final name =
        '${profile['display_name'] ?? profile['email'] ?? 'this account'}';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(context),
        title: Text(
          'Delete account?',
          style: TextStyle(color: AppColors.textPrimary(context)),
        ),
        content: Text(
          'Remove $name permanently? This cannot be undone.',
          style: TextStyle(color: AppColors.textMuted(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: TextStyle(color: AppColors.errorText()),
            ),
          ),
        ],
      ),
    );
    if (ok != true || id.isEmpty) return;

    try {
      if (!SupabaseService.isReady) {
        throw Exception('Supabase is not connected');
      }
      final res = await SupabaseService.client.functions.invoke(
        'admin-delete-user',
        body: {'user_id': id},
      );
      if (res.status != 200) {
        final data = res.data;
        final err = data is Map ? '${data['error'] ?? data}' : '$data';
        // Fallback: delete profile row only if the function is not deployed.
        if (err.toLowerCase().contains('function') ||
            err.toLowerCase().contains('not found')) {
          await SupabaseService.client.from('profiles').delete().eq('id', id);
        } else {
          throw Exception(err);
        }
      }
      await _loadProfiles();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Account deleted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  Future<void> _openCreateUser() async {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    var role = 'trainee';
    var busy = false;
    String? formError;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              backgroundColor: AppColors.card(context),
              title: Row(
                children: [
                  Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 20,
                    color: AppColors.primaryText(),
                  ),
                  const Gap(8),
                  Text(
                    'Create account',
                    style: TextStyle(color: AppColors.textPrimary(context)),
                  ),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: emailCtrl,
                      style: TextStyle(color: AppColors.textPrimary(context)),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: AppColors.textMuted(context),
                        ),
                        labelStyle:
                            TextStyle(color: AppColors.textMuted(context)),
                      ),
                    ),
                    const Gap(10),
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      style: TextStyle(color: AppColors.textPrimary(context)),
                      decoration: InputDecoration(
                        labelText: 'Password (min 8)',
                        prefixIcon: Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.textMuted(context),
                        ),
                        labelStyle:
                            TextStyle(color: AppColors.textMuted(context)),
                      ),
                    ),
                    const Gap(10),
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: AppColors.textPrimary(context)),
                      decoration: InputDecoration(
                        labelText: 'Display name',
                        prefixIcon: Icon(
                          Icons.badge_outlined,
                          color: AppColors.textMuted(context),
                        ),
                        labelStyle:
                            TextStyle(color: AppColors.textMuted(context)),
                      ),
                    ),
                    const Gap(10),
                    DropdownButtonFormField<String>(
                      value: role,
                      dropdownColor: AppColors.card(context),
                      style: TextStyle(color: AppColors.textPrimary(context)),
                      decoration: InputDecoration(
                        labelText: 'Role',
                        prefixIcon: Icon(
                          Icons.manage_accounts_outlined,
                          color: AppColors.textMuted(context),
                        ),
                        labelStyle:
                            TextStyle(color: AppColors.textMuted(context)),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'trainee',
                          child: Text('trainee'),
                        ),
                        DropdownMenuItem(
                          value: 'trainer',
                          child: Text('trainer'),
                        ),
                        DropdownMenuItem(value: 'admin', child: Text('admin')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setLocal(() => role = v);
                      },
                    ),
                    if (formError != null) ...[
                      const Gap(12),
                      Text(
                        formError!,
                        style: TextStyle(color: AppColors.errorText()),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: busy ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: busy
                      ? null
                      : () async {
                          setLocal(() {
                            busy = true;
                            formError = null;
                          });
                          try {
                            if (!SupabaseService.isReady) {
                              throw Exception('Supabase is not connected');
                            }
                            final res =
                                await SupabaseService.client.functions.invoke(
                              'admin-create-user',
                              body: {
                                'email': emailCtrl.text.trim(),
                                'password': passCtrl.text,
                                'display_name': nameCtrl.text.trim(),
                                'role': role,
                              },
                            );
                            final data = res.data;
                            if (res.status != 200) {
                              final err = data is Map
                                  ? '${data['error'] ?? data}'
                                  : '$data';
                              throw Exception(err);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            await _loadProfiles();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Account created')),
                            );
                          } catch (e) {
                            var msg = e.toString();
                            if (msg.contains('permission denied') ||
                                msg.contains('profile update failed')) {
                              msg =
                                  'Login was created, but the profile row could not be saved. Ask your system owner to run the admin setup script, then set this user\'s role from Accounts.';
                            }
                            setLocal(() {
                              busy = false;
                              formError = msg;
                            });
                          }
                        },
                  child: Text(busy ? 'Creating...' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryText().withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 20,
                      color: AppColors.secondaryText(),
                    ),
                  ),
                  const Gap(10),
                  Text(
                    'Admin',
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap(12),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: AppColors.textMuted(context),
                      ),
                      const Gap(4),
                      Text(
                        ProfileData.displayName,
                        style: TextStyle(color: AppColors.textMuted(context)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _openCreateUser,
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
                    label: const Text('Create account'),
                  ),
                  TextButton.icon(
                    onPressed: _loadProfiles,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Refresh'),
                  ),
                  TextButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded, size: 16),
                    label: const Text('Sign out'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _tabChip('Accounts', 0, Icons.people_alt_outlined),
                  const Gap(8),
                  _tabChip('Activity', 1, Icons.monitor_heart_outlined),
                  const Gap(8),
                  _tabChip('Notes', 2, Icons.sticky_note_2_outlined),
                ],
              ),
            ),
            const Gap(12),
            Expanded(
              child: _tab == 0
                  ? _buildAccounts()
                  : _tab == 1
                      ? const LogMonitoringScreen(
                          showAllRoles: true,
                          embedded: true,
                        )
                      : _buildNotes(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabChip(String label, int index, IconData icon) {
    final selected = _tab == index;
    return InkWell(
      onTap: () => setState(() => _tab = index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.secondaryText()
              : AppColors.card(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.secondaryText()
                : AppColors.borderIdle(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected
                  ? AppColors.onPrimary(context)
                  : AppColors.textMuted(context),
            ),
            const Gap(6),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? AppColors.onPrimary(context)
                    : AppColors.textMuted(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccounts() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.errorText()),
          ),
        ),
      );
    }
    final rows = _filtered;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: TextField(
                style: TextStyle(color: AppColors.textPrimary(context)),
                decoration: InputDecoration(
                  hintText: 'Search name, email, or role',
                  hintStyle: TextStyle(color: AppColors.textMuted(context)),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppColors.textMuted(context),
                  ),
                  filled: true,
                  fillColor: AppColors.surface(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          ),
          const Gap(12),
          Text(
            '${rows.length} account(s)',
            style: TextStyle(color: AppColors.textMuted(context), fontSize: 13),
          ),
          const Gap(8),
          Expanded(
            child: rows.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.group_off_outlined,
                          size: 38,
                          color: AppColors.textMuted(context),
                        ),
                        const Gap(10),
                        Text(
                          'No accounts found yet. Use Create account to add the first user.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted(context)),
                        ),
                      ],
                    ),
                  )
                : Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: ListView.separated(
                        itemCount: rows.length,
                        separatorBuilder: (_, __) => const Gap(8),
                        itemBuilder: (context, i) {
                          final p = rows[i];
                          final id = '${p['id'] ?? ''}';
                          final name = '${p['display_name'] ?? 'Unnamed'}';
                          final email = '${p['email'] ?? ''}';
                          final role = '${p['role'] ?? 'trainee'}';
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface(context),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.chipBg(context),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color:
                                        _roleTone(role).withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _roleIcon(role),
                                    size: 18,
                                    color: _roleTone(role),
                                  ),
                                ),
                                const Gap(12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          color: AppColors.textPrimary(context),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Gap(3),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.mail_outline_rounded,
                                            size: 12,
                                            color: AppColors.textMuted(context),
                                          ),
                                          const Gap(4),
                                          Flexible(
                                            child: Text(
                                              email,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: AppColors.textMuted(
                                                    context),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                DropdownButton<String>(
                                  value: role == 'admin' ||
                                          role == 'trainer' ||
                                          role == 'trainee'
                                      ? role
                                      : 'trainee',
                                  dropdownColor: AppColors.card(context),
                                  style: TextStyle(
                                      color: AppColors.textPrimary(context)),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'trainee',
                                      child: Text('trainee'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'trainer',
                                      child: Text('trainer'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'admin',
                                      child: Text('admin'),
                                    ),
                                  ],
                                  onChanged: (v) {
                                    if (v == null || id.isEmpty) return;
                                    _setRole(id, v);
                                  },
                                ),
                                const Gap(4),
                                IconButton(
                                  tooltip: 'Edit',
                                  onPressed: () => _openEditUser(p),
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    color: AppColors.textMuted(context),
                                    size: 20,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  onPressed: () => _confirmDelete(p),
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: AppColors.errorText(),
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotes() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sticky_note_2_outlined,
                size: 18,
                color: AppColors.secondaryText(),
              ),
              const Gap(8),
              Text(
                'Admin tips',
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Gap(12),
          _tip(
            Icons.person_add_alt_1_outlined,
            'Create account adds a new trainee, trainer, or admin login.',
          ),
          _tip(
            Icons.edit_outlined,
            'Edit changes display name and role. Delete removes the account.',
          ),
          _tip(
            Icons.monitor_heart_outlined,
            'Activity shows logins and practice sessions for trainees and trainers.',
          ),
          _tip(
            Icons.build_outlined,
            'If Create account fails, finish the admin setup scripts in the project docs.',
          ),
        ],
      ),
    );
  }

  Widget _tip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.chipBg(context),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 14,
              color: AppColors.textSecondary(context),
            ),
          ),
          const Gap(10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textMuted(context),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings_outlined;
      case 'trainer':
        return Icons.co_present_outlined;
      default:
        return Icons.school_outlined;
    }
  }

  Color _roleTone(String role) {
    switch (role) {
      case 'admin':
        return AppColors.errorText();
      case 'trainer':
        return AppColors.warningText();
      default:
        return AppColors.primaryText();
    }
  }
}
