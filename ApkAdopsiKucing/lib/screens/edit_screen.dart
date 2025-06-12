import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class EditScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> initialData;

  const EditScreen({super.key, required this.docId, required this.initialData});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController jenisController;
  late TextEditingController warnaController;
  late TextEditingController umurController;
  late TextEditingController deskripsiController;

  LatLng? selectedLocation;
  String? selectedAddress;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialData['name']);
    jenisController = TextEditingController(text: widget.initialData['jenis']);
    warnaController = TextEditingController(text: widget.initialData['warna']);
    umurController = TextEditingController(text: widget.initialData['umur']);
    deskripsiController = TextEditingController(
      text: widget.initialData['deskripsi'] ?? '',
    );
    selectedLocation = LatLng(
      widget.initialData['latitude'] ?? 0.0,
      widget.initialData['longitude'] ?? 0.0,
    );
    selectedAddress = widget.initialData['alamat'] ?? '';
  }

  Future<void> _updateAddress(LatLng pos) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address =
            '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
        setState(() => selectedAddress = address);
      }
    } catch (e) {
      selectedAddress = "Gagal mendapatkan alamat";
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latlng = LatLng(position.latitude, position.longitude);
      setState(() {
        selectedLocation = latlng;
      });
      await _updateAddress(latlng);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mendapatkan lokasi: $e')));
    }
  }

  Future<void> _saveUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseFirestore.instance
          .collection('cats')
          .doc(widget.docId)
          .update({
            'name': nameController.text.trim(),
            'jenis': jenisController.text.trim(),
            'warna': warnaController.text.trim(),
            'umur': umurController.text.trim(),
            'deskripsi': deskripsiController.text.trim(),
            'latitude': selectedLocation?.latitude,
            'longitude': selectedLocation?.longitude,
            'alamat': selectedAddress,
            'updated_at': FieldValue.serverTimestamp(),
          });

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan perubahan')));
    }
  }

  Widget _buildInput(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    bool isOptional = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        validator: (val) {
          if (isOptional) return null;
          return (val == null || val.trim().isEmpty) ? 'Wajib diisi' : null;
        },
      ),
    );
  }

  Widget _buildMap() {
    return SizedBox(
      height: 200,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: selectedLocation!,
          initialZoom: 15,
          onTap: (tapPos, latlng) async {
            setState(() => selectedLocation = latlng);
            await _updateAddress(latlng);
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: selectedLocation!,
                width: 40,
                height: 40,
                child: Icon(Icons.location_on, size: 40, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageBase64 = widget.initialData['image_base64'];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Postingan',
          style: TextStyle(color: Color(0xFF6FCF97)),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (imageBase64 != null && imageBase64.toString().isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    base64Decode(imageBase64),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              SizedBox(height: 16),
              _buildInput("Nama Kucing", nameController),
              _buildInput("Jenis Kucing", jenisController),
              _buildInput("Warna", warnaController),
              _buildInput("Umur", umurController),
              _buildInput(
                "Deskripsi",
                deskripsiController,
                maxLines: 3,
                isOptional: true,
              ),
              SizedBox(height: 16),
              _buildMap(),
              SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: Icon(Icons.my_location, color: Colors.green),
                  label: Text("Ambil Lokasi Saya"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  selectedAddress ?? 'Alamat belum tersedia',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6FCF97),
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                ),
                child: Text(
                  "Simpan Perubahan",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
