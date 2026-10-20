class AppUser {
  const AppUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.department,
    required this.emailVerified,
    this.phone,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String department;
  final String? phone;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool emailVerified;

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final names = fullName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (names.isEmpty) return 'U';
    if (names.length == 1) return names.first[0].toUpperCase();
    return '${names.first[0]}${names.last[0]}'.toUpperCase();
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      firstName: json['nome']?.toString() ?? '',
      lastName: json['sobrenome']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      department: json['setor']?.toString() ?? '',
      phone: json['telefone']?.toString(),
      createdAt: DateTime.tryParse(json['criadoEm']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['atualizadoEm']?.toString() ?? ''),
      emailVerified: json['emailVerificado'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'nome': firstName,
      'sobrenome': lastName,
      'email': email,
      'setor': department,
      'telefone': phone,
      'criadoEm': createdAt?.toIso8601String(),
      'atualizadoEm': updatedAt?.toIso8601String(),
      'emailVerificado': emailVerified,
    };
  }
}
