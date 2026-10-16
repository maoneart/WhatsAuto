import 'package:flutter/material.dart';
import '../models/menu_node.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';
import '../services/auto_reply_engine.dart';

class TestReplySimulatorScreen extends StatefulWidget {
  const TestReplySimulatorScreen({super.key});

  @override
  State<TestReplySimulatorScreen> createState() => _TestReplySimulatorScreenState();
}

class _TestReplySimulatorScreenState extends State<TestReplySimulatorScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  AutoReplyEngine? _engine;
  bool _isLoading = true;
  bool _isSimulatingGroup = false;

  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  Future<void> _initEngine() async {
    final projects = await StorageService.loadMenuProjects();
    final projectNodesMap = {for (var p in projects) p.id: p.nodes};
    final activeProject = await StorageService.loadActiveProject();
    final settings = await StorageService.loadSettings();
    final keywordReplies = await StorageService.loadKeywordReplies();
    final sheetConfig = await StorageService.loadSpreadsheetConfig();

    _engine = AutoReplyEngine(
      nodes: activeProject.nodes,
      keywordReplies: keywordReplies,
      sheetItems: sheetConfig.items,
      isSheetEnabled: sheetConfig.isEnabled,
      settings: settings,
      projectNodes: projectNodesMap,
    );

    setState(() {
      _isLoading = false;
    });

    // Kirim sapaan awal bot simulasi
    _simulateInitialGreeting();
  }

  void _simulateInitialGreeting() {
    if (_engine == null) return;
    const greeting = '👋 Halo! Asisten MaoneAuto siap melayani Anda.\n\nKetik *menu* atau kirim kata kunci yang Anda atur untuk membuka Menu Balas interaktif.';
    setState(() {
      _messages.add(_ChatMessage(
        text: greeting,
        isUser: false,
        time: _getCurrentTime(),
      ));
    });
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  void _sendMessage(String text) {
    final clean = text.trim();
    if (clean.isEmpty || _engine == null) return;

    _textController.clear();

    setState(() {
      // Tambah pesan user
      _messages.add(_ChatMessage(
        text: clean,
        isUser: true,
        time: _getCurrentTime(),
      ));
    });

    _scrollToBottom();

    // Simulasi delay pengetikan bot (250ms)
    Future.delayed(const Duration(milliseconds: 250), () async {
      final reply = await _engine!.processMessageAsync(
        senderId: _isSimulatingGroup ? 'Budi Santoso @ Grup Diskusi' : 'Budi Santoso',
        incomingMessage: clean,
        isGroup: _isSimulatingGroup,
      );

      if (!mounted) return;

      setState(() {
        if (reply.trim().isEmpty) {
          _messages.add(_ChatMessage(
            text: '🔇 *(Pesan diabaikan: Tidak cocok dengan kata kunci terdaftar)*',
            isUser: false,
            time: _getCurrentTime(),
          ));
        } else {
          _messages.add(_ChatMessage(
            text: reply,
            isUser: false,
            time: _getCurrentTime(),
          ));
        }
      });

      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getAiStatusSubtitle() {
    if (_engine == null) return 'memuat...';
    final s = _engine!.settings;
    if (!s.aiReplyEnabled) {
      return 'online • AI Nonaktif';
    }
    final activeForMode = _isSimulatingGroup ? s.aiReplyGroup : s.aiReplyPersonal;
    if (!activeForMode) {
      return 'online • AI Off (${_isSimulatingGroup ? "Grup" : "Japri"})';
    }
    final provName = s.aiProvider == 'gemini' ? 'Gemini' : '9Router';
    return 'online • AI Aktif ($provName)';
  }

  bool _isAiActiveForCurrentMode() {
    if (_engine == null) return false;
    final s = _engine!.settings;
    return s.aiReplyEnabled && (_isSimulatingGroup ? s.aiReplyGroup : s.aiReplyPersonal);
  }

  void _resetChat() {
    _engine?.resetSession('Budi Santoso');
    _engine?.resetSession('Budi Santoso @ Grup Diskusi');
    _engine?.resetSession('simulator_user');
    setState(() {
      _messages.clear();
      _isLoading = true;
    });
    _initEngine();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B141B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111B21),
        elevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF00A884),
              child: Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tanggapan Uji (Bot Kaido)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  _getAiStatusSubtitle(),
                  style: TextStyle(
                    fontSize: 12,
                    color: _isAiActiveForCurrentMode() ? const Color(0xFF00A884) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Switch Simulasi Japri / Grup
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              setState(() {
                _isSimulatingGroup = !_isSimulatingGroup;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isSimulatingGroup
                        ? 'Simulasi beralih ke Mode Grup (👥)'
                        : 'Simulasi beralih ke Mode Pribadi / Japri (👤)',
                  ),
                  duration: const Duration(milliseconds: 900),
                  backgroundColor: const Color(0xFF111B21),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _isSimulatingGroup
                    ? const Color(0xFF38BDF8).withOpacity(0.2)
                    : const Color(0xFF10B981).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isSimulatingGroup ? const Color(0xFF38BDF8) : const Color(0xFF10B981),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isSimulatingGroup ? Icons.groups_rounded : Icons.person_rounded,
                    size: 16,
                    color: _isSimulatingGroup ? const Color(0xFF38BDF8) : const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isSimulatingGroup ? 'Grup' : 'Japri',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _isSimulatingGroup ? const Color(0xFF38BDF8) : const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _resetChat,
            tooltip: 'Reset Simulasi',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A884)))
          : Column(
              children: [
                // Quick Action Chips (Shortcut Angka)
                Container(
                  color: const Color(0xFF111B21),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickChip('menu', () => _sendMessage('menu')),
                        const SizedBox(width: 6),
                        _buildQuickChip('1', () => _sendMessage('1')),
                        const SizedBox(width: 6),
                        _buildQuickChip('2', () => _sendMessage('2')),
                        const SizedBox(width: 6),
                        _buildQuickChip('3', () => _sendMessage('3')),
                        const SizedBox(width: 6),
                        _buildQuickChip('0 (Kembali)', () => _sendMessage('0')),
                        const SizedBox(width: 6),
                        _buildQuickChip('keluar', () => _sendMessage('keluar')),
                      ],
                    ),
                  ),
                ),

                // Area Bubble Chat
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(14),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, index) {
                      final msg = _messages[index];
                      return _buildMessageBubble(msg);
                    },
                  ),
                ),

                // Bottom Input Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  color: const Color(0xFF111B21),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F2C34),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextField(
                              controller: _textController,
                              style: const TextStyle(color: Colors.white),
                              onSubmitted: _sendMessage,
                              decoration: InputDecoration(
                                hintText: 'Ketik pesan / nomor menu...',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 23,
                          backgroundColor: const Color(0xFF00A884),
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white, size: 20),
                            onPressed: () => _sendMessage(_textController.text),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuickChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2C34),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Color(0xFF00A884), fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF005D4B) : const Color(0xFF1F2C34),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 2),
            bottomRight: Radius.circular(isUser ? 2 : 14),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                msg.time,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final String time;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
}
