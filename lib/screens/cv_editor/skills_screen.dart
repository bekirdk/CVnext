import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:yeni_cv_uygulamasi/providers/cv_provider.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, List<String>> _skills = { 'technical': [], 'soft': [], 'languages': [] };
  final Map<String, TextEditingController> _controllers = {
    'technical': TextEditingController(), 'soft': TextEditingController(), 'languages': TextEditingController(),
  };
  bool _isLoading = true;
  String? _userId;
  String? _selectedCvId;

  @override
  void initState() {
    super.initState();
    // didChangeDependencies ilk build'de de çağrılır
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cvProvider = Provider.of<CvProvider>(context);
    final newSelectedCvId = cvProvider.selectedCvId;

    if (newSelectedCvId != _selectedCvId) {
       _selectedCvId = newSelectedCvId;
       _userId = _auth.currentUser?.uid;
       print("SkillsScreen: Loading data for CV ID: $_selectedCvId");
       _loadSkills();
    } else if (_isLoading && _selectedCvId == null){
       _handleMissingCvSelection();
    }
  }

  void _handleMissingCvSelection(){
     if(mounted) setState(() => _isLoading = false);
     WidgetsBinding.instance.addPostFrameCallback((_) {
         if(mounted) { _showInfoSnackBar('Lütfen önce bir CV seçin veya oluşturun.'); }
       });
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) { controller.dispose(); });
    super.dispose();
  }

  Future<void> _loadSkills() async {
    if (_userId == null || _selectedCvId == null) {
       if (mounted) setState(() { _skills = {'technical': [], 'soft': [], 'languages': []}; _isLoading = false; });
       print("Yetenekler yüklenemedi: Kullanıcı veya CV seçili değil.");
       return;
    }
     if (!mounted) return;
    setState(() { _isLoading = true; });
    try {
      final docSnapshot = await _firestore.collection('users').doc(_userId).collection('cvs').doc(_selectedCvId).get();
      if (mounted) {
        Map<String, List<String>> loadedSkills = {'technical': [], 'soft': [], 'languages': []}; // Önce boşalt
        if (docSnapshot.exists && docSnapshot.data()!.containsKey('skills')) {
          final Map<String, dynamic> data = docSnapshot.data()!['skills'];
          loadedSkills['technical'] = List<String>.from(data['technical'] ?? []);
          loadedSkills['soft'] = List<String>.from(data['soft'] ?? []);
          loadedSkills['languages'] = List<String>.from(data['languages'] ?? []);
        }
        setState(() { _skills = loadedSkills; });
      }
    } catch (e) { print("Yetenekler yüklenirken hata: $e"); _showErrorSnackBar('Yetenekler yüklenirken bir hata oluştu.'); }
    finally { if (mounted) setState(() { _isLoading = false; }); }
  }

  Future<void> _saveSkills() async {
     if (_userId == null || _selectedCvId == null || !mounted) return;
     try {
         await _firestore.collection('users').doc(_userId).collection('cvs').doc(_selectedCvId).set(
           { 'skills': _skills, 'lastUpdated': FieldValue.serverTimestamp() }, SetOptions(merge: true) );
         print("Yetenekler Firestore'a kaydedildi.");
     } catch (e) { print("Yetenekler kaydedilirken hata: $e"); _showErrorSnackBar('Yetenekler kaydedilirken bir hata oluştu.'); }
  }

  void _removeSkill(String category, String skill) {
    if (!mounted) return;
    setState(() { _skills[category]?.remove(skill); });
    _saveSkills();
  }

  void _addSkill(String category) {
    final String skill = _controllers[category]!.text.trim();
    if (skill.isNotEmpty && !(_skills[category]?.contains(skill) ?? true)) {
       if (!mounted) return;
       setState(() {
         _skills[category] = _skills[category] ?? [];
         _skills[category]?.add(skill);
         _controllers[category]!.clear();
       });
       _saveSkills();
    }
  }

  // SnackBar fonksiyonları
  void _showSnackBar(String message, {Color backgroundColor = Colors.grey}) { if (!mounted) return; ScaffoldMessenger.of(context).removeCurrentSnackBar(); ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(message), backgroundColor: backgroundColor, duration: const Duration(seconds: 2)) ); }
  void _showErrorSnackBar(String message) { _showSnackBar(message, backgroundColor: Colors.red); }
  void _showSuccessSnackBar(String message) { _showSnackBar(message, backgroundColor: Colors.green); }
  void _showInfoSnackBar(String message) { _showSnackBar(message, backgroundColor: Colors.orange); }


  @override
  Widget build(BuildContext context) {
     if (_isLoading) { return Scaffold(appBar: AppBar(title: const Text("Yetenekler")), body: const Center(child: CircularProgressIndicator())); }
     if (_selectedCvId == null) { return Scaffold(appBar: AppBar(title: const Text("Yetenekler")), body: const Center(child: Text("Lütfen önce bir CV seçin."))); }

    return Scaffold(
      appBar: AppBar(
        title: Text('Yetenekler', style: GoogleFonts.poppins()),
      ),
      body: RefreshIndicator(
              onRefresh: _loadSkills,
              child: ListView( // Form olmadığı için ListView daha uygun
                padding: const EdgeInsets.all(16.0),
                children: <Widget>[
                  // Her kategori için buildSkillCategory çağrısı
                  _buildSkillCategory('Teknik Yetenekler', 'technical'),
                  _buildSkillCategory('Sosyal Yetenekler', 'soft'),
                  _buildSkillCategory('Dil Yetenekleri', 'languages'),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  } // build metodunun sonu

  // --- YARDIMCI FONKSİYON (_buildSkillCategory) - SADECE BİR KERE ---
  Widget _buildSkillCategory(String title, String categoryKey) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
          child: Text( title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).primaryColor)),
        ),
        // Chip listesi
        (_skills[categoryKey]?.isEmpty ?? true)
         ? const Padding( // Boşsa mesaj göster
             padding: EdgeInsets.symmetric(vertical: 8.0),
             child: Text("Bu kategori için henüz yetenek eklenmedi.", style: TextStyle(color: Colors.grey)),
           )
         : Wrap( // Doluysa Chipleri göster
            spacing: 8.0, runSpacing: 4.0,
            children: _skills[categoryKey]!.map((skill) => Chip(
                  label: Text(skill),
                  deleteIconColor: Colors.red.shade700,
                  onDeleted: () => _removeSkill(categoryKey, skill),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Daha küçük dokunma alanı
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), // Chip içi boşluk
                )).toList(),
          ),
        const SizedBox(height: 12.0),
        // Ekleme alanı
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controllers[categoryKey],
                decoration: InputDecoration(
                  hintText: '$title Yeteneği Ekle...',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor)),
                ),
                onSubmitted: (_) => _addSkill(categoryKey),
              ),
            ),
            const SizedBox(width: 8.0),
            IconButton.filled(
               icon: const Icon(Icons.add),
               tooltip: 'Ekle',
               style: IconButton.styleFrom( backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1), foregroundColor: Theme.of(context).primaryColor),
               onPressed: () => _addSkill(categoryKey),
             )
          ],
        ),
        Divider(height: 30, thickness: 1, color: Colors.grey.shade200),
      ],
    );
  }
  // --- YARDIMCI FONKSİYON SONU ---

} // _SkillsScreenState sınıfının sonu