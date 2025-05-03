import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
                  'Profile',
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
                      onPressed: () {
                        // TODO: Navigasi ke halaman notifikasi
                      },
                    ),
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
                          '3', // jumlah notifikasi (dummy)
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
      // body: Stack(
      //   children: [
      //     SingleChildScrollView(
      //       child: Padding(padding: const EdgeInsets.all(16),
      //       child: Column(
      //         children: [
      //           Container(
      //             decoration: BoxDecoration(
      //               border: Border.all(color: Colors.green, width: 2),
      //               shape: BoxShape.circle,
      //             ),
      //             child: CircleAvatar(
      //               radius: 50,
      //               backgroundImage: _imageFile.isNotEmpty,
      //               ? (kIsWeb
      //               ? NetworkImage(_imageFile)
      //               : FileImage(File(_imageFile))) as ImageProvider
      //               : AssetImage('assets/images/person.png')
      //             ),
      //           ),
      //           const SizedBox(height: 10)
      //           IconButton(
      //             onPressed: onPressed,
      //             icon: Icon(Icons.camera_alt),
      //             color: Colors.green,
      //             iconSize: 30,
      //           ),
      //           const SizedBox(height: 20),
      //             Text(_UserName,
      //               style: TextStyle(
      //                 fontSize: 20,
      //                 fontWeight: FontWeight.bold,
      //               ),
      //             ),
      //             const SizedBox(height: 5)
      //         ],
      //       ),,
      //       ),
      //     ),
      //   ],
      // ),
    );
  }
}
