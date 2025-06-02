import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class CatService {
  // Kompres dan encode gambar ke base64
  static Future<String?> compressAndEncodeImage(
    XFile? imageFile, {
    int maxWidth = 400,
    int quality = 70,
  }) async {
    if (imageFile == null) return null;
    final bytes = await File(imageFile.path).readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return null;

    img.Image resized = img.copyResize(image, width: maxWidth);
    List<int> jpg = img.encodeJpg(resized, quality: quality);

    if (jpg.length > 900 * 1024) return null;
    return base64Encode(jpg);
  }

  // Simpan data kucing ke Firestore
  static Future<void> saveCatData({
    required String name,
    required String jenis,
    required String gender,
    required String umur,
    required String satuanUmur,
    required String warna,
    required String deskripsi,
    required double? latitude,
    required double? longitude,
    required String? alamat,
    required XFile? imageFile,
    required String? userId,
  }) async {
    String? imageBase64 = await compressAndEncodeImage(imageFile);

    if (imageFile != null && imageBase64 == null) {
      throw Exception('Ukuran gambar terlalu besar!');
    }

    await FirebaseFirestore.instance.collection('cats').add({
      'name': name,
      'jenis': jenis,
      'gender': gender,
      'umur': umur,
      'satuan_umur': satuanUmur,
      'warna': warna,
      'deskripsi': deskripsi,
      'latitude': latitude,
      'longitude': longitude,
      'alamat': alamat,
      'image_base64': imageBase64,
      'uid': userId,
      'created_at': FieldValue.serverTimestamp(),
    });
  }
}
