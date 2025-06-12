import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  Stream<QuerySnapshot> get userPostsStream {
    return FirebaseFirestore.instance
        .collection('cats')
        .where('uid', isEqualTo: userId)
        .snapshots(); // TANPA orderBy
  }

  Future<void> deletePost(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('cats').doc(docId).delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Postingan berhasil dihapus')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus postingan')));
    }
  }

  @override
  Widget build(BuildContext context) {
    print("UID Login: $userId");

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Riwayat Posting',
          style: TextStyle(color: Color(0xFF6FCF97)),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: userPostsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print("Firestore error: ${snapshot.error}");
            return Center(child: Text('Terjadi kesalahan saat memuat data'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          print("Jumlah posting ditemukan: ${docs.length}");

          if (docs.isEmpty) {
            return Center(child: Text('Belum ada postingan'));
          }

          return ListView.builder(
            itemCount: docs.length,
            padding: EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;

              return Card(
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Column(
                  children: [
                    if (data['image_base64'] != null &&
                        data['image_base64'].toString().isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.memory(
                          base64Decode(data['image_base64']),
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] ?? '-',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            data['jenis'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.green,
                              ),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  data['alamat'] ?? '-',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  // TODO: Navigasi ke halaman Edit
                                  // Navigator.push(...);
                                },
                                icon: Icon(
                                  Icons.edit,
                                  color: Color(0xFF6FCF97),
                                ),
                                label: Text(
                                  'Edit',
                                  style: TextStyle(color: Color(0xFF6FCF97)),
                                ),
                              ),
                              SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () => deletePost(docId),
                                icon: Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                label: Text(
                                  'Hapus',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
