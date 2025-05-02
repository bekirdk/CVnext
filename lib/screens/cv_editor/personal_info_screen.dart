import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:yeni_cv_uygulamasi/providers/cv_provider.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _linkedinController;
  late TextEditingController _portfolioController;

  bool _isLoading = true;
  String? _userId;
  String? _selectedCvId;

  @override
  void initState() {
    super.initState();
     // Controller'ları boş başlat
    _nameController = TextEditingController(); _titleController = TextEditingController();
    _emailController = TextEditingController(); _phoneController = TextEditingController();
    _addressController = TextEditingController(); _linkedinController = TextEditingController();
    _portfolioController = TextEditingController();
    // İlk yükleme didChangeDependencies'de tetiklenecek
  }

   @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cvProvider = Provider.of<CvProvider>(context);
    final newSelectedCvId = cvProvider.selectedCvId;
    if (newSelectedCvId != _selectedCvId) {
      _selectedCvId = newSelectedCvId;
      _userId = _auth.currentUser?.uid;
       print("PersonalInfoScreen: Loading data for CV ID: $_selectedCvId");
      _loadExistingData();
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
    _nameController.dispose(); _titleController.dispose(); _emailController.dispose();
    _phoneController.dispose(); _addressController.dispose(); _linkedinController.dispose();
    _portfolioController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingData() async {
     if (_userId == null || _selectedCvId == null) { if (mounted) setState(() => _isLoading = false); return; }
     if (!mounted) return; setState(() => _isLoading = true);
     try {
        final docSnapshot = await _firestore.collection('users').doc(_userId).collection('cvs').doc(_selectedCvId).get();
        if (docSnapshot.exists && docSnapshot.data()!.containsKey('personalInfo') && mounted) {
           final data = docSnapshot.data()!['personalInfo'] as Map<String, dynamic>;
           setState(() {
              _nameController.text = data['fullName'] ?? _auth.currentUser?.displayName ?? '';
              _titleController.text = data['jobTitle'] ?? '';
              _emailController.text = data['email'] ?? _auth.currentUser?.email ?? '';
              _phoneController.text = data['phone'] ?? '';
              _addressController.text = data['address'] ?? '';
              _linkedinController.text = data['linkedinUrl'] ?? '';
              _portfolioController.text = data['portfolioUrl'] ?? '';
           });
        } else if(mounted) { setState(() { _emailController.text = _auth.currentUser?.email ?? ''; /* Diğerlerini temizle? */ }); }
     } catch (e) { print("Kişisel Bilgiler yüklenirken hata: $e"); _showErrorSnackBar('Bilgiler yüklenirken hata oluştu.'); }
     finally { if (mounted) setState(() { _isLoading = false; }); }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    final currentSelectedCvId = Provider.of<CvProvider>(context, listen: false).selectedCvId;
    _userId = _auth.currentUser?.uid;
    if (_userId == null || currentSelectedCvId == null || !mounted) { _showErrorSnackBar('Kullanıcı veya seçili CV bulunamadı! Kayıt yapılamadı.'); return; }

    setState(() { _isLoading = true; });
    final Map<String, dynamic> personalInfoData = { /* ... Veri Map'i ... */ };
    try {
      await _firestore.collection('users').doc(_userId).collection('cvs').doc(currentSelectedCvId).set(
        { 'personalInfo': personalInfoData, 'lastUpdated': FieldValue.serverTimestamp() }, SetOptions(merge: true) );
      if (mounted) { _showSuccessSnackBar('Kişisel bilgiler başarıyla kaydedildi!'); /* Pop yok */ }
    } catch (e) { print("Firestore Kaydetme Hatası: $e"); if (mounted) { _showErrorSnackBar('Bilgiler kaydedilirken bir hata oluştu.'); } }
    finally { if (mounted) { setState(() { _isLoading = false; }); } }
  }

  void _showSnackBar(String message, {Color backgroundColor = Colors.grey}) { /* ... */ }
  void _showErrorSnackBar(String message) { _showSnackBar(message, backgroundColor: Colors.red); }
  void _showSuccessSnackBar(String message) { _showSnackBar(message, backgroundColor: Colors.green); }
  void _showInfoSnackBar(String message) { _showSnackBar(message, backgroundColor: Colors.orange); }

  // --- BUILD METODU (TAM HALİ) ---
  @override
  Widget build(BuildContext context) {
     // Bu kontrolü build'in başına alalım
     final currentSelectedCvId = context.watch<CvProvider>().selectedCvId;
     if (currentSelectedCvId == null) {
       return Scaffold(appBar: AppBar(title: const Text("Kişisel Bilgiler")), body: const Center(child: Text("Lütfen önce bir CV seçin.")));
     }
      // Eğer state'deki ID provider'dan farklıysa (CV yeni seçildi) yükleme göster
      // Bu durum didChangeDependencies'de ele alınıyor, tekrar kontrol gerekmeyebilir ama emin olmak için
      if (_isLoading || _selectedCvId != currentSelectedCvId) {
          // Veri yüklenirken veya CV ID'si henüz state'e yansımamışken
          return Scaffold(appBar: AppBar(title: const Text("Kişisel Bilgiler")), body: const Center(child: CircularProgressIndicator()));
      }

    return Scaffold(
      appBar: AppBar(
        title: Text('Kişisel Bilgiler', style: GoogleFonts.poppins()),
        actions: [
           _isLoading
           ? const Padding(
               padding: EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
               child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.0))),
             )
           : IconButton(
               icon: const Icon(Icons.save_outlined),
               tooltip: 'Kaydet',
               onPressed: _isLoading ? null : _saveForm,
             )
        ],
      ),
      body: AnimationLimiter(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: AnimationConfiguration.toStaggeredList(
                          duration: const Duration(milliseconds: 375),
                          childAnimationBuilder: (widget) => SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(child: widget),
                          ),
                          children: <Widget>[ // Form elemanları
                             TextFormField( controller: _nameController, decoration: const InputDecoration( labelText: 'Ad Soyad', prefixIcon: Icon(Icons.person_outline, size: 20) ), validator: (v)=>(v==null||v.trim().isEmpty)?'Zorunlu':null, textInputAction: TextInputAction.next),
                             const SizedBox(height: 16.0),
                             TextFormField( controller: _titleController, decoration: const InputDecoration( labelText: 'Unvan / Başlık', hintText: 'Örn: Flutter Developer', prefixIcon: Icon(Icons.badge_outlined, size: 20) ), textInputAction: TextInputAction.next ),
                             const SizedBox(height: 16.0),
                             const Padding( padding: EdgeInsets.only(top: 16.0, bottom: 8.0), child: Text('İletişim Bilgileri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))), // TitleMedium yerine
                             TextFormField( controller: _emailController, decoration: const InputDecoration( labelText: 'E-posta Adresi', prefixIcon: Icon(Icons.email_outlined, size: 20) ), validator: (v)=>(v==null||v.trim().isEmpty||!v.contains('@'))?'Geçerli e-posta':null, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next ),
                             const SizedBox(height: 16.0),
                             TextFormField( controller: _phoneController, decoration: const InputDecoration( labelText: 'Telefon (İsteğe bağlı)', prefixIcon: Icon(Icons.phone_outlined, size: 20) ), keyboardType: TextInputType.phone, textInputAction: TextInputAction.next ),
                             const SizedBox(height: 16.0),
                             TextFormField( controller: _addressController, decoration: const InputDecoration( labelText: 'Konum (İsteğe bağlı)', hintText: 'Örn: Ankara', prefixIcon: Icon(Icons.location_on_outlined, size: 20) ), textInputAction: TextInputAction.next ),
                             const SizedBox(height: 16.0),
                             const Padding( padding: EdgeInsets.only(top: 16.0, bottom: 8.0), child: Text('Online Profiller', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                             TextFormField( controller: _linkedinController, decoration: const InputDecoration( labelText: 'LinkedIn URL (İsteğe bağlı)', prefixIcon: Icon(Icons.link, size: 20) ), keyboardType: TextInputType.url, textInputAction: TextInputAction.next ),
                             const SizedBox(height: 16.0),
                             TextFormField( controller: _portfolioController, decoration: const InputDecoration( labelText: 'Portfolyo URL (İsteğe bağlı)', prefixIcon: Icon(Icons.public, size: 20) ), keyboardType: TextInputType.url, textInputAction: TextInputAction.done, onFieldSubmitted: (_) => _isLoading ? null : _saveForm() ),
                             const SizedBox(height: 32.0),
                             ElevatedButton(
                                onPressed: _isLoading ? null : _saveForm,
                                child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Kaydet'),
                             ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}