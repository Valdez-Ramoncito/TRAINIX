//this creates the customer
//this is what the AI responses back
class Customer {
  final String reply;
  final String emotion;
  final bool accountProvided;
  final String? accountId;
  final String problemStatus;
  final String callStatus;
  final bool isError;

  const Customer({
    required this.reply,
    required this.emotion,
    required this.accountProvided,
    this.accountId,
    required this.problemStatus,
    required this.callStatus,
    this.isError = false,
  });

  //from json, create a customer
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      reply: json['reply'] as String? ?? '',
      emotion: json['emotion'] as String? ?? 'neutral',
      accountProvided: json['accountProvided'] as bool? ?? false,
      accountId: json['accountId'] as String?,
      problemStatus: json['problemStatus'] as String? ?? 'pending',
      callStatus: json['callStatus'] as String? ?? 'ongoing',
    );
  }

  //if the creation fails, call this
  factory Customer.fallback(String rawText) {
    return Customer(
      reply: rawText,
      emotion: 'neutral',
      accountProvided: false,
      accountId: null,
      problemStatus: 'pending',
      callStatus: 'ongoing',
    );
  }

  //used specifically when every retry attempt failed (connection/API
  //trouble) — signals the caller to show a dedicated error state
  //instead of treating this as something the customer actually said
  factory Customer.connectionError() {
    return const Customer(
      reply: '',
      emotion: 'neutral',
      accountProvided: false,
      accountId: null,
      problemStatus: 'pending',
      callStatus: 'ongoing',
      isError: true,
    );
  }
}
