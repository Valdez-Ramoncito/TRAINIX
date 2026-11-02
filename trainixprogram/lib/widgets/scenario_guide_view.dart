import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/models/simulation_coach.dart';
import 'package:trainixprogram/models/coach_view_model.dart';
import 'package:trainixprogram/widgets/agent_notepad.dart';
import 'package:trainixprogram/widgets/sector_issue_guide_view.dart';

class ScenarioGuideView extends StatefulWidget {
  final String? sector;
  final String? emotion;
  final String? problem;
  final String? customerName;
  final String? accountId;
  final String? coachTip;
  final bool customerConfirmed;
  final bool awaitingClosing;
  final bool hasTraineeSpoken;
  final bool hasCustomerSpoken;
  final bool toolWorkDone;
  final bool showEscalationTab;
  final bool isEscalating;
  final int traineeTurnCount;
  final String lastCustomerMessage;
  final String lastTraineeMessage;

  final ValueChanged<String>? onEscalationSubmit;

  final List<String> reminders;
  final CoachViewModel? coachVm;

  const ScenarioGuideView({
    super.key,
    required this.sector,
    required this.emotion,
    required this.problem,
    this.customerName,
    this.accountId,
    this.coachTip,
    this.customerConfirmed = false,
    this.awaitingClosing = false,
    this.hasTraineeSpoken = false,
    this.hasCustomerSpoken = true,
    this.toolWorkDone = false,
    this.showEscalationTab = false,
    this.isEscalating = false,
    this.traineeTurnCount = 0,
    this.lastCustomerMessage = '',
    this.lastTraineeMessage = '',

    this.onEscalationSubmit,

    this.reminders = const [],
    this.coachVm,
  });

  @override
  State<ScenarioGuideView> createState() => _ScenarioGuideViewState();
}

class _ScenarioGuideViewState extends State<ScenarioGuideView> {
  int _subTab = 0;
  int _maxActionStep = 0;
  String _stepProblemKey = '';
  final ScrollController _scriptScrollController = ScrollController();
  final GlobalKey _highlightKey = GlobalKey();
  String? _lastHighlight;

