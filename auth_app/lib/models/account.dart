class Account {
  final String type;
  final String name;
  final String key;

  Account({required this.type, required this.name, required this.key});

  // Convert Account to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      'key': key,
    };
  }

  // Create Account from JSON
  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      type: json['type'],
      name: json['name'],
      key: json['key'],
    );
  }
}
