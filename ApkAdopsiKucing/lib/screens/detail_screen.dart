import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;

class DetailScreen extends StatefulWidget {
  final DocumentSnapshot document;

  const DetailScreen({super.key, required this.document});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final TextEditingController commentController = TextEditingController();
  final Map<String, TextEditingController> replyControllers = {};
  List<Map<String, dynamic>> comments = [];
  bool isLiked = false;
  int likeCount = 0;
  bool showAllComments = false;
  String? replyingTo;
  Map<String, bool> showReplies = {};

  @override
  void initState() {
    super.initState();
    fetchLikeData();
    fetchComments();
  }

  Future<void> fetchLikeData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final snapshot =
        await FirebaseFirestore.instance
            .collection('cats')
            .doc(widget.document.id)
            .get();

    final data = snapshot.data();
    if (data != null) {
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      setState(() {
        isLiked = likedBy.contains(userId);
        likeCount = data['likeCount'] ?? 0;
      });
    }
  }

  Future<void> fetchComments() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('cats')
            .doc(widget.document.id)
            .collection('comments')
            .orderBy('timestamp', descending: false)
            .get();

    setState(() {
      comments =
          snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    });
  }

  void toggleLike() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('cats')
        .doc(widget.document.id);
    final snapshot = await docRef.get();
    final data = snapshot.data();

    List likedBy = data?['likedBy'] ?? [];

    if (isLiked) {
      likedBy.remove(userId);
      likeCount -= 1;
    } else {
      likedBy.add(userId);
      likeCount += 1;
    }

    await docRef.update({'likedBy': likedBy, 'likeCount': likeCount});

    setState(() {
      isLiked = !isLiked;
    });
  }

  Future<void> addComment({String? parentId}) async {
    final controller =
        parentId == null ? commentController : replyControllers[parentId]!;
    final text = controller.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final userData = userDoc.data();
    final username = userData?['username'] ?? 'User';

    await FirebaseFirestore.instance
        .collection('cats')
        .doc(widget.document.id)
        .collection('comments')
        .add({
          'text': text,
          'userId': user.uid,
          'username': username,
          'timestamp': FieldValue.serverTimestamp(),
          'parentId': parentId,
        });

    controller.clear();
    setState(() {
      replyingTo = null;
    });
    fetchComments();
  }

  List<Map<String, dynamic>> getReplies(String parentId) {
    return comments
        .where((c) => c['parentId'] == parentId)
        .toList()
        .cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.document.data() as Map<String, dynamic>;
    final imageBase64 = data['image_base64'] ?? '';
    final image =
        imageBase64.isNotEmpty
            ? Image.memory(base64Decode(imageBase64), fit: BoxFit.cover)
            : Icon(Icons.image_not_supported, size: 100);

    final mainComments = comments.where((c) => c['parentId'] == null).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Detail',
          style: TextStyle(
            color: Color(0xFF6FCF97),
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 250,
                width: double.infinity,
                child: image,
              ),
            ),
            SizedBox(height: 16),
            Text(
              data['name'] ?? '',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(data['jenis'] ?? '', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.pets, color: Colors.grey),
                SizedBox(width: 6),
                Text(
                  "${data['gender'] ?? ''}, ${data['umur'] ?? ''} ${data['satuan_umur'] ?? ''}",
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.color_lens, color: Colors.grey),
                SizedBox(width: 6),
                Text(data['warna'] ?? '', style: TextStyle(fontSize: 14)),
              ],
            ),
            SizedBox(height: 12),
            Text("Deskripsi:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(data['deskripsi'] ?? '-', style: TextStyle(fontSize: 14)),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.green),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    data['alamat'] ?? 'Lokasi tidak tersedia',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: Colors.redAccent,
                  ),
                  onPressed: toggleLike,
                ),
                Text('$likeCount suka'),
              ],
            ),
            SizedBox(height: 16),
            Divider(),
            Text(
              'Komentar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),

            // Komentar utama + balasan
            ...List.generate(
              showAllComments
                  ? mainComments.length
                  : (mainComments.length >= 2 ? 2 : mainComments.length),
              (i) {
                final comment = mainComments[i];
                final time = (comment['timestamp'] as Timestamp?)?.toDate();
                final text = comment['text'] ?? '';
                final username = comment['username'] ?? 'User';
                final id = comment['id'];

                replyControllers.putIfAbsent(id, () => TextEditingController());

                final replies = getReplies(id);
                final isShowingReplies = showReplies[id] ?? false;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          username,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 8),
                        Text(
                          time != null ? timeago.format(time) : 'Baru saja',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(text),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() => replyingTo = id);
                          },
                          child: Text(
                            'Balas',
                            style: TextStyle(color: Colors.blue, fontSize: 12),
                          ),
                        ),
                        if (replies.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                showReplies[id] = !isShowingReplies;
                              });
                            },
                            child: Text(
                              isShowingReplies
                                  ? 'Sembunyikan balasan'
                                  : 'Lihat balasan (${replies.length})',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Balasan-komentar
                    if (isShowingReplies)
                      ...replies.map((reply) {
                        final rtime =
                            (reply['timestamp'] as Timestamp?)?.toDate();
                        return Padding(
                          padding: EdgeInsets.only(left: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    reply['username'] ?? 'User',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    rtime != null
                                        ? timeago.format(rtime)
                                        : 'Baru saja',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(reply['text'] ?? ''),
                              SizedBox(height: 8),
                            ],
                          ),
                        );
                      }),

                    // Input reply
                    if (replyingTo == id)
                      Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: replyControllers[id],
                                decoration: InputDecoration(
                                  hintText: 'Tulis balasan...',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.send,
                                color: Colors.green,
                                size: 24,
                              ),
                              onPressed: () => addComment(parentId: id),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
            if (mainComments.length > 2)
              TextButton(
                onPressed: () {
                  setState(() => showAllComments = !showAllComments);
                },
                child: Text(
                  showAllComments ? 'Tutup komentar' : 'Lihat semua komentar',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: 'Tulis komentar...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.green),
                  onPressed: () => addComment(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
