// Copyright 2024 the Dart project authors. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

// AIzaSyCDRy528NkxcpPs1UuBJ_cQrY4R_ZRPUWc

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:url_launcher/link.dart';

void main() {
  runApp(const GenerativeAISample());
}

class GenerativeAISample extends StatelessWidget {
  const GenerativeAISample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Master Chef',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color.fromARGB(255, 171, 222, 244),
        ),
        useMaterial3: true,
      ),
      home: const ChatScreen(title: 'Master Chef'),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.title});

  final String title;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? apiKey;
  List<Map<String, String>> favoriteConversations = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Master Chef AI', // Centered title
          style: TextStyle(
            fontSize: 20, // Font size for the title
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu), // Hamburger menu icon
            onPressed: () {
              // Open the drawer
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_restaurant), // Chef hat icon
            onPressed: () {
              // Add your chef hat action here
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.only(top: 16), // Add top padding here
            children: <Widget>[
              Container(
                height: 50, // Set the height for the header
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(20),
                    top: Radius.circular(20),
                  ), // Rounded corners for both top and bottom
                ),
                child: const Center( // Center the text horizontally
                  child: Text(
                    'Menu',
                    style: TextStyle(
                      fontSize: 20, // Adjust font size if needed
                      color: Colors.white, // Ensure text color is visible
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Conversa'),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  // Implement navigation logic to "Diálogo" if needed
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite),
                title: const Text('Conversas favoritas'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FavoritesPage(favorites: favoriteConversations), // Pass the favorites list
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: switch (apiKey) {
              final providedKey? => ChatWidget(
                apiKey: providedKey,
                favoriteConversations: favoriteConversations, // Pass the favorites list
                onSaveFavorite: _saveConversationToFavorites, // Pass a callback to save favorites
              ),
              _ => ApiKeyWidget(
                onSubmitted: (key) {
                  setState(() => apiKey = key);
                },
              ),
            },
          ),
        ],
      ),
    );
  }
  void _saveConversationToFavorites(String title, String summary) {
    setState(() {
      favoriteConversations.add({
        'title': title,
        'summary': summary,
      });
    });
  }
}

class ApiKeyWidget extends StatelessWidget {
  ApiKeyWidget({required this.onSubmitted, super.key});

  final ValueChanged<String> onSubmitted;
  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Para utilizar o Gemini API, você vai precisar de uma chave. '
              'Se você não tem uma chave, você pode criar uma nesse link'
              'Google AI Studio.',
            ),
            const SizedBox(height: 8),
            Link(
              uri: Uri.https('makersuite.google.com', '/app/apikey'),
              target: LinkTarget.blank,
              builder: (context, followLink) => TextButton(
                onPressed: followLink,
                child: const Text('Get an API Key'),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration:
                        textFieldDecoration(context, 'Enter your API key'),
                    controller: _textController,
                    onSubmitted: (value) {
                      onSubmitted(value);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    onSubmitted(_textController.value.text);
                  },
                  child: const Text('Submit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChatWidget extends StatefulWidget {
  const ChatWidget({
    required this.apiKey,
    required this.favoriteConversations, // Receive the favorites list
    required this.onSaveFavorite, // Receive a callback to save favorites
    super.key,
  });

  final String apiKey;
  final List<Map<String, String>> favoriteConversations; // Store the favorites list
  final Function(String, String) onSaveFavorite; // Callback for saving favorites

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  late final GenerativeModel _model;
  ChatSession? _chat;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode(debugLabel: 'TextField');
  bool _loading = false;

  List<Map<String, String>> favoriteConversations = [];

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: widget.apiKey,
      systemInstruction: Content.system(
        'Você vai atuar com um papel de um chefe de cozinha renomado mundialmente. ' +
        'Pergunte para o usuário qual o chefe de cozinha ou colinaria do mundo ele prefere.' +
        'Diga que vai sugerir uma receita epecial para ele com base nas informações fornecidas.' +
        'Fornece de forma apetitosa um resumo do prato que irá sendo feito.' +
        'Pergunte se o usuário está pronto para começar.' +
        'Se a resposta for sim, comece a descrever primeiro os ingredientes que serão necessários' +
        'Se o usuário tiver todos os ingredientes descreva uma etapa de cada vez as ações necessárias para seguir a receita.' +
        'Depois da execução do usuário deseje um bom apetite' +
        'Responda de forma educada e descontraída.' +
        'Gere mensagens curtas.' +
        'Conduza o diálogo como um chefe de conzinha experiente que ensina um amigo a cozinhar.'
      )
    );
    _chat = _model.startChat();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      ),
    );
  }

  void _saveConversationToFavorites() {
    final history = _chat?.history.toList() ?? []; // Get the chat history
    final StringBuffer conversationSummary = StringBuffer();

    for (var content in history) {
      final text = content.parts
          .whereType<TextPart>()
          .map<String>((e) => e.text)
          .join('');

      // Append the sender's name and the corresponding message
      conversationSummary.writeln('${content.role == 'user' ? 'Você' : 'Master Chef'}: $text');
    }

    // Save the conversation summary with an appropriate title
    widget.onSaveFavorite(
        'Conversa Favorita ${widget.favoriteConversations.length + 1}',
        conversationSummary.toString()
    );
  }

  void _clearConversation() {
    setState(() {
      // Restart the chat session by creating a new chat instance
      _chat = _model.startChat();
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = _chat?.history.toList() ?? [];
    return Column(
      children: [
        // The header with title and delete button
        Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 230, 86, 76), // Solid background color for the header
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20), top: Radius.circular(20)), // Rounded corners at the bottom
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Padding around the container
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8), // Padding on the left for the Text component
              child: const Text(
                'Conversa',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Ensure the text is visible
                ),
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: _clearConversation,
                  icon: const Icon(Icons.delete, color: Colors.white), // Ensure the icon is visible
                ),
                // Step 2: Add favorite button
                IconButton(
                  onPressed: _saveConversationToFavorites,
                  icon: const Icon(Icons.favorite, color: Colors.white), // Heart icon for favorite
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3), // Background color with opacity
              borderRadius: BorderRadius.circular(16.0), // Rounded corners
              image: DecorationImage(
                image: AssetImage('assets/food.jpg'), // Background image for conversation
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.65), // Add black overlay with opacity
                  BlendMode.darken,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Add padding here
              child: ListView.builder(
                controller: _scrollController,
                itemBuilder: (context, idx) {
                  final content = history[idx];
                  final text = content.parts
                      .whereType<TextPart>()
                      .map<String>((e) => e.text)
                      .join('');
                  return MessageWidget(
                    text: text,
                    isFromUser: content.role == 'user',
                  );
                },
                itemCount: history.length,
              ),
            ),
          ),
        ),
        // Message input area is NOT affected by background image
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 25,
            horizontal: 15,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  autofocus: true,
                  focusNode: _textFieldFocus,
                  decoration:
                      textFieldDecoration(context, 'Digite uma mensagem...'),
                  controller: _textController,
                  onSubmitted: (String value) {
                    _sendChatMessage(value);
                  },
                  maxLines: null, // Allow unlimited lines for the text field
                  minLines: 1, // Minimum lines when there is no input
                ),
              ),
              const SizedBox.square(dimension: 15),
              if (!_loading)
                IconButton(
                  onPressed: () async {
                    _sendChatMessage(_textController.text);
                  },
                  icon: Icon(
                    Icons.send,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              else
                const CircularProgressIndicator(),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _sendChatMessage(String message) async {
    if (_chat == null) {
      _showError('Chat session not initialized.');
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final response = await _chat!.sendMessage(
        Content.text(message),
      );

      final text = response.text;

      if (text == null) {
        _showError('Empty response.');
      } else {
        setState(() {
          _loading = false;
          _scrollDown(); // Ensure it scrolls to the bottom after sending
        });
      }
    } catch (e) {
      _showError(e.toString());
      setState(() {
        _loading = false;
      });
    } finally {
      _textController.clear();
      setState(() {
        _loading = false;
      });
      _textFieldFocus.requestFocus();
      _scrollDown(); // Scroll after the message is added
    }
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Something went wrong'),
          content: SingleChildScrollView(
            child: Text(message),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            )
          ],
        );
      },
    );
  }
}

