import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:yeni_cv_uygulamasi/screens/main_tabs/my_cvs_screen.dart';
import 'package:yeni_cv_uygulamasi/screens/cv_editor_main_screen.dart';
import 'package:yeni_cv_uygulamasi/screens/main_tabs/ai_review_screen.dart';
import 'package:yeni_cv_uygulamasi/screens/main_tabs/profile_screen.dart';
import 'package:yeni_cv_uygulamasi/widgets/app_drawer.dart';
import 'package:yeni_cv_uygulamasi/utils/pdf_generator.dart';
import 'package:yeni_cv_uygulamasi/screens/pdf_preview_screen.dart';
import 'package:provider/provider.dart';
import 'package:yeni_cv_uygulamasi/providers/cv_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // 0: CVlerim, 1: Düzenle, 2: AI, 3: Profil
  bool _isPdfLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const List<Widget> _screens = <Widget>[
    MyCvsScreen(),
    CvEditorMainScreen(),
    AiReviewScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) { // Ortadaki 'Ekle' butonu
      _createNewCv();
      return;
    }
    setState(() {
      // Diğer ikonlar için widget index'ini ayarla
      _selectedIndex = index > 2 ? index - 1 : index; // 0, 1, 3->2, 4->3
    });
  }

  String _getTitleForIndex(int index){
    switch (index) {
      case 0: return 'Gösterge Paneli';
      case 1: return 'CV Düzenle';
      case 2: return 'AI İnceleme';
      case 3: return 'Profil';
      default: return 'AI CV Builder';
    }
  }

  Future<void> _createNewCv() async {
    final String? userId = _auth.currentUser?.uid;
    if (userId == null || !mounted) { _showErrorSnackBar('Önce giriş yapmalısınız.'); return; }
    String defaultCvName = "Yeni CV - ${DateFormat('dd/MM/yy HH:mm').format(DateTime.now())}";
    final TextEditingController nameController = TextEditingController(text: defaultCvName);
    final String? chosenName = await showDialog<String>( context: context, builder: (context) => AlertDialog( title: const Text("Yeni CV Adı"), content: TextField( controller: nameController, decoration: const InputDecoration(hintText: "CV için bir isim girin"), autofocus: true ), actions: [ TextButton(onPressed: ()=> Navigator.pop(context), child: const Text("İptal")), TextButton(onPressed: ()=> Navigator.pop(context, nameController.text.trim()), child: const Text("Oluştur")) ] ) );
    if (chosenName == null || chosenName.isEmpty) return;
    final String cvName = chosenName;
    _showInfoSnackBar('"$cvName" oluşturuluyor...');
    try {
        final newDocRef = await _firestore.collection('users').doc(userId).collection('cvs').add({ 'cvName': cvName, 'createdAt': FieldValue.serverTimestamp(), 'lastUpdated': FieldValue.serverTimestamp(), 'personalInfo': {'email': _auth.currentUser?.email ?? ''}, 'summary': '', 'skills': {}, 'experiences': [], 'education': [], 'projects': [] });
        if (mounted) { Provider.of<CvProvider>(context, listen: false).selectCv(newDocRef.id, cvName); setState(() { _selectedIndex = 0; }); _showSuccessSnackBar('"$cvName" oluşturuldu.'); }
    } catch (e) { if (mounted) { _showErrorSnackBar('CV oluşturulurken hata.'); } }
  }

  Future<void> _exportPdf() async {
     if (!mounted) return;
     final selectedCvId = Provider.of<CvProvider>(context, listen: false).selectedCvId;
     final userId = _auth.currentUser?.uid;
     if (userId == null || selectedCvId == null) { _showInfoSnackBar('Lütfen önce dışa aktarılacak bir CV seçin.'); return; }
     final PdfTemplate? selectedTemplate = await showDialog<PdfTemplate>( context: context, builder: (BuildContext context) { return SimpleDialog( title: const Text('CV Şablonu Seçin'), children: <Widget>[ SimpleDialogOption( onPressed: () { Navigator.pop(context, PdfTemplate.template1); }, child: const Text('Şablon 1: Standart Dikey') ), SimpleDialogOption( onPressed: () { Navigator.pop(context, PdfTemplate.template2); }, child: const Text('Şablon 2: İki Kolonlu (Basit)') ) ] ); } );
     if (selectedTemplate == null) return;
     setState(() => _isPdfLoading = true);
     final pdfGenerator = PdfGenerator();
     final Uint8List? pdfBytes = await pdfGenerator.generateCvPdf(userId, selectedCvId, selectedTemplate);
     if (!mounted) { setState(() => _isPdfLoading = false); return; }
     setState(() => _isPdfLoading = false);
     if (pdfBytes != null) { Navigator.push( context, MaterialPageRoute( builder: (_) => PdfPreviewScreen(pdfBytes: pdfBytes) ) ); }
     else { _showErrorSnackBar('PDF oluşturulamadı (Veri eksik veya hata oluştu).'); }
   }

   void _showSnackBar(String message, {Color backgroundColor = Colors.grey}) { if (!mounted) return; ScaffoldMessenger.of(context).removeCurrentSnackBar(); ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(message), backgroundColor: backgroundColor, duration: const Duration(seconds: 2)) ); }
   void _showErrorSnackBar(String message) { _showSnackBar(message, backgroundColor: Theme.of(context).colorScheme.error); }
   void _showSuccessSnackBar(String message) { _showSnackBar(message, backgroundColor: Colors.green); }
   void _showInfoSnackBar(String message) { _showSnackBar(message, backgroundColor: Colors.orangeAccent); }


  @override
  Widget build(BuildContext context) {
    // Aktif olan alt bar ikonunun index'ini hesapla (0, 1, _, 2, 3)
    int bottomNavIndex = _selectedIndex >= 2 ? _selectedIndex + 1 : _selectedIndex;

    return Scaffold(
      appBar: AppBar(
        // AppBar stilini temadan alıyor olmalı (main.dart'ta tanımlandı)
        title: Text(_getTitleForIndex(_selectedIndex)),
        // flexibleSpace (arka plan resmi) kaldırıldı
        actions: [
           _isPdfLoading
           ? const Padding( padding: EdgeInsets.symmetric(horizontal: 16.0), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))) )
           : IconButton( icon: const Icon(Icons.picture_as_pdf_outlined), tooltip: 'PDF Olarak Dışa Aktar/Önizle', onPressed: _exportPdf ),
           Builder( builder: (context) => IconButton( icon: const Icon(Icons.menu_rounded), tooltip: 'Menü', onPressed: () => Scaffold.of(context).openEndDrawer() ) ),
        ],
      ),
      endDrawer: const AppDrawer(), // Yan menü
      body: Center(
        child: _screens.elementAt(_selectedIndex), // Doğru ekranı gösterir
      ),
      // BottomNavigationBar (kj.jpg stili - Tema'dan stil alır)
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem( icon: Icon(Icons.dashboard_outlined), label: 'Dashboard', activeIcon: Icon(Icons.dashboard) ),
          BottomNavigationBarItem( icon: Icon(Icons.edit_outlined), label: 'Düzenle', activeIcon: Icon(Icons.edit) ),
          BottomNavigationBarItem( icon: Icon(Icons.add_circle_outline), label: 'Yeni Ekle', activeIcon: Icon(Icons.add_circle)),
          BottomNavigationBarItem( icon: Icon(Icons.auto_awesome_outlined), label: 'AI', activeIcon: Icon(Icons.auto_awesome) ),
          BottomNavigationBarItem( icon: Icon(Icons.person_outlined), label: 'Profil', activeIcon: Icon(Icons.person) ),
        ],
        currentIndex: bottomNavIndex,
        onTap: _onItemTapped,
        // Stil özellikleri main.dart'taki ThemeData -> bottomNavigationBarTheme'den gelir
        // Burada tekrar belirtmeye gerek yok ama istersen override edebilirsin:
        // type: BottomNavigationBarType.fixed,
        // backgroundColor: Colors.white,
        // selectedItemColor: Theme.of(context).primaryColor,
        // unselectedItemColor: Colors.grey.shade500,
        // showSelectedLabels: false,
        // showUnselectedLabels: false,
      ),
    );
  }
}