import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';

class ContactsTab extends StatefulWidget {
  final AppSettings settings;
  final VoidCallback onSettingsChanged;

  const ContactsTab({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  void _setReplyTo(String val) async {
    setState(() {
      widget.settings.replyTo = val;
    });
    await StorageService.saveSettings(widget.settings);
    widget.onSettingsChanged();
  }

  void _toggleGroups(bool? val) async {
    setState(() {
      widget.settings.enableGroups = val ?? false;
    });
    await StorageService.saveSettings(widget.settings);
    widget.onSettingsChanged();
  }

  @override
  Widget build(BuildContext context) {
    final replyTo = widget.settings.replyTo;
    final enableGroups = widget.settings.enableGroups;

    return Scaffold(
      backgroundColor: const Color(0xFF0B141B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111B21),
        elevation: 0,
        title: const Text(
          'MaoneAuto',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white70),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.send_outlined, color: Colors.white70),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card: Balas otomatis ke
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111B21),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Balas otomatis ke',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00A884),
                        ),
                      ),
                      Icon(Icons.info_outline, color: Colors.white.withOpacity(0.4), size: 20),
                    ],
                  ),
                  const SizedBox(height: 8),

                  _buildRadioItem('Semua orang', 'all', replyTo),
                  _buildRadioItem('Daftar kontak saya...', 'contacts', replyTo),
                  _buildRadioItem('Kecuali daftar kontak saya...', 'except_contacts', replyTo),
                  _buildRadioItem('Kecuali kontak telepon saya', 'except_phone', replyTo),

                  const SizedBox(height: 6),
                  Divider(color: Colors.white.withOpacity(0.08)),
                  const SizedBox(height: 6),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: enableGroups,
                            onChanged: _toggleGroups,
                            activeColor: const Color(0xFF00A884),
                            checkColor: Colors.white,
                            side: BorderSide(color: Colors.white.withOpacity(0.4)),
                          ),
                          const Text(
                            'Aktifkan Grup',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white54, size: 20),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card: Daftar Kontak
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF111B21),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A884).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.people, color: Color(0xFF00A884), size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    replyTo == 'all'
                        ? 'Balas otomatis kepada Semua.'
                        : 'Balas otomatis sesuai konfigurasi kontak.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioItem(String title, String value, String groupValue) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => _setReplyTo(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF00A884) : Colors.white.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00A884),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
