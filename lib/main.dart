import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SaktiDocApp());
}

class AppConfig {
  static const String urlApiGas = "https://script.google.com/macros/s/AKfycbwVkzr9KyPo-h5C3YSYzQPKvqcYzOBOn3k_WbE1WAc5ESDUgxCDSYi0kDirte5EEGq-Ag/exec";
  static const String whatsappAdmin = "628XXXXXXXXXX";
  static const String telegramAdmin = "admin_saktidoc";
}

class SaktiDocApp extends StatelessWidget {
  const SaktiDocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SaktiDoc Ultimate',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff1E88E5),
          background: const Color(0xffF5F5F7),
          surface: const Color(0xffFFFBFE),
        ),
      ),
      home: const MainNavigationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentTabIndex = 0;
  String _cloudStatus = "Sinkronisasi...";
  List<dynamic> _masterTemplates = [];
  List<dynamic> _filteredTemplates = [];
  List<String> _favoritIds = [];
  String _kategoriAktif = "Semua";
  bool _isLoading = false;
  String _myDeviceId = "";

  final TextEditingController _searchController = TextEditingController();
  late SharedPreferences _prefs;

  final List<String> _daftarKategori = [
    "Semua", "Favorit", "Kerja", "Bisnis", "Pribadi", "Pendidikan",
    "Hukum", "Keuangan", "Akademik", "Kesehatan", "Sosial", "Lainnya"
  ];

  @override
  void initState() {
    super.initState();
    _loadConfigAndSync();
    _searchController.addListener(_jalankanFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConfigAndSync() async {
    _prefs = await SharedPreferences.getInstance();
    String? existingId = _prefs.getString('cfg_device_id');
    if (existingId == null || existingId.isEmpty) {
      final random = Random();
      final int randomNumber = random.nextInt(900000) + 100000;
      existingId = "SD-${DateTime.now().millisecondsSinceEpoch}-$randomNumber";
      await _prefs.setString('cfg_device_id', existingId);
    }

    setState(() {
      _favoritIds = _prefs.getStringList('favorit_surat') ?? [];
      _myDeviceId = existingId!;
    });
    
    _initSinkronisasiTemplates();
  }

  void _jalankanFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTemplates = _masterTemplates.where((item) {
        bool cocokKategori = true;
        if (_kategoriAktif == "Favorit") {
          cocokKategori = _favoritIds.contains(item['id'].toString());
        } else if (_kategoriAktif != "Semua") {
          String katSurat = item['kategori'] ?? 'Lainnya';
          cocokKategori = katSurat.toLowerCase() == _kategoriAktif.toLowerCase();
        }
        bool cocokPencarian = item['nama'].toString().toLowerCase().contains(query);
        return cocokKategori && cocokPencarian;
      }).toList();
    });
  }

  Future<void> _toggleFavorit(String id) async {
    setState(() {
      if (_favoritIds.contains(id)) {
        _favoritIds.remove(id);
      } else {
        _favoritIds.add(id);
      }
    });
    await _prefs.setStringList('favorit_surat', _favoritIds);
    _jalankanFilter();
  }

  Future<void> _initSinkronisasiTemplates() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(AppConfig.urlApiGas),
        headers: {"Content-Type": "application/json;charset=utf-8"},
        body: jsonEncode({"aksi": "ambil_template", "device_id": _myDeviceId}),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['sukses'] == true) {
          await _prefs.setString('offline_db', jsonEncode(resData['data']));
          setState(() {
            _masterTemplates = resData['data'];
            _cloudStatus = "Online";
            _isLoading = false;
          });
          _jalankanFilter();
          return;
        }
      }
      _muatOffline();
    } catch (_) {
      _muatOffline();
    }
  }

  void _muatOffline() {
    final String? localData = _prefs.getString('offline_db');
    setState(() {
      _isLoading = false;
      _cloudStatus = "Luring";
      if (localData != null) {
        _masterTemplates = jsonDecode(localData);
      }
    });
    _jalankanFilter();
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _bukaWhatsApp(String pesan) async {
    final cleanWa = AppConfig.whatsappAdmin.replaceAll(RegExp(r'[^0-9]'), '');
    final Uri uri = Uri.parse("https://wa.me/$cleanWa?text=${Uri.encodeComponent(pesan)}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackbar("Tidak dapat membuka WhatsApp.");
    }
  }

  void _bukaTelegram(String pesan) async {
    final cleanTg = AppConfig.telegramAdmin.replaceAll('@', '').trim();
    final Uri uri = Uri.parse("https://t.me/$cleanTg");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackbar("Tidak dapat membuka Telegram.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SaktiDoc Ultimate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xff111111))),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _cloudStatus == "Online" ? const Color(0xffD4EDDA) : const Color(0xffFFF3CD), 
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _cloudStatus, 
                  style: TextStyle(color: _cloudStatus == "Online" ? const Color(0xff155724) : const Color(0xff856404), fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ),
          )
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentTabIndex,
            children: [
              _buildKatalogTab(),
              _buildIsiUlangTab(),
            ],
          ),
          if (_isLoading)
            const Positioned(
              top: 0, left: 0, right: 0,
              child: LinearProgressIndicator(color: Color(0xff1E88E5), backgroundColor: Colors.transparent),
            )
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BottomNavigationBar(
            currentIndex: _currentTabIndex,
            elevation: 0,
            backgroundColor: Colors.transparent,
            selectedItemColor: const Color(0xff1E88E5),
            unselectedItemColor: const Color(0xff79747E),
            onTap: (index) => setState(() => _currentTabIndex = index),
            items: const [
              BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 2), child: Text("📋", style: TextStyle(fontSize: 18))), label: 'Katalog'),
              BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 2), child: Text("🪙", style: TextStyle(fontSize: 18))), label: 'Isi Saldo'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKatalogTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari template dokumen...',
              prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _daftarKategori.length,
            itemBuilder: (context, idx) {
              final kat = _daftarKategori[idx];
              final isSelected = _kategoriAktif == kat;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: FilterChip(
                  label: Text(kat, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() => _kategoriAktif = kat);
                    _jalankanFilter();
                  },
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _filteredTemplates.isEmpty
              ? Center(child: Text(_isLoading ? "Sinkronisasi..." : "Template tidak ditemukan", style: const TextStyle(color: Colors.grey, fontSize: 13)))
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1.0,
                  ),
                  itemCount: _filteredTemplates.length,
                  itemBuilder: (context, index) {
                    final item = _filteredTemplates[index];
                    final itemID = item['id'].toString();
                    final isFav = _favoritIds.contains(itemID);
                    final koinDefault = (item['templates'] != null && item['templates'].isNotEmpty)
                        ? item['templates'][0]['harga_koin'] ?? 0 : 0;
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Stack(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditorScreen(itemData: item, deviceId: _myDeviceId),
                                ),
                              ).then((_) => _initSinkronisasiTemplates());
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(item['icon'] ?? '📄', style: const TextStyle(fontSize: 36)),
                                    const SizedBox(height: 8),
                                    Text(item['nama'] ?? '', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xff222222)), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8, left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xffFFFDF0), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xffFFE082))),
                              child: Text("🪙 $koinDefault", style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xffB45309))),
                            ),
                          ),
                          Positioned(
                            top: 2, right: 2,
                            child: IconButton(
                              icon: Icon(isFav ? Icons.star : Icons.star_border, color: isFav ? Colors.amber : Colors.grey, size: 20),
                              onPressed: () => _toggleFavorit(itemID),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildIsiUlangTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Isi Ulang Saldo Koin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text("Konversi resmi: 1 Koin = Rp1.000,-. Sistem enkripsi lisensi terikat otomatis pada Device ID Anda.", style: TextStyle(fontSize: 13, color: Color(0xff79747E), height: 1.5)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: SelectableText("ID Pelanggan: $_myDeviceId", style: const TextStyle(fontSize: 11, fontFamily: 'Courier', fontWeight: FontWeight.bold))),
                const Icon(Icons.copy, size: 16, color: Colors.grey),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.3,
            children: [
              _buildCoinCard(5, "Rp5.000"),
              _buildCoinCard(10, "Rp10.000"),
              _buildCoinCard(25, "Rp25.000"),
              _buildCoinCard(50, "Rp50.000"),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff25D366), foregroundColor: Colors.white,
                    minimumSize: const Size(0, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Text("💬"),
                  label: const Text("Bantuan WhatsApp"),
                  onPressed: () => _bukaWhatsApp("Halo Admin, saya konfirmasi keluhan/pertanyaan akun SaktiDoc.\nID Pelanggan: $_myDeviceId"),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCoinCard(int koin, String harga) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xffFFFDF0), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xffFFD700), width: 1.2)),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("🪙 $koin Koin", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(harga, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xffB45309))),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Text("💬", style: TextStyle(fontSize: 13)),
                onPressed: () => _bukaWhatsApp("Halo Admin SaktiDoc, saya mau order Paket $koin Koin ($harga).\nID Pelanggan: $_myDeviceId"),
              ),
              IconButton(
                icon: const Text("✈️", style: TextStyle(fontSize: 13)),
                onPressed: () => _bukaTelegram("Halo Admin SaktiDoc, saya mau order Paket $koin Koin ($harga).\nID Pelanggan: $_myDeviceId"),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class EditorScreen extends StatefulWidget {
  final Map<String, dynamic> itemData;
  final String deviceId;

  const EditorScreen({super.key, required this.itemData, required this.deviceId});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  int _indeksVersiAktif = 0;
  double _ukuranFontSekarang = 13.0;
  bool _isFocusMode = false;
  bool _isLoading = false;
  
  int _marginAtas = 30;
  int _marginKiri = 25;

  late TextEditingController _textEditorController;
  int _jumlahKata = 0;
  int _jumlahKarakter = 0;

  @override
  void initState() {
    super.initState();
    _textEditorController = TextEditingController();
    _muatKontenDanTarifKertas();
    _textEditorController.addListener(() {
      _hitungMetrikKertas();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _textEditorController.dispose();
    super.dispose();
  }

  void _muatKontenDanTarifKertas() {
    final versions = widget.itemData['templates'] as List<dynamic>;
    if (versions.isNotEmpty) {
      final currentVer = versions[_indeksVersiAktif];
      setState(() {
        _textEditorController.text = currentVer['konten'] ?? '';
        _marginAtas = currentVer['margin_atas'] ?? 30;
        _marginKiri = currentVer['margin_kiri'] ?? 25;
      });
      _hitungMetrikKertas();
    }
  }

  void _hitungMetrikKertas() {
    final txt = _textEditorController.text;
    _jumlahKarakter = txt.length;
    _jumlahKata = txt.trim().isEmpty ? 0 : txt.trim().split(RegExp(r'\s+')).length;
  }

  pw.Document _generateLivePdfDocument() {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.only(
          top: _marginAtas.toDouble(),
          left: _marginKiri.toDouble(),
          right: 25,
          bottom: 25,
        ),
        build: (pw.Context context) {
          return pw.FullPage(
            ignoreMargins: false,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _textEditorController.text,
                  style: const pw.TextStyle(fontSize: 10, lineSpacing: 2),
                ),
              ],
            ),
          );
        },
      ),
    );
    return pdf;
  }

  void _panggilAiGasDelegatedOptimizer() async {
    final promptController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Asisten AI SaktiDoc", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: promptController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: "Contoh: Ubah nama perusahaan jadi PT Maju Jaya dan rapikan bahasanya...", border: OutlineInputBorder(), hintStyle: TextStyle(fontSize: 12)),
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              final instruksi = promptController.text.trim();
              Navigator.pop(context);
              if (instruksi.isNotEmpty) _eksekusiDelegasiAiServer(instruksi);
            },
            child: const Text("Proses AI"),
          )
        ],
      ),
    );
  }

  Future Holiday_eksekusiDelegasiAiServer(String instruksi) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(AppConfig.urlApiGas),
        headers: {"Content-Type": "application/json;charset=utf-8"},
        body: jsonEncode({
          "aksi": "optimasi_ai_gemini", 
          "device_id": widget.deviceId,
          "teks_surat": _textEditorController.text,
          "instruksi": instruksi
        }),
      ).timeout(const Duration(seconds: 25));

      setState(() => _isLoading = false);
      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['sukses'] == true && resData['data'] != null) {
          setState(() {
            _textEditorController.text = resData['data'].toString().trim();
          });
          _hitungMetrikKertas();
          return;
        }
        _alertError(resData['error'] ?? resData['msg'] ?? "Ditolak oleh server.");
      } else {
        _alertError("Server bermasalah (${response.statusCode})");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _alertError("Gagal terhubung ke jaringan AI server.");
    }
  }

  void _prosesSimpanDanCetak() async {
    final versions = widget.itemData['templates'] as List<dynamic>;
    final templateAktif = versions[_indeksVersiAktif];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Penerbitan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text("Aksi cetak ini membutuhkan kuota sebanyak ${templateAktif['harga_koin']} Koin dari saldo Anda. Lanjutkan?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _kirimAksiCetak(templateAktif);
            },
            child: const Text("Lanjutkan"),
          )
        ],
      ),
    );
  }

  Future<void> _kirimAksiCetak(dynamic templateAktif) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(AppConfig.urlApiGas),
        headers: {"Content-Type": "application/json;charset=utf-8"},
        body: jsonEncode({
          "aksi": "cetak_docs_pdf",
          "device_id": widget.deviceId,
          "id_surat": widget.itemData['id'],
          "nama_versi": templateAktif['nama_versi'],
          "nama_file": "${widget.itemData['nama'].toString().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch}",
          "teks_konten": _textEditorController.text
        }),
      ).timeout(const Duration(seconds: 30));

      setState(() => _isLoading = false);
      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        if (res['sukses'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dokumen berhasil diterbitkan!")));
          if (res['url'] != null) {
            final Uri docUri = Uri.parse(res['url']);
            if (await canLaunchUrl(docUri)) {
              await launchUrl(docUri, mode: LaunchMode.externalApplication);
            }
          }
        } else {
          _alertError(res['error'] ?? res['msg'] ?? "Saldo tidak mencukupi.");
        }
      }
    } catch (_) {
      setState(() => _isLoading = false);
      _alertError("Gangguan transmisi pengiriman dokumen.");
    }
  }

  void _alertError(String msg) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Perhatian", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text(msg, style: const TextStyle(fontSize: 13)),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> versions = widget.itemData['templates'] ?? [];
    final templateAktif = versions.isNotEmpty ? versions[_indeksVersiAktif] : null;

    return Scaffold(
      backgroundColor: const Color(0xffF5F5F7),
      appBar: AppBar(title: Text(widget.itemData['nama'] ?? 'Editor'), elevation: 0, backgroundColor: Colors.white),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (versions.length > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.black12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _indeksVersiAktif, isExpanded: true,
                        items: List.generate(versions.length, (index) {
                          return DropdownMenuItem(value: index, child: Text(versions[index]['nama_versi'] ?? '', style: const TextStyle(fontSize: 14)));
                        }),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _indeksVersiAktif = val);
                            _muatKontenDanTarifKertas();
                          }
                        },
                      ),
                    ),
                  ),
                
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black.withOpacity(0.05))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.vertical_align_top, size: 16, color: Colors.grey),
                          const Text(' M. Atas: ', style: TextStyle(fontSize: 11)),
                          IconButton(icon: const Icon(Icons.remove_circle_outline, size: 18), onPressed: _marginAtas > 10 ? () => setState(() => _marginAtas -= 5) : null),
                          Text('$_marginAtas', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          IconButton(icon: const Icon(Icons.add_circle_outline, size: 18), onPressed: () => setState(() => _marginAtas += 5)),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.vertical_align_center, size: 16, color: Colors.grey),
                          const Text(' M. Kiri: ', style: TextStyle(fontSize: 11)),
                          IconButton(icon: const Icon(Icons.remove_circle_outline, size: 18), onPressed: _marginKiri > 10 ? () => setState(() => _marginKiri -= 5) : null),
                          Text('$_marginKiri', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          IconButton(icon: const Icon(Icons.add_circle_outline, size: 18), onPressed: () => setState(() => _marginKiri += 5)),
                        ],
                      ),
                    ],
                  ),
                ),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildToolbarBtn("🔍 Teks +", () => setState(() => _ukuranFontSekarang = (_ukuranFontSekarang < 22) ? _ukuranFontSekarang + 1 : _ukuranFontSekarang)),
                      const SizedBox(width: 6),
                      _buildToolbarBtn("🔍 Teks -", () => setState(() => _ukuranFontSekarang = (_ukuranFontSekarang > 10) ? _ukuranFontSekarang - 1 : _ukuranFontSekarang)),
                      const SizedBox(width: 6),
                      _buildToolbarBtn(_isFocusMode ? "🎨 Mode Normal" : "🎨 Mode Fokus", () => setState(() => _isFocusMode = !_isFocusMode)),
                      const SizedBox(width: 6),
                      _buildToolbarBtn("✨ Optimasi AI", _panggilAiGasDelegatedOptimizer),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: Flex(
                    direction: MediaQuery.of(context).orientation == Orientation.landscape ? Axis.horizontal : Axis.vertical,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _isFocusMode ? const Color(0xffFDF6E3) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black.withOpacity(0.08)),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: TextField(
                            controller: _textEditorController,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: _ukuranFontSekarang,
                              color: _isFocusMode ? const Color(0xff586E75) : const Color(0xff1C1B1F),
                              height: 1.6,
                            ),
                            decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
                          ),
                        ),
                      ),
                      if (!_isFocusMode) ...[
                        const SizedBox(height: 8, width: 8),
                        Expanded(
                          flex: 3,
                          child: Container(
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: PdfPreview(
                                build: (format) => _generateLivePdfDocument().save(),
                                allowPrinting: false,
                                allowSharing: false,
                                canChangePageFormat: false,
                                canChangeOrientation: false,
                              ),
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("$_jumlahKata Kata", style: const TextStyle(fontSize: 11, color: Color(0xff79747E), fontWeight: FontWeight.w500)),
                      Text("$_jumlahKarakter Karakter", style: const TextStyle(fontSize: 11, color: Color(0xff79747E), fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff79747E), foregroundColor: Colors.white, minimumSize: const Size(0, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Kembali"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff1E88E5), foregroundColor: Colors.white, minimumSize: const Size(0, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: _prosesSimpanDanCetak,
                        child: Text(templateAktif != null ? "Terbitkan PDF (${templateAktif['harga_koin']} Koin)" : "Proses Dokumen", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black12,
                child: const Center(child: CircularProgressIndicator()),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildToolbarBtn(String label, VoidCallback onPress) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xffE7E7E9), foregroundColor: const Color(0xff444444),
        elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onPressed: onPress,
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}
