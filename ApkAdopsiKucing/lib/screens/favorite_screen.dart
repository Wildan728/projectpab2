import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'detail_screen.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  String searchQuery = '';
  List<DocumentSnapshot> favoriteCats = [];

  @override
  void initState() {
    super.initState();
    fetchFavorites();
  }

  Future<void> fetchFavorites() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final snapshot =
        await FirebaseFirestore.instance
            .collection('cats')
            .where('likedBy', arrayContains: userId)
            .get();

    setState(() {
      favoriteCats = snapshot.docs;
    });
  }

  Future<void> toggleFavorite(DocumentSnapshot cat) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final docRef = FirebaseFirestore.instance.collection('cats').doc(cat.id);
    final data = cat.data() as Map<String, dynamic>;
    final likedBy = List<String>.from(data['likedBy'] ?? []);
    final newLikedBy = List<String>.from(likedBy)..remove(userId);
    final newLikeCount = (data['likeCount'] ?? 0) - 1;

    await docRef.update({
      'likedBy': newLikedBy,
      'likeCount': newLikeCount < 0 ? 0 : newLikeCount,
    });

    fetchFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCats =
        favoriteCats.where((cat) {
          final data = cat.data() as Map<String, dynamic>;
          final name = data['name']?.toString().toLowerCase() ?? '';
          return name.contains(searchQuery.toLowerCase());
        }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Kucing Favorit',
          style: TextStyle(
            color: Color(0xFF6FCF97),
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
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
            if (filteredCats.isEmpty)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Belum ada kucing favorit."),
                    SizedBox(height: 16),
                  ],
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: filteredCats.length,
                  itemBuilder: (context, index) {
                    final cat = filteredCats[index];
                    final data = cat.data() as Map<String, dynamic>;
                    final imageBase64 = data['image_base64'] ?? '';
                    final image =
                        imageBase64.isNotEmpty
                            ? Image.memory(
                              base64Decode(imageBase64),
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            )
                            : Icon(Icons.image, size: 70);

                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFA8E6CF), // Hijau muda
                            Color(0xFF27AE60), // Hijau solid
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(10),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: image,
                        ),
                        title: Text(
                          data['name'] ?? '',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "${data['gender'] ?? ''}, ${data['umur'] ?? ''} ${data['satuan_umur'] ?? ''}",
                          style: TextStyle(color: Colors.white70),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.favorite,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => toggleFavorite(cat),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            DetailScreen(document: cat),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
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
