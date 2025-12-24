import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'settings_provider.dart';

// 1. DATA MODEL
class FamilyMember {
  final String name;
  final String relation;
  final String phoneNumber;
  final String imagePath;
  final bool isAsset;
  final Color color;

  FamilyMember({
    required this.name,
    required this.relation,
    required this.phoneNumber,
    required this.imagePath,
    this.isAsset = true,
    required this.color,
  });
}

class FamilyPage extends StatefulWidget {
  const FamilyPage({super.key});

  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  // MOCK DATA
  final List<FamilyMember> _family = [
    FamilyMember(
      name: 'Rohan',
      relation: 'Son',
      phoneNumber: '+91 98765 43210',
      imagePath: 'assets/images/son.jpg',
      color: const Color(0xFFE0F2F1),
    ),
    FamilyMember(
      name: 'Priya',
      relation: 'Granddaughter',
      phoneNumber: '+91 91234 56789',
      imagePath: 'assets/images/daughter.jpg',
      color: const Color(0xFFFFF3E0),
    ),
    FamilyMember(
      name: 'Dr. Mehta',
      relation: 'Doctor',
      phoneNumber: '+91 11 2345 6789',
      imagePath: 'assets/images/doctor.jpeg',
      color: const Color(0xFFE3F2FD),
    ),
  ];

  final PageController _pageController = PageController(viewportFraction: 0.85);
  final ImagePicker _picker = ImagePicker();

  // --- DELETE LOGIC ---
  void _deleteMember(int index) {
    setState(() {
      _family.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Memory removed."),
        backgroundColor: Colors.grey[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // --- ADD MEMORY LOGIC ---
  Future<void> _showAddMemberDialog() async {
    final nameController = TextEditingController();
    final relationController = TextEditingController();
    final phoneController = TextEditingController();
    String? pickedImagePath;

    final List<Color> pastelColors = [
      const Color(0xFFF3E5F5),
      const Color(0xFFE8F5E9),
      const Color(0xFFFFF3E0),
      const Color(0xFFE3F2FD),
      const Color(0xFFFCE4EC),
    ];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text("New Memory", style: TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setDialogState(() {
                            pickedImagePath = image.path;
                          });
                        }
                      },
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFFE0F2F1),
                        backgroundImage: pickedImagePath != null
                            ? FileImage(File(pickedImagePath!))
                            : null,
                        child: pickedImagePath == null
                            ? const Icon(Icons.add_a_photo, size: 30, color: Color(0xFF26A69A))
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text("Tap to add photo", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 16),
                    _buildTextField(nameController, "Name", Icons.person_outline),
                    const SizedBox(height: 12),
                    _buildTextField(relationController, "Relation", Icons.favorite_border),
                    const SizedBox(height: 12),
                    _buildTextField(phoneController, "Phone Number", Icons.phone_outlined, isPhone: true),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF26A69A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () {
                    if (nameController.text.isNotEmpty && pickedImagePath != null) {
                      setState(() {
                        _family.add(FamilyMember(
                          name: nameController.text,
                          relation: relationController.text,
                          phoneNumber: phoneController.text,
                          imagePath: pickedImagePath!,
                          isAsset: false,
                          color: pastelColors[Random().nextInt(pastelColors.length)],
                        ));
                      });
                      Navigator.pop(context);
                      Future.delayed(const Duration(milliseconds: 300), () {
                        _pageController.animateToPage(_family.length - 1, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
                      });
                    }
                  },
                  child: const Text("Save Memory"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isPhone = false}) {
    return TextField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF26A69A), size: 20),
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF5F7F6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsProvider.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        title: Text('Loved Ones',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'Raleway',
                fontSize: 22 * settings.fontSizeMultiplier,
                fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2D6A4F), Color(0xFF26A69A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          Text(
            "Tap a card to flip it",
            style: TextStyle(
              fontSize: 16 * settings.fontSizeMultiplier,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ).animate().fadeIn(delay: 500.ms),

          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _family.length + 1,
              itemBuilder: (context, index) {
                if (index == _family.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                    child: AddMemoryCard(
                      onTap: _showAddMemberDialog,
                      fontSizeMultiplier: settings.fontSizeMultiplier,
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  child: FlipCard(
                    member: _family[index],
                    fontSizeMultiplier: settings.fontSizeMultiplier,
                    onDelete: () => _deleteMember(index),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}

// 3. ADD MEMORY CARD
class AddMemoryCard extends StatelessWidget {
  final VoidCallback onTap;
  final double fontSizeMultiplier;

  const AddMemoryCard({
    super.key,
    required this.onTap,
    required this.fontSizeMultiplier,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8F7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF26A69A).withOpacity(0.5),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFF26A69A).withOpacity(0.2), blurRadius: 15, spreadRadius: 5)
                ],
              ),
              child: const Icon(Icons.add_a_photo_rounded, size: 50, color: Color(0xFF26A69A)),
            ),
            const SizedBox(height: 24),
            Text(
              "Add New Memory",
              style: TextStyle(
                fontSize: 22 * fontSizeMultiplier,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF004D40),
                fontFamily: 'Raleway',
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                "Keep your loved ones close.\nTap here to add a photo.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16 * fontSizeMultiplier, color: Colors.grey[600], height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 4. FLIP CARD
class FlipCard extends StatefulWidget {
  final FamilyMember member;
  final double fontSizeMultiplier;
  final VoidCallback onDelete;

  const FlipCard({
    super.key,
    required this.member,
    required this.fontSizeMultiplier,
    required this.onDelete,
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );
  }

  void _flipCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() => _isFront = !_isFront);
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final String cleanNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Memory?", style: TextStyle(color: Colors.redAccent)),
        content: Text("Are you sure you want to remove ${widget.member.name} from your loved ones?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Keep", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete();
            },
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final isBack = angle > (pi / 2);

          return Transform(
            transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(angle),
            alignment: Alignment.center,
            child: isBack
                ? Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateY(pi),
              child: _buildBack(),
            )
                : _buildFront(),
          );
        },
      ),
    );
  }

