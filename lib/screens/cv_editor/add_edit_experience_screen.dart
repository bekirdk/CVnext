import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddEditExperienceScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  // docId artık CV dokümanının ID'si, experienceId ise liste içindeki öğenin ID'si
  final String? docId; // Bu aslında CV'nin docId'si, kafa karıştırıcı olabilir - şimdilik kullanmıyoruz
  final String? experienceId; // Liste öğesinin unique ID'si

  const AddEditExperienceScreen({
    super.key,
    this.initialData,
    this.docId, // CV'nin ID'si (şimdilik gerekli değil)
    this.experienceId, // Düzenlenecek deneyimin ID'si
  });

  // Düzenleme modunda olup olmadığımızı kontrol et (experienceId varsa düzenlemedir)
  bool get isEditing => initialData != null && experienceId != null;

  @override
  State<AddEditExperienceScreen> createState() => _AddEditExperienceScreenState();
}

class _AddEditExperienceScreenState extends State<AddEditExperienceScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _companyNameController;
  late TextEditingController _jobTitleController;
  late TextEditingController _locationController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  late TextEditingController _descriptionController;
  bool _isCurrentJob = false;

  @override
  void initState() {
    super.initState();
    final initialData = widget.initialData;
    _companyNameController = TextEditingController(text: initialData?['companyName']);
    _jobTitleController = TextEditingController(text: initialData?['jobTitle']);
    _locationController = TextEditingController(text: initialData?['location']);
    _startDateController = TextEditingController(text: initialData?['startDate']);
    _isCurrentJob = initialData?['isCurrentJob'] ?? false;
    _endDateController = TextEditingController(text: _isCurrentJob ? '' : initialData?['endDate']);
    _descriptionController = TextEditingController(text: initialData?['description']);
  }

  @override
  void dispose() {
    // ... controller dispose kodları ...
    _companyNameController.dispose(); _jobTitleController.dispose(); _locationController.dispose();
    _startDateController.dispose(); _endDateController.dispose(); _descriptionController.dispose();
    super.dispose();
  }

  void _saveExperience() {
    if (_formKey.currentState!.validate()) {
      final experienceData = {
        'companyName': _companyNameController.text.trim(),
        'jobTitle': _jobTitleController.text.trim(),
        'location': _locationController.text.trim(),
        'startDate': _startDateController.text.trim(),
        'endDate': _isCurrentJob ? '' : _endDateController.text.trim(),
        'description': _descriptionController.text.trim(),
        'isCurrentJob': _isCurrentJob,
        // Eklerken oluşturulan ID ve tarihi koruyalım (varsa)
        'id': widget.experienceId ?? widget.initialData?['id'], // Düzenlemedeyse eski ID'yi koru
        'addedAt': widget.initialData?['addedAt'], // Eklenme tarihini koru
      };

      // Veriyi ve (düzenleme ise) experienceId'yi geri gönder
      Navigator.pop(context, {
         'data': experienceData,
         'experienceId': widget.experienceId // Sadece düzenleme modunda dolu olacak
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Deneyimi Düzenle' : 'Yeni Deneyim Ekle', style: GoogleFonts.poppins()),
      ),
      body: SingleChildScrollView( /* ... Form içeriği aynı ... */ ),
    );
  }
}