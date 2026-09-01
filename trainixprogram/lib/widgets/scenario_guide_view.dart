import 'package:flutter/material.dart';

//shared Scenario Guide UI, used identically by both the voice and chat
//channels.
class ScenarioGuideView extends StatelessWidget {
  final String? sector;
  final String? emotion;
  final String? problem;

  const ScenarioGuideView({
    super.key,
    required this.sector,
    required this.emotion,
    required this.problem,
  });

  @override
  Widget build(BuildContext context) {
    final sector = this.sector;

    //if this is empty, return a neutral text
    if (sector == null || sector.isEmpty) {
      return const Center(
        child: Text(
          'Start the conversation to reveal the scenario.',
          textAlign: TextAlign.center,
        ),
      );
    }

    //return the guide
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGuideSection('Sector', sector),
          _buildGuideSection(
            'Customer emotion',
            (emotion ?? 'unknown')[0].toUpperCase() +
                (emotion ?? 'unknown').substring(1),
          ),
          _buildGuideSection('Customer problem', problem ?? 'Unknown'),
          if (_getProblemGuidance(problem).isNotEmpty)
            _buildGuideSection(
              'Specific to this case',
              _getProblemGuidance(problem),
            ),
          const Divider(height: 24),
          _buildGuideSection(
            'Handling approach',
            _getHandlingTip(emotion ?? ''),
          ),
          _buildGuideSection('Sector reminders', _getSectorReminder(sector)),
          const Divider(height: 24),
          _buildGuideList('Key phrases to use', _getKeyPhrases()),
          const SizedBox(height: 12),
          _buildGuideList('Things to avoid', _getThingsToAvoid(emotion ?? '')),
        ],
      ),
    );
  }

  Widget _buildGuideSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(content, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildGuideList(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 3.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 13)),
                  Expanded(
                    child: Text(item, style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  //problem specific coaching tip, keyed by the exact problem string from
  //OpenRouterAPIService's _problemsBySector. Each one traces back to a
  //real regulatory/industry category: BSP, NTC, PhilHealth, or ITIL
  static const Map<String, String> _problemGuidance = {
    //Finance (BSP)
    'an unauthorized transaction appeared on their account':
        "Under BSP's consumer protection rules, the customer isn't "
        'presumed at fault until the bank\'s own investigation says '
        'otherwise  reassure them of that while you start the '
        'dispute process.',
    'their account balance does not match their records':
        'Walk through the transaction history together line by line '
        'before concluding anything  most balance disputes trace '
        "back to a specific entry the customer just hasn't spotted "
        'yet.',
    'their card is being declined despite having funds':
        'Check for a hold, a blocked card status, or a mismatched '
        'billing address before assuming it\'s a balance issue  '
        'declines with sufficient funds are rarely about the money '
        'itself.',
    'unexpected fees were charged without explanation':
        'Pull up the fee schedule and point to exactly which fee '
        'applied and why  vague explanations are what turn a fee '
        'question into a formal complaint.',
    'their loan application was rejected without a clear reason':
        "Lenders are expected to give a specific reason for a rejected "
        "application  if you don't have it in front of you, that's "
        'what needs escalating, not the rejection itself.',
    'someone else may have accessed their account information without permission':
        "This is a data privacy concern, not just an account issue  "
        'treat it with the same urgency as a security incident and '
        "don't downplay it.",
    'they received a suspicious call or message asking for their account details':
        "Confirm they haven't already responded with real account "
        'details  if they have, this shifts from a warning '
        'conversation to an active fraud response.',
    'a collection agent has been contacting them aggressively about a loan':
        'Abusive collection practices are explicitly against BSP rules '
        " acknowledge that plainly rather than defending the "
        "agent's conduct.",
    "a fund transfer they sent never arrived in the recipient's account":
        "InstaPay/PESONet transfers can 'hang'  deducted from the "
        'sender without crediting the receiver. Confirm the '
        'transaction reference number before troubleshooting '
        'further.',
    "they want to restructure their loan because they can't keep up with payments":
        'This is a proactive request, not a complaint  the tone '
        'should be collaborative, focused on what options actually '
        'exist for their situation.',
    'an ATM took money from their account without dispensing any cash':
        'This is one of the most common BSP-tracked dispute types  '
        'reassure them this is a known, resolvable issue, not '
        'something unusual.',
    'they were charged twice for the same online purchase':
        'Ask for the merchant name and both transaction dates/amounts '
        'up front  duplicate charges are usually easy to confirm '
        'once you have both entries side by side.',

    //Healthcare PhilHealth / HMO
    'their insurance claim was denied':
        'Ask which denial reason was given  non-accreditation, '
        'contribution gaps, and coding errors all need a '
        'completely different next step.',
    'they were billed incorrectly for a recent hospital visit':
        'Request an itemized Statement of Account before disputing any '
        'specific charge  non-itemized billing is itself a valid '
        'complaint.',
    'they are unable to schedule an appointment':
        'Confirm whether this is a capacity issue or a coverage/'
        'referral issue  the fix is completely different '
        'depending on which it is.',
    'their prescription is not being covered by insurance':
        "Check whether the medication is even in the plan's covered "
        'formulary before troubleshooting anything else.',
    'they are confused about a referral they received':
        'Slow down and confirm what the referral is actually for  '
        "confusion here usually means the referring provider didn't "
        'explain it clearly the first time.',
    "their claim was denied because the hospital wasn't an accredited facility":
        "This one isn't reversible after the fact  be honest that "
        'accreditation has to be verified before admission, and '
        'focus on what alternative coverage options exist now.',
    'their claim was denied over a gap in their contributions':
        'This disproportionately affects self-paying members and OFWs '
        ' check contribution history with them rather than '
        'assuming it\'s a simple oversight.',
    "their claim was denied due to a coding error on the hospital's part":
        "This is the hospital's error to fix, not the patient's  be "
        'clear the responsibility sits with the billing department, '
        'not the member.',
    'the hospital is asking them to pay cash before they can be discharged':
        "Patients shouldn't be pressured to pay cash or sign waivers "
        'before discharge when they have active coverage  this is '
        'a real grievance category, treat it seriously.',
    "the hospital never filed their claim and now they're stuck paying the full bill":
        "This is a hospital-side filing failure, not the member's "
        'fault  the path forward is holding the facility '
        'accountable, not re-litigating the original diagnosis.',

    //Telco NTC
    'their internet connection keeps dropping':
        'Rule out a known outage in their area first  no point '
        "troubleshooting a home router during a network-wide issue.",
    'unexpected charges appeared on their bill':
        "Break the bill down line by line with them  NTC's electronic "
        'billing rules require charges to be transparent, so there '
        "should be a clear line item for whatever they're disputing.",
    'their mobile data is not working despite having an active plan':
        "Check whether they've hit a fair-use policy data cap before "
        'assuming it\'s a technical fault  throttling after a cap '
        'is a policy issue, not a bug.',
    'there is a service outage in their area':
        "Give a real timeline if one exists  vague 'we're looking "
        "into it' responses are what turn outage reports into "
        'formal complaints.',
    'they were charged for roaming they did not expect':
        'Confirm whether roaming was ever actually enabled on the line '
        ' unexpected roaming charges are usually a settings or '
        'notification failure, not intentional use.',
    'they keep receiving suspicious text messages that look like a scam':
        "Point them toward reporting the number through the carrier's "
        'scam-reporting channel  this is an NTC-tracked category, '
        "so there's a real process for it, not just a shrug.",
    'their prepaid load disappeared without them using it':
        "'Vanishing load' is a specifically recognized NTC complaint "
        'category  take it seriously rather than assuming the '
        'customer miscounted their own usage.',
    'they were denied a plan upgrade without a clear reason':
        'Customers are entitled to a real reason for a denied '
        "application  if you don't have one on hand, that's the "
        'actual gap to close.',
    "they're being charged an early termination fee they weren't told about":
        'Lock-in period terms have to be disclosed up front  if the '
        "customer says they weren't told, that's a legitimate "
        'dispute, not just a technicality.',
    'they signed up for a service they never asked for and are now being billed for it':
        'Unrequested value-added services are a recognized complaint '
        'category  the fix is usually a straightforward opt-out '
        'plus a refund, not a debate about whether they signed up.',
    'their internet speed is far slower than what was advertised':
        "Ask if they've run a proper speed test at a wired connection "
        " 'advertised vs. actual' speed disputes need real "
        "numbers, not just a general 'it feels slow.'",

    //Tech Support ITIL
    'their device stopped working after a recent update':
        'Confirm the exact update version and when it installed  '
        "'stopped working after an update' almost always narrows "
        'down fast once you have a timestamp.',
    'a software they need fails to install':
        "Check the error code first, don't guess  installation "
        'failures usually fail in a specific, identifiable way.',
    'they are locked out of their account and cannot recover it':
        'Verify identity through a secondary method before doing '
        'anything else  account recovery is exactly where '
        'security shortcuts cause real damage.',
    'their device has become unusably slow':
        'Ask what changed recently (new software, an update, low '
        "storage) before assuming it's just old hardware.",
    'important files disappeared after a system restore':
        "Don't promise recovery is guaranteed  walk them through "
        'checking backup/recovery locations first, honestly, before '
        'setting expectations.',
    "their two-factor authentication app stopped working and they can't log in":
        'This is one of the highest-volume help desk categories for a '
        'reason  have a clear, calm backup-verification path '
        'ready instead of treating it as unusual.',
    'they got a security alert about a possible virus on their device':
        'Treat this as a possible real security incident until proven '
        "otherwise  don't just tell them to 'ignore the pop-up' "
        'without checking.',
    "they can't log into a work application even though their password is correct":
        "This is very often an SSO/session issue, not a password issue "
        ' check the identity provider status before asking them '
        'to reset anything.',
    'a new device they were issued was never properly set up':
        'This is a provisioning gap, not user error  the fix is '
        'completing setup, not troubleshooting a device that was '
        'never finished in the first place.',
    "their software subscription shows as expired even though they're still paying for it":
        'Check whether the payment and the license key are actually '
        'linked on the backend  this is a common licensing-sync '
        'issue, not a billing dispute.',
  };

  //returns the problem specific tip, or a sensible generic fallback if
  //the problem string isn't in the map
  String _getProblemGuidance(String? problem) {
    if (problem == null || problem.isEmpty) return '';
    return _problemGuidance[problem] ??
        'No specific note for this case yet  ask clarifying questions '
            "and confirm the customer's exact situation before offering "
            'a solution.';
  }

  //get handling tip based on emotion
  String _getHandlingTip(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'angry':
        return 'De-escalate first. Acknowledge the frustration sincerely '
            'before offering any solution. Never argue or match their tone.';
      case 'frustrated':
        return 'Validate their experience, then move quickly to a solution. '
            'Keep your tone calm and apologetic without being defensive.';
      case 'anxious':
        return 'Reassure early and often. Use confident, steady language. '
            '"I will take care of this for you right away."';
      case 'confused':
        return 'Slow down. Avoid jargon. Confirm understanding at each step '
            'before moving forward. Repeat key points if needed.';
      case 'impatient':
        return 'Be efficient. Skip long explanations  summarize steps briefly '
            'and keep the customer updated on progress.';
      case 'polite but urgent':
        return 'Acknowledge the urgency immediately. Work quickly and provide '
            'clear timelines so they know you are taking it seriously.';
      default:
        return 'Stay professional and solution-focused. Mirror their calm '
            'tone and guide the conversation toward resolution.';
    }
  }

  //get sector reminders based on sector
  String _getSectorReminder(String sector) {
    switch (sector) {
      case 'Finance':
        return 'Verify account identity before sharing or adjusting any details. '
            'Comply with the Data Privacy Act. Explain all adjustments clearly '
            'and confirm the customer understands before ending the call.';
      case 'Healthcare':
        return 'Use plain language  avoid medical jargon. Protect patient privacy '
            'at all times. Confirm appointment or claim details before making changes.';
      case 'Telco':
        return 'Run basic troubleshooting before escalating. Confirm the service area '
            'and check the billing cycle when handling charge disputes.';
      default:
        return 'Gather device and OS information early. Confirm any recent changes '
            'such as updates or new installs. Guide the customer step by step '
            'and confirm each action before proceeding.';
    }
  }

  //get key phrases
  List<String> _getKeyPhrases() {
    return [
      'Instead of "I can\'t do that" ? "What I can do for you is..."',
      'Instead of "You need to wait" ? "I\'ll have this resolved as quickly as possible."',
      'Instead of "That\'s not my department" ? "Let me connect you with the right team."',
      '"I completely understand your concern."',
      '"Thank you for bringing this to our attention."',
      '"Is there anything else I can help you with today?"',
    ];
  }

  //get things to avoid based on emotion
  List<String> _getThingsToAvoid(String emotion) {
    final universal = [
      'Never say "calm down"  it escalates tension.',
      'Do not place the customer on hold without explaining why and asking permission.',
      'Avoid filler words: "um", "uh", "like", "you know".',
      'Never promise something you cannot deliver.',
    ];
    if (emotion == 'angry' || emotion == 'frustrated') {
      universal.add('Do not say "That\'s not our fault"  take ownership.');
    }
    if (emotion == 'confused') {
      universal.add(
        'Avoid using technical terms without explaining them first.',
      );
    }
    return universal;
  }
}
