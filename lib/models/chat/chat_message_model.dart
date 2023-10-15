/// Model for chat message
class ChatMessage {
  final String from;
  final DateTime timestamp;
  final String contents;

  ChatMessage({
    required this.from,
    required this.timestamp,
    required this.contents,
  });
}