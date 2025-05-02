import 'dart:typed_data'; // PDF için
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart'; // Paket importu

// Ekran Importları
import 'package:yeni_cv_uygulamasi/screens/main_tabs/my_cvs_screen.dart';
import 'package:yeni_cv_uygulamasi/screens/cv_editor_main_screen.dart';
import 'package:yeni_cv_uygulamasi/screens/main_tabs/ai_review_screen.dart';
import 'package:yeni_cv_uygulamasi/screens/main_tabs/profile_screen.dart';
import 'package:yeni_cv_uygulamasi/widgets/app_drawer.dart';
import 'package:yeni_cv_uygulamasi/utils/pdf_generator.dart';
import 'package:yeni_cv_uygulamasi/screens/pdf_preview_screen.dart';
import 'package:yeni_cv_uygulamasi/providers/cv_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isPdfLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final iconList = <IconData>[
    Icons.dashboard_outlined,
    Icons.edit_outlined,
    Icons.auto_awesome_outlined,
    Icons.person_outlined,
  ];

  static const List<Widget> _screens = <Widget>[
    MyCvsScreen(),
    CvEditorMainScreen(),
    AiReviewScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
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

  // --- Diğer Fonksiyonlar (Değişiklik Yok) ---
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
  // --- Diğer Fonksiyonlar Sonu ---


  @override
  Widget build(BuildContext context) {
    // Tema renklerini alalım
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color activeColor = primaryColor;
    final Color inactiveColor = Theme.of(context).bottomNavigationBarTheme.unselectedItemColor ?? Colors.grey.shade500;
    final Color fabBackgroundColor = primaryColor;
    final Color barBackgroundColor = Theme.of(context).bottomNavigationBarTheme.backgroundColor ?? Theme.of(context).colorScheme.surface;
    final Color fabIconColor = Theme.of(context).colorScheme.onPrimary;


    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitleForIndex(_selectedIndex)),
        actions: [
           _isPdfLoading
           ? const Padding( padding: EdgeInsets.symmetric(horizontal: 16.0), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))) )
           : IconButton( icon: const Icon(Icons.picture_as_pdf_outlined), tooltip: 'PDF Olarak Dışa Aktar/Önizle', onPressed: _exportPdf ),
           Builder( builder: (context) => IconButton( icon: const Icon(Icons.menu_rounded), tooltip: 'Menü', onPressed: () => Scaffold.of(context).openEndDrawer() ) ),
        ],
      ),
      endDrawer: const AppDrawer(),
      body: Center(
        child: _screens.elementAt(_selectedIndex),
      ),

      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: fabBackgroundColor,
        foregroundColor: fabIconColor,
        onPressed: _createNewCv,
        tooltip: 'Yeni CV Oluştur',
        elevation: 2.0,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // *** AnimatedBottomNavigationBar (Hata Düzeltildi) ***
      bottomNavigationBar: AnimatedBottomNavigationBar(
        icons: iconList,
        activeIndex: _selectedIndex,
        gapLocation: GapLocation.center,
        notchSmoothness: NotchSmoothness.softEdge,
        leftCornerRadius: 32,
        rightCornerRadius: 32,
        onTap: _onItemTapped,

        // Stil Ayarları
        backgroundColor: barBackgroundColor,
        activeColor: activeColor,
        inactiveColor: inactiveColor,
        iconSize: 24,
        // height: 60, // Opsiyonel

        // Gölge
        shadow: BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 8,
        ),

        // !! KALDIRILDI: animationDuration: const Duration(milliseconds: 300),
        // !! KALDIRILDI: animationCurve: Curves.easeInOut,
      ),
    );
  }
}