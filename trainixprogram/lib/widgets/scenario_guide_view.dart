import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
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
  final GlobalKey _suggestedSectionKey = GlobalKey();
  String? _lastHighlight;

  void _scrollToHighlight() {
    void run() {
      final activeCtx = _highlightKey.currentContext;
      final sectionCtx = _suggestedSectionKey.currentContext;
      final ctx = activeCtx ?? sectionCtx;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
          alignment: 0.08,
        );
        return;
      }
      if (_scriptScrollController.hasClients) {
        final max = _scriptScrollController.position.maxScrollExtent;
        if (max > 0) {
          _scriptScrollController.animateTo(
            max,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOut,
          );
        }
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      run();
      Future.delayed(const Duration(milliseconds: 180), () {
        if (mounted) run();
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) run();
      });
    });
  }

  @override
  void didUpdateWidget(covariant ScenarioGuideView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reminders.length > oldWidget.reminders.length) {
      setState(() => _subTab = 1);
    }

    final tipChanged = (widget.coachTip ?? '') != (oldWidget.coachTip ?? '') ||
        (widget.coachVm?.tip ?? '') != (oldWidget.coachVm?.tip ?? '');
    final stepChanged = (widget.coachVm?.currentObjectiveLabel ?? '') !=
        (oldWidget.coachVm?.currentObjectiveLabel ?? '');
    final turnChanged = widget.traineeTurnCount != oldWidget.traineeTurnCount;
    final oldEx = oldWidget.coachVm?.examples ?? const [];
    final newEx = widget.coachVm?.examples ?? const [];
    final examplesChanged = oldEx.length != newEx.length ||
        (oldEx.isNotEmpty &&
            newEx.isNotEmpty &&
            oldEx.first.text != newEx.first.text);
    if (tipChanged || stepChanged || turnChanged || examplesChanged) {
      _lastHighlight = null;
      _scrollToHighlight();
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) _scrollToHighlight();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sector = widget.sector;
    if (sector == null || sector.isEmpty || !widget.hasCustomerSpoken) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Waiting for the customer.\nScript Guide, tips, and details appear after their first message.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted(context), height: 1.4),
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
                _subChip(context, 'Script Guide', 0),
                const Gap(8),
                _subChip(context, 'Reminders', 1,
                    badge: widget.reminders.length),
                if (widget.showEscalationTab) ...[
                  const Gap(8),
                  _subChip(context, 'Escalation', 2),
                ],
              ],
            ),
          ),
        ),
        const Gap(8),
        Expanded(
          child: _subTab == 1
              ? _buildReminders(
                  context,
                )
              : _subTab == 2 && widget.showEscalationTab
                  ? _buildEscalation(context, sector)
                  : _buildScript(sector),
        ),
      ],
    );
  }

  Widget _subChip(BuildContext context, String label, int index,
      {int badge = 0}) {
    final selected = _subTab == index;
    return GestureDetector(
      onTap: () => setState(() => _subTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.nextTint(context) : AppColors.panel(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.primaryText()
                : AppColors.borderIdle(context),
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
                color: selected
                    ? AppColors.textPrimary(context)
                    : AppColors.textMuted(context),
              ),
            ),
            if (badge > 0) ...[
              const Gap(6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.errorStrongText(),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.onPrimary(context),
                  ),
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
      final forceEscalate = tipLower.contains('escalat') ||
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
    final firstLine = lines.isNotEmpty ? lines.first.text : '';
    final scrollToken =
        '$highlight|$stepLabel|${lines.length}|$firstLine|${widget.traineeTurnCount}';
    if (scrollToken != _lastHighlight) {
      _lastHighlight = scrollToken;
      if (lines.isNotEmpty || highlight.isNotEmpty) {
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
              color: AppColors.elevated(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.secondaryText()),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer terms to notice',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryText(),
                  ),
                ),
                const Gap(6),
                Text(
                  termHits.map((e) => e['term']).join(' · '),
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textPrimary(context)),
                ),
                const Gap(4),
                Text(
                  'Open ${SimulationCoach.sectorGuideTabLabel(sector)} for meanings and related steps.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted(context),
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
            color: AppColors.nextTint(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.nextTint(context)),
          ),
          child: Text(
            'How to use this panel: blue = what to think about. Amber = actions to take in the tools. Green cards = example words you may type (use your own wording).',
            style: TextStyle(
              fontSize: 11,
              height: 1.35,
              color: AppColors.primaryText(),
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
              color: AppColors.textSecondary(context),
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
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
          if (tip != null && tip.isNotEmpty) ...[
            const Gap(8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.completeTint(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.secondaryText()),
              ),
              child: Text(
                tip,
                style:
                    TextStyle(fontSize: 12, color: AppColors.secondaryText()),
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
              color: AppColors.textSecondary(context),
            ),
          ),
          const Gap(6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.completeTint(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.secondaryText()),
            ),
            child: Text(
              tip,
              style: TextStyle(fontSize: 12, color: AppColors.secondaryText()),
            ),
          ),
          const Gap(14),
        ],
        if (actionTips.isNotEmpty) ...[
          Text(
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
                color: AppColors.elevated(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warningText()),
              ),
              child: Text(
                t,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.warningText(),
                  height: 1.35,
                ),
              ),
            ),
          ),
          const Gap(12),
        ],
        Text(
          key: _suggestedSectionKey,
          'Suggested replies',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const Gap(8),
        ...() {
          var keyed = false;
          final typeable = lines.where((l) => l.tag != 'step').toList();
          return typeable.toList().asMap().entries.map((entry) {
            final i = entry.key;
            final line = entry.value;
            final active = highlight.isNotEmpty &&
                (line.tag == highlight ||
                    (highlight == 'opening' && line.tag == 'opening') ||
                    (highlight == 'closing' &&
                        (line.tag == 'closing' || line.tag == 'confirm')) ||
                    (highlight == 'say' && line.tag == 'say') ||
                    (highlight == 'step' && line.tag == 'step') ||
                    (highlight == 'guide' && line.tag == 'guide'));
            final card = _lineCard(context, line, active || i == 0);
            if (!keyed && (active || i == 0)) {
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
        color: AppColors.panel(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderIdle(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _metaRow(context, 'Company', SimulationCoach.companyName),
          _metaRow(context, 'Agent', SimulationCoach.agentName),
          _metaRow(context, 'Customer', name),
          _metaRow(context, 'Sector', sector),
          _metaRow(context, 'Emotion', emotion),
          _metaRow(context, 'Problem', problem),
          if (widget.accountId != null && widget.accountId!.isNotEmpty)
            _metaRow(context, 'Account', widget.accountId!),
          _metaRow(context, 'Current state', state),
        ],
      ),
    );
  }

  Widget _metaRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted(context),
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                  fontSize: 12, color: AppColors.textSecondary(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lineCard(BuildContext context, ScriptLine line, bool active) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active ? AppColors.nextTint(context) : AppColors.panel(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              active ? AppColors.primaryText() : AppColors.borderIdle(context),
          width: active ? 1.2 : 0.5,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.primaryText().withValues(alpha: 0.35),
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
                  ? AppColors.primaryText()
                  : AppColors.textMuted(context),
            ),
          ),
          const Gap(6),
          Text(
            line.text,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary(context),
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

  Widget _buildEscalation(BuildContext context, String sector) {
    final problem = widget.problem ?? 'Unknown';
    final name = widget.customerName ?? 'Customer';
    final depts = SimulationCoach.escalationDepartments(sector);
    _selectedDept ??= depts.first['id'];
    if (_impactCtrl.text.trim().isEmpty) {
      _impactCtrl.text =
          'Customer is affected by: $problem. Needs specialist follow-up.';
    }
    if (_triedCtrl.text.trim().isEmpty) {
      _triedCtrl.text =
          'First-line steps were already guided with the customer.';
    }
    if (_callbackCtrl.text.trim().isEmpty) {
      _callbackCtrl.text = 'Use the contact method on file for $name.';
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 72),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.elevated(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.warningText()),
          ),
          child: Text(
            'Use this when first-line steps are not enough. Pick a team, review the summary fields, then submit. After submit, tell the customer the case is with a specialist, then close.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.warningText(),
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
                    ? AppColors.nextTint(context)
                    : AppColors.panel(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? AppColors.primaryText()
                      : AppColors.borderIdle(context),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d['label'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const Gap(4),
                  Text(
                    'When: ${d['when']}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted(context),
                      height: 1.3,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    'Means: ${d['means']}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted(context),
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
          children: [
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
                      ? AppColors.completeTint(context)
                      : AppColors.panel(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? AppColors.secondaryText()
                        : AppColors.borderIdle(context),
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: selected
                        ? AppColors.secondaryText()
                        : AppColors.textSecondary(context),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const Gap(12),
        Text(
          'Customer: $name',
          style:
              TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
        ),
        if (widget.accountId != null && widget.accountId!.isNotEmpty)
          Text(
            'Account: ${widget.accountId}',
            style: TextStyle(
                fontSize: 12, color: AppColors.textSecondary(context)),
          ),
        Text(
          'Issue: $problem',
          style:
              TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
        ),
        const Gap(10),
        _escField(
          context,
          _impactCtrl,
          'Impact (example: behind on 2 payments, risk of default)',
        ),
        const Gap(8),
        _escField(
          context,
          _triedCtrl,
          'Already tried (example: reviewed payment history, offered due-date change)',
        ),
        const Gap(8),
        _escField(context, _callbackCtrl, 'Callback number or best contact'),
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
              backgroundColor: AppColors.nextTint(context),
              foregroundColor: AppColors.textPrimary(context),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Submit escalation handoff'),
          ),
        ),
      ],
    );
  }

  Widget _escField(
      BuildContext context, TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: TextStyle(color: AppColors.textPrimary(context), fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textMuted(context), fontSize: 12),
        filled: true,
        fillColor: AppColors.panel(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.borderIdle(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.borderIdle(context)),
        ),
      ),
    );
  }

  Widget _buildReminders(
    BuildContext context,
  ) {
    if (widget.reminders.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No reminders yet.\nRisky or weak replies will appear here with better options.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted(context), height: 1.4),
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
            color: AppColors.elevated(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.errorStrongText().withValues(alpha: 0.5),
            ),
          ),
          child: Text(
            item,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary(context),
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
  final double notepadBottomInset;

  const CollapsibleScriptGuide({
    super.key,
    required this.child,
    this.initiallyExpanded = true,
    this.notepadBottomInset = 12,
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
              tooltip:
                  _expanded ? 'Collapse Script Guide' : 'Expand Script Guide',
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(
                _expanded ? Icons.chevron_right : Icons.chevron_left,
                color: AppColors.textSecondary(context),
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
          AgentNotepad(bottomInset: widget.notepadBottomInset),
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
        ? AppColors.nextTint(context)
        : current
            ? AppColors.completeTint(context)
            : AppColors.chipBg(context);
    final border = done
        ? AppColors.primaryText()
        : current
            ? AppColors.secondaryText()
            : AppColors.borderStrong(context);
    final fg = done
        ? AppColors.primaryText()
        : current
            ? AppColors.secondaryText()
            : AppColors.textMuted(context);
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
