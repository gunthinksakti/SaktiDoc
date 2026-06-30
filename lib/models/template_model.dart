class Template {
  final String id, nama, icon;
  final List<TemplateVersion> templates;
  Template({required this.id, required this.nama, required this.icon, required this.templates});
  factory Template.fromJson(Map<String, dynamic> json) => Template(
    id: json['id'] ?? '',
    nama: json['nama'] ?? '',
    icon: json['icon'] ?? '📄',
    templates: (json['templates'] as List).map((i) => TemplateVersion.fromJson(i)).toList(),
  );
}

class TemplateVersion {
  final String namaVersi, konten;
  final int hargaKoin;
  TemplateVersion({required this.namaVersi, required this.konten, required this.hargaKoin});
  factory TemplateVersion.fromJson(Map<String, dynamic> json) => TemplateVersion(
    namaVersi: json['nama_versi'] ?? 'Default',
    konten: json['konten'] ?? '',
    hargaKoin: json['harga_koin'] ?? 0,
  );
}
