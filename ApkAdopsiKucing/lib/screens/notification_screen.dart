import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:pawfinder/screens/detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final catsSnapshot =
        await FirebaseFirestore.instance
            .collection('cats')
            .where('uid', isEqualTo: userId)
            .get();

    List<Map<String, dynamic>> tempNotifications = [];

    for (final catDoc in catsSnapshot.docs) {
      final allCommentsSnapshot =
          await FirebaseFirestore.instance
              .collection('cats')
              .doc(catDoc.id)
              .collection('comments')
              .orderBy('timestamp', descending: true)
              .get();

      for (final comment in allCommentsSnapshot.docs) {
        final data = comment.data();
        if (!data.containsKey('parentId') || data['parentId'] == null) {
          tempNotifications.add({
            'catDoc': catDoc,
            'comment': data,
            'timestamp': (data['timestamp'] as Timestamp?)?.toDate(),
          });
        }
      }
    }

    tempNotifications.sort(
      (a, b) => b['timestamp']?.compareTo(a['timestamp']) ?? 0,
    );

    setState(() {
      notifications = tempNotifications;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Notifikasi", style: TextStyle(color: Color(0xFF6FCF97))),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body:
          notifications.isEmpty
              ? Center(child: Text("Belum ada komentar masuk."))
              : ListView.builder(
                itemCount: notifications.length,
                padding: EdgeInsets.all(12),
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  final catDoc = notif['catDoc'];
                  final comment = notif['comment'];
                  final time = notif['timestamp'];
                  final username = comment['username'] ?? 'User';
                  final text = comment['text'] ?? '';

                  return ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailScreen(document: catDoc),
                        ),
                      );
                    },
                    leading: Icon(Icons.comment, color: Color(0xFF6FCF97)),
                    title: Text('$username mengomentari postingan kamu'),
                    subtitle: Text(
                      text.length > 50 ? '${text.substring(0, 50)}...' : text,
                    ),
                    trailing: Text(
                      time != null ? timeago.format(time) : '',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  );
                },
              ),
    );
  }
}
