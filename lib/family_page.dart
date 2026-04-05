import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- DATA MODEL ---
class FamilyMember {
  final String id;
  final String name;
  final String relation;
  final String phoneNumber;
  final String imagePath;
  final String memoryPrompt;
  final bool isAsset;

  FamilyMember({
    required this.id,
    required this.name,
    required this.relation,
    required this.phoneNumber,
    required this.imagePath,
    this.memoryPrompt = "",
    this.isAsset = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'relation': relation,
    'phoneNumber': phoneNumber,
    'imagePath': imagePath,
    'memoryPrompt': memoryPrompt,
    'isAsset': isAsset,
  };

  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
    id: json['id'] ?? DateTime.now().toString(),
    name: json['name'],
    relation: json['relation'],
    phoneNumber: json['phoneNumber'],
    imagePath: json['imagePath'],
    memoryPrompt: json['memoryPrompt'] ?? "",
    isAsset: json['isAsset'] ?? false,
  );
}

class FamilyPage extends StatefulWidget {
  const FamilyPage({super.key});
  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  static const Color navyText = Color(0xFF0F172A);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color softBackground = Color(0xFFF8FAFC);

  List<FamilyMember> _family = [];
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadFamily();
  }

  Future<void> _loadFamily() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('saved_family');
    if (data != null) {
      final List<dynamic> jsonData = jsonDecode(data);
      setState(() {
        _family = jsonData.map((item) => FamilyMember.fromJson(item)).toList();
        _isLoading = false;
      });
    } else {
      _family = [
        FamilyMember(
          id: '1',
          name: 'Rohan',
          relation: 'Son',
          phoneNumber: '+91 98765 43210',
          imagePath: '',
          memoryPrompt: "Rohan is your son. He lives in Mumbai and calls you every Sunday morning.",
        ),
      ];
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveFamily() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(_family.map((f) => f.toJson()).toList());
    await prefs.setString('saved_family', encodedData);
  }

  void _deleteMember(String id) {
    setState(() {
      _family.removeWhere((m) => m.id == id);
    });
    _saveFamily();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBackground,
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: navyText, size: 28),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Loved Ones", style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.w800, color: navyText, fontSize: 26)),
            Text("People who care about you", style: GoogleFonts.atkinsonHyperlegible(color: accentBlue, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMemberDialog(), // No member passed = Add mode
        backgroundColor: navyText,
        icon: const Icon(Icons.add_reaction_rounded, color: Colors.white, size: 30),
        label: Text("Add Someone", style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        itemCount: _family.length,
        itemBuilder: (context, index) => _buildFamilyCard(_family[index]),
      ),
    );
  }

  Widget _buildFamilyCard(FamilyMember member) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FamilyDetailScreen(
            member: member,
            onDelete: () => _deleteMember(member.id),
            onEdit: () => _showMemberDialog(member: member),
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Hero(
                tag: 'img-${member.id}',
                child: Container(
                  height: 80, width: 80,
                  decoration: BoxDecoration(
                    color: accentBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                    image: member.imagePath.isNotEmpty
                        ? DecorationImage(
                        image: member.isAsset ? AssetImage(member.imagePath) as ImageProvider : FileImage(File(member.imagePath)),
                        fit: BoxFit.cover)
                        : null,
                  ),
                  child: member.imagePath.isEmpty ? const Icon(Icons.person_rounded, size: 40, color: accentBlue) : null,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.name, style: GoogleFonts.atkinsonHyperlegible(fontSize: 24, fontWeight: FontWeight.bold, color: navyText)),
                    Text(member.relation, style: GoogleFonts.atkinsonHyperlegible(fontSize: 18, color: accentBlue, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  // --- COMBINED ADD/EDIT DIALOG ---
  void _showMemberDialog({FamilyMember? member}) {
    final isEdit = member != null;
    final nameCtrl = TextEditingController(text: isEdit ? member.name : "");
    final relationCtrl = TextEditingController(text: isEdit ? member.relation : "");
    final phoneCtrl = TextEditingController(text: isEdit ? member.phoneNumber : "");
    final promptCtrl = TextEditingController(text: isEdit ? member.memoryPrompt : "");
    String? pickedPath = isEdit ? (member.isAsset ? null : member.imagePath) : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          title: Text(isEdit ? "Edit Memory" : "Add a Loved One",
              style: GoogleFonts.atkinsonHyperlegible(fontWeight: FontWeight.w900, color: navyText)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                    if (image != null) setDialogState(() => pickedPath = image.path);
                  },
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: accentBlue.withOpacity(0.1),
                    backgroundImage: pickedPath != null
                        ? FileImage(File(pickedPath!))
                        : (isEdit && member.isAsset && member.imagePath.isNotEmpty ? AssetImage(member.imagePath) as ImageProvider : null),
                    child: (pickedPath == null && (!isEdit || member.imagePath.isEmpty))
                        ? const Icon(Icons.camera_alt_rounded, size: 30, color: accentBlue)
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                _dialogField(nameCtrl, "Name", Icons.person_rounded),
                const SizedBox(height: 12),
                _dialogField(relationCtrl, "Relation", Icons.favorite_rounded),
                const SizedBox(height: 12),
                _dialogField(phoneCtrl, "Phone Number", Icons.phone_rounded, isPhone: true),
                const SizedBox(height: 12),
                _dialogField(promptCtrl, "Memory Helper (Who is this?)", Icons.note_rounded, maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: navyText, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                if (nameCtrl.text.isEmpty) return;

                final newMember = FamilyMember(
                  id: isEdit ? member.id : DateTime.now().toString(),
                  name: nameCtrl.text,
                  relation: relationCtrl.text,
                  phoneNumber: phoneCtrl.text,
                  memoryPrompt: promptCtrl.text,
                  imagePath: pickedPath ?? (isEdit ? member.imagePath : ''),
                  isAsset: pickedPath == null && isEdit ? member.isAsset : false,
                );

                setState(() {
                  if (isEdit) {
                    int idx = _family.indexWhere((m) => m.id == member.id);
                    _family[idx] = newMember;
                  } else {
                    _family.add(newMember);
                  }
                });
                _saveFamily();
                Navigator.pop(context);
                if (isEdit) Navigator.pop(context); // Close the detail screen too to refresh data
              },
              child: Text(isEdit ? "Update" : "Save", style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String hint, IconData icon, {bool isPhone = false, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: accentBlue),
        hintText: hint,
        filled: true,
        fillColor: softBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}

// --- FULL SCREEN DETAIL PAGE ---
class FamilyDetailScreen extends StatelessWidget {
  final FamilyMember member;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const FamilyDetailScreen({
    super.key,
    required this.member,
    required this.onDelete,
    required this.onEdit
  });

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Remove this memory?"),
        content: Text("Are you sure you want to remove ${member.name} from your list?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Keep")),
          TextButton(
              onPressed: () {
                onDelete();
                Navigator.pop(context); // Close Dialog
                Navigator.pop(context); // Back to List
              },
              child: const Text("Remove", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Hero(
              tag: 'img-${member.id}',
              child: member.imagePath.isNotEmpty
                  ? Image(
                image: member.isAsset ? AssetImage(member.imagePath) as ImageProvider : FileImage(File(member.imagePath)),
                fit: BoxFit.cover,
              )
                  : Container(color: const Color(0xFFF1F5F9), child: const Icon(Icons.person_rounded, size: 200, color: Color(0xFFCBD5E1))),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.4), Colors.transparent, Colors.black.withOpacity(0.9)],
                ),
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black), onPressed: () => Navigator.pop(context)),
                ),
                // --- MANAGE BUTTON ---
                PopupMenuButton<String>(
                  icon: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.more_vert, color: Colors.black)),
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'delete') _confirmDelete(context);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 10), Text("Edit")])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 10), Text("Remove", style: TextStyle(color: Colors.red))])),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.name, style: GoogleFonts.atkinsonHyperlegible(fontSize: 45, fontWeight: FontWeight.w900, color: Colors.white)),
                  Text(member.relation, style: GoogleFonts.atkinsonHyperlegible(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF3B82F6))),
                  const SizedBox(height: 20),
                  if (member.memoryPrompt.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb_outline_rounded, color: Colors.yellow, size: 30),
                          const SizedBox(width: 15),
                          Expanded(child: Text(member.memoryPrompt, style: GoogleFonts.atkinsonHyperlegible(fontSize: 18, color: Colors.white, height: 1.4))),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(child: _detailActionBtn(label: "Call", icon: Icons.call_rounded, color: const Color(0xFF3B82F6), onTap: () => _makeCall(member.phoneNumber))),
                      const SizedBox(width: 15),
                      Expanded(child: _detailActionBtn(label: "Message", icon: Icons.chat_bubble_rounded, color: const Color(0xFF10B981), onTap: () => _openWhatsApp(member.phoneNumber))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makeCall(String number) async {
    final Uri url = Uri(scheme: 'tel', path: number.replaceAll(' ', ''));
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Future<void> _openWhatsApp(String number) async {
    final cleanNum = number.replaceAll(RegExp(r'[^\d]'), '');
    final url = Uri.parse("https://wa.me/$cleanNum");
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Widget _detailActionBtn({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10)]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 10),
            Text(label, style: GoogleFonts.atkinsonHyperlegible(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
          ],
        ),
      ),
    );
  }
}