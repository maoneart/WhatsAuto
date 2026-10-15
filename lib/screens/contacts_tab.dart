import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';
import '../widgets/glassmorphism_modal.dart';

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

  void _toggleGroups(bool val) async {
    setState(() {
      widget.settings.enableGroups = val;
    });
    await StorageService.saveSettings(widget.settings);
    widget.onSettingsChanged();
  }

  void _editHeader() async {
    final result = await GlassmorphismModal.showInputModal(
      context: context,
      title: 'Ubah Header Balasan',
      subtitle: 'Teks ini akan diletakkan di baris paling atas setiap pesan balasan.',
      initialValue: widget.settings.replyHeaderText,
      hintText: 'Contoh: *[Balasan Otomatis]*',
      maxLines: 2,
      icon: Icons.title,
    );
    if (result != null) {
      setState(() {
        widget.settings.replyHeaderText = result;
      });
      await StorageService.saveSettings(widget.settings);
      widget.onSettingsChanged();
    }
  }

  void _editFooter() async {
    final result = await GlassmorphismModal.showInputModal(
      context: context,
      title: 'Ubah Footer Balasan',
      subtitle: 'Teks ini akan diletakkan di baris paling bawah setiap pesan balasan.',
      initialValue: widget.settings.replyFooterText,
      hintText: 'Contoh: _Terkirim via MaoneAuto_',
      maxLines: 2,
      icon: Icons.subtitles_outlined,
    );
    if (result != null) {
      setState(() {
        widget.settings.replyFooterText = result;
      });
      await StorageService.saveSettings(widget.settings);
      widget.onSettingsChanged();
    }
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
          'Target & Kontak',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Card: Target Balas Otomatis
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111B21),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.tune, color: Color(0xFF00A884), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Balas Otomatis Ke',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00A884),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A884).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getRecipientSummary(replyTo),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00A884),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _buildSelectionTile(
                    title: 'Semua Orang',
                    subtitle: 'Balas ke setiap pesan masuk tanpa membedakan kontak',
                    icon: Icons.public,
                    value: 'all',
                    groupValue: replyTo,
                  ),
                  const SizedBox(height: 8),
                  _buildSelectionTile(
                    title: 'Daftar Kontak Saya',
                    subtitle: 'Hanya balas nomor yang tersimpan di buku kontak',
                    icon: Icons.contact_phone_outlined,
                    value: 'contacts',
                    groupValue: replyTo,
                  ),
                  const SizedBox(height: 8),
                  _buildSelectionTile(
                    title: 'Kecuali Kontak Saya',
                    subtitle: 'Balas nomor baru dan kecualikan kontak pribadi',
                    icon: Icons.person_off_outlined,
                    value: 'except_contacts',
                    groupValue: replyTo,
                  ),
                  const SizedBox(height: 8),
                  _buildSelectionTile(
                    title: 'Nomor Tak Dikenal Saja',
                    subtitle: 'Hanya balas pesan dari nomor baru yang belum disimpan',
                    icon: Icons.contact_emergency_outlined,
                    value: 'except_phone',
                    groupValue: replyTo,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Card: Pengaturan Grup WhatsApp
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111B21),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: enableGroups
                      ? const Color(0xFF00A884).withOpacity(0.3)
                      : Colors.white.withOpacity(0.08),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: enableGroups
                          ? const Color(0xFF00A884).withOpacity(0.15)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.groups_outlined,
                      color: enableGroups ? const Color(0xFF00A884) : Colors.white38,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aktifkan Grup WhatsApp',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          enableGroups
                              ? 'Bot akan merespons pesan yang masuk di grup'
                              : 'Pesan obrolan grup diabaikan untuk mencegah spam',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.65),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: enableGroups,
                    onChanged: _toggleGroups,
                    activeColor: const Color(0xFF00A884),
                    activeTrackColor: const Color(0xFF00A884).withOpacity(0.4),
                    inactiveThumbColor: Colors.white60,
                    inactiveTrackColor: Colors.white12,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Card: Header & Footer Balasan
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111B21),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.format_quote, color: Color(0xFF00A884), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Header & Footer Balasan',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00A884),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Header Switch & Edit
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gunakan Header',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.settings.replyHeaderText,
                              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18, color: Color(0xFF00A884)),
                        onPressed: _editHeader,
                        tooltip: 'Ubah Header',
                      ),
                      Switch(
                        value: widget.settings.enableReplyHeader,
                        onChanged: (val) async {
                          setState(() => widget.settings.enableReplyHeader = val);
                          await StorageService.saveSettings(widget.settings);
                          widget.onSettingsChanged();
                        },
                        activeColor: const Color(0xFF00A884),
                      ),
                    ],
                  ),
                  Divider(color: Colors.white.withOpacity(0.08)),

                  // Footer Switch & Edit
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gunakan Footer',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.settings.replyFooterText,
                              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18, color: Color(0xFF00A884)),
                        onPressed: _editFooter,
                        tooltip: 'Ubah Footer',
                      ),
                      Switch(
                        value: widget.settings.enableReplyFooter,
                        onChanged: (val) async {
                          setState(() => widget.settings.enableReplyFooter = val);
                          await StorageService.saveSettings(widget.settings);
                          widget.onSettingsChanged();
                        },
                        activeColor: const Color(0xFF00A884),
                      ),
                    ],
                  ),

                  // Live Preview Bubble
                  if (widget.settings.enableReplyHeader || widget.settings.enableReplyFooter) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2C34),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.04)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.settings.enableReplyHeader && widget.settings.replyHeaderText.isNotEmpty) ...[
                            Text(
                              widget.settings.replyHeaderText,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF00A884), fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                          ],
                          const Text(
                            'Halo Kak! Ada yang bisa kami bantu hari ini?',
                            style: TextStyle(fontSize: 13, color: Colors.white),
                          ),
                          if (widget.settings.enableReplyFooter && widget.settings.replyFooterText.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.settings.replyFooterText,
                              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.55)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRecipientSummary(String replyTo) {
    switch (replyTo) {
      case 'all':
        return 'Semua Orang';
      case 'contacts':
        return 'Buku Kontak';
      case 'except_contacts':
        return 'Kecuali Kontak';
      case 'except_phone':
        return 'Nomor Baru';
      default:
        return 'Aktif';
    }
  }

  Widget _buildSelectionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required String groupValue,
  }) {
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => _setReplyTo(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00A884).withOpacity(0.1) : const Color(0xFF0B141B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF00A884).withOpacity(0.4) : Colors.white.withOpacity(0.05),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF00A884).withOpacity(0.2) : Colors.white.withOpacity(0.04),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFF00A884) : Colors.white54,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.white.withOpacity(0.55),
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF00A884) : Colors.white38,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00A884),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
