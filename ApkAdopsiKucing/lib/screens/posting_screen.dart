import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pawfinder/services/cat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;

class PostingScreen extends StatefulWidget {
  @override
  _PostingScreenState createState() => _PostingScreenState();
}

class _PostingScreenState extends State<PostingScreen> {
  dynamic _pickedImage;
  final picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  XFile? _imageFile;

  double _imageHeight = 150;
  double _imageWidth = double.infinity;

  String name = '';
  String jenis = '';
  String gender = '';
  String umur = '';
  String warna = '';
  String deskripsi = '';
  // String userId = '';
  String selectedTimeUnit = 'Tahun';

  LatLng? selectedLocation;
  LatLng defaultLocation = LatLng(-2.990934, 104.756554);
  String? selectedAddress;

  final List<String> timeUnits = ['Hari', 'Minggu', 'Bulan', 'Tahun'];
  final List<String> genderOptions = ['Jantan', 'Betina'];

  String? selectedJenisKucingDropdownValue;
  TextEditingController _otherJenisKucingController = TextEditingController();
  bool _showOtherJenisKucingField = false;
  final List<String> jenisKucingOptions = [
    'Domestik/Kampung',
    'Persia',
    'Maine Coon',
    'Siam',
    'Anggora',
    'Sphynx',
    'Bengal',
    'Ragdoll',
    'British Shorthair',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _checkLocationPermissionAndGetLocation();
  }