  ImageProvider _getImageProvider() {
    if (widget.member.isAsset) {
      return AssetImage(widget.member.imagePath);
    } else {
      return FileImage(File(widget.member.imagePath));
    }
  }

  Widget _buildFront() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: AspectRatio(
              aspectRatio: 1 / 1,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.member.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const Center(child: Icon(Icons.person, size: 80, color: Colors.white54)),
                      Image(
                        image: _getImageProvider(),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.member.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26 * widget.fontSizeMultiplier,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF004D40),
                        fontFamily: 'Raleway',
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.member.color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.member.relation,
                        style: TextStyle(
                          fontSize: 14 * widget.fontSizeMultiplier,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Icon(Icons.touch_app_outlined, size: 20, color: Colors.grey[300]),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // --- FIXED BACK WIDGET ---
  Widget _buildBack() {
    return Container(
      decoration: BoxDecoration(
        color: widget.member.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white, width: 12),
      ),
      // STACKFIT.EXPAND ensures the stack fills the Container, preventing shrinkage
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. MAIN CONTENT
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.favorite, color: Colors.pink[300], size: 45),
                ),
                const SizedBox(height: 24),
                Text(
                  "Call",
                  style: TextStyle(fontSize: 16 * widget.fontSizeMultiplier, color: Colors.grey[700]),
                ),
                Text(
                  widget.member.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28 * widget.fontSizeMultiplier,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF004D40),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 200,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: () => _makePhoneCall(widget.member.phoneNumber),
                    icon: const Icon(Icons.call, size: 28),
                    label: Text(
                      "CALL",
                      style: TextStyle(fontSize: 20 * widget.fontSizeMultiplier, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF26A69A),
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.member.phoneNumber,
                  style: TextStyle(
                    fontSize: 18 * widget.fontSizeMultiplier,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // 2. DELETE BUTTON (Positioned correctly inside the frame)
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              onPressed: _confirmDelete,
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}