  void _scrollToHighlight() {
    void run() {
      final ctx = _highlightKey.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
        alignment: 0.05,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      run();
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) run();
      });
    });
  }

  @override
  void didUpdateWidget(covariant ScenarioGuideView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reminders.length > oldWidget.reminders.length) {
      setState(() => _subTab = 1);
    } else if (widget.isEscalating && !oldWidget.isEscalating) {
      setState(() => _subTab = 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sector = widget.sector;
    if (sector == null || sector.isEmpty || !widget.hasCustomerSpoken) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Waiting for the customer.\nScript Guide, tips, and details appear after their first message.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, height: 1.4),
          ),
        ),
      );
    }

    if (!widget.showEscalationTab && _subTab == 2) {
      _subTab = 0;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _subChip('Script Guide', 0),
                const Gap(8),
                _subChip('Reminders', 1, badge: widget.reminders.length),
                if (widget.showEscalationTab) ...[
                  const Gap(8),
                  _subChip('Escalation', 2),
                ],
              ],
            ),
          ),
        ),
        const Gap(8),
        Expanded(
          child: _subTab == 1
              ? _buildReminders()
              : _subTab == 2 && widget.showEscalationTab
              ? _buildEscalation(sector)
              : _buildScript(sector),
        ),
      ],
    );
  }

  Widget _subChip(String label, int index, {int badge = 0}) {
    final selected = _subTab == index;
    return GestureDetector(
      onTap: () => setState(() => _subTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? const Color.fromARGB(255, 12, 67, 30)
              : const Color.fromARGB(180, 21, 21, 21),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color.fromARGB(255, 112, 189, 138)
                : const Color.fromARGB(255, 49, 48, 48),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF9CA3AF),
              ),
            ),
            if (badge > 0) ...[
              const Gap(6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScript(String sector) {
    final problem = widget.problem ?? 'Unknown';
    final emotion = widget.emotion ?? 'neutral';
    final name = widget.customerName ?? 'Customer';
    final tip = widget.coachVm?.tip ?? widget.coachTip;
    var highlight = SimulationCoach.highlightTagForTip(tip);
    if (!widget.hasTraineeSpoken && widget.hasCustomerSpoken) {
      highlight = 'opening';
    }
    final state = widget.awaitingClosing
        ? 'Awaiting your closing spiel'
        : widget.customerConfirmed
        ? 'Customer confirmed resolution'
        : !widget.hasTraineeSpoken
        ? 'Deliver opening spiel'
        : 'Active handling';

    List<String> actionTips = [];
    var lines = SimulationCoach.scriptLines(
      sector: sector,
      problem: problem,
      emotion: emotion,
      customerName: name,
      accountId: widget.accountId,
      customerConfirmed: widget.customerConfirmed,
      awaitingClosing: widget.awaitingClosing,
      hasTraineeSpoken: widget.hasTraineeSpoken,
      coachTip: tip,
      toolWorkDone: widget.toolWorkDone,
      hasCustomerSpoken: widget.hasCustomerSpoken,
      isEscalating: widget.isEscalating,
    );

    if (!widget.customerConfirmed &&
        !widget.awaitingClosing &&
        !widget.isEscalating &&
        widget.hasTraineeSpoken &&
        widget.hasCustomerSpoken) {
      final matchText = [
        problem,
        widget.lastCustomerMessage,
      ].where((e) => e.trim().isNotEmpty).join(' ');
      final matched = SectorIssueCatalog.matchedIssue(sector, matchText);
      final tipLower = (tip ?? '').toLowerCase();
      final forceEscalate =
          tipLower.contains('escalat') ||
          tipLower.contains('handoff') ||
          tipLower.contains('specialist');
      if (matched != null && !forceEscalate) {
        final issue = matched;
        final turn = widget.traineeTurnCount;
        // Examples: catalog line only before first reply; after that use
        // tip-based lines and drop empathy / already-used text.
        final catalogLine = ScriptLine(
          category: 'say',
          choiceNumber: 1,
          title: 'What to say',
          text: issue.sayThis,
        );
        if (turn <= 0) {
          lines = [catalogLine];
        } else {
          var advanced = SimulationCoach.scriptLines(
            sector: sector,
            problem: problem,
            emotion: emotion,
            customerName: name,
            accountId: widget.accountId,
            customerConfirmed: widget.customerConfirmed,
            awaitingClosing: widget.awaitingClosing,
            hasTraineeSpoken: widget.hasTraineeSpoken,
            coachTip: tip ?? issue.sayThis,
            toolWorkDone: widget.toolWorkDone,
            hasCustomerSpoken: widget.hasCustomerSpoken,
            isEscalating: widget.isEscalating,
          );
          advanced = SimulationCoach.filterAlreadyUsedLines(
            advanced,
            widget.lastTraineeMessage,
          );
          // Prefer concrete guide/explain/clarify over empathy after opening.
          final preferred = advanced
              .where((l) => l.category != 'empathy' && l.category != 'opening')
              .toList();
          if (preferred.isNotEmpty) {
            lines = preferred.take(3).toList();
          } else if (advanced.isNotEmpty) {
            lines = advanced.take(3).toList();
          } else if (turn <= 1) {
            lines = [catalogLine];
          } else {
            lines = [
              ScriptLine(
                category: 'guide',
                choiceNumber: 1,
                title: 'Next step',
                text: issue.steps.isNotEmpty
                    ? 'Next: ${issue.steps[turn.clamp(0, issue.steps.length - 1)]}'
                    : issue.sayThis,
              ),
            ];
          }
        }
        highlight = lines.isNotEmpty ? lines.first.tag : 'say';
        // Stable steps: one step per trainee reply only. Never jump by keywords.
        if (issue.steps.isNotEmpty) {
          final problemKey = '${sector}|${problem}|${issue.title}';
          if (_stepProblemKey != problemKey) {
            _stepProblemKey = problemKey;
            _maxActionStep = 0;
          }
          final stepIndex = (turn <= 0 ? 0 : turn - 1).clamp(
            0,
            issue.steps.length - 1,
          );
          if (stepIndex > _maxActionStep) {
            _maxActionStep = stepIndex;
          }
          final show = stepIndex >= _maxActionStep ? stepIndex : _maxActionStep;
          final safe = show.clamp(0, issue.steps.length - 1);
          actionTips = [
            'Step ${safe + 1} of ${issue.steps.length}: ${issue.steps[safe]}',
          ];
        }
      } else if (forceEscalate) {
        // Keep escalation script lines from SimulationCoach.scriptLines above
        actionTips = [
          'Collect handoff details before closing. Do not invent recovery steps for an escalation case.',
        ];
      } else {
        var fallback = SimulationCoach.fallbackGuidanceLines(
          sector: sector,
          problem: matchText,
          emotion: emotion,
          customerName: name,
          lastCustomerMessage: widget.lastCustomerMessage,
          lastTraineeMessage: widget.lastTraineeMessage,
        );
        fallback = SimulationCoach.filterAlreadyUsedLines(
          fallback,
          widget.lastTraineeMessage,
        );
        final turn = widget.traineeTurnCount;
        if (turn <= 1) {
          lines = fallback.take(2).toList();
          highlight = lines.isNotEmpty ? lines.first.tag : 'say';
        } else {
          // Prefer next actionable line after empathy, never only repeat last send
          final actionable = fallback
              .where((l) => l.tag != 'say' || l.choiceNumber > 1)
              .toList();
          if (actionable.isEmpty) {
            lines = fallback.take(2).toList();
          } else if (actionable.length == 1) {
            lines = [actionable.first];
          } else {
            final idx = (turn - 2).clamp(0, actionable.length - 1);
            lines = [actionable[idx]];
            if (idx + 1 < actionable.length) {
              lines = [...lines, actionable[idx + 1]];
            }
          }
          highlight = lines.isNotEmpty ? lines.first.tag : 'clarify';
        }
      }
    }

    final stage = SimulationCoach.stageFor(
      hasCustomerSpoken: widget.hasCustomerSpoken,
      hasTraineeSpoken: widget.hasTraineeSpoken,
      customerConfirmed: widget.customerConfirmed,
      awaitingClosing: widget.awaitingClosing,
      isEscalating: widget.isEscalating,
      traineeTurnCount: widget.traineeTurnCount,
      toolWorkDone: widget.toolWorkDone,
    );
    if (widget.coachVm != null) {
      lines = widget.coachVm!.examples;
      if (widget.coachVm!.amberStepText != null) {
        actionTips = [widget.coachVm!.amberStepText!];
      } else {
        actionTips = [];
      }
      if (lines.isNotEmpty) {
        highlight = lines.first.tag;
      }
    } else {
      lines = SimulationCoach.filterExamplesForStage(
        lines: lines,
        stage: stage,
        toolWorkDone: widget.toolWorkDone,
      );
      if (lines.isNotEmpty) {
        highlight = lines.first.tag;
      }
    }

    final termHits = SectorIssueCatalog.termsMentioned(
      sector,
      widget.lastCustomerMessage.isNotEmpty
          ? widget.lastCustomerMessage
          : problem,
    );

    final stepLabel = widget.coachVm?.currentObjectiveLabel ?? '';
    final scrollToken = '$highlight|$stepLabel|${lines.length}';
    if (scrollToken != _lastHighlight) {
      _lastHighlight = scrollToken;
      if (highlight.isNotEmpty || lines.isNotEmpty) {
        _scrollToHighlight();
      }
    }

    return ListView(
      controller: _scriptScrollController,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
      children: [
        _metaCard(sector, name, emotion, problem, state),
        const Gap(12),
        if (termHits.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF3B82F6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customer terms to notice',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF93C5FD),
                  ),
                ),
                const Gap(6),
                Text(
                  termHits.map((e) => e['term']).join(' · '),
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
                const Gap(4),
                Text(
                  'Open ${SimulationCoach.sectorGuideTabLabel(sector)} for meanings and related steps.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          const Gap(12),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF15201A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2E4A38)),
          ),
          child: const Text(
            'How to use this panel: blue = what to think about. Amber = actions to take in the tools. Green cards = example words you may type (use your own wording).',
            style: TextStyle(
              fontSize: 11,
              height: 1.35,
              color: Color(0xFFD7E8DB),
            ),
          ),
        ),
        if (widget.coachVm != null &&
            widget.coachVm!.checklistLabels.isNotEmpty) ...[
          Text(
            'Progress',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const Gap(6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < widget.coachVm!.checklistLabels.length; i++)
                _ObjectiveChip(
                  label: widget.coachVm!.checklistLabels[i],
                  status: i < widget.coachVm!.checklistStatuses.length
                      ? widget.coachVm!.checklistStatuses[i]
                      : 'upcoming',
                ),
            ],
          ),
          if (widget.coachVm!.currentObjectiveLabel != null &&
              widget.coachVm!.currentObjectiveLabel!.isNotEmpty) ...[
            const Gap(8),
            Text(
              'NOW: ${widget.coachVm!.currentObjectiveLabel}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFFE2E8F0),
              ),
            ),
          ],
          if (tip != null && tip.isNotEmpty) ...[
            const Gap(8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A5F),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF3B82F6)),
              ),
              child: Text(
                tip,
                style: const TextStyle(fontSize: 12, color: Color(0xFF93C5FD)),
              ),
            ),
          ],
          const Gap(14),
        ],
        if (tip != null &&
            tip.isNotEmpty &&
            !(widget.coachVm?.hideFocusDuplicate == true &&
                widget.coachVm!.checklistLabels.isNotEmpty)) ...[
          Text(
            'Next step',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const Gap(6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A5F),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF3B82F6)),
            ),
            child: Text(
              tip,
              style: const TextStyle(fontSize: 12, color: Color(0xFF93C5FD)),
            ),
          ),
          const Gap(14),
        ],
        if (actionTips.isNotEmpty) ...[
          const Text(
            'Use the tools panel for this step',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const Gap(6),
          ...actionTips.map(
            (t) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Text(
                t,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFFBBF24),
                  height: 1.35,
                ),
              ),
            ),
          ),
          const Gap(12),
        ],
        const Text(
          'Suggested replies',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const Gap(8),
        ...() {
          var keyed = false;
          final typeable = lines.where((l) => l.tag != 'step').toList();
          return typeable.map((line) {
            final active =
                highlight.isNotEmpty &&
                (line.tag == highlight ||
                    (highlight == 'opening' && line.tag == 'opening') ||
                    (highlight == 'closing' &&
                        (line.tag == 'closing' || line.tag == 'confirm')) ||
                    (highlight == 'say' && line.tag == 'say') ||
                    (highlight == 'step' && line.tag == 'step'));
            final card = _lineCard(line, active);
            if (active && !keyed) {
              keyed = true;
              return KeyedSubtree(key: _highlightKey, child: card);
            }
            return card;
          });
        }(),
      ],
    );
  }

  Widget _metaCard(
    String sector,
    String name,
    String emotion,
    String problem,
    String state,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(180, 21, 21, 21),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color.fromARGB(255, 49, 48, 48)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _metaRow('Company', SimulationCoach.companyName),
          _metaRow('Agent', SimulationCoach.agentName),
          _metaRow('Customer', name),
          _metaRow('Sector', sector),
          _metaRow('Emotion', emotion),
          _metaRow('Problem', problem),
          if (widget.accountId != null && widget.accountId!.isNotEmpty)
            _metaRow('Account', widget.accountId!),
          _metaRow('Current state', state),
        ],
      ),
    );
  }

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9CA3AF),
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lineCard(ScriptLine line, bool active) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active
            ? const Color.fromARGB(255, 12, 67, 30)
            : const Color.fromARGB(180, 21, 21, 21),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active
              ? const Color.fromARGB(255, 112, 189, 138)
              : const Color.fromARGB(255, 49, 48, 48),
          width: active ? 1.2 : 0.5,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: const Color.fromARGB(
                    255,
                    112,
                    189,
                    138,
                  ).withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 0.5,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            line.tag == 'step'
                ? '#${line.choiceNumber}  Do this  ${line.title}'
                : '#${line.choiceNumber}  Type this  ${line.title}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: active
                  ? const Color.fromARGB(255, 112, 189, 138)
                  : const Color(0xFF9CA3AF),
            ),
          ),
          const Gap(6),
          Text(
            line.text,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  String? _selectedDept;
  String _problemType = 'Complex unresolved issue';
  final _impactCtrl = TextEditingController();
  final _triedCtrl = TextEditingController();
  final _callbackCtrl = TextEditingController();

  @override
  void dispose() {
    _scriptScrollController.dispose();
    _impactCtrl.dispose();
    _triedCtrl.dispose();
    _callbackCtrl.dispose();
    super.dispose();
  }

  Widget _buildEscalation(String sector) {
    final problem = widget.problem ?? 'Unknown';
    final name = widget.customerName ?? 'Customer';
    final depts = SimulationCoach.escalationDepartments(sector);
    _selectedDept ??= depts.first['id'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 72),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF3B2F14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFF59E0B)),
          ),
          child: const Text(
            'Collect details in chat first, then complete this handoff. Empty fields are left out of the customer message. Choose the team that owns the next step.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFFBBF24),
              height: 1.35,
            ),
          ),
        ),
        const Gap(12),
        const Text(
          'Department',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const Gap(8),
        ...depts.map((d) {
          final selected = _selectedDept == d['id'];
          return GestureDetector(
            onTap: () => setState(() => _selectedDept = d['id']),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected
                    ? const Color.fromARGB(255, 12, 67, 30)
                    : const Color.fromARGB(180, 21, 21, 21),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? const Color.fromARGB(255, 112, 189, 138)
                      : const Color.fromARGB(255, 49, 48, 48),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d['label'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    'When: ${d['when']}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                      height: 1.3,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    'Means: ${d['means']}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const Gap(8),
        const Text(
          'Problem type',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const Gap(8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              [
                'Data / access loss',
                'Service not working',
                'Billing dispute',
                'Security concern',
                'Policy exception',
                'Complex unresolved issue',
              ].map((label) {
                final selected = _problemType == label;
                return GestureDetector(
                  onTap: () => setState(() => _problemType = label),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF1E3A5F)
                          : const Color.fromARGB(180, 21, 21, 21),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF3B82F6)
                            : const Color.fromARGB(255, 49, 48, 48),
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: selected
                            ? const Color(0xFF93C5FD)
                            : Colors.white70,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
        const Gap(12),
        Text(
          'Customer: $name',
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
        if (widget.accountId != null && widget.accountId!.isNotEmpty)
          Text(
            'Account: ${widget.accountId}',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        Text(
          'Issue: $problem',
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const Gap(10),
        _escField(
          _impactCtrl,
          'Impact (example: behind on 2 payments, risk of default)',
        ),
        const Gap(8),
        _escField(
          _triedCtrl,
          'Already tried (example: reviewed payment history, offered due-date change)',
        ),
        const Gap(8),
        _escField(_callbackCtrl, 'Callback number or best contact'),
        const Gap(14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.onEscalationSubmit == null
                ? null
                : () {
                    final dept = depts.firstWhere(
                      (d) => d['id'] == _selectedDept,
                      orElse: () => depts.first,
                    );
                    final msg = SimulationCoach.buildEscalationMessage(
                      departmentLabel: dept['label'] ?? 'Tier 2 Support',
                      problemType: _problemType,
                      customerName: name,
                      problem: problem,
                      accountId: widget.accountId,
                      impact: _impactCtrl.text.trim(),
                      tried: _triedCtrl.text.trim(),
                      callback: _callbackCtrl.text.trim(),
                    );
                    widget.onEscalationSubmit!(msg);
                    setState(() => _subTab = 0);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF166534),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Submit escalation handoff'),
          ),
        ),
      ],
    );
  }

  Widget _escField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
        filled: true,
        fillColor: const Color.fromARGB(180, 21, 21, 21),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color.fromARGB(255, 49, 48, 48)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color.fromARGB(255, 49, 48, 48)),
        ),
      ),
    );
  }

  Widget _buildReminders() {
    if (widget.reminders.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No reminders yet.\nRisky or weak replies will appear here with better options.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, height: 1.4),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 72),
      itemCount: widget.reminders.length,
      itemBuilder: (_, i) {
        final item = widget.reminders[widget.reminders.length - 1 - i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF3F1D1D),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.5),
            ),
          ),
          child: Text(
            item,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        );
      },
    );
  }
}