  @override
  void dispose() {
    _otherJenisKucingController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        selectedLocation = LatLng(position.latitude, position.longitude);
        selectedAddress = null;
      });
      await _updateAddress(selectedLocation!);
    } catch (e) {
      print("Gagal mendapatkan lokasi: $e");
    }
  }

  Future<void> _checkLocationPermissionAndGetLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Izin lokasi ditolak');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      print('Izin lokasi ditolak permanen');
      return;
    }
    _getCurrentLocation();
  }

  Future<void> _updateAddress(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address =
            '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
        setState(() {
          selectedAddress = address;
        });
      } else {
        setState(() {
          selectedAddress = 'Alamat tidak ditemukan';
        });
      }
    } catch (e) {
      print("Error reverse geocoding: $e");
      setState(() {
        selectedAddress = 'Gagal mendapatkan alamat';
      });
    }
  }

  // Kompres dan encode gambar ke base64
  Future<String?> compressAndEncodeImage(
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

    // Pastikan ukuran di bawah 900KB (batas aman Firestore)
    if (jpg.length > 900 * 1024) {
      return null;
    }

    return base64Encode(jpg);
  }

  Future<void> saveCatData() async {
    String? imageBase64 = await compressAndEncodeImage(_imageFile);

    if (_imageFile != null && imageBase64 == null) {
      // Gambar terlalu besar walau sudah dikompres
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ukuran gambar terlalu besar!')));
      return;
    }
    final userId = FirebaseAuth.instance.currentUser?.uid;
    await FirebaseFirestore.instance.collection('cats').add({
      'name': name,
      'jenis': jenis,
      'gender': gender,
      'umur': umur,
      'satuan_umur': selectedTimeUnit,
      'warna': warna,
      'deskripsi': deskripsi,
      'latitude': selectedLocation?.latitude,
      'longitude': selectedLocation?.longitude,
      'alamat': selectedAddress,
      'image_base64': imageBase64,
      'uid': userId,
      'created_at': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Data berhasil disimpan!')));
    Navigator.pop(context);
  }

  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _pickedImage = null;
      _imageFile = null;
      name = '';
      jenis = '';
      gender = '';
      umur = '';
      warna = '';
      deskripsi = '';
      selectedTimeUnit = 'Tahun';
      selectedJenisKucingDropdownValue = null;
      _otherJenisKucingController.clear();
      _showOtherJenisKucingField = false;
      // Jika ingin reset lokasi dan alamat juga, uncomment:
      // selectedLocation = null;
      // selectedAddress = null;
    });
  }

  Widget _buildImageWidget() {
    if (_pickedImage == null) {
      return Center(
        child: Icon(Icons.add_a_photo, size: 50, color: Colors.grey[700]),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _pickedImage,
          fit: BoxFit.contain,
          width: _imageWidth,
          height: _imageHeight,
        ),
      );
    }
  }

  Widget _buildTextField(
    String label,
    Function(String) onSaved, {
    String? initialValue,
    String? Function(String?)? customValidator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 14),
          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        style: TextStyle(fontSize: 14),
        validator:
            customValidator ??
            (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Wajib diisi';
              }
              if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(val.trim())) {
                return 'Hanya boleh huruf dan spasi';
              }
              return null;
            },
        onSaved: (val) => onSaved(val!.trim()),
      ),
    );
  }

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

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Jenis Kelamin',
          labelStyle: TextStyle(fontSize: 14),
          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        value: gender.isNotEmpty ? gender : null,
        items:
            genderOptions.map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
        onChanged: (newValue) {
          setState(() {
            gender = newValue ?? '';
          });
        },
        validator: (val) {
          if (val == null || val.isEmpty) {
            return 'Wajib memilih jenis kelamin';
          }
          return null;
        },
        onSaved: (val) => gender = val ?? '',
      ),
    );
  }

  Widget _buildJenisKucingDropdown() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Jenis Kucing',
              labelStyle: TextStyle(fontSize: 14),
              contentPadding: EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            value: selectedJenisKucingDropdownValue,
            items:
                jenisKucingOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
            onChanged: (newValue) {
              setState(() {
                selectedJenisKucingDropdownValue = newValue;
                _showOtherJenisKucingField = (newValue == 'Lainnya');
                if (!_showOtherJenisKucingField) {
                  _otherJenisKucingController.clear();
                }
              });
            },
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Wajib memilih jenis kucing';
              }
              return null;
            },
            onSaved: (val) {
              if (val == 'Lainnya') {
                jenis = _otherJenisKucingController.text.trim();
              } else {
                jenis = val ?? '';
              }
            },
          ),
        ),
        if (_showOtherJenisKucingField)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextFormField(
              controller: _otherJenisKucingController,
              decoration: InputDecoration(
                labelText: 'Jenis Kucing Lainnya',
                hintText: 'Misal: Russian Blue, Bengal',
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
              validator: (val) {
                if (_showOtherJenisKucingField &&
                    (val == null || val.trim().isEmpty)) {
                  return 'Wajib diisi jika memilih "Lainnya"';
                }
                if (_showOtherJenisKucingField &&
                    !RegExp(r'^[a-zA-Z\s]+$').hasMatch(val!.trim())) {
                  return 'Hanya boleh huruf dan spasi';
                }
                return null;
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFlutterMap() {
    final LatLng mapCenter = selectedLocation ?? defaultLocation;
    return SizedBox(
      height: 200,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: mapCenter,
          initialZoom: 15,
          onTap: (tapPos, latlng) async {
            setState(() {
              selectedLocation = latlng;
              selectedAddress = null;
            });
            await _updateAddress(latlng);
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          if (selectedLocation != null)
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
                  onPressed: () {},
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
              _buildJenisKucingDropdown(),
              _buildGenderDropdown(),
              _buildAgeField(),
              _buildTextField('Warna', (val) => warna = val),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Deskripsi (Opsional)',
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
                  maxLines: 3,
                  onSaved: (val) => deskripsi = val?.trim() ?? '',
                ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Pilih Lokasi Adopsi di Map: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: Icon(Icons.my_location, color: Colors.green),
                    label: Text("Ambil Lokasi Saya"),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      backgroundColor: Colors.white, // warna tombol
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              // Map dan lokasi
              _buildFlutterMap(),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        selectedAddress ?? 'Alamat belum tersedia',
                        style: TextStyle(fontSize: 13),
                      ),
                      subtitle:
                          selectedLocation != null
                              ? Text(
                                'Lat: ${selectedLocation!.latitude.toStringAsFixed(5)}, Lng: ${selectedLocation!.longitude.toStringAsFixed(5)}',
                                style: TextStyle(fontSize: 11),
                              )
                              : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_imageFile == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Harap pilih gambar terlebih dahulu'),
                        ),
                      );
                      return; // Hentikan proses jika gambar belum dipilih
                    }
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      try {
                        final userId = FirebaseAuth.instance.currentUser?.uid;
                        await CatService.saveCatData(
                          name: name,
                          jenis: jenis,
                          gender: gender,
                          umur: umur,
                          satuanUmur: selectedTimeUnit,
                          warna: warna,
                          deskripsi: deskripsi,
                          latitude: selectedLocation?.latitude,
                          longitude: selectedLocation?.longitude,
                          alamat: selectedAddress,
                          imageFile: _imageFile,
                          userId: userId,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Berhasil posting!')),
                          );
                          _resetForm(); // reset semua field
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal posting: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6FCF97),
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Posting',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
