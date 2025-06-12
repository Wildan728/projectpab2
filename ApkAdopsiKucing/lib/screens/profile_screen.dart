import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawfinder/screens/history_screen.dart';
import 'package:pawfinder/screens/login_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;
  XFile? _profileImageFile;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    if (user != null) {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .get();
      setState(() {
        userData = userDoc.data() as Map<String, dynamic>?;
      });
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/LoginScreen');
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.photo_camera),
                  title: Text("Ambil Foto"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text("Pilih dari Galeri"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _profileImageFile = pickedFile;
      });

      try {
        final bytes = await File(_profileImageFile!.path).readAsBytes();
        final base64Image = base64Encode(bytes);

        await FirebaseFirestore.instance.collection('users').doc(user!.uid).set(
          {'photo_base64': base64Image},
          SetOptions(merge: true),
        );

        await fetchUserData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Foto profil berhasil disimpan")),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal menyimpan foto")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Profil',
                  style: TextStyle(
                    color: Color(0xFF6FCF97),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body:
          userData == null
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Color(0xFF6FCF97).withOpacity(0.2),
                          backgroundImage:
                              _profileImageFile != null
                                  ? FileImage(File(_profileImageFile!.path))
                                  : (userData!['photo_base64'] != null
                                      ? MemoryImage(
                                        base64Decode(userData!['photo_base64']),
                                      )
                                      : null),
                          child:
                              (_profileImageFile == null &&
                                      userData!['photo_base64'] == null)
                                  ? Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Color(0xFF6FCF97),
                                  )
                                  : null,
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: _showImageSourceDialog,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.camera_alt,
                                color: Color(0xFF6FCF97),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      userData!['name'] ?? 'Nama Pengguna',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '@${userData!['username'] ?? 'username'}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 20),
                    _buildInfoCard(
                      Icons.phone,
                      "No. Telepon",
                      userData!['phone'],
                    ),
                    _buildInfoCard(Icons.email, "Email", user!.email ?? ''),
                    SizedBox(height: 20),
                    _buildActionButton(Icons.history, "Riwayat Posting", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => HistoryScreen()),
                      );
                    }),
                    SizedBox(height: 10),
                    _buildActionButton(
                      Icons.logout,
                      "Logout",
                      _logout,
                      isLogout: true,
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF6FCF97)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onPressed, {
    bool isLogout = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isLogout ? Colors.redAccent : Color(0xFF6FCF97),
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
