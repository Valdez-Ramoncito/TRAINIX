import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart' as wf;
import 'package:webview_windows/webview_windows.dart' as ww;
import 'package:trainixprogram/components/button/create_button.dart';
import 'package:trainixprogram/components/class/jitsi_room.dart';
import 'package:trainixprogram/components/class/live_training_session.dart';
import 'package:trainixprogram/components/size.dart';
import 'package:trainixprogram/screens/page/profile.dart';
import 'package:trainixprogram/components/class/trainee_activity_log.dart';
import 'package:trainixprogram/services/jaas_token_service.dart';

class LiveTrainingRoom extends StatefulWidget {
  const LiveTrainingRoom({
    super.key,
    required this.session,
    required this.isTrainer,
  });

  final LiveTrainingSession session;
  final bool isTrainer;

  @override
  State<LiveTrainingRoom> createState() => _LiveTrainingRoomState();
}

class _LiveTrainingRoomState extends State<LiveTrainingRoom> {
  wf.WebViewController? _mobileController;
  ww.WebviewController? _windowsController;
  bool _webviewReady = false;
  bool _webviewFailed = false;
  bool _showDetails = false;
  String? _statusMessage;
  late TextEditingController _noteTitleCtrl;
  late TextEditingController _noteBodyCtrl;
  late TextEditingController _feedbackCtrl;
  late TextEditingController _takeawayCtrl;
  late TextEditingController _checklistAddCtrl;
  int? _rating;
  bool _needsFollowUp = false;
  bool _kicked = false;
  String? _jwt;

  bool get _isWindowsDesktop => !kIsWeb && Platform.isWindows;

  LiveTrainingSession get _live =>
      LiveSessionStore.instance.findByCode(widget.session.id) ?? widget.session;

  String get _meetingUrl => JitsiConfig.meetingUrl(
        roomCode: _live.id,
        displayName: ProfileData.displayName,
        asModerator: widget.isTrainer,
        jwt: _jwt,
      );

  @override
  void initState() {
    super.initState();
    final bench = LiveSessionStore.instance.workbenchFor(widget.session);
    final active = bench.activeNote;
    _noteTitleCtrl = TextEditingController(text: active?.title ?? '');
    _noteBodyCtrl = TextEditingController(text: active?.body ?? '');
    _feedbackCtrl = TextEditingController(text: bench.feedback);
    _takeawayCtrl = TextEditingController(text: bench.takeaway);
    _checklistAddCtrl = TextEditingController();
    _rating = bench.rating ?? 5;
    _needsFollowUp = bench.needsFollowUp;
    LiveSessionStore.instance.addListener(_onStoreChanged);
    LiveSessionStore.instance.startRealtime();
    _initWebView();
  }

  void _onStoreChanged() {
    if (!mounted || _kicked) return;
    final live = LiveSessionStore.instance.findByCode(widget.session.id);
    final ended = live == null || live.closed;
    if (ended) {
      _kicked = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            live == null
                ? 'Session ended. Results were saved to your dashboard.'
                : 'Session ended. You have left the room.',
          ),
        ),
      );
      Navigator.of(context).pop();
      return;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    LiveSessionStore.instance.removeListener(_onStoreChanged);
    _noteTitleCtrl.dispose();
    _noteBodyCtrl.dispose();
    _feedbackCtrl.dispose();
    _takeawayCtrl.dispose();
    _checklistAddCtrl.dispose();
    _windowsController?.dispose();
    super.dispose();
  }

  Future<void> _initWebView() async {
    setState(() {
      _webviewFailed = false;
      _webviewReady = false;
      _statusMessage = 'Loading call...';
    });

    if (JitsiConfig.jaasConfigured) {
      setState(() => _statusMessage = 'Starting video call...');
      _jwt = await JaasTokenService.instance.fetchToken(
        roomCode: _live.id,
        asModerator: widget.isTrainer,
      );
      if (!mounted) return;
      if (_jwt == null) {
        setState(() {
          _statusMessage = JitsiConfig.statusHint(hasJwt: false);
        });
      }
    }

    if (_isWindowsDesktop) {
      await _initWindowsWebView();
    } else {
      await _initStandardWebView();
    }
  }

  Future<void> _initWindowsWebView() async {
    try {
      final version = await ww.WebviewController.getWebViewVersion();
      if (version == null) {
        if (!mounted) return;
        setState(() {
          _webviewFailed = true;
          _statusMessage =
              'Microsoft Edge WebView2 Runtime is missing. Install it, or use Open in browser.';
        });
        return;
      }

      final controller = ww.WebviewController();
      await controller.initialize();
      await controller.setBackgroundColor(AppColors.inputFill(context));
      await controller.setPopupWindowPolicy(ww.WebviewPopupWindowPolicy.deny);
      await controller.loadUrl(_meetingUrl);

      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _windowsController = controller;
        _webviewReady = true;
        _statusMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _webviewFailed = true;
        _statusMessage =
            'Could not start in-app call on Windows. Use Open in browser.';
      });
    }
  }

  Future<void> _initStandardWebView() async {
    try {
      final controller = wf.WebViewController()
        ..setJavaScriptMode(wf.JavaScriptMode.unrestricted)
        ..setBackgroundColor(AppColors.inputFill(context))
        ..setNavigationDelegate(
          wf.NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) {
                setState(() {
                  _webviewReady = true;
                  _statusMessage = null;
                });
              }
            },
            onWebResourceError: (_) {
              if (mounted) {
                setState(() {
                  _webviewFailed = true;
                  _statusMessage =
                      'In-app call could not load. Use Open in browser.';
                });
              }
            },
          ),
        );
      await controller.loadRequest(Uri.parse(_meetingUrl));
      if (!mounted) return;
      setState(() {
        _mobileController = controller;
        _statusMessage = 'Loading call...';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _webviewFailed = true;
        _statusMessage =
            'In-app call is not available on this platform. Use Open in browser.';
      });
    }
  }

  Future<void> _openExternal() async {
    final uri = Uri.parse(_meetingUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the browser.')),
      );
    }
  }

  Future<void> _reloadCall() async {
    if (_isWindowsDesktop) {
      final c = _windowsController;
      if (c != null) {
        setState(() {
          _webviewReady = false;
          _statusMessage = 'Loading call...';
        });
        try {
          await c.loadUrl(_meetingUrl);
          if (mounted) {
            setState(() {
              _webviewReady = true;
              _statusMessage = null;
            });
          }
        } catch (_) {
          await _initWebView();
        }
      } else {
        await _initWebView();
      }
      return;
    }

    setState(() {
      _webviewFailed = false;
      _webviewReady = false;
      _statusMessage = 'Loading call...';
    });
    final c = _mobileController;
    if (c != null) {
      await c.loadRequest(Uri.parse(_meetingUrl));
    } else {
      await _initWebView();
    }
  }

  Future<void> _openSessionTools() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppColors.elevated(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.borderIdle(context)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 620),
            child: _SessionToolsPanel(
              roomId: _live.id,
              isTrainer: widget.isTrainer,
              noteTitleCtrl: _noteTitleCtrl,
              noteBodyCtrl: _noteBodyCtrl,
              feedbackCtrl: _feedbackCtrl,
              takeawayCtrl: _takeawayCtrl,
              checklistAddCtrl: _checklistAddCtrl,
              rating: _rating,
              needsFollowUp: _needsFollowUp,
              onRating: (v) {
                setState(() => _rating = v);
              },
              onFollowUp: (v) {
                setState(() => _needsFollowUp = v);
              },
              onChanged: () {
                if (mounted) setState(() {});
              },
              onClose: () => Navigator.pop(ctx),
            ),
          ),
        );
      },
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final live = _live;
    final info = computeRoomStatus(live);
    final roleLabel = widget.isTrainer ? 'Trainer' : 'Trainee';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryText().withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.video_camera_front_outlined,
                      size: 20,
                      color: AppColors.secondaryText(),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Live Training Room',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontSize: context.responsiveFont(6),
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Gap(10),
                            _StatusPill(info: info),
                          ],
                        ),
                        const Gap(6),
                        Text(
                          '${live.name}  ·  $roleLabel  ·  ${live.presence.occupantCount} / 2',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: AppColors.textMuted(context),
                                  fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Gap(12),
                  CreateButton(
                    text: 'Leave',
                    icon: Icons.logout_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Gap(12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.scaffold(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.borderIdle(context),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildCallArea(),
                ),
              ),
              const Gap(10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${JitsiConfig.statusHint(hasJwt: _jwt != null)}',
                      style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.vpn_key_outlined,
                        size: 14,
                        color: AppColors.secondaryText(),
                      ),
                      const Gap(5),
                      SelectableText(
                        'Room code: ${live.id}',
                        style: TextStyle(
                          color: AppColors.secondaryText(),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Gap(10),
              Align(
                alignment: Alignment.center,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    CreateButton(
                      text: 'Reload call',
                      icon: Icons.refresh_rounded,
                      onTap: _reloadCall,
                    ),
                    CreateButton(
                      text: 'Open in browser',
                      icon: Icons.open_in_new_rounded,
                      onTap: _openExternal,
                    ),
                    CreateButton(
                      text: _showDetails ? 'Hide info' : 'Room info',
                      icon: Icons.info_outline_rounded,
                      onTap: () => setState(() {
                        _showDetails = !_showDetails;
                      }),
                    ),
                    if (widget.isTrainer)
                      CreateButton(
                        text: 'Session tools',
                        icon: Icons.tune_rounded,
                        onTap: () => _openSessionTools(),
                      ),
                  ],
                ),
              ),
              if (_showDetails) ...[
                const Gap(10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.panel(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.borderIdle(context),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _row('Room code', live.id),
                          const Gap(8),
                          _row('Trainer', live.trainerName),
                          const Gap(8),
                          _row(
                            'Visibility',
                            live.isPrivate ? 'Private' : 'Public',
                          ),
                          if (live.designatedTraineeName != null) ...[
                            const Gap(8),
                            _row('Trainee', live.designatedTraineeName!),
                          ],
                          const Gap(8),
                          _row('Mode', live.mode.name),
                          if (live.description != null) ...[
                            const Gap(8),
                            _row('Agenda', live.description!),
                          ],
                          const Gap(8),
                          _row(
                            'Jitsi room',
                            JitsiConfig.roomNameFromCode(live.id),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallArea() {
    if (_webviewFailed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.videocam_off_outlined,
                size: 40,
                color: AppColors.textMuted(context),
              ),
              const Gap(12),
              Text(
                _statusMessage ?? 'In-app call could not start.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textMuted(context), fontSize: 13),
              ),
              const Gap(16),
              CreateButton(text: 'Open in browser', onTap: _openExternal),
            ],
          ),
        ),
      );
    }

    if (_isWindowsDesktop && _windowsController != null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: ww.Webview(
                  _windowsController!,
                  width: w.isFinite ? w : null,
                  height: h.isFinite ? h : null,
                  permissionRequested:
                      (url, permission, isUserInitiated) async {
                    return ww.WebviewPermissionDecision.allow;
                  },
                ),
              ),
              if (!_webviewReady)
                Container(
                  color: AppColors.scaffold(context),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const Gap(12),
                      Text(
                        _statusMessage ?? 'Loading call...',
                        style: TextStyle(
                          color: AppColors.textMuted(context),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      );
    }

    if (_mobileController != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: wf.WebViewWidget(controller: _mobileController!),
          ),
          if (!_webviewReady)
            Container(
              color: AppColors.scaffold(context),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const Gap(12),
                  Text(
                    _statusMessage ?? 'Loading call...',
                    style: TextStyle(
                        color: AppColors.textMuted(context), fontSize: 13),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const Gap(12),
          Text(
            _statusMessage ?? 'Loading call...',
            style: TextStyle(color: AppColors.textMuted(context), fontSize: 13),
          ),
        ],
      ),
    );
  }

  IconData _detailIcon(String label) {
    switch (label) {
      case 'Room code':
        return Icons.vpn_key_outlined;
      case 'Trainer':
        return Icons.person_outline_rounded;
      case 'Visibility':
        return Icons.visibility_outlined;
      case 'Trainee':
        return Icons.school_outlined;
      case 'Mode':
        return Icons.category_outlined;
      case 'Agenda':
        return Icons.notes_rounded;
      case 'Jitsi room':
        return Icons.videocam_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  Widget _row(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            _detailIcon(label),
            size: 13,
            color: AppColors.textMuted(context),
          ),
        ),
        const Gap(6),
        SizedBox(
          width: 94,
          child: Text(
            label,
            style: TextStyle(color: AppColors.textMuted(context), fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
                color: AppColors.textSecondary(context), fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _SessionToolsPanel extends StatefulWidget {
  const _SessionToolsPanel({
    required this.roomId,
    required this.isTrainer,
    required this.noteTitleCtrl,
    required this.noteBodyCtrl,
    required this.feedbackCtrl,
    required this.takeawayCtrl,
    required this.checklistAddCtrl,
    required this.rating,
    required this.needsFollowUp,
    required this.onRating,
    required this.onFollowUp,
    required this.onChanged,
    required this.onClose,
  });

  final String roomId;
  final bool isTrainer;
  final TextEditingController noteTitleCtrl;
  final TextEditingController noteBodyCtrl;
  final TextEditingController feedbackCtrl;
  final TextEditingController takeawayCtrl;
  final TextEditingController checklistAddCtrl;
  final int? rating;
  final bool needsFollowUp;
  final ValueChanged<int?> onRating;
  final ValueChanged<bool> onFollowUp;
  final VoidCallback onChanged;
  final VoidCallback onClose;

  @override
  State<_SessionToolsPanel> createState() => _SessionToolsPanelState();
}

class _SessionToolsPanelState extends State<_SessionToolsPanel> {
  late int? _rating;
  late bool _followUp;

  @override
  void initState() {
    super.initState();
    _rating = widget.rating ?? 5;
    _followUp = widget.needsFollowUp;
  }

  SessionWorkbench get _bench => LiveSessionStore.instance.workbenchFor(
        LiveSessionStore.instance.findByCode(widget.roomId) ??
            LiveTrainingSession(
              id: widget.roomId,
              name: '',
              trainerName: '',
              createdAt: DateTime.now(),
            ),
      );

  void _loadActiveNote(SessionWorkbench bench) {
    final active = bench.activeNote;
    widget.noteTitleCtrl.text = active?.title ?? '';
    widget.noteBodyCtrl.text = active?.body ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final bench = _bench;
    final activeId = bench.activeNote?.id;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune_rounded,
                size: 20,
                color: AppColors.secondaryText(),
              ),
              const Gap(8),
              const Expanded(
                child: Text(
                  'Session tools',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: widget.onClose,
                icon: Icon(Icons.close,
                    size: 20, color: AppColors.textMuted(context)),
              ),
            ],
          ),
          const Gap(10),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Notes',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (widget.isTrainer && !bench.ended)
                            IconButton(
                              tooltip: 'Add note',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                              onPressed: () {
                                final next = LiveSessionStore.instance.addNote(
                                  widget.roomId,
                                );
                                _loadActiveNote(next);
                                setState(() {});
                                widget.onChanged();
                              },
                              icon: Icon(
                                Icons.add,
                                size: 18,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                        ],
                      ),
                      const Gap(6),
                      Expanded(
                        child: ListView.builder(
                          itemCount: bench.notes.length,
                          itemBuilder: (_, i) {
                            final n = bench.notes[i];
                            final selected = n.id == activeId;
                            return InkWell(
                              onTap: () {
                                LiveSessionStore.instance.selectNote(
                                  widget.roomId,
                                  n.id,
                                );
                                _loadActiveNote(_bench);
                                setState(() {});
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.secondaryText()
                                          .withValues(alpha: 0.2)
                                      : AppColors.inputFill(context),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.secondaryText()
                                        : AppColors.borderIdle(context),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        n.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: selected
                                              ? AppColors.textPrimary(context)
                                              : AppColors.textSecondary(
                                                  context),
                                        ),
                                      ),
                                    ),
                                    if (widget.isTrainer &&
                                        !bench.ended &&
                                        bench.notes.length > 1)
                                      GestureDetector(
                                        onTap: () {
                                          final next = LiveSessionStore.instance
                                              .removeNote(widget.roomId, n.id);
                                          _loadActiveNote(next);
                                          setState(() {});
                                          widget.onChanged();
                                        },
                                        child: Icon(
                                          Icons.close,
                                          size: 14,
                                          color: AppColors.textMuted(context),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(14),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Active note',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const Gap(8),
                        TextField(
                          controller: widget.noteTitleCtrl,
                          enabled: !bench.ended,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary(context),
                          ),
                          decoration: _fieldDecoration('Title'),
                          onChanged: (v) {
                            LiveSessionStore.instance.updateActiveNote(
                              roomId: widget.roomId,
                              title: v,
                            );
                            setState(() {});
                          },
                        ),
                        const Gap(8),
                        TextField(
                          controller: widget.noteBodyCtrl,
                          enabled: !bench.ended,
                          maxLines: 5,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary(context),
                          ),
                          decoration: _fieldDecoration(
                            widget.isTrainer
                                ? 'What did you cover? Tips for the trainee...'
                                : 'What did you learn or need to retry?',
                          ),
                          onChanged: (v) {
                            LiveSessionStore.instance.updateActiveNote(
                              roomId: widget.roomId,
                              body: v,
                            );
                          },
                        ),
                        const Gap(16),
                        const Text(
                          'Checklist',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const Gap(6),
                        ...bench.checklist.map((item) {
                          return Row(
                            children: [
                              Expanded(
                                child: CheckboxListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  value: item.done,
                                  title: Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: item.done
                                          ? AppColors.textMuted(context)
                                          : AppColors.textSecondary(context),
                                      decoration: item.done
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  onChanged: bench.ended
                                      ? null
                                      : (_) {
                                          LiveSessionStore.instance
                                              .toggleChecklistItem(
                                            widget.roomId,
                                            item.id,
                                          );
                                          setState(() {});
                                          widget.onChanged();
                                        },
                                ),
                              ),
                              if (widget.isTrainer && !bench.ended)
                                IconButton(
                                  onPressed: () {
                                    LiveSessionStore.instance
                                        .removeChecklistItem(
                                      widget.roomId,
                                      item.id,
                                    );
                                    setState(() {});
                                    widget.onChanged();
                                  },
                                  icon: Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: AppColors.textMuted(context),
                                  ),
                                ),
                            ],
                          );
                        }),
                        if (widget.isTrainer && !bench.ended) ...[
                          const Gap(6),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: widget.checklistAddCtrl,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary(context),
                                  ),
                                  decoration: _fieldDecoration(
                                    'Add checklist item',
                                  ),
                                  onSubmitted: (_) => _addChecklist(),
                                ),
                              ),
                              const Gap(8),
                              CreateButton(text: 'Add', onTap: _addChecklist),
                            ],
                          ),
                        ],
                        const Gap(16),
                        const Text(
                          'Key takeaway',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const Gap(8),
                        TextField(
                          controller: widget.takeawayCtrl,
                          enabled: !bench.ended,
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary(context),
                          ),
                          decoration: _fieldDecoration(
                            'One main point to remember...',
                          ),
                          onChanged: (v) {
                            LiveSessionStore.instance.saveFeedback(
                              roomId: widget.roomId,
                              rating: _rating,
                              feedback: widget.feedbackCtrl.text,
                              takeaway: v,
                              needsFollowUp: _followUp,
                            );
                          },
                        ),
                        const Gap(10),
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: _followUp,
                          title: Text(
                            'Needs follow-up session',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                          onChanged: bench.ended
                              ? null
                              : (v) {
                                  final val = v ?? false;
                                  setState(() => _followUp = val);
                                  widget.onFollowUp(val);
                                  LiveSessionStore.instance.saveFeedback(
                                    roomId: widget.roomId,
                                    rating: _rating,
                                    feedback: widget.feedbackCtrl.text,
                                    takeaway: widget.takeawayCtrl.text,
                                    needsFollowUp: val,
                                  );
                                },
                        ),
                        const Gap(12),
                        const Text(
                          'End feedback',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const Gap(6),
                        Row(
                          children: List.generate(5, (i) {
                            final star = i + 1;
                            final selected =
                                _rating != null && _rating! >= star;
                            return IconButton(
                              onPressed: bench.ended
                                  ? null
                                  : () {
                                      setState(() => _rating = star);
                                      widget.onRating(star);
                                      LiveSessionStore.instance.saveFeedback(
                                        roomId: widget.roomId,
                                        rating: star,
                                        feedback: widget.feedbackCtrl.text,
                                        takeaway: widget.takeawayCtrl.text,
                                        needsFollowUp: _followUp,
                                      );
                                    },
                              icon: Icon(
                                selected
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 28,
                                color: selected
                                    ? AppColors.warningText()
                                    : AppColors.textMuted(context),
                              ),
                            );
                          }),
                        ),
                        const Gap(6),
                        TextField(
                          controller: widget.feedbackCtrl,
                          maxLines: 3,
                          enabled: !bench.ended,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary(context),
                          ),
                          decoration: _fieldDecoration(
                            'Short feedback after the session...',
                          ),
                          onChanged: (v) {
                            LiveSessionStore.instance.saveFeedback(
                              roomId: widget.roomId,
                              rating: _rating,
                              feedback: v,
                              takeaway: widget.takeawayCtrl.text,
                              needsFollowUp: _followUp,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(12),
          if (bench.ended)
            Text(
              'Session ended${bench.endedAt != null ? " · ${formatCreatedAt(bench.endedAt!)}" : ""}',
              style: TextStyle(color: AppColors.primaryText(), fontSize: 13),
            )
          else if (!widget.isTrainer)
            CreateButton(text: 'Close', onTap: widget.onClose)
          else
            Row(
              children: [
                Expanded(
                  child: CreateButton(text: 'Close', onTap: widget.onClose),
                ),
                const Gap(12),
                Expanded(
                  child: CreateButton(
                    text: 'End session',
                    onTap: () {
                      if (_rating == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Star rating is required before ending the session.',
                            ),
                          ),
                        );
                        return;
                      }
                      LiveSessionStore.instance.saveFeedback(
                        roomId: widget.roomId,
                        rating: _rating,
                        feedback: widget.feedbackCtrl.text,
                        takeaway: widget.takeawayCtrl.text,
                        needsFollowUp: _followUp,
                      );
                      LiveSessionStore.instance.endSession(widget.roomId);
                      TraineeActivityLogStore.instance.log(
                        actorName: ProfileData.displayName,
                        actorRole: 'trainer',
                        category: TraineeLogCategory.liveTraining,
                        action: 'Ended session',
                        detail: 'Marked live session as ended',
                        roomId: widget.roomId,
                      );
                      widget.onChanged();
                      widget.onClose();
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _addChecklist() {
    final label = widget.checklistAddCtrl.text;
    LiveSessionStore.instance.addChecklistItem(widget.roomId, label);
    widget.checklistAddCtrl.clear();
    setState(() {});
    widget.onChanged();
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textMuted(context), fontSize: 13),
      filled: true,
      fillColor: AppColors.inputFill(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.borderIdle(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.borderIdle(context)),
      ),
      contentPadding: const EdgeInsets.all(12),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.info});

  final RoomStatusInfo info;

  @override
  Widget build(BuildContext context) {
    Color c;
    switch (info.tone) {
      case ColorTone.green:
        c = AppColors.primaryText();
      case ColorTone.blue:
        c = AppColors.secondaryText();
      case ColorTone.amber:
        c = AppColors.warningText();
      case ColorTone.red:
        c = AppColors.errorText();
      case ColorTone.neutral:
        c = AppColors.textMuted(context);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withValues(alpha: 0.45)),
      ),
      child: Text(
        info.label.toUpperCase(),
        style: TextStyle(
          color: c,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
