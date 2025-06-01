import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart'; // Untuk mengambil gambar dari galeri
import 'package:geolocator/geolocator.dart'; // Untuk mengambil lokasi pengguna
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

class PostingScreen extends StatefulWidget {
  @override
  _PostingScreenState createState() => _PostingScreenState();
}

class _PostingScreenState extends State<PostingScreen> {
  // Variabel untuk menyimpan gambar yang dipilih
  dynamic _pickedImage;
  // Instance ImagePicker untuk mengambil gambar
  final picker = ImagePicker();
  // Key untuk form validasi
  final _formKey = GlobalKey<FormState>();
  // Variabel untuk menyimpan file gambar
  XFile? _imageFile;

  // Ukuran tampilan gambar
  double _imageHeight = 150;
  double _imageWidth = double.infinity;

  // Variabel data kucing
  String name = '';
  String jenis = ''; // Menyimpan jenis kucing yang dipilih/diinput
  String gender = '';
  String umur = '';
  String warna = '';
  String deskripsi = '';
  String selectedTimeUnit = 'Tahun';

  // Variabel lokasi
  LatLng? selectedLocation;
  LatLng defaultLocation = LatLng(
    -2.990934,
    104.756554,
  ); // Lokasi default: Palembang
  String? selectedAddress;

  // List pilihan satuan umur dan gender
  final List<String> timeUnits = ['Hari', 'Minggu', 'Bulan', 'Tahun'];
  final List<String> genderOptions = ['Jantan', 'Betina'];

  // Variabel dan list untuk dropdown jenis kucing
  String? selectedJenisKucingDropdownValue; // Menyimpan nilai dropdown
  TextEditingController _otherJenisKucingController =
      TextEditingController(); // Controller untuk input "Lainnya"
  bool _showOtherJenisKucingField =
      false; // Menampilkan input jika pilih "Lainnya"
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
    'Lainnya', // Jika ini dipilih, muncul field manual
  ];

  @override
  void initState() {
    super.initState();
    // Saat inisialisasi, cek izin lokasi dan ambil lokasi pengguna
    _checkLocationPermissionAndGetLocation();
  }

  @override
  void dispose() {
    // Penting: dispose controller untuk menghindari memory leak
    _otherJenisKucingController.dispose();
    super.dispose();
  }

  // Fungsi untuk mengambil gambar dari galeri
  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  // Fungsi untuk mengambil lokasi saat ini
  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        selectedLocation = LatLng(position.latitude, position.longitude);
        selectedAddress = null; // Reset alamat saat lokasi baru diambil
      });
      await _updateAddress(
        selectedLocation!,
      ); // Update alamat berdasarkan lokasi
    } catch (e) {
      print("Gagal mendapatkan lokasi: $e");
    }
  }

  // Fungsi untuk cek izin lokasi, jika sudah dapat izin langsung ambil lokasi
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

  // Fungsi reverse geocoding: mengubah latlng jadi alamat
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

  // Widget untuk menampilkan gambar yang dipilih
  Widget _buildImageWidget() {
    if (_pickedImage == null) {
      // Jika belum ada gambar, tampilkan icon
      return Center(
        child: Icon(Icons.add_a_photo, size: 50, color: Colors.grey[700]),
      );
    } else {
      // Jika sudah ada gambar, tampilkan gambar
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

  // Widget input teks umum dengan validasi default huruf dan spasi
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

  // Widget input umur (angka) + dropdown satuan umur
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
          // Dropdown satuan umur
          DropdownButton<String>(
            value: selectedTimeUnit,
            onChanged: (String? newValue) {
              setState(() {
                selectedTimeUnit = newValue!;
              });
            },
            items:
                timeUnits
                    .map(
                      (String timeUnit) => DropdownMenuItem<String>(
                        value: timeUnit,
                        child: Text(timeUnit),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  // Widget dropdown jenis kelamin
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
            genderOptions
                .map(
                  (String value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  ),
                )
                .toList(),
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

  // Widget dropdown jenis kucing + field manual jika pilih "Lainnya"
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
                // Jika pilih "Lainnya", tampilkan field manual
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
              // Jika pilih "Lainnya", simpan dari field manual
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
              onSaved: (val) {
                // Tidak perlu onSaved di sini, karena sudah diambil di onSaved dropdown
              },
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Menentukan posisi tengah peta (jika ada fitur peta)
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
              // Widget untuk memilih dan menampilkan gambar
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
              // Input nama kucing
              _buildTextField('Nama Kucing', (val) => name = val),
              // Dropdown jenis kucing (bisa input manual jika "Lainnya")
              _buildJenisKucingDropdown(),
              // Dropdown jenis kelamin
              _buildGenderDropdown(),
              // Input umur + satuan
              _buildAgeField(),
              // Input warna kucing
              _buildTextField('Warna', (val) => warna = val),
              // Input deskripsi opsional
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
              Row(
                children: [
                  Text(
                    'Pilih Lokasi Adopsi di Map: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: _getCurrentLocation,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.my_location, color: Colors.blue),
                          SizedBox(width: 8),
                          Text("Ambil Lokasi Saya"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Container(
                height: 250, // Sesuaikan tinggi peta
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
              if (selectedAddress != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.green),
                      SizedBox(width: 8),
                      Expanded(child: Text(selectedAddress!)),
                    ],
                  ),
                ),
              // Tombol simpan, tambahkan validasi gambar wajib diunggah di sini
              SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Validasi gambar wajib diunggah
                      if (_pickedImage == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gambar wajib diunggah!'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      if (selectedLocation == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Wajib memilih lokasi di peta!'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      _formKey.currentState!.save();
                      // Lanjutkan proses simpan ke database di sini
                      // Contoh: Print semua data yang telah diisi
                      print('Nama: $name');
                      print('Jenis: $jenis');
                      print('Gender: $gender');
                      print('Umur: $umur $selectedTimeUnit');
                      print('Warna: $warna');
                      print('Deskripsi: $deskripsi');
                      print(
                        'Lokasi: ${selectedLocation?.latitude}, ${selectedLocation?.longitude}',
                      );
                      print('Alamat: $selectedAddress');

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Data berhasil disimpan!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6FCF97),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Simpan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
