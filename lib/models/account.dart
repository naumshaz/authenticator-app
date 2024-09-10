class Account {
  final String type;
  final String name;
  final String key;
  int lastOtpGenerationTime;
  final int otpInterval;

  Account({
    required this.type,
    required this.name,
    required this.key,
    required this.lastOtpGenerationTime,
    this.otpInterval = 30,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      type: json['type'],
      name: json['name'],
      key: json['key'],
      lastOtpGenerationTime: json['lastOtpGenerationTime'] ?? 0,
      otpInterval: json['otpInterval'] ?? 30,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      'key': key,
      'lastOtpGenerationTime': lastOtpGenerationTime,
      'otpInterval': otpInterval,
    };
  }
}
