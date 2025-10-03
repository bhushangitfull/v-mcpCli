import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chatmcp/dao/chat.dart';
import 'package:chatmcp/llm/model.dart';
import 'package:chatmcp/repository/chat_repository.dart';
import 'package:chatmcp/config/pagination_config.dart';

class RemoteChatRepository implements ChatRepository {
  final String baseUrl;
  final String apiKey;

  RemoteChatRepository({required this.baseUrl, required this.apiKey});

  Map<String, String> get _headers => {'Content-Type': 'application/json', 'Authorization': 'Bearer $apiKey'};

  @override
  Future<ChatListResult> getChats({
    int page = 1, 
    int pageSize = PaginationConfig.defaultPageSize,
    String? searchKeyword,
  }) async {
    var uri = Uri.parse('$baseUrl/chats');
    final queryParams = <String, String>{'page': page.toString(), 'pageSize': pageSize.toString()};

    if (searchKeyword != null && searchKeyword.isNotEmpty) {
      queryParams['search'] = searchKeyword;
    }

    uri = uri.replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> chatsData = data['chats'] ?? [];
      final chats = chatsData.map((item) => _chatFromJson(item)).toList();

      return ChatListResult(chats: chats, total: data['total'] ?? chats.length, hasMore: data['hasMore'] ?? false);
    } else {
      throw Exception('Failed to load chats: ${response.statusCode}');
    }
  }

  @override
  Future<List<Chat>> getAllChats() async {
    final response = await http.get(Uri.parse('$baseUrl/chats'), headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => _chatFromJson(item)).toList();
    } else {
      throw Exception('Failed to load chats: ${response.statusCode}');
    }
  }

  @override
  Future<Chat?> getChatById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/chats/$id'), headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return _chatFromJson(data);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to load chat: ${response.statusCode}');
    }
  }

  @override
  Future<Chat> createChat(Chat chat, List<ChatMessage> messages) async {
    final requestBody = {
      'title': chat.title,
      'createdAt': chat.createdAt.toIso8601String(),
      'updatedAt': chat.updatedAt.toIso8601String(),
      'messages': messages.map((m) => _messageToJson(m)).toList(),
    };

    final response = await http.post(Uri.parse('$baseUrl/chats'), headers: _headers, body: json.encode(requestBody));

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return _chatFromJson(data);
    } else {
      throw Exception('Failed to create chat: ${response.statusCode}');
    }
  }

  @override
  Future<void> updateChat(Chat chat) async {
    if (chat.id == null) throw ArgumentError('Chat ID cannot be null');

    final requestBody = {'title': chat.title, 'updatedAt': chat.updatedAt.toIso8601String()};

    final response = await http.put(Uri.parse('$baseUrl/chats/${chat.id}'), headers: _headers, body: json.encode(requestBody));

    if (response.statusCode != 200) {
      throw Exception('Failed to update chat: ${response.statusCode}');
    }
  }

  @override
  Future<void> deleteChat(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/chats/$id'), headers: _headers);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete chat: ${response.statusCode}');
    }
  }

  @override
  Future<void> addChatMessage(int chatId, List<ChatMessage> messages) async {
    final requestBody = {'messages': messages.map((m) => _messageToJson(m)).toList()};

    final response = await http.post(Uri.parse('$baseUrl/chats/$chatId/messages'), headers: _headers, body: json.encode(requestBody));

    if (response.statusCode != 201) {
      throw Exception('Failed to add messages: ${response.statusCode}');
    }
  }

  @override
  Future<List<ChatMessage>> getChatMessages(int chatId) async {
    final response = await http.get(Uri.parse('$baseUrl/chats/$chatId/messages'), headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => _messageFromJson(item)).toList();
    } else {
      throw Exception('Failed to load messages: ${response.statusCode}');
    }
  }

  Chat _chatFromJson(Map<String, dynamic> json) {
    return Chat(id: json['id'], title: json['title'], createdAt: DateTime.parse(json['createdAt']), updatedAt: DateTime.parse(json['updatedAt']));
  }

  Map<String, dynamic> _messageToJson(ChatMessage message) {
    return {
      'messageId': message.messageId,
      'parentMessageId': message.parentMessageId,
      'content': message.content,
      'role': message.role.name,
      'name': message.name,
      'toolCallId': message.toolCallId,
    };
  }

  ChatMessage _messageFromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['messageId'] ?? '',
      parentMessageId: json['parentMessageId'] ?? '',
      content: json['content'],
      role: MessageRole.values.firstWhere((e) => e.name == json['role'], orElse: () => MessageRole.user),
      name: json['name'],
      toolCallId: json['toolCallId'],
    );
  }
}
