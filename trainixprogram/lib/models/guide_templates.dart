import 'package:trainixprogram/models/problem_family.dart';
import 'package:trainixprogram/models/simulation_stage.dart';

class GuideStep {
  final String text;
  final SimulationStage stage;

  const GuideStep({required this.text, required this.stage});
}

class GuideTemplates {
  static List<GuideStep> forFamily(ProblemFamily family) {
    switch (family) {
      case ProblemFamily.planEligibility:
        return const [
          GuideStep(
            text: 'Confirm which plan they have and which they want',
            stage: SimulationStage.exploring,
          ),
          GuideStep(
            text: 'Look up the account and confirm one detail',
            stage: SimulationStage.exploring,
          ),
          GuideStep(
            text: 'Check the eligibility reason (contract, balance, tenure)',
            stage: SimulationStage.acting,
          ),
          GuideStep(
            text: 'Explain the reason in plain words and the options',
            stage: SimulationStage.acting,
          ),
          GuideStep(
            text: 'File the upgrade review or service request',
            stage: SimulationStage.acting,
          ),
          GuideStep(
            text: 'Confirm what happens next and the timeline',
            stage: SimulationStage.acting,
          ),
        ];
      case ProblemFamily.loginAccess:
        return const [
          GuideStep(
            text: 'Confirm the exact username or email used to sign in',
            stage: SimulationStage.exploring,
          ),
          GuideStep(
            text: 'Acknowledge what they already tried',
            stage: SimulationStage.exploring,
          ),
          GuideStep(
            text: 'Guide the official reset path one step at a time',
            stage: SimulationStage.acting,
          ),
          GuideStep(
            text: 'Confirm whether a reset email arrives',
            stage: SimulationStage.acting,
          ),
          GuideStep(
            text: 'Open a secure review if access stays blocked',
            stage: SimulationStage.acting,
          ),
        ];
      case ProblemFamily.billingSurprise:
        return const [
          GuideStep(
            text: 'Confirm the billing period that looks wrong',
            stage: SimulationStage.exploring,
          ),
          GuideStep(
            text: 'Look up the account and confirm one detail',
            stage: SimulationStage.exploring,
          ),
          GuideStep(
            text: 'List unusual charges in plain words',
            stage: SimulationStage.acting,
          ),
          GuideStep(
            text: 'Explain what changed versus a typical month',
            stage: SimulationStage.acting,
          ),
          GuideStep(
            text: 'File a billing review or correction request if needed',
            stage: SimulationStage.acting,
          ),
        ];
      case ProblemFamily.networkConnectivity:
        return const [
          GuideStep(
            text:
                'Confirm service type and symptoms (calls, data, SMS, outage)',
            stage: SimulationStage.exploring,
          ),
          GuideStep(
            text: 'Ask when it started and wired versus Wi-Fi if relevant',
            stage: SimulationStage.exploring,
          ),
          GuideStep(
            text: 'Guide one check at a time and confirm the result',
            stage: SimulationStage.acting,
          ),
          GuideStep(
            text: 'Try one new step or file a network review if still down',
            stage: SimulationStage.acting,
          ),
        ];
      case ProblemFamily.claimStatus:
        return const [
          GuideStep(
            text:
                'Acknowledge the claim concern and ask for claim number or service date',
            stage: SimulationStage.exploring,
          ),
          GuideStep(
            text: 'Confirm identity before sharing protected claim details',
            stage: SimulationStage.exploring,
          ),
          GuideStep(
            text: 'Explain current status in plain words',
            stage: SimulationStage.acting,
          ),
          GuideStep(
            text: 'List any missing documents',
            stage: SimulationStage.acting,
          ),
          GuideStep(
            text: 'File a review or appeal path if needed',
            stage: SimulationStage.acting,
          ),
        ];
      case ProblemFamily.prescriptionRefill:
        return const [
          GuideStep(
            text: 'Confirm medication request and pharmacy',
            stage: SimulationStage.exploring,
          ),
          GuideStep(
            text: 'Explain the refill path (cannot prescribe or change meds)',
            stage: SimulationStage.acting,
          ),
          GuideStep(
            text: 'Share expected processing time',
            stage: SimulationStage.acting,
          ),
          GuideStep(
            text: 'File a follow-up if the refill stays delayed',
            stage: SimulationStage.acting,
          ),
        ];
      case ProblemFamily.fundTransfer:
        return const [
          GuideStep(
            text: 'Confirm amount, send time, and where it was sent',
            stage: SimulationStage.exploring,
          ),
          GuideStep(
            text: 'Verify identity before account status',
            stage: SimulationStage.exploring,
          ),
          GuideStep(
            text: 'Explain normal timing and what the record shows',
            stage: SimulationStage.acting,
          ),
          GuideStep(
            text: 'File a transfer review if past the promised window',
            stage: SimulationStage.acting,
          ),
        ];
      case ProblemFamily.appointmentPrep:
        return const [
          GuideStep(
            text: 'Confirm the appointment details',
            stage: SimulationStage.exploring,
          ),
          GuideStep(
            text: 'Share preparation steps in plain words',
            stage: SimulationStage.acting,
          ),
          GuideStep(
            text: 'Confirm what to expect next',
            stage: SimulationStage.acting,
          ),
        ];
      case ProblemFamily.trueEscalate:
        return const [
          GuideStep(
            text: 'Acknowledge the issue and gather required details',
            stage: SimulationStage.exploring,
          ),
          GuideStep(
            text: 'Explain why a specialist team must continue',
            stage: SimulationStage.escalating,
          ),
          GuideStep(
            text: 'Collect handoff summary and set expectation',
            stage: SimulationStage.escalating,
          ),
        ];
      case ProblemFamily.genericAccount:
        return const [
          GuideStep(
            text: 'Acknowledge the issue and clarify the goal',
            stage: SimulationStage.exploring,
          ),
          GuideStep(
            text: 'Look up the account and confirm one detail',
            stage: SimulationStage.exploring,
          ),
          GuideStep(
            text: 'Explain findings in plain words',
            stage: SimulationStage.acting,
          ),
          GuideStep(
            text: 'File a service request, callback, or review ticket',
            stage: SimulationStage.acting,
          ),
        ];
      case ProblemFamily.genericNonAccount:
        return const [
          GuideStep(
            text: 'Acknowledge the issue and clarify one detail',
            stage: SimulationStage.exploring,
          ),
          GuideStep(
            text: 'Guide one clear step at a time',
            stage: SimulationStage.acting,
          ),
          GuideStep(
            text: 'Confirm the customer can continue',
            stage: SimulationStage.acting,
          ),
        ];
    }
  }
}
