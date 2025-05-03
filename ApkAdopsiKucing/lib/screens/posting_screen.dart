import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Mobile
import 'package:image_picker_web/image_picker_web.dart'; // Web
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

class PostingScreen extends StatefulWidget {
  @override
  _PostingScreenState createState() => _PostingScreenState();
}

class _PostingScreenState extends State<PostingScreen> {
  dynamic _pickedImage;
  final picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  double _imageHeight = 150;
  double _imageWidth = double.infinity;

  String name = '';
  String jenis = '';
  String gender = '';
  String umur = '';
  String warna = '';
  String deskripsi = '';
  String selectedTimeUnit = 'Tahun'; // Default value untuk unit waktu

  LatLng? selectedLocation;
  LatLng defaultLocation = LatLng(-2.990934, 104.756554); // Palembang

  final List<String> timeUnits = [
    'Hari',
    'Minggu',
    'Bulan',
    'Tahun',
  ]; // Pilihan unit waktu

  Future<void> _requestPermission() async {
    if (kIsWeb) {
      return;
    } else {
      PermissionStatus status = await Permission.storage.request();
      if (!status.isGranted) {
        print("Izin storage tidak diberikan.");
      }
    }
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      final imageBytes = await ImagePickerWeb.getImageAsBytes();
      if (imageBytes != null) {
        setState(() {
          _pickedImage = imageBytes;
        });
      }
    } else {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _pickedImage = File(pickedFile.path);
        });
        print("Image picked: ${pickedFile.path}");
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        selectedLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print("Gagal mendapatkan lokasi: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _requestPermission();
  }

  Widget _buildImageWidget() {
    if (_pickedImage == null) {
      return Center(
        child: Icon(Icons.add_a_photo, size: 50, color: Colors.grey[700]),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child:
            kIsWeb
                ? Image.memory(
                  _pickedImage,
                  fit: BoxFit.contain,
                  width: _imageWidth,
                  height: _imageHeight,
                )
                : Image.file(
                  _pickedImage,
                  fit: BoxFit.contain,
                  width: _imageWidth,
                  height: _imageHeight,
                ),
      );
    }
  }

  // Membuat TextField yang hanya menerima angka atau desimal
  Widget _buildTextField(String label, Function(String) onSaved) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 14),
          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        style: TextStyle(fontSize: 14),
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        validator: (val) {
          if (val == null || val.isEmpty) {
            return 'Wajib diisi';
          }
          if (double.tryParse(val) == null) {
            return 'Harap masukkan angka valid';
          }
          return null;
        },
        onSaved: (val) => onSaved(val!),
      ),
    );
  }

  // Field untuk umur kucing dengan dropdown unit waktu di dalamnya
  Widget _buildAgeField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'Umur',
                labelStyle: TextStyle(fontSize: 14),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              style: TextStyle(fontSize: 14),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Wajib diisi';
                }
                if (double.tryParse(val) == null) {
                  return 'Harap masukkan angka valid';
                }
                return null;
              },
              onSaved: (val) => umur = val!,
            ),
          ),
          SizedBox(width: 8),
          DropdownButton<String>(
            value: selectedTimeUnit,
            onChanged: (String? newValue) {
              setState(() {
                selectedTimeUnit = newValue!;
              });
            },
            items:
                timeUnits.map((String timeUnit) {
                  return DropdownMenuItem<String>(
                    value: timeUnit,
                    child: Text(timeUnit),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  // Dropdown untuk memilih unit waktu (Hari, Minggu, Bulan, Tahun)
  Widget _buildTimeUnitDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: selectedTimeUnit,
        decoration: InputDecoration(
          labelText: 'Unit Waktu',
          labelStyle: TextStyle(fontSize: 14),
          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onChanged: (String? newValue) {
          setState(() {
            selectedTimeUnit = newValue!;
          });
        },
        items:
            timeUnits.map((String timeUnit) {
              return DropdownMenuItem<String>(
                value: timeUnit,
                child: Text(timeUnit),
              );
            }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LatLng mapCenter = selectedLocation ?? defaultLocation;

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
                  'Posting',
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
                    // TODO: Navigasi ke halaman notifikasi
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: _imageHeight,
                  width: _imageWidth,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildImageWidget(),
                ),
              ),
              SizedBox(height: 16),
              _buildTextField('Nama Kucing', (val) => name = val),
              _buildTextField('Jenis Kucing', (val) => jenis = val),
              _buildTextField('Jenis Kelamin', (val) => gender = val),
              _buildAgeField(), // Menggunakan field umur dengan dropdown unit waktu di dalamnya
              _buildTextField('Warna', (val) => warna = val),
              _buildTextField('Deskripsi (Opsional)', (val) => deskripsi = val),
              SizedBox(height: 16),
              SizedBox(height: 16),
              Text(
                'Pilih Lokasi Adopsi di Map: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              SizedBox(
                height: 250,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: mapCenter,
                    initialZoom: 15,
                    onTap: (tapPos, latlng) {
                      setState(() {
                        selectedLocation = latlng;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c'],
                    ),
                    if (selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: selectedLocation!,
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.location_on,
                              size: 40,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              if (selectedLocation != null)
                Text(
                  'Lokasi dipilih: (${selectedLocation!.latitude.toStringAsFixed(4)}, ${selectedLocation!.longitude.toStringAsFixed(4)})',
                  style: TextStyle(color: Colors.black87),
                ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() &&
                      selectedLocation != null) {
                    _formKey.currentState!.save();
                    // TODO: Kirim data ke Firebase
                    print("Data siap disimpan:");
                    print("Nama: $name");
                    print("Jenis: $jenis");
                    print("Gender: $gender");
                    print("Umur: $umur");
                    print("Warna: $warna");
                    print("Deskripsi: $deskripsi");
                    print(
                      "Lokasi: ${selectedLocation!.latitude}, ${selectedLocation!.longitude}",
                    );
                  }
                },
                child: Text('Simpan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6FCF97),
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
