class Student {
  final int studentId; // match Laravel primary key
  final String name;
  final String email;
  final String phone;
  final String role;

  Student({
    required this.studentId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      studentId: json['student_id'], // match backend
      name: json['name'],
      email: json['email'],
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'student',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
    };
  }
}
