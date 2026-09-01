//shared simulation-phase enum
//used by both MockCallScreen and VoicePanel
//reacts to phase changes for accept, hold, after-call-work, etc.
enum SimulationPhase {
  incoming,
  active,
  onHold,
  afterCallWork,
  postCallBreak,
  wrappingUp,
}
