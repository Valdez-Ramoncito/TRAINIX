import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/components/app_colors.dart';
import 'package:trainixprogram/models/scoring_transparency.dart';

/// Shared rubric presentation used by assessment results, voice scoring
/// feedback, and any surface that has to justify a score.
///
/// Every colour comes from [AppColors] so light and dark stay in step. Light
/// mode adds [AppColors.cardShadow] depth; dark mode is unchanged.

class RubricBandChip extends StatelessWidget {
  final String label;
  final Color color;
  final double fontSize;

  const RubricBandChip({
    super.key,
    required this.label,
    required this.color,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class RubricHowScoredCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String formula;
  final List<String> rules;
  final bool showBands;
  final String? footer;
  final String? notice;

  const RubricHowScoredCard({
    super.key,
    required this.title,
    required this.formula,
    this.icon = Icons.rule_folder_outlined,
    this.rules = const [],
    this.showBands = true,
    this.footer,
    this.notice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.listBase(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: AppColors.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.secondaryText(context)),
              const Gap(8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const Gap(10),
          Text(
            formula,
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          if (notice != null) ...[
            const Gap(10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warningTint(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warningText(context).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: AppColors.warningText(context),
                  ),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      notice!,
                      style: TextStyle(
                        color: AppColors.warningText(context),
                        fontSize: 11,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (rules.isNotEmpty) ...[
            const Gap(10),
            for (final rule in rules)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.textMuted(context),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        rule,
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (showBands) ...[
            const Gap(6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final level in ScoringTransparency.levels)
                  RubricBandChip(
                    label: ScoringTransparency.chipText(level),
                    color: AppColors.readable(
                      Color(level.colorValue),
                      context,
                    ),
                  ),
              ],
            ),
          ],
          if (footer != null) ...[
            const Gap(10),
            Text(
              footer!,
              style: TextStyle(
                color: AppColors.textMuted(context),
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class RubricEvidenceQuote extends StatelessWidget {
  final String text;
  final String? label;
  final Color? color;

  const RubricEvidenceQuote({
    super.key,
    required this.text,
    this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.secondaryText(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.elevated(context),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: accent, width: 3),
          top: BorderSide(color: AppColors.border(context)),
          right: BorderSide(color: AppColors.border(context)),
          bottom: BorderSide(color: AppColors.border(context)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: TextStyle(
                color: AppColors.textMuted(context),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const Gap(3),
          ],
          Text(
            text,
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// One scored item or dimension, with the rule behind the number and the
/// evidence that was actually observed.
class RubricDimensionTile extends StatefulWidget {
  final String label;
  final String bandLabel;
  final Color color;
  final String scoreText;
  final double fraction;
  final String basis;
  final String? summary;
  final List<String> parts;
  final List<String> evidence;
  final List<String> notes;
  final List<String> anchors;
  final String sourceNote;
  final String? strongerLine;
  final IconData? icon;
  final bool initiallyOpen;
  final bool notScored;
  final String? notScoredReason;

  const RubricDimensionTile({
    super.key,
    required this.label,
    required this.bandLabel,
    required this.color,
    required this.scoreText,
    required this.fraction,
    required this.basis,
    this.summary,
    this.parts = const [],
    this.evidence = const [],
    this.notes = const [],
    this.anchors = const [],
    this.sourceNote = '',
    this.strongerLine,
    this.icon,
    this.initiallyOpen = false,
    this.notScored = false,
    this.notScoredReason,
  });

  @override
  State<RubricDimensionTile> createState() => _RubricDimensionTileState();
}

class _RubricDimensionTileState extends State<RubricDimensionTile> {
  late bool _open;

  @override
  void initState() {
    super.initState();
    _open = widget.initiallyOpen;
  }

  @override
  Widget build(BuildContext context) {
    final hasEvidence = widget.evidence.isNotEmpty;
    final hasNotes = widget.notes.isNotEmpty;
    final pct = widget.fraction.clamp(0.0, 1.0);
    final isNotScored = widget.notScored;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.listBase(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _open
              ? widget.color.withValues(alpha: 0.45)
              : AppColors.border(context),
        ),
        boxShadow: AppColors.cardShadow(context, blur: 10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          mouseCursor: SystemMouseCursors.click,
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.icon ?? Icons.analytics_outlined,
                        color: widget.color,
                        size: 18,
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.label,
                            style: TextStyle(
                              color: AppColors.textPrimary(context),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Gap(3),
                          RubricBandChip(
                            label: widget.bandLabel,
                            color: widget.color,
                          ),
                        ],
                      ),
                    ),
                    const Gap(8),
                    Text(
                      isNotScored ? 'Not scored' : widget.scoreText,
                      style: TextStyle(
                        color: isNotScored
                            ? AppColors.textMuted(context)
                            : widget.color,
                        fontSize: isNotScored ? 12 : 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Gap(4),
                    Icon(
                      _open
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: AppColors.textSecondary(context),
                    ),
                  ],
                ),
                const Gap(8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: isNotScored ? 0 : pct,
                    minHeight: 7,
                    backgroundColor: AppColors.border(context),
                    color: isNotScored
                        ? AppColors.textMuted(context)
                        : widget.color,
                  ),
                ),
                const Gap(8),
                Text(
                  widget.basis,
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isNotScored && widget.notScoredReason != null) ...[
                  const Gap(6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 13,
                          color: AppColors.textMuted(context),
                        ),
                      ),
                      const Gap(6),
                      Expanded(
                        child: Text(
                          widget.notScoredReason!,
                          style: TextStyle(
                            color: AppColors.textMuted(context),
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_open) ...[
                  if (widget.summary != null && widget.summary!.isNotEmpty) ...[
                    const Gap(8),
                    Text(
                      widget.summary!,
                      style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (widget.parts.isNotEmpty) ...[
                    const Gap(10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.scaffold(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.chipBg(context)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Score breakdown',
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Gap(6),
                          for (final part in widget.parts)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(
                                part,
                                style: TextStyle(
                                  color: AppColors.textSecondary(context),
                                  fontSize: 11,
                                  height: 1.35,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (hasEvidence) ...[
                    const Gap(10),
                    Text(
                      'Evidence observed',
                      style: TextStyle(
                        color: AppColors.secondaryText(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(6),
                    for (final line in widget.evidence)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: RubricEvidenceQuote(text: line),
                      ),
                  ] else if (!isNotScored && widget.fraction >= 0.999) ...[
                    const Gap(10),
                    RubricEvidenceQuote(
                      label: 'Evidence observed',
                      text:
                          'No gap observed. Full marks for this criterion in this attempt.',
                      color: AppColors.successText(context),
                    ),
                  ],
                  if (hasNotes) ...[
                    const Gap(4),
                    Text(
                      'Why points were removed or what to fix',
                      style: TextStyle(
                        color: AppColors.warningText(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(6),
                    for (final note in widget.notes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          note,
                          style: TextStyle(
                            color: AppColors.textSecondary(context),
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ),
                  ],
                  if (widget.strongerLine != null &&
                      widget.strongerLine!.isNotEmpty) ...[
                    const Gap(6),
                    Text(
                      'Try a stronger line',
                      style: TextStyle(
                        color: AppColors.successText(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      '"${widget.strongerLine}"',
                      style: TextStyle(
                        color: AppColors.primaryText(context),
                        fontSize: 12,
                        height: 1.35,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  if (widget.anchors.isNotEmpty) ...[
                    const Gap(10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.scaffold(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.chipBg(context)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Possible deductions for this criterion',
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Gap(6),
                          for (final anchor in widget.anchors)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(
                                anchor,
                                style: TextStyle(
                                  color: AppColors.textSecondary(context),
                                  fontSize: 11,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          if (widget.sourceNote.isNotEmpty) ...[
                            const Gap(4),
                            Text(
                              'Source: ${widget.sourceNote}',
                              style: TextStyle(
                                color: AppColors.textMuted(context),
                                fontSize: 10,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
