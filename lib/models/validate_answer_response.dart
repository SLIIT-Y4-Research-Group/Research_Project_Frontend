class ValidateAnswerResponse {
  final String status;
  final String normalized;
  final bool isYesNo;
  final String? directMood;

  ValidateAnswerResponse({
    required this.status,
    required this.normalized,
    required this.isYesNo,
    this.directMood,
  });

  factory ValidateAnswerResponse.fromJson(Map<String, dynamic> json) {
    return ValidateAnswerResponse(
      status: (json['status'] ?? '').toString(),
      normalized: (json['normalized'] ?? '').toString(),
      isYesNo: json['is_yes_no'] == true,
      directMood: json['direct_mood']?.toString(),
    );
  }

  String get statusNormalized => status.trim().toUpperCase();

  bool get isEmpty => statusNormalized == "EMPTY";
  bool get needsMoreInfo => statusNormalized == "NEED_MORE_INFO";
  bool get isIrrelevant => statusNormalized == "IRRELEVANT";
  bool get isYesNoAnswer => statusNormalized == "YES_NO" || isYesNo;
  bool get isValidText => statusNormalized == "VALID_TEXT";
  bool get isQ1DirectMood => statusNormalized == "Q1_DIRECT_MOOD";
  bool get isNeutralPhrase => statusNormalized == "NEUTRAL_PHRASE";
}