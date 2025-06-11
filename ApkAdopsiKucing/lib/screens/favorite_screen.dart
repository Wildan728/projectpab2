import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

import 'package:pawfinder/screens/detail_screen.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  String searchQuery = '';
  List<DocumentSnapshot> favoriteCats = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFavorites();
  }

  Future<void> fetchFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('cats')
        .where('likedBy', arrayContains: user.uid)
        .get();

    setState(() {
      favoriteCats = snapshot.docs;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredCats = favoriteCats.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = data['name']?.toLowerCase() ?? '';
      return name.contains(searchQuery.toLowerCase());
    }).toList();

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
                  'Favorite',
                  style: TextStyle(
                    color: Color(0xFF6FCF97),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.notifications_none,
                    color: Colors.black87,
                    size: 30,
                  ),
                  onPressed: () {
                    // Navigasi ke notifikasi
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Cari kucing...',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
            ),
            SizedBox(height: 16),
            isLoading
                ? CircularProgressIndicator()
                : filteredCats.isEmpty
                ? Text('Tidak ada kucing favorit.')
                : Expanded(
              child: ListView.builder(
                itemCount: filteredCats.length,
                itemBuilder: (context, index) {
                  final data = filteredCats[index].data()
                  as Map<String, dynamic>;

                  final imageBase64 = data['image_base64'] ?? '';
                  final imageWidget = imageBase64.isNotEmpty
                      ? Image.memory(
                    base64Decode(imageBase64),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  )
                      : Icon(Icons.image_not_supported,
                      size: 80, color: Colors.grey);

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imageWidget,
                      ),
                      title: Text(
                        data['name'] ?? 'Tanpa Nama',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        "${data['gender'] ?? ''}, ${data['umur'] ?? ''} ${data['satuan_umur'] ?? ''}",
                      ),
                      onTap: () {
                        // Navigasi ke DetailScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(
                              document: filteredCats[index],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

