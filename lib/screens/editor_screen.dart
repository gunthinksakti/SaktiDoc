import 'package:flutter/material.dart';
import '../models/template_model.dart';
import '../widgets/custom_snackbar.dart';

class EditorScreen extends StatefulWidget {
  final Template template;
  const EditorScreen({super.key, required this.template});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  int selectedVersion = 0;
  late TextEditingController controller;
  double fontSize = 13;
  bool focusMode = false;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(
      text: widget.template.templates.isNotEmpty ? widget.template.templates[0].konten : ''
    );
  }

  @override
  Widget build(BuildContext context) {
    final aktif = widget.template.templates[selectedVersion];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template.nama),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              value: selectedVersion,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              items: widget.template.templates.asMap().entries.map((e) {
                return DropdownMenuItem(value: e.key, child: Text(e.value.namaVersi));
              }).toList(),
              onChanged: (v) => setState(() {
                selectedVersion = v!;
                controller.text = widget.template.templates[v].konten;
              }),
            ),
            const SizedBox(height: 12),
            // Toolbar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.copy), onPressed: () => CustomSnackbar.show(context, 'Teks disalin!')),
                  IconButton(icon: const Icon(Icons.zoom_in), onPressed: () => setState(() => fontSize += 1)),
                  IconButton(icon: const Icon(Icons.zoom_out), onPressed: () => setState(() => fontSize -= 1)),
                  IconButton(
                    icon: Icon(focusMode ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => focusMode = !focusMode),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Editor
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: focusMode ? const Color(0xFFFDF6E3) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  expands: true,
                  style: TextStyle(fontSize: fontSize, fontFamily: 'monospace'),
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade600),
                    child: const Text('Kembali'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      CustomSnackbar.show(context, 'Cetak ${aktif.namaVersi} - ${aktif.hargaKoin} Koin');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: Text('Cetak (${aktif.hargaKoin} Koin)'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