class CollapsibleScriptGuide extends StatefulWidget {
  final Widget child;
  final bool initiallyExpanded;

  const CollapsibleScriptGuide({
    super.key,
    required this.child,
    this.initiallyExpanded = true,
  });

  @override
  State<CollapsibleScriptGuide> createState() => _CollapsibleScriptGuideState();
}

class _CollapsibleScriptGuideState extends State<CollapsibleScriptGuide> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    // Always keep width so Notepad stays visible on every left tab
    // (Account Lookup, sector guide, reminders, escalation).
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: _expanded
                  ? 'Collapse Script Guide'
                  : 'Expand Script Guide',
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(
                _expanded ? Icons.chevron_right : Icons.chevron_left,
                color: Colors.white70,
                size: 20,
              ),
            ),
          ),
          if (_expanded)
            Expanded(child: widget.child)
          else
            Expanded(
              child: Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _expanded = true),
                  icon: const Icon(Icons.menu_book_outlined, size: 16),
                  label: const Text('Show Script Guide'),
                ),
              ),
            ),
          const AgentNotepad(),
        ],
      ),
    );
  }
}

class _ObjectiveChip extends StatelessWidget {
  final String label;
  final String status;

  const _ObjectiveChip({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final done = status == 'done';
    final current = status == 'current';
    final bg = done
        ? const Color(0xFF14532D)
        : current
        ? const Color(0xFF1E3A5F)
        : const Color(0xFF1F2937);
    final border = done
        ? const Color(0xFF22C55E)
        : current
        ? const Color(0xFF3B82F6)
        : const Color(0xFF374151);
    final fg = done
        ? const Color(0xFFBBF7D0)
        : current
        ? const Color(0xFF93C5FD)
        : const Color(0xFF9CA3AF);
    final prefix = done
        ? 'x '
        : current
        ? '> '
        : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        '$prefix$label',
        style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
