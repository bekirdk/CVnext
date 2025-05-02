import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddEditProjectScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final String? docId;

  const AddEditProjectScreen({
    super.key,
    this.initialData,
    this.docId,
  });

  bool get isEditing => initialData != null && docId != null;

  @override
  State<AddEditProjectScreen> createState() => _AddEditProjectScreenState();
}

class _AddEditProjectScreenState extends State<AddEditProjectScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _projectNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _technologiesController; // Virgülle ayrılmış string
  late TextEditingController _linkController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;

  @override
  void initState() {
    super.initState();
    final initialData = widget.initialData;
    _projectNameController = TextEditingController(text: initialData?['projectName']);
    _descriptionController = TextEditingController(text: initialData?['description']);
    // Teknolojileri List<String>'den virgüllü String'e çevir
    _technologiesController = TextEditingController(text: (initialData?['technologies'] as List<dynamic>?)?.join(', '));
    _linkController = TextEditingController(text: initialData?['link']);
    _startDateController = TextEditingController(text: initialData?['startDate']);
    _endDateController = TextEditingController(text: initialData?['endDate']);
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _descriptionController.dispose();
    _technologiesController.dispose();
    _linkController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  void _saveProject() {
    if (_formKey.currentState!.validate()) {
      // Virgülle ayrılmış teknolojileri temizleyip List<String>'e çevir
      final List<String> technologiesList = _technologiesController.text
          .split(',')
          .map((tech) => tech.trim()) // Başındaki/sonundaki boşlukları sil
          .where((tech) => tech.isNotEmpty) // Boş elemanları kaldır
          .toList();

      final projectData = {
        'projectName': _projectNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'technologies': technologiesList, // Liste olarak kaydet
        'link': _linkController.text.trim(),
        'startDate': _startDateController.text.trim(), // Tarihler şimdilik string
        'endDate': _endDateController.text.trim(),
      };

      Navigator.pop(context, {
         'data': projectData,
         'docId': widget.docId
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Projeyi Düzenle' : 'Yeni Proje Ekle', style: GoogleFonts.poppins()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _projectNameController,
                decoration: const InputDecoration(labelText: 'Proje Adı'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Lütfen proje adını girin.' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Proje Açıklaması',
                  alignLabelWithHint: true,
                ),
                 maxLines: 4,
                 keyboardType: TextInputType.multiline,
                 textInputAction: TextInputAction.next,
                 // validator: (value) => (value == null || value.trim().isEmpty) ? 'Açıklama gerekli.' : null, // Zorunlu mu?
              ),
              const SizedBox(height: 16.0),
               TextFormField(
                controller: _technologiesController,
                decoration: const InputDecoration(
                  labelText: 'Kullanılan Teknolojiler (Virgülle ayırın)',
                  hintText: 'örn: Flutter, Firebase, Dart',
                ),
                 textInputAction: TextInputAction.next,
              ),
               const SizedBox(height: 16.0),
               TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'Proje Linki (GitHub, Web Sitesi vb. - İsteğe bağlı)',
                ),
                 keyboardType: TextInputType.url,
                 textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16.0),
              // Opsiyonel Tarih Alanları
               Row(
                 children: [
                   Expanded(
                     child: TextFormField(
                       controller: _startDateController,
                       decoration: const InputDecoration(labelText: 'Başlangıç Tarihi (İsteğe bağlı)', hintText: 'örn: Mart 2023'),
                       textInputAction: TextInputAction.next,
                     ),
                   ),
                   const SizedBox(width: 16.0),
                   Expanded(
                     child: TextFormField(
                       controller: _endDateController,
                       decoration: const InputDecoration(labelText: 'Bitiş Tarihi (İsteğe bağlı)', hintText: 'örn: Nisan 2023'),
                       textInputAction: TextInputAction.done,
                       onFieldSubmitted: (_) => _saveProject(),
                     ),
                   ),
                 ],
               ),
              const SizedBox(height: 32.0),
              ElevatedButton(
                onPressed: _saveProject,
                child: Text(widget.isEditing ? 'Değişiklikleri Kaydet' : 'Projeyi Ekle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}