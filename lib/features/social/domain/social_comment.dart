import 'package:cloud_firestore/cloud_firestore.dart';

class SocialComment {
  const SocialComment({
    required this.id,
    required this.authorId,
    required this.text,
    required this.displayName,
    required this.createdAt,
    this.avatarUrl = '',
  });

  final String id;
  final String authorId;
  final String text;
  final String displayName;
  final String avatarUrl;
  final DateTime createdAt;

  factory SocialComment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return SocialComment(
      id: doc.id,
      authorId: data['authorId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
