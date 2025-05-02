import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddEditEducationScreen extends StatefulWidget {
  // Düzenleme için initialData ve docId eklendi
  final Map<String, dynamic>? initialData;
  final String? docId;

  const AddEditEducationScreen({
    super.key,
    this.initialData, // Artık bu parametreler var
    this.docId,      // Artık bu parametre var
  });

  // Düzenleme modunda olup olmadığımızı kontrol eden getter
  bool get isEditing => initialData != null && docId != null;

  @override
  State<AddEditEducationScreen> createState() => _AddEditEducationScreenState();
}

class _AddEditEducationScreenState extends State<AddEditEducationScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _institutionNameController;
  late TextEditingController _degreeController;
  late TextEditingController _fieldOfStudyController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  late TextEditingController _descriptionController;
  bool _isCurrent = false;

  @override
  void initState() {
    super.initState();
    final initialData = widget.initialData;
    // Controller'ları gelen veriyle başlat (düzenleme moduysa)
    _institutionNameController = TextEditingController(text: initialData?['institutionName']);
    _degreeController = TextEditingController(text: initialData?['degree']);
    _fieldOfStudyController = TextEditingController(text: initialData?['fieldOfStudy']);
    _startDateController = TextEditingController(text: initialData?['startDate']);
    _isCurrent = initialData?['isCurrent'] ?? false;
    _endDateController = TextEditingController(text: _isCurrent ? '' : initialData?['endDate']);
    _descriptionController = TextEditingController(text: initialData?['description']);
  }

  @override
  void dispose() {
    _institutionNameController.dispose();
    _degreeController.dispose();
    _fieldOfStudyController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveEducation() {
    if (_formKey.currentState!.validate()) {
      final educationData = {
        'institutionName': _institutionNameController.text.trim(),
        'degree': _degreeController.text.trim(),
        'fieldOfStudy': _fieldOfStudyController.text.trim(),
        'startDate': _startDateController.text.trim(),
        'endDate': _isCurrent ? '' : _endDateController.text.trim(),
        'description': _descriptionController.text.trim(),
        'isCurrent': _isCurrent,
      };
      // Veriyi ve (varsa) docId'yi geri gönder
      Navigator.pop(context, {
         'data': educationData,
         'docId': widget.docId // Ekleme modunda bu null olacak
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Düzenleme moduna göre başlığı değiştir
        title: Text(widget.isEditing ? 'Eğitimi Düzenle' : 'Yeni Eğitim Ekle', style: GoogleFonts.poppins()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _institutionNameController,
                decoration: const InputDecoration(labelText: 'Okul / Kurum Adı'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Lütfen kurum adını girin.' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _degreeController,
                decoration: const InputDecoration(labelText: 'Derece / Bölüm', hintText: 'örn: Lisans, Bilgisayar Mühendisliği'),
                 validator: (value) => (value == null || value.trim().isEmpty) ? 'Lütfen derece/bölüm girin.' : null,
                 textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _fieldOfStudyController,
                decoration: const InputDecoration(labelText: 'Alan (İsteğe bağlı)', hintText: 'örn: Yapay Zeka Uzmanlığı'),
                 textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16.0),
              CheckboxListTile(
                 title: const Text("Halen devam ediyorum"),
                 value: _isCurrent,
                 onChanged: (bool? value) {
                   if (value != null) {
                     setState(() {
                       _isCurrent = value;
                       if (_isCurrent) {
                         _endDateController.clear();
                       }
                     });
                   }
                 },
                 controlAffinity: ListTileControlAffinity.leading,
                 contentPadding: EdgeInsets.zero,
               ),
              const SizedBox(height: 16.0),
              Row(
                 children: [
                   Expanded(
                     child: TextFormField(
                       controller: _startDateController,
                       decoration: const InputDecoration(labelText: 'Başlangıç Tarihi', hintText: 'örn: Eylül 2018'),
                       validator: (value) => (value == null || value.trim().isEmpty) ? 'Başlangıç tarihi gerekli.' : null,
                       textInputAction: TextInputAction.next,
                     ),
                   ),
                   const SizedBox(width: 16.0),
                   Expanded(
                     child: TextFormField(
                       controller: _endDateController,
                       enabled: !_isCurrent,
                       decoration: InputDecoration(
                         labelText: 'Bitiş Tarihi',
                         hintText: _isCurrent ? 'Devam Ediyor' : 'örn: Haziran 2022',
                       ),
                       validator: (value) => (!_isCurrent && (value == null || value.trim().isEmpty)) ? 'Bitiş tarihi gerekli.' : null,
                       textInputAction: TextInputAction.next,
                     ),
                   ),
                 ],
               ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama / Notlar (İsteğe bağlı)',
                  hintText: 'Ortalama, projeler, tez konusu vb.',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _saveEducation(),
              ),
              const SizedBox(height: 32.0),
              ElevatedButton(
                onPressed: _saveEducation,
                // Düzenleme moduna göre buton yazısını değiştir
                child: Text(widget.isEditing ? 'Değişiklikleri Kaydet' : 'Eğitimi Ekle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}