import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final bool isAdmin;
  final String status;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final Map<String, dynamic>? metadata;
  
  AdminUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.isAdmin = false,
    this.status = 'active',
    required this.createdAt,
    this.lastLogin,
    this.metadata,
  });
  
  factory AdminUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final createdAtTimestamp = data['createdAt'] as Timestamp?;
    final lastLoginTimestamp = data['lastLogin'] as Timestamp?;
    
    return AdminUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      isAdmin: data['role'] == 'admin',
      status: data['status'] ?? 'active',
      createdAt: createdAtTimestamp?.toDate() ?? DateTime.now(),
      lastLogin: lastLoginTimestamp?.toDate(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'role': isAdmin ? 'admin' : 'user',
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'metadata': metadata,
    };
  }
  
  // For CSV export
  List<String> toCsvRow() {
    return [
      uid,
      email,
      displayName ?? '',
      isAdmin ? 'Admin' : 'User',
      status,
      DateFormat('yyyy-MM-dd').format(createdAt),
      lastLogin != null ? DateFormat('yyyy-MM-dd').format(lastLogin!) : '',
    ];
  }
  
  // For display in UI
  String get joinDate => DateFormat('MMM d, yyyy').format(createdAt);
  
  String get lastLoginFormatted => 
      lastLogin != null ? DateFormat('MMM d, yyyy').format(lastLogin!) : 'Never';
  
  AdminUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    bool? isAdmin,
    String? status,
    DateTime? createdAt,
    DateTime? lastLogin,
    Map<String, dynamic>? metadata,
  }) {
    return AdminUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      isAdmin: isAdmin ?? this.isAdmin,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      metadata: metadata ?? this.metadata,
    );
  }
}