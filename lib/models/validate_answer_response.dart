class ValidateAnswerResponse {
  final String status; // EMPTY, YES_NO, NEED_MORE_INFO, IRRELEVANT, VALID_TEXT, Q1_DIRECT_MOOD
  final String normalized;
  final bool isYesNo;
  final String? directMood; // For Q1_DIRECT_MOOD: Happy|Normal|Bad

  ValidateAnswerResponse({
    required this.status,
    required this.normalized,
    required this.isYesNo,
    this.directMood,
  });

  factory ValidateAnswerResponse.fromJson(Map<String, dynamic> json) {
    return ValidateAnswerResponse(
      status: json['status'] ?? '',
      normalized: json['normalized'] ?? '',
      isYesNo: json['is_yes_no'] ?? false,
      directMood: json['direct_mood'],
    );
  }

  bool get isEmpty => status == 'EMPTY';
  bool get needsMoreInfo => status == 'NEED_MORE_INFO';
  bool get isIrrelevant => status == 'IRRELEVANT';
  bool get isYesNoAnswer => status == 'YES_NO';
  bool get isValidText => status == 'VALID_TEXT';
  bool get isQ1DirectMood => status == 'Q1_DIRECT_MOOD';
}
