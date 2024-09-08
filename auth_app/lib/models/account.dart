class Account {
  final String type;
  final String name;
  final String otp;

  Account({required this.type, required this.name, required this.otp});

  // Convert Account to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      'otp': otp,
    };
  }

  // Create Account from JSON
  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      type: json['type'],
      name: json['name'],
      otp: json['otp'],
    );
  }
}
