import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/models/simulation_coach.dart';

class SectorIssueGuideView extends StatefulWidget {
  final String sector;
  final String? customerProblem;
  final VoidCallback? onIssueOpened;

  const SectorIssueGuideView({
    super.key,
    required this.sector,
    this.customerProblem,
    this.onIssueOpened,
  });

  @override
  State<SectorIssueGuideView> createState() => _SectorIssueGuideViewState();
}

class _SectorIssueGuideViewState extends State<SectorIssueGuideView> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final issues = SectorIssueCatalog.forSector(widget.sector);
    final problem = widget.customerProblem ?? '';
    final matchIndex = SectorIssueCatalog.matchIndex(widget.sector, problem);
    final unmatched = problem.isNotEmpty && matchIndex == null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${SimulationCoach.sectorGuideTabLabel(widget.sector)} · ${widget.sector}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(6),
          Text(
            unmatched
                ? 'No close match for this customer issue. Treat it as escalation and collect handoff details.'
                : 'Pick a common issue for step-by-step guidance. If nothing matches the customer, escalate.',
            style: TextStyle(
              color: unmatched
                  ? const Color(0xFFFBBF24)
                  : const Color(0xFF9CA3AF),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const Gap(14),
          Expanded(
            child: _selectedIndex == null
                ? _buildHome(issues, matchIndex)
                : _buildSteps(issues[_selectedIndex!]),
          ),
        ],
      ),
    );
  }

  Widget _buildHome(List<SectorIssue> issues, int? matchIndex) {
    final terms = SectorIssueCatalog.commonTerms(widget.sector);
    final escalateCases = SectorIssueCatalog.escalateWhen(widget.sector);
    return ListView(
      children: [
        const Text(
          'Common issues',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const Gap(8),
        ...List.generate(issues.length, (index) {
          final issue = issues[index];
          final highlighted = matchIndex == index;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedIndex = index);
                widget.onIssueOpened?.call();
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: highlighted
                      ? const Color(0xFF1E293B)
                      : const Color.fromARGB(255, 28, 29, 29),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: highlighted
                        ? const Color(0xFF3B82F6)
                        : const Color.fromARGB(255, 50, 51, 54),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            issue.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Gap(4),
                          Text(
                            issue.summary,
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
                  ],
                ),
              ),
            ),
          );
        }),
        const Gap(8),
        const Text(
          'Common terms',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const Gap(8),
        ...terms.map(
          (term) => Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color.fromARGB(180, 21, 21, 21),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color.fromARGB(255, 49, 48, 48)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  term['term'] ?? '',
                  style: const TextStyle(
                    color: Color(0xFF93C5FD),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const Gap(4),
                Text(
                  term['meaning'] ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Gap(8),
        const Text(
          'When to escalate',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const Gap(8),
        ...escalateCases.map(
          (item) => Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3B2F14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['case'] ?? '',
                  style: const TextStyle(
                    color: Color(0xFFFBBF24),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const Gap(6),
                Text(
                  'Say: ${item['say']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSteps(SectorIssue issue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _selectedIndex = null),
            icon: const Icon(Icons.arrow_back, size: 16, color: Colors.white70),
            label: const Text(
              'Back to issues',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
        const Gap(4),
        Text(
          issue.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Gap(6),
        Text(
          issue.sayThis,
          style: const TextStyle(
            color: Color(0xFF93C5FD),
            fontSize: 12,
            height: 1.35,
          ),
        ),
        const Gap(14),
        Expanded(
          child: ListView.separated(
            itemCount: issue.steps.length,
            separatorBuilder: (_, __) => const Gap(10),
            itemBuilder: (context, index) {
              final step = issue.steps[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(180, 21, 21, 21),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color.fromARGB(255, 49, 48, 48),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A5F),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Color(0xFF93C5FD),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: Text(
                        step,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const Gap(10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF3B2F14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFF59E0B)),
          ),
          child: const Text(
            'If these steps do not apply or the issue is not listed, escalate with a full handoff summary.',
            style: TextStyle(
              color: Color(0xFFFBBF24),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class SectorIssue {
  final String title;
  final String summary;
  final String sayThis;
  final List<String> steps;
  final List<String> keywords;

  const SectorIssue({
    required this.title,
    required this.summary,
    required this.sayThis,
    required this.steps,
    required this.keywords,
  });
}

class SectorIssueCatalog {
  static List<SectorIssue> forSector(String sector) {
    final s = sector.toLowerCase();
    List<SectorIssue> base;
    if (s.contains('tech') || s.contains('it')) {
      base = _tech;
    } else if (s.contains('telco') ||
        s.contains('telecom') ||
        s.contains('mobile')) {
      base = _telco;
    } else if (s.contains('health')) {
      base = _healthcare;
    } else if (s.contains('finance') || s.contains('bank')) {
      base = _finance;
    } else if (s.contains('retail') || s.contains('ecommerce')) {
      base = _retail;
    } else {
      base = _general;
    }
    return [...base, otherIssuesFor(sector)];
  }

  static SectorIssue otherIssuesFor(String sector) {
    final label = sector.trim().isEmpty ? 'this sector' : sector;
    return SectorIssue(
      title: 'Other issues',
      summary:
          'No exact match for the customer issue. Use a safe generic path, or escalate if policy blocks you.',
      sayThis:
          'I understand this is important. I will walk you through one clear step at a time for $label support.',
      keywords: const ['other', 'generic', 'unlisted', 'unknown', 'not listed'],
      steps: const [
        'Acknowledge the issue in the customer\'s words.',
        'Ask what they already tried, if anything.',
        'Give one safe, policy-aligned step and wait for the result.',
        'If still unresolved, offer to log a follow-up or escalate with a clear handoff.',
        'Confirm next steps and close only when the customer is ready.',
      ],
    );
  }

  static List<Map<String, String>> termsMentioned(String sector, String text) {
    final t = text.toLowerCase();
    if (t.isEmpty) return const [];
    final hits = <Map<String, String>>[];
    for (final term in commonTerms(sector)) {
      final key = term['term']!.toLowerCase();
      if (t.contains(key)) hits.add(term);
    }
    return hits;
  }

  static List<Map<String, String>> commonTerms(String sector) {
    final s = sector.toLowerCase();
    if (s.contains('tech') || s.contains('it')) {
      return const [
        {
          'term': 'system restore',
          'meaning':
              'Rolling the PC back to an earlier snapshot; can remove files created after that point.',
        },
        {
          'term': 'reset',
          'meaning':
              'Device or OS was wiped or returned toward factory/default state.',
        },
        {
          'term': 'recycle bin',
          'meaning':
              'Local deleted-file holding area before permanent removal.',
        },
        {
          'term': 'backup',
          'meaning': 'Copy of files stored elsewhere for recovery.',
        },
        {
          'term': 'OneDrive',
          'meaning':
              'Cloud file sync; check recycle bin and version history online.',
        },
        {
          'term': 'File History',
          'meaning':
              'Windows backup feature that can restore prior file versions.',
        },
        {
          'term': 'malware',
          'meaning':
              'Harmful software; treat pay-now security pop-ups as suspicious until verified.',
        },
        {
          'term': 'security alert',
          'meaning':
              'Warning from the OS or security app; capture exact wording before any fix.',
        },
        {
          'term': 'safe mode',
          'meaning':
              'Limited startup mode used to troubleshoot stubborn device issues.',
        },
      ];
    }
    if (s.contains('telco') || s.contains('telecom') || s.contains('mobile')) {
      return const [
        {
          'term': 'SIM',
          'meaning': 'Card that authenticates the line on the network.',
        },
        {
          'term': 'signal',
          'meaning': 'Radio strength from the tower to the device.',
        },
        {
          'term': 'APN',
          'meaning': 'Mobile data access settings for the carrier.',
        },
        {
          'term': 'outage',
          'meaning': 'Network-side service disruption in an area.',
        },
        {
          'term': 'porting',
          'meaning': 'Moving a phone number from one carrier to another.',
        },
        {
          'term': 'roaming',
          'meaning':
              'Using service outside the home network, often with extra charges.',
        },
        {
          'term': 'plan upgrade',
          'meaning':
              'Moving to a higher-tier service plan; may be blocked by eligibility rules.',
        },
      ];
    }
    if (s.contains('health')) {
      return const [
        {
          'term': 'claim',
          'meaning': 'Request for insurance to pay for a service.',
        },
        {
          'term': 'authorization',
          'meaning': 'Pre-approval required before some care.',
        },
        {
          'term': 'deductible',
          'meaning': 'Amount the member pays before coverage applies.',
        },
        {
          'term': 'referral',
          'meaning': 'Direction from a provider to another specialist.',
        },
        {
          'term': 'EOB',
          'meaning':
              'Explanation of Benefits; shows what insurance paid versus patient share.',
        },
        {
          'term': 'portal',
          'meaning': 'Online patient account for records, bills, and messages.',
        },
      ];
    }
    if (s.contains('finance') || s.contains('bank')) {
      return const [
        {
          'term': 'authorization hold',
          'meaning':
              'Temporary reservation of funds, not always a final charge.',
        },
        {
          'term': 'posting',
          'meaning': 'When a pending transaction becomes final on the account.',
        },
        {
          'term': 'chargeback',
          'meaning': 'Dispute process to reverse a card charge.',
        },
        {
          'term': 'hardship',
          'meaning':
              'Customer cannot meet payment terms and may need special review.',
        },
        {
          'term': 'card freeze',
          'meaning':
              'Temporary block on card spending, often customer or fraud driven.',
        },
        {
          'term': 'APR',
          'meaning': 'Annual percentage rate on credit products.',
        },
      ];
    }
    if (s.contains('retail') || s.contains('ecommerce')) {
      return const [
        {
          'term': 'tracking',
          'meaning': 'Carrier status events for a shipment.',
        },
        {
          'term': 'fulfillment',
          'meaning': 'Warehouse picking and shipping stage.',
        },
        {
          'term': 'RMA',
          'meaning': 'Return authorization for sending an item back.',
        },
        {
          'term': 'fulfillment center',
          'meaning': 'Warehouse location that packs and ships the order.',
        },
        {
          'term': 'delivery exception',
          'meaning': 'Carrier event that delayed or blocked delivery.',
        },
      ];
    }
    return const [
      {
        'term': 'escalation',
        'meaning': 'Moving the case to a specialist team with a full handoff.',
      },
      {
        'term': 'reference number',
        'meaning': 'ID the customer uses to track a ticket or case.',
      },
    ];
  }

  static List<Map<String, String>> escalateWhen(String sector) {
    final s = sector.toLowerCase();
    if (s.contains('tech') || s.contains('it')) {
      return const [
        {
          'case': 'Files still missing after recycle bin and backup checks',
          'say':
              'I cannot complete recovery at my level. I will escalate to Data Recovery with device details and what we already tried.',
        },
        {
          'case': 'Device will not boot or shows repeated critical errors',
          'say':
              'This needs advanced hardware or OS support. I will open a Tier 2 handoff with the exact error text.',
        },
      ];
    }
    if (s.contains('finance') || s.contains('bank')) {
      return const [
        {
          'case': 'Fraud investigation or identity theft',
          'say':
              'For your security this must go to Fraud / Security. I will collect impact and contact details for them.',
        },
        {
          'case': 'Loan restructure or hardship exception',
          'say':
              'Approvals sit with a specialist team. I will escalate with your situation summary and preferred callback time.',
        },
      ];
    }
    return const [
      {
        'case': 'Frontline tools cannot complete the request',
        'say':
            'I will escalate with a clear summary so you do not have to repeat everything.',
      },
      {
        'case': 'Policy exception or specialist approval required',
        'say':
            'This needs elevated review. I will send the case to the right department with your details.',
      },
    ];
  }

  static int? matchIndex(String sector, String problem) {
    return _bestIndex(forSector(sector), problem);
  }

  static SectorIssue? matchedIssue(String sector, String problem) {
    final primary = forSector(sector);
    final idx = _bestIndex(primary, problem);
    if (idx != null) return primary[idx];
    final general = _general;
    final gIdx = _bestIndex(general, problem);
    if (gIdx != null) return general[gIdx];
    return null;
  }

  static int? _bestIndex(List<SectorIssue> issues, String problem) {
    final p = problem.toLowerCase();
    if (p.isEmpty) return null;
    int best = -1;
    int bestScore = 0;
    for (var i = 0; i < issues.length; i++) {
      var score = 0;
      for (final k in issues[i].keywords) {
        if (!p.contains(k)) continue;
        // Longer / more specific phrases beat single generic words like "reset"
        score += k.contains(' ') ? 4 : (k.length >= 6 ? 2 : 1);
      }
      if (score > bestScore) {
        bestScore = score;
        best = i;
      }
    }
    if (bestScore == 0) return null;
    return best;
  }

  static const List<SectorIssue> _tech = [
    SectorIssue(
      title: 'Security alert or possible virus',
      summary:
          'Device shows a virus, malware, or security pop-up and the customer is worried.',
      sayThis:
          'I understand a security alert is stressful. Do not enter passwords or pay any pop-up. We will check this safely one step at a time.',
      keywords: [
        'virus',
        'malware',
        'security alert',
        'security',
        'infected',
        'pop-up',
        'popup',
        'antivirus',
        'trojan',
        'spyware',
      ],
      steps: [
        'Confirm phone or computer, and the exact alert wording.',
        'Tell them not to click pay-now or password prompts on the alert.',
        'Close the alert, uninstall any recently installed suspicious app or game if safe to do so.',
        'Run a scan with built-in security or a trusted antivirus, then restart and recheck.',
        'If the alert remains, escalate with device type, alert text, and steps already tried.',
      ],
    ),
    SectorIssue(
      title: 'Cannot connect to Wi-Fi',
      summary: 'Device fails to join or stay on the network.',
      sayThis:
          'I can walk you through a few connection checks. Please tell me the result after each step.',
      keywords: ['wifi', 'wi-fi', 'wireless', 'connect', 'network'],
      steps: [
        'Confirm the correct network name is selected.',
        'Toggle airplane mode on for 10 seconds, then off.',
        'Forget the network, then reconnect with the password.',
        'Restart the router, wait 2 minutes, then try again.',
        'If it still fails, note any error text and escalate with device model.',
      ],
    ),
    SectorIssue(
      title: 'Slow internet or buffering',
      summary: 'Pages load slowly or video keeps buffering.',
      sayThis:
          'Let us measure speed and isolate whether this is device or network related.',
      keywords: ['slow', 'buffer', 'speed', 'lag'],
      steps: [
        'Ask for a quick speed test result on the affected device.',
        'Test on a second device on the same network.',
        'Move closer to the router or try a wired connection if available.',
        'Restart modem and router, then retest.',
        'If both devices stay slow, escalate with speed numbers and plan type.',
      ],
    ),
    SectorIssue(
      title: 'App crash or freeze',
      summary: 'App closes, freezes, or will not open.',
      sayThis: 'We can try a short reset path for the app before we escalate.',
      keywords: [
        'crash',
        'freeze',
        'app',
        'not opening',
        'force close',
        'startup',
        'startup screen',
        'wont go past',
        "won't go past",
        'boot loop',
      ],
      steps: [
        'Force close the app and reopen it.',
        'Confirm the app is updated to the latest version.',
        'Clear app cache if the device supports it.',
        'Restart the device and open the app again.',
        'If it still fails, escalate with device OS and exact error message.',
      ],
    ),
    SectorIssue(
      title: 'Files missing after reset or update',
      summary:
          'Documents or data disappeared after a system reset, update, or restore.',
      sayThis:
          'I am sorry your files are missing. I will walk you through recovery checks one step at a time, and we will escalate if recovery is outside frontline tools.',
      keywords: [
        'missing files',
        'files missing',
        'deleted files',
        'documents disappeared',
        'file recovery',
        'lost files',
        'recycle bin',
        'update',
        'disappeared',
        'lost data',
        'documents',
      ],
      steps: [
        'Confirm when the reset or update happened and which device or OS was used.',
        'Check Recycle Bin, Trash, or Recently Deleted for the missing files.',
        'Ask whether File History, Time Machine, OneDrive, Google Drive, or another backup is enabled.',
        'If a backup exists, guide a restore of the specific folders only.',
        'If nothing is recoverable at frontline level, escalate with device model, reset time, and what was lost.',
      ],
    ),

    SectorIssue(
      title: 'Device will not start or keeps restarting',
      summary:
          'Phone or computer fails to boot, loops, or shows a critical startup error.',
      sayThis:
          'I understand the device will not start normally. We will try safe basic checks before any advanced recovery.',
      keywords: [
        'will not start',
        'wont start',
        "won't start",
        'boot',
        'restarting',
        'blue screen',
        'black screen',
        'loop',
      ],
      steps: [
        'Confirm whether it powers on at all and any exact error text.',
        'Try a forced restart only, and note what appears on screen.',
        'Ask if this started after an update, drop, or battery drain.',
        'If it still will not boot, escalate with device model and error text.',
      ],
    ),
    SectorIssue(
      title: 'Email or account access problem',
      summary: 'Cannot send, receive, or sign in to email or a work account.',
      sayThis:
          'I can help with email or account access. We will verify the exact error without sharing passwords out loud.',
      keywords: [
        'email',
        'outlook',
        'gmail',
        'cannot send',
        'cannot receive',
        'mailbox',
      ],
      steps: [
        'Confirm which email app or site and the exact error message.',
        'Check network connectivity on the device.',
        'Try sign-out and sign-in only through the official flow.',
        'Escalate with the error text if access remains blocked.',
      ],
    ),
    SectorIssue(
      title: 'Password or login failure',
      summary: 'User cannot sign in to an account or service.',
      sayThis:
          'I will guide a secure login reset without sharing passwords out loud.',
      keywords: ['password', 'login', 'sign in', 'locked out', 'credentials'],
      steps: [
        'Confirm the exact username or email being used.',
        'Send or start a password reset through the official flow.',
        'Ask them to try a private or different browser if web-based.',
        'Check for pending verification email or SMS code.',
        'If still locked after reset, escalate with account ID and time of failure.',
      ],
    ),
  ];

  static const List<SectorIssue> _telco = [
    SectorIssue(
      title: 'Home internet down or outage',
      summary: 'No home connection, modem offline, or area outage concern.',
      sayThis:
          'I understand your home internet is down. We will try one safe check first, then log an outage path if it stays down.',
      keywords: [
        'internet',
        'down',
        'outage',
        'modem',
        'router',
        'no connection',
        'offline',
        'home internet',
        'neighbors',
        'wifi',
        'wi-fi',
      ],
      steps: [
        'Confirm whether the modem and router lights are normal.',
        'Guide a power cycle: unplug modem and router for 30 seconds, modem first on restore.',
        'Ask if neighbors still have service to separate local vs area issues.',
        'If still down, offer to log an outage check and set clear wait expectations.',
        'Escalate with address, modem status, and last time service worked if policy requires elevated handling.',
      ],
    ),
    SectorIssue(
      title: 'Plan upgrade denied',
      summary:
          'Online plan change or upgrade was blocked with little or no explanation.',
      sayThis:
          'I understand this is about a denied plan upgrade, not a network issue. I will help check what blocked the change.',
      keywords: [
        'upgrade',
        'plan',
        'denied',
        'change plan',
        'plan change',
        'blocked',
        'eligibility',
      ],
      steps: [
        'Confirm the plan they wanted and when they tried the change.',
        'Ask what message or error, if any, appeared on screen.',
        'Review account eligibility factors available in tools.',
        'Explain the blocker in plain words if you can see it.',
        'Escalate to billing or plan operations if the denial is system-side or unclear.',
      ],
    ),
    SectorIssue(
      title: 'No signal or dropped calls',
      summary: 'Weak coverage, calls drop, or no bars.',
      sayThis: 'Let us check coverage and device radio settings first.',
      keywords: ['signal', 'bars', 'dropped', 'coverage', 'no service'],
      steps: [
        'Toggle airplane mode for 15 seconds, then off.',
        'Confirm mobile data and calls are enabled.',
        'Ask if the issue happens only indoors or in one area.',
        'Restart the phone and retest a call.',
        'If coverage stays poor in a known good area, escalate with location and device model.',
      ],
    ),
    SectorIssue(
      title: 'Mobile data not working',
      summary: 'Calls may work but data does not load.',
      sayThis: 'We will verify APN and data settings before escalation.',
      keywords: ['mobile data', 'lte', '5g', 'no data', 'internet on phone'],
      steps: [
        'Confirm mobile data is turned on.',
        'Toggle airplane mode, then retest data.',
        'Check that the SIM is recognized in settings.',
        'Restart the phone and test a known website.',
        'If data stays down, escalate with plan type and last time it worked.',
      ],
    ),

    SectorIssue(
      title: 'Unexpected charges on bill',
      summary: 'Bill is higher than expected or has unknown line items.',
      sayThis:
          'I understand a bill surprise is frustrating. I will help review the charges in plain words.',
      keywords: [
        'bill',
        'charge on bill',
        'overcharged',
        'roaming',
        'unexpected charge',
        'invoice',
      ],
      steps: [
        'Confirm the billing period and the amount that looks wrong.',
        'Review plan, add-ons, and roaming or overage lines if visible.',
        'Explain each unusual item in simple language.',
        'Escalate billing operations if a correction needs elevated authority.',
      ],
    ),
    SectorIssue(
      title: 'Number porting or SIM swap issue',
      summary:
          'Customer cannot finish moving a number or activating a replacement SIM.',
      sayThis:
          'Porting and SIM swaps often need careful checks. I will confirm where the process stopped.',
      keywords: [
        'port',
        'porting',
        'sim swap',
        'activate sim',
        'transfer number',
      ],
      steps: [
        'Confirm old and new carrier or SIM status if they know it.',
        'Ask for any error shown during activation or port.',
        'Verify identity before discussing line details.',
        'Escalate to network or provisioning if the port is stuck system-side.',
      ],
    ),
    SectorIssue(
      title: 'SIM not detected',
      summary: 'Phone reports no SIM or invalid SIM.',
      sayThis: 'We can try a safe SIM check path. Avoid forcing the tray.',
      keywords: ['sim', 'not detected', 'invalid sim'],
      steps: [
        'Restart the phone with the SIM inserted.',
        'Reseat the SIM carefully if the customer is comfortable doing so.',
        'Test the SIM in another compatible phone if available.',
        'Confirm the account line is active in account tools if accessible.',
        'If still invalid, escalate for SIM replacement with account details.',
      ],
    ),
  ];

  static const List<SectorIssue> _healthcare = [
    SectorIssue(
      title: 'Appointment scheduling help',
      summary: 'Need to book, move, or confirm an appointment.',
      sayThis:
          'I can guide the scheduling steps and confirm what you should expect next.',
      keywords: ['appointment', 'schedule', 'booking', 'reschedule'],
      steps: [
        'Confirm patient name and preferred date range.',
        'Clarify visit type and location or telehealth preference.',
        'Offer the next available options from policy.',
        'Confirm any prep instructions the patient must follow.',
        'If no slots match medical urgency, escalate to scheduling specialist.',
      ],
    ),
    SectorIssue(
      title: 'Claim status inquiry',
      summary: 'Customer asks where a claim stands.',
      sayThis:
          'I can explain the claim status process and what documents are needed.',
      keywords: ['claim', 'status', 'denied', 'insurance'],
      steps: [
        'Verify identity before sharing claim details.',
        'Collect claim number or date of service.',
        'Explain current status in plain words.',
        'List any missing documents the member must provide.',
        'If denial needs appeal or exception, escalate with claim references.',
      ],
    ),

    SectorIssue(
      title: 'Patient portal or app login',
      summary: 'Cannot sign in to the health portal or mobile health app.',
      sayThis:
          'I can help with portal access. We will use official reset steps only and protect your information.',
      keywords: [
        'portal',
        'cannot login',
        'cannot sign in',
        'health app',
        'mychart',
      ],
      steps: [
        'Confirm which portal or app and the exact error.',
        'Guide the official password reset only.',
        'Ask them to try a different browser or update the app if relevant.',
        'Escalate if the account remains locked after the official reset.',
      ],
    ),
    SectorIssue(
      title: 'Medical bill or statement question',
      summary:
          'Confusion about a medical bill amount, insurance share, or statement.',
      sayThis:
          'Billing statements can be confusing. I will help explain the amounts we can see and what still needs specialist review.',
      keywords: [
        'medical bill',
        'statement',
        'balance due',
        'copay',
        'coinsurance',
        'explanation of benefits',
        'eob',
      ],
      steps: [
        'Verify identity before discussing bill details.',
        'Confirm the date of service and amount in question.',
        'Explain patient responsibility versus insurance portion in plain words.',
        'Escalate billing or claims review when adjustment or appeal is required.',
      ],
    ),
    SectorIssue(
      title: 'Prescription refill guidance',
      summary: 'Questions about refill timing or pharmacy process.',
      sayThis:
          'I will explain the refill path. I cannot prescribe or change medication.',
      keywords: ['prescription', 'refill', 'pharmacy', 'medication'],
      steps: [
        'Confirm medication name only as provided by the customer.',
        'Explain standard refill request through pharmacy or portal.',
        'Share expected processing time based on policy.',
        'Advise when to contact the prescriber if no refills remain.',
        'Escalate clinical or urgent medication concerns to the right team.',
      ],
    ),
  ];

  static const List<SectorIssue> _finance = [
    SectorIssue(
      title: 'Unrecognized card charge',
      summary: 'Customer disputes a charge they do not recognize.',
      sayThis:
          'We will verify the account first, then review the charge safely.',
      keywords: ['charge', 'unauthorized', 'dispute', 'transaction'],
      steps: [
        'Verify identity and account ownership.',
        'Locate the charge date and amount with the customer.',
        'Explain pending vs posted timing.',
        'Offer dispute or block-card options per policy.',
        'If fraud investigation is required, escalate with transaction IDs.',
      ],
    ),
    SectorIssue(
      title: 'Payment failed or declined',
      summary: 'Customer cannot complete a payment.',
      sayThis: 'Let us confirm payment method details and retry rules.',
      keywords: ['payment failed', 'declined', 'cannot pay', 'payment error'],
      steps: [
        'Confirm the payment method on file.',
        'Check for insufficient funds or expired card messages.',
        'Guide updating the payment method if allowed.',
        'Retry once after correction.',
        'If still failing, escalate with error code and payment attempt time.',
      ],
    ),

    SectorIssue(
      title: 'Card declined at purchase',
      summary:
          'Card is declined in store or online while the customer expects it to work.',
      sayThis:
          'I understand a declined card is stressful. I will help check common blockers without exposing full card numbers.',
      keywords: [
        'card declined',
        'declined at',
        'purchase declined',
        'not accepting my card',
      ],
      steps: [
        'Verify identity before discussing the account.',
        'Confirm online versus in-store and any message shown.',
        'Check for freeze, limit, or suspected fraud flags if tools allow.',
        'Escalate fraud or card operations if the decline is not a simple limit issue.',
      ],
    ),
    SectorIssue(
      title: 'Account locked or cannot sign in',
      summary:
          'Banking app or web account is locked after failed sign-in attempts.',
      sayThis:
          'For security I will guide a safe unlock path and will not ask for your full password in chat.',
      keywords: [
        'account locked',
        'locked out',
        'cannot sign in',
        'banking app',
        'access locked',
      ],
      steps: [
        'Verify identity using approved checks only.',
        'Guide the official unlock or password reset flow.',
        'Confirm whether a fraud alert triggered the lock.',
        'Escalate security if the account stays locked after official steps.',
      ],
    ),
    SectorIssue(
      title: 'Loan or payment arrangement help',
      summary: 'Hardship, restructure, or arrangement requests.',
      sayThis:
          'This often needs a specialist team. I can collect details for a proper handoff.',
      keywords: [
        'loan',
        'restructure',
        'hardship',
        'arrangement',
        'cannot pay',
      ],
      steps: [
        'Acknowledge the concern without promising approval.',
        'Collect income impact and preferred arrangement type.',
        'Verify identity and account.',
        'Explain that specialist review is required.',
        'Escalate with a complete summary and callback window.',
      ],
    ),
  ];

  static const List<SectorIssue> _retail = [
    SectorIssue(
      title: 'Order status and delivery',
      summary: 'Where is my order, delayed delivery questions.',
      sayThis: 'I can help track the order and explain the next delivery step.',
      keywords: ['order', 'delivery', 'shipping', 'tracking'],
      steps: [
        'Collect order number and email used at checkout.',
        'Confirm shipping status in plain words.',
        'Share expected delivery window.',
        'Offer address correction only if policy allows before ship.',
        'Escalate carrier exceptions with tracking ID.',
      ],
    ),

    SectorIssue(
      title: 'Damaged or wrong item received',
      summary: 'Package arrived damaged or the item is not what was ordered.',
      sayThis:
          'I am sorry the order arrived wrong or damaged. I will confirm the order details and the next return or replacement step.',
      keywords: [
        'damaged',
        'broken',
        'wrong item',
        'incorrect item',
        'not what i ordered',
      ],
      steps: [
        'Collect order number and describe the damage or mismatch.',
        'Confirm photos are needed only if policy requires them.',
        'Explain replacement versus refund options available.',
        'Escalate fulfillment exceptions when policy tools cannot complete the fix.',
      ],
    ),
    SectorIssue(
      title: 'Cancel order or missing package',
      summary:
          'Customer wants to cancel before ship or the package never arrived.',
      sayThis:
          'I can help with cancellation or a missing package check. Let us confirm the order status first.',
      keywords: [
        'cancel order',
        'missing package',
        'never arrived',
        'lost package',
        'where is my package',
      ],
      steps: [
        'Collect order number and current status.',
        'If not shipped, attempt cancellation per policy.',
        'If shipped, review tracking and delivery scan events.',
        'Escalate carrier claim paths when tracking shows an exception.',
      ],
    ),
    SectorIssue(
      title: 'Return or refund request',
      summary: 'Customer wants to return an item or get a refund.',
      sayThis: 'I will explain the return window and refund timing.',
      keywords: ['return', 'refund', 'exchange'],
      steps: [
        'Confirm item and order number.',
        'Check return window eligibility.',
        'Explain how to start the return label process.',
        'Share refund timing after warehouse receive.',
        'Escalate damaged or missing-item claims with photos if required.',
      ],
    ),
  ];

  static const List<SectorIssue> _general = [
    SectorIssue(
      title: 'Data or access lost after a change',
      summary:
          'Something disappeared or stopped working after a reset, update, or account change.',
      sayThis:
          'I am sorry this happened after the change. I will clarify what was lost and guide safe recovery checks before we escalate if needed.',
      keywords: [
        'deleted',
        'missing',
        'lost',
        'disappeared',
        'reset',
        'after update',
        'after reset',
        'cannot access',
        'wiped',
      ],
      steps: [
        'Confirm what changed right before the problem and what is missing now.',
        'Check simple recovery paths available for that product (backup, trash, restore, recent activity).',
        'Have the customer try one recovery step and report the result.',
        'Document what was tried and whether anything was restored.',
        'Escalate if recovery is incomplete or outside frontline tools.',
      ],
    ),
    SectorIssue(
      title: 'General how-to guidance',
      summary: 'Customer needs clear steps for a process.',
      sayThis:
          'I will break this into short steps. Please confirm after each one.',
      keywords: ['how to', 'help', 'guide', 'process'],
      steps: [
        'Restate the goal in one sentence.',
        'Give the first action only.',
        'Wait for the customer result.',
        'Continue one step at a time.',
        'Escalate if the process is outside frontline tools.',
      ],
    ),
    SectorIssue(
      title: 'Service not working as expected',
      summary: 'Feature or service behaves incorrectly.',
      sayThis: 'Let us isolate what happens versus what should happen.',
      keywords: ['not working', 'broken', 'error', 'issue'],
      steps: [
        'Ask what they expected to happen.',
        'Ask what actually happened, including any error text.',
        'Try one basic reset step appropriate to the product.',
        'Confirm whether the issue reproduces.',
        'Escalate with exact steps to reproduce if unresolved.',
      ],
    ),
  ];
}