class MessageWidget extends StatelessWidget {
  const MessageWidget({
    super.key,
    required this.text,
    required this.isFromUser,
  });

  final String text;
  final bool isFromUser;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isFromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                decoration: BoxDecoration(
                  color: isFromUser
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 16, // Horizontal padding for the message
                ),
                margin: EdgeInsets.only(
                  bottom: 4,
                  left: isFromUser ? 70 : 10, // More distance from left edge for user messages
                  right: isFromUser ? 10 : 70, // More distance from right edge for assistant messages
                ),
                child: MarkdownBody(data: text),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12), // Horizontal padding for sender label
          child: Text(
            isFromUser ? 'Você' : 'Master Chef', // Conditionally display "User" or "Assistant"
            style: TextStyle(
              fontSize: 14, // Smaller font size for the label
              color: const Color.fromARGB(255, 255, 100, 89), // Faded color for text
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 6), // Space between the sender label and the message bubble
      ],
    );
  }
}

InputDecoration textFieldDecoration(BuildContext context, String hintText) =>
    InputDecoration(
      contentPadding: const EdgeInsets.all(15),
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(
          Radius.circular(14),
        ),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(
          Radius.circular(14),
        ),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );

class FavoritesPage extends StatefulWidget {
  final List<Map<String, String>> favorites;

  const FavoritesPage({super.key, required this.favorites});

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  void _deleteFavorite(int index) {
    setState(() {
      widget.favorites.removeAt(index); // Remove the item from the list
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted ${widget.favorites[index]['title']}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversas Favoritas'),
      ),
      body: ListView.builder(
        itemCount: widget.favorites.length,
        itemBuilder: (context, index) {
          final conversation = widget.favorites[index];
          return ListTile(
            title: Text(conversation['title']!),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteFavorite(index),
              tooltip: 'Delete Favorite',
            ),
            onTap: () {
              // Navigate to the conversation detail page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConversationDetailPage(
                    title: conversation['title']!,
                    summary: conversation['summary']!,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ConversationDetailPage extends StatelessWidget {
  final String title;
  final String summary; // This could be replaced with a more structured format

  const ConversationDetailPage({super.key, required this.title, required this.summary});

  @override
  Widget build(BuildContext context) {
    // Split the summary into lines for individual messages
    final messages = summary.split('\n'); // Assuming messages are newline-separated

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to the favorites page
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3), // Background color with opacity
                borderRadius: BorderRadius.circular(16.0), // Rounded corners
                image: DecorationImage(
                  image: AssetImage('assets/food.jpg'), // Background image for conversation
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.65), // Add black overlay with opacity
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];

                    // Display the message directly as plain text with increased size
                    return Text(
                      message,
                      style: TextStyle(
                        fontSize: 18, // Increase font size slightly
                        color: const Color.fromARGB(255, 231, 229, 229), // Default text color
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}