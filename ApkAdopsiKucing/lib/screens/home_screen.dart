import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawfinder/screens/detail_screen.dart';
import 'package:pawfinder/screens/notification_screen.dart';
import 'package:pawfinder/screens/posting_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String searchQuery = '';
  int unreadCount = 0;

  Stream<QuerySnapshot> catStream =
      FirebaseFirestore.instance
          .collection('cats')
          .orderBy('created_at', descending: true)
          .snapshots();

  @override
  void initState() {
    super.initState();
    fetchUnreadCount();
  }

  Future<void> fetchUnreadCount() async {
    final count = await getUnreadNotifCount();
    setState(() {
      unreadCount = count;
    });
  }

  Future<DateTime?> getLastReadNotifTime() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    final data = snapshot.data();
    if (data != null && data['lastReadNotif'] != null) {
      return (data['lastReadNotif'] as Timestamp).toDate();
    }

    return null;
  }

  Future<void> updateLastReadNotif() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'lastReadNotif': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<int> getUnreadNotifCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    final lastRead = await getLastReadNotifTime();

    final catsSnapshot =
        await FirebaseFirestore.instance
            .collection('cats')
            .where('uid', isEqualTo: user.uid)
            .get();

    int count = 0;

    for (final catDoc in catsSnapshot.docs) {
      final commentsSnapshot =
          await FirebaseFirestore.instance
              .collection('cats')
              .doc(catDoc.id)
              .collection('comments')
              .orderBy('timestamp', descending: true)
              .get();

      for (final comment in commentsSnapshot.docs) {
        final data = comment.data();
        final ts = (data['timestamp'] as Timestamp?)?.toDate();

        final isMainComment =
            !data.containsKey('parentId') || data['parentId'] == null;

        if (isMainComment &&
            ts != null &&
            (lastRead == null || ts.isAfter(lastRead))) {
          count++;
        }
      }
    }

    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Home',
                  style: TextStyle(
                    color: Color(0xFF6FCF97),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Stack(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.notifications_none,
                        color: Colors.black87,
                        size: 30,
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationScreen(),
                          ),
                        );
                        await updateLastReadNotif();
                        fetchUnreadCount();
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
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
            // 🔍 Search Field
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
            SizedBox(height: 12),

            // 🐱 GridView Cat Cards
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: catStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text("Belum ada kucing yang diposting"),
                    );
                  }

                  final filteredCats =
                      snapshot.data!.docs.where((doc) {
                        final name =
                            (doc['name'] ?? '').toString().toLowerCase();
                        return name.contains(searchQuery.toLowerCase());
                      }).toList();

                  return GridView.builder(
                    itemCount: filteredCats.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.6,
                    ),
                    itemBuilder: (context, index) {
                      final cat = filteredCats[index];
                      final name = cat['name'] ?? '';
                      final jenis = cat['jenis'] ?? '';
                      final fullAddress = cat['alamat'] ?? '';
                      final imageBase64 = cat['image_base64'] ?? '';

                      // Ambil kota dari alamat (elemen ke-2 atau ke-3)
                      final location =
                          fullAddress.split(',').length >= 3
                              ? fullAddress.split(',')[3].trim()
                              : fullAddress;

                      return GestureDetector(
                        onTap: () {
                          // TODO: Navigasi ke detail kucing
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailScreen(document: cat),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.15),
                                blurRadius: 8,
                                offset: Offset(2, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                child:
                                    imageBase64.isNotEmpty
                                        ? AspectRatio(
                                          aspectRatio: 1, // Rasio 1:1
                                          child: Image.memory(
                                            base64Decode(imageBase64),
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                        : Container(
                                          height: 100,
                                          color: Colors.grey[300],
                                          child: Icon(
                                            Icons.image_not_supported,
                                          ),
                                        ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      jenis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 14,
                                          color: Colors.green[600],
                                        ),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            location,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ➕ Floating Action Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF6FCF97),
        onPressed: () {
          // TODO: Navigasi ke form tambah postingan
          //Navigator.pushReplacementNamed(context, '/PostingScreen');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PostingScreen()),
          );
        },
        child: Icon(Icons.pets, size: 28),
        elevation: 6,
      ),
    );
  }
}
