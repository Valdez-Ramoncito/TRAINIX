import 'dart:math';

import 'package:trainixprogram/models/problem_family.dart';
import 'package:trainixprogram/models/sim_mission.dart';
import 'package:trainixprogram/models/sim_mission_catalog.dart';

class SimIdentityVariant {
  final String customerName;
  final String emotion;
  final String? openingCustomerLine;

  const SimIdentityVariant({
    required this.customerName,
    required this.emotion,
    this.openingCustomerLine,
  });
}

/// Shared sector family pick + light identity variation for simulation sessions.
/// Keeps chat and voice on the same selection rules.
class SimPackSelector {
  static final Random _random = Random();
  static final Map<String, List<ProblemFamily>> _recentBySector = {};
  static final Map<String, String> _lastIdentityKey = {};

  static const int _recentWindow = 4;

  static List<ProblemFamily> familiesForSector(String sector) {
    final s = sector.toLowerCase();
    if (s.contains('finance') || s.contains('bank')) {
      return const [
        ProblemFamily.billingSurprise,
        ProblemFamily.fundTransfer,
        ProblemFamily.genericAccount,
      ];
    }
    if (s.contains('health')) {
      return const [
        ProblemFamily.claimStatus,
        ProblemFamily.prescriptionRefill,
        ProblemFamily.appointmentPrep,
      ];
    }
    if (s.contains('telco') || s.contains('telecom') || s.contains('mobile')) {
      return const [
        ProblemFamily.networkConnectivity,
        ProblemFamily.planEligibility,
        ProblemFamily.genericAccount,
      ];
    }
    if (s.contains('tech') || s.contains('it')) {
      return const [
        ProblemFamily.loginAccess,
        ProblemFamily.genericNonAccount,
        ProblemFamily.genericAccount,
      ];
    }
    return const [
      ProblemFamily.genericAccount,
      ProblemFamily.genericNonAccount,
      ProblemFamily.billingSurprise,
    ];
  }

  static ProblemFamily pickFamily(String sector) {
    final key = sector.toLowerCase().trim();
    final pool = familiesForSector(sector);
    final recent = _recentBySector[key] ?? <ProblemFamily>[];

    var candidates = pool.where((f) => !recent.contains(f)).toList();
    if (candidates.isEmpty) {
      candidates = pool
          .where((f) => recent.isEmpty || f != recent.last)
          .toList();
    }
    if (candidates.isEmpty) {
      candidates = List<ProblemFamily>.from(pool);
    }

    final picked = candidates[_random.nextInt(candidates.length)];
    final nextRecent = List<ProblemFamily>.from(recent)..add(picked);
    while (nextRecent.length > _recentWindow) {
      nextRecent.removeAt(0);
    }
    _recentBySector[key] = nextRecent;
    return picked;
  }

  static SimPack resolveForSector(String sector) {
    final family = pickFamily(sector);
    final base = SimMissionCatalog.resolve(
      sector: sector,
      problem: family.name,
      family: family,
      needsAccount: ProblemFamilyClassifier.defaultNeedsAccount(family),
    );
    return applyIdentityVariant(base);
  }

  static SimPack applyIdentityVariant(SimPack pack) {
    final variants = _variantsForPack(pack);
    if (variants.isEmpty) {
      return _ensureAccountAligned(pack);
    }

    final sectorKey = pack.sector.toLowerCase();
    final lastKey = _lastIdentityKey[sectorKey];
    final filtered = variants
        .where((v) => '${pack.id}|${v.customerName}' != lastKey)
        .toList();
    final pool = filtered.isNotEmpty ? filtered : variants;
    final chosen = pool[_random.nextInt(pool.length)];
    _lastIdentityKey[sectorKey] = '${pack.id}|${chosen.customerName}';

    final oldName = pack.customerName;
    final accountDigits = _accountDigitsForPack(pack, chosen.customerName);
    final rewrittenSteps = pack.steps
        .map(
          (step) => SimStep(
            id: step.id,
            label: step.label,
            kind: step.kind,
            tip: step.tip,
            examples: step.examples,
            passPhrases: step.passPhrases,
            customerLine: _rewriteIdentityText(
              step.customerLine,
              oldName: oldName,
              newName: chosen.customerName,
              accountDigits: accountDigits,
            ),
            customerLineAfterPass: _rewriteIdentityText(
              step.customerLineAfterPass,
              oldName: oldName,
              newName: chosen.customerName,
              accountDigits: accountDigits,
            ),
            toolEvent: step.toolEvent,
            toolHint: step.toolHint,
            highlightAccountLookup: step.highlightAccountLookup,
            highlightSectorGuide: step.highlightSectorGuide,
          ),
        )
        .toList();

    final details = Map<String, String>.from(pack.accountDetails);
    details['Account ID'] = accountDigits;
    if (!details.containsKey('Member ID')) {
      details['Member ID'] = 'ACC-$accountDigits';
    }

    final opening = chosen.openingCustomerLine ??
        _rewriteIdentityText(
          pack.openingCustomerLine,
          oldName: oldName,
          newName: chosen.customerName,
          accountDigits: accountDigits,
        );

    return pack.copyWith(
      customerName: chosen.customerName,
      emotion: chosen.emotion,
      openingCustomerLine: opening ?? pack.openingCustomerLine,
      steps: rewrittenSteps,
      accountDetails: details,
    );
  }

