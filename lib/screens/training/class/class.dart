//enumerations for the phases of the simulation
enum SimulationPhase {
  incoming,
  active,
  onHold,
  afterCallWork,
  postCallBreak,
  wrappingUp,
}

//enumeration for the phases of the voice call
enum VoicePhase {
  idle,
  customerSpeaking,
  traineeSpeaking,
  transcribing,
  processing,
  resolved,
}


//regular expressions for filler words used in Voice Call
final RegExp fillerWordPattern = RegExp(
  r'\b(um+|uh+|hmm+|like|you know|i mean)\b',
  caseSensitive: false,
);

//count all the filler words that are present in the text
//then return the result
int countFillerWords(String text) {
  return fillerWordPattern.allMatches(text).length;
}

//enumerations for the phases of the chat conversation
//afterCallWork mirrors voice's — a manual report step before the grace
//period, instead of jumping straight from resolution into the countdown
enum ChatPhase { active, resolved, afterCallWork, gracePeriod, waitingToEnd }
