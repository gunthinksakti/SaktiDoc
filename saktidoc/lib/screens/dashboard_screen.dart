import 'package:flutter/material.dart';
import '../models/template_model.dart';
import '../services/api_service.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/custom_snackbar.dart';
import 'editor_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Template> templates = [];
  List<Template> filtered = [];
  bool loading = true;
  final TextEditingController search = TextEditingController();

  @override
  void initState() {
    super.initState();
    ApiService.fetchTemplates().then((data) {
      setState(() { templates = data; filtered = data; loading = false; });
    });
  }

  void filter(String keyword) {
    setState(() {
      filtered = templates.where((t) => t.nama.toLowerCase().contains(keyword.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SaktiDoc'), backgroundColor: Colors.white, elevation: 0),
      body: loading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: search,
                  onChanged: filter,
                  decoration: InputDecoration(
                    hintText: 'Cari template dokumen...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final harga = item.templates.isNotEmpty ? item.templates[0].hargaKoin : 0;
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => EditorScreen(template: item),
                        ));
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 10, right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.yellow.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.yellow.shade300),
                                ),
                                child: Text('🪙 $harga', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(item.icon, style: const TextStyle(fontSize: 36)),
                                  const SizedBox(height: 6),
                                  Text(item.nama, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
    );
  }
}
