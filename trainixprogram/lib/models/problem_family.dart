enum ProblemFamily {
  planEligibility,
  networkConnectivity,
  billingSurprise,
  claimStatus,
  prescriptionRefill,
  loginAccess,
  fundTransfer,
  appointmentPrep,
  genericAccount,
  genericNonAccount,
  trueEscalate,
}

class _Rule {
  final ProblemFamily family;
  final List<String> anyOf;
  final List<String> sectors;

  const _Rule(this.family, this.anyOf, [this.sectors = const []]);

  bool matches(String text, String sector) {
    if (sectors.isNotEmpty) {
      final s = sector.toLowerCase();
      final hit = sectors.any((x) => s.contains(x.toLowerCase()));
      if (!hit) return false;
    }
    for (final k in anyOf) {
      if (text.contains(k)) return true;
    }
    return false;
  }
}

class ProblemFamilyClassifier {
  static const List<_Rule> _rules = [
    _Rule(ProblemFamily.loginAccess, [
      'password',
      'locked out',
      'cannot log in',
      "can't log in",
      'cannot sign in',
      "can't sign in",
      'otp',
      'verification code',
      'reset link',
      'reset email',
      'sign in',
    ]),
    _Rule(ProblemFamily.planEligibility, [
      'upgrade',
      'downgrade',
      'plan change',
      'not eligible',
      'eligibility',
      'promo',
      'change my plan',
      'plan denied',
      'denied',
    ]),
    _Rule(ProblemFamily.billingSurprise, [
      'bill',
      'billing',
      'charged',
      'overcharge',
      'higher than',
      'unknown fee',
      'extra charge',
      'surprise',
    ]),
    _Rule(
      ProblemFamily.networkConnectivity,
      [
        'no signal',
        'slow',
        'internet down',
        'outage',
        'no connection',
        'router',
        'disconnected',
        'intermittent',
        'wifi',
        'wi-fi',
      ],
      ['telco', 'tech'],
    ),
    _Rule(
      ProblemFamily.claimStatus,
      ['claim', 'reimbursement', 'claim status', 'adjuster'],
      ['care', 'health', 'insurance'],
    ),
    _Rule(
      ProblemFamily.prescriptionRefill,
      ['refill', 'prescription', 'pharmacy', 'medication'],
      ['care', 'health'],
    ),
    _Rule(
      ProblemFamily.fundTransfer,
      [
        'transfer',
        'remittance',
        'wrong recipient',
        'pending transfer',
        'sent money',
        'fund',
      ],
      ['bank', 'finance'],
    ),
    _Rule(ProblemFamily.appointmentPrep, [
      'appointment',
      'schedule',
      'reschedule',
      'book',
      'what do i bring',
      'preparation',
      'prepare',
    ]),
  ];

  static ProblemFamily classify({
    required String problem,
    required String sector,
    String lastCustomerMessage = '',
    bool escalateFromStart = false,
    bool needsAccount = false,
  }) {
    if (escalateFromStart) return ProblemFamily.trueEscalate;
    final text = '${problem} ${lastCustomerMessage}'.toLowerCase();
    for (final rule in _rules) {
      if (rule.matches(text, sector)) return rule.family;
    }
    return needsAccount
        ? ProblemFamily.genericAccount
        : ProblemFamily.genericNonAccount;
  }

  static bool defaultNeedsAccount(ProblemFamily f) {
    switch (f) {
      case ProblemFamily.networkConnectivity:
      case ProblemFamily.appointmentPrep:
      case ProblemFamily.genericNonAccount:
        return false;
      default:
        return true;
    }
  }
}