  static SimPack _ensureAccountAligned(SimPack pack) {
    final accountDigits = _accountDigitsForPack(pack, pack.customerName);
    final details = Map<String, String>.from(pack.accountDetails);
    if (details.containsKey('Account ID') ||
        details.containsKey('Card Ending') ||
        details.containsKey('Mobile Ending') ||
        details.containsKey('Member ID')) {
      if (!details.containsKey('Account ID')) {
        details['Account ID'] = accountDigits;
      }
      return pack.copyWith(accountDetails: details);
    }
    details['Account ID'] = accountDigits;
    details['Member ID'] = 'ACC-$accountDigits';
    final rewrittenSteps = pack.steps
        .map(
          (step) => SimStep(
            id: step.id,
            label: step.label,
            kind: step.kind,
            tip: step.tip,
            examples: step.examples,
            passPhrases: step.passPhrases,
            customerLine: _rewriteIdentityText(
              step.customerLine,
              oldName: pack.customerName,
              newName: pack.customerName,
              accountDigits: accountDigits,
            ),
            customerLineAfterPass: _rewriteIdentityText(
              step.customerLineAfterPass,
              oldName: pack.customerName,
              newName: pack.customerName,
              accountDigits: accountDigits,
            ),
            toolEvent: step.toolEvent,
            toolHint: step.toolHint,
            highlightAccountLookup: step.highlightAccountLookup,
            highlightSectorGuide: step.highlightSectorGuide,
          ),
        )
        .toList();
    return pack.copyWith(
      steps: rewrittenSteps,
      accountDetails: details,
    );
  }

  /// Always last-4 digits so customer speech matches Account Lookup lists.
  static String _accountDigitsForPack(SimPack pack, String ownerName) {
    final d = pack.accountDetails;
    for (final key in [
      'Account ID',
      'Card Ending',
      'Mobile Ending',
      'Member ID',
    ]) {
      final raw = d[key];
      if (raw == null || raw.trim().isEmpty) continue;
      final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length >= 4) {
        return digits.substring(digits.length - 4);
      }
    }
    for (final step in pack.steps) {
      final text =
          '${step.customerLineAfterPass ?? ''} ${step.customerLine ?? ''}';
      final match = RegExp(
        r'account\s*(?:ends?\s*(?:in|with)?|number|#)?\s*([0-9]{4,6})',
        caseSensitive: false,
      ).firstMatch(text);
      if (match != null) {
        final digits = match.group(1)!;
        return digits.length <= 4
            ? digits
            : digits.substring(digits.length - 4);
      }
      final cardMatch = RegExp(
        r'(?:card|ending)\s*(?:ends?\s*(?:in|with)?|in)?\s*([0-9]{4})',
        caseSensitive: false,
      ).firstMatch(text);
      if (cardMatch != null) return cardMatch.group(1)!;
    }
    final n = ownerName.hashCode.abs() % 9000 + 1000;
    return n.toString().padLeft(4, '0').substring(
          n.toString().padLeft(4, '0').length - 4,
        );
  }

  static String? _rewriteIdentityText(
    String? text, {
    required String oldName,
    required String newName,
    required String accountDigits,
  }) {
    if (text == null) return null;
    var out = text;
    if (oldName.isNotEmpty && oldName != newName) {
      out = out.replaceAll(oldName, newName);
    }
    out = out.replaceAllMapped(
      RegExp(
        r'(account\s*(?:ends?\s*(?:in|with)?|number|#)?\s*)([0-9]{4,6})',
        caseSensitive: false,
      ),
      (m) => '${m.group(1)}$accountDigits',
    );
    out = out.replaceAllMapped(
      RegExp(
        r'((?:card|ending)\s*(?:ends?\s*(?:in|with)?|in)?\s*)([0-9]{4})',
        caseSensitive: false,
      ),
      (m) => '${m.group(1)}$accountDigits',
    );
    return out;
  }

  static List<SimIdentityVariant> _variantsForPack(SimPack pack) {
    switch (pack.family) {
      case ProblemFamily.billingSurprise:
        return const [
          SimIdentityVariant(
            customerName: 'Daniel Cruz',
            emotion: 'worried',
          ),
          SimIdentityVariant(
            customerName: 'Marites Alonzo',
            emotion: 'frustrated',
            openingCustomerLine:
                'Hi, there is a pending charge on my card and I am worried it will post twice. Can you check it?',
          ),
          SimIdentityVariant(
            customerName: 'Jonah Reyes',
            emotion: 'impatient',
            openingCustomerLine:
                'I need help with a pending payment that still has not cleared. I do not want a double charge.',
          ),
          SimIdentityVariant(
            customerName: 'Rico Mendoza',
            emotion: 'angry',
            openingCustomerLine:
                'This unauthorized charge is unacceptable. I want it reversed now and I want a clear explanation.',
          ),
        ];
      case ProblemFamily.fundTransfer:
        return const [
          SimIdentityVariant(
            customerName: 'Paolo Mendoza',
            emotion: 'concerned',
          ),
          SimIdentityVariant(
            customerName: 'Liza Santos',
            emotion: 'worried',
            openingCustomerLine:
                'Hi, I sent a fund transfer and it is still not showing on the other side. Can you help me track it?',
          ),
          SimIdentityVariant(
            customerName: 'Eric Bautista',
            emotion: 'frustrated',
            openingCustomerLine:
                'My transfer has been pending too long. I need to know if it went through or if something failed.',
          ),
        ];
      case ProblemFamily.claimStatus:
        return const [
          SimIdentityVariant(
            customerName: 'Andrea Villanueva',
            emotion: 'anxious',
          ),
          SimIdentityVariant(
            customerName: 'Ramon Dela Cruz',
            emotion: 'frustrated',
            openingCustomerLine:
                'I filed a claim and I still do not have a clear status update. Can you check where it is?',
          ),
          SimIdentityVariant(
            customerName: 'Sofia Navarro',
            emotion: 'worried',
            openingCustomerLine:
                'Hi, I need an update on my claim. It has been pending and I am not sure what is missing.',
          ),
          SimIdentityVariant(
            customerName: 'Elena Marquez',
            emotion: 'disappointed',
            openingCustomerLine:
                'I was told my claim would be updated by now. Can you check what is taking so long?',
          ),
          SimIdentityVariant(
            customerName: 'Benito Salcedo',
            emotion: 'angry',
            openingCustomerLine:
                'My claim has been stuck for weeks with no answers. This is unacceptable. I need a status and a next step now.',
          ),
        ];
      case ProblemFamily.prescriptionRefill:
        return const [
          SimIdentityVariant(
            customerName: 'Katrina Domingo',
            emotion: 'worried',
          ),
          SimIdentityVariant(
            customerName: 'Miguel Torres',
            emotion: 'anxious',
            openingCustomerLine:
                'My prescription refill is delayed and I am running low. Can you tell me what is holding it?',
          ),
          SimIdentityVariant(
            customerName: 'Helen Quinto',
            emotion: 'impatient',
            openingCustomerLine:
                'Hi, the pharmacy says my refill is still pending authorization. I need the next step.',
          ),
          SimIdentityVariant(
            customerName: 'Rosa Villamor',
            emotion: 'sad',
            openingCustomerLine:
                'My refill is delayed and I am really struggling without it. Can you help me figure out what to do?',
          ),
        ];
      case ProblemFamily.appointmentPrep:
        return const [
          SimIdentityVariant(
            customerName: 'Nina Corpuz',
            emotion: 'neutral',
          ),
          SimIdentityVariant(
            customerName: 'Carlo Jimenez',
            emotion: 'worried',
            openingCustomerLine:
                'I have an upcoming appointment and I need to confirm the prep instructions and timing.',
          ),
          SimIdentityVariant(
            customerName: 'Bea Lim',
            emotion: 'confused',
            openingCustomerLine:
                'Hi, I am not sure what to prepare before my visit. Can you walk me through the requirements?',
          ),
        ];
      case ProblemFamily.networkConnectivity:
        return const [
          SimIdentityVariant(
            customerName: 'Grace Villanueva',
            emotion: 'impatient',
          ),
          SimIdentityVariant(
            customerName: 'Mark Tolentino',
            emotion: 'frustrated',
            openingCustomerLine:
                'My home internet has been down for hours and my neighbors still have service. Can you check for an outage?',
          ),
          SimIdentityVariant(
            customerName: 'Alyssa Gomez',
            emotion: 'worried',
            openingCustomerLine:
                'Hi, my connection dropped this morning and it still is not back. I already restarted the modem.',
          ),
        ];
      case ProblemFamily.planEligibility:
        return const [
          SimIdentityVariant(
            customerName: 'Bryan Custodio',
            emotion: 'frustrated',
          ),
          SimIdentityVariant(
            customerName: 'Patricia Ong',
            emotion: 'disappointed',
            openingCustomerLine:
                'My plan upgrade was denied in the app with no clear reason. I need to know why and what I can do next.',
          ),
          SimIdentityVariant(
            customerName: 'Kevin Salazar',
            emotion: 'impatient',
            openingCustomerLine:
                'Hi, the app blocked my upgrade and I still do not know the eligibility issue. Can you review it?',
          ),
        ];
      case ProblemFamily.loginAccess:
        return const [
          SimIdentityVariant(
            customerName: 'Chris Padilla',
            emotion: 'frustrated',
          ),
          SimIdentityVariant(
            customerName: 'Diane Rocha',
            emotion: 'worried',
            openingCustomerLine:
                'I cannot sign in to my account even after a password reset. Can you help me regain access?',
          ),
          SimIdentityVariant(
            customerName: 'Owen Mercado',
            emotion: 'impatient',
            openingCustomerLine:
                'Hi, login keeps failing on my side. I need this fixed so I can get into my account today.',
          ),
          SimIdentityVariant(
            customerName: 'Victor Sison',
            emotion: 'paranoid',
            openingCustomerLine:
                'I cannot log in and I am worried someone else tried to access my account. Can you verify this is secure before we reset anything?',
          ),
        ];
      case ProblemFamily.trueEscalate:
        return const [
          SimIdentityVariant(
            customerName: 'Specialist Handoff',
            emotion: 'frustrated',
          ),
          SimIdentityVariant(
            customerName: 'Irene Castillo',
            emotion: 'angry',
            openingCustomerLine:
                'I already tried the usual steps and this still is not resolved. I need this escalated now. This has gone on long enough.',
          ),
          SimIdentityVariant(
            customerName: 'Carlo Dizon',
            emotion: 'angry',
            openingCustomerLine:
                'I am done repeating myself. Escalate this to a specialist and give me a real timeline.',
          ),
        ];
      case ProblemFamily.genericAccount:
        return const [
          SimIdentityVariant(
            customerName: 'Alex Rivera',
            emotion: 'neutral',
          ),
          SimIdentityVariant(
            customerName: 'Sam Torres',
            emotion: 'concerned',
          ),
          SimIdentityVariant(
            customerName: 'Jordan Cruz',
            emotion: 'impatient',
          ),
        ];
      case ProblemFamily.genericNonAccount:
        return const [
          SimIdentityVariant(
            customerName: 'Taylor Reyes',
            emotion: 'neutral',
          ),
          SimIdentityVariant(
            customerName: 'Morgan Lim',
            emotion: 'confused',
          ),
          SimIdentityVariant(
            customerName: 'Casey Villanueva',
            emotion: 'frustrated',
          ),
        ];
    }
  }
}
