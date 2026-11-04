import 'package:flutter/material.dart';
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
          .update({'role': role})
          .eq('id', id);
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
              backgroundColor: const Color(0xFF1A1F26),
              title: const Text(
                'Edit account',
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${profile['email'] ?? ''}',
                      style: const TextStyle(color: Color(0xFF9CA3AF)),
                    ),
                    const Gap(12),
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Display name',
                        labelStyle: TextStyle(color: Color(0xFF9CA3AF)),
                      ),
                    ),
                    const Gap(10),
                    DropdownButtonFormField<String>(
                      value: role,
                      dropdownColor: const Color(0xFF1A1F26),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        labelStyle: TextStyle(color: Color(0xFF9CA3AF)),
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
                        style: const TextStyle(color: Color(0xFFF87171)),
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
                                })
                                .eq('id', id);
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
        backgroundColor: const Color(0xFF1A1F26),
        title: const Text(
          'Delete account?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Remove $name permanently? This cannot be undone.',
          style: const TextStyle(color: Color(0xFF9CA3AF)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFF87171)),
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
              backgroundColor: const Color(0xFF1A1F26),
              title: const Text(
                'Create account',
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: emailCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: Color(0xFF9CA3AF)),
                      ),
                    ),
                    const Gap(10),
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Password (min 8)',
                        labelStyle: TextStyle(color: Color(0xFF9CA3AF)),
                      ),
                    ),
                    const Gap(10),
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Display name',
                        labelStyle: TextStyle(color: Color(0xFF9CA3AF)),
                      ),
                    ),
                    const Gap(10),
                    DropdownButtonFormField<String>(
                      value: role,
                      dropdownColor: const Color(0xFF1A1F26),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        labelStyle: TextStyle(color: Color(0xFF9CA3AF)),
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
                        style: const TextStyle(color: Color(0xFFF87171)),
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
                            final res = await SupabaseService.client.functions
                                .invoke(
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
      backgroundColor: const Color(0xFF0B0F14),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Text(
                    'Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap(12),
                  Text(
                    ProfileData.displayName,
                    style: const TextStyle(color: Color(0xFF9CA3AF)),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _openCreateUser,
                    child: const Text('Create account'),
                  ),
                  TextButton(
                    onPressed: _loadProfiles,
                    child: const Text('Refresh'),
                  ),
                  TextButton(onPressed: _logout, child: const Text('Sign out')),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _tabChip('Accounts', 0),
                  const Gap(8),
                  _tabChip('Activity', 1),
                  const Gap(8),
                  _tabChip('Notes', 2),
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

  Widget _tabChip(String label, int index) {
    final selected = _tab == index;
    return InkWell(
      onTap: () => setState(() => _tab = index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1D4ED8) : const Color(0xFF1A1F26),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF9CA3AF),
            fontWeight: FontWeight.w600,
          ),
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
            style: const TextStyle(color: Color(0xFFF87171)),
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
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search name, email, or role',
                  hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                  filled: true,
                  fillColor: const Color(0xFF12171D),
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
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          ),
          const Gap(8),
          Expanded(
            child: rows.isEmpty
                ? const Center(
                    child: Text(
                      'No accounts found yet. Use Create account to add the first user.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF9CA3AF)),
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
                              color: const Color(0xFF12171D),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Gap(4),
                                      Text(
                                        email,
                                        style: const TextStyle(
                                          color: Color(0xFF9CA3AF),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DropdownButton<String>(
                                  value:
                                      role == 'admin' ||
                                          role == 'trainer' ||
                                          role == 'trainee'
                                      ? role
                                      : 'trainee',
                                  dropdownColor: const Color(0xFF1A1F26),
                                  style: const TextStyle(color: Colors.white),
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
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: Color(0xFF9CA3AF),
                                    size: 20,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  onPressed: () => _confirmDelete(p),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFF87171),
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
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin tips',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          Gap(12),
          Text(
            '• Create account adds a new trainee, trainer, or admin login.',
            style: TextStyle(color: Color(0xFF9CA3AF), height: 1.5),
          ),
          Text(
            '• Edit changes display name and role. Delete removes the account.',
            style: TextStyle(color: Color(0xFF9CA3AF), height: 1.5),
          ),
          Text(
            '• Activity shows logins and practice sessions for trainees and trainers.',
            style: TextStyle(color: Color(0xFF9CA3AF), height: 1.5),
          ),
          Text(
            '• If Create account fails, finish the admin setup scripts in the project docs.',
            style: TextStyle(color: Color(0xFF9CA3AF), height: 1.5),
          ),
        ],
      ),
    );
  }
}
