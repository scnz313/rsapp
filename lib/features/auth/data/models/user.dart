class User {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool isAdmin;

  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.isAdmin = false,
  });
}
