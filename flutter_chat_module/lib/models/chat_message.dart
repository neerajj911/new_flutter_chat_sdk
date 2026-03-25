class ChatMessage {
  final String id;
  final String text;
  final String senderId;
  final String senderName;
  final DateTime timestamp;
  final bool isMe;

  ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
    required this.isMe,
  });

  factory ChatMessage.fromJson(
    Map<String, dynamic> json,
    String currentUserId,
  ) {
    final senderId = json['senderId'] as String? ?? '';
    return ChatMessage(
      id:
          json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      text: json['text'] as String? ?? '',
      senderId: senderId,
      senderName: json['senderName'] as String? ?? 'Unknown',
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : DateTime.now(),
      isMe: senderId == currentUserId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'senderId': senderId,
      'senderName': senderName,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}
