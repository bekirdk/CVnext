// lib/screens/home_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';

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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isPdfLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final iconList = <IconData>[
    Icons.space_dashboard_rounded, 
    Icons.edit_note_rounded,      
    Icons.flare_rounded, 
    Icons.person_rounded,
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

  String _getTitleForIndex(int index) {
    switch (index) {
      case 0: return 'Gösterge Paneli';
      case 1: return 'CV Düzenle';
      case 2: return 'AI Araçları';
      case 3: return 'Profil';
      default: return 'CVNext';
    }
  }

  Future<void> _createNewCv() async {
    final String? userId = _auth.currentUser?.uid;
    if (userId == null || !mounted) { _showErrorSnackBar('Önce giriş yapmalısınız.'); return; }
    String defaultCvName = "Yeni CV - ${DateFormat('dd/MM/yy HH:mm','tr_TR').format(DateTime.now())}";
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

   void _showSnackBar(String message, {Color backgroundColor = Colors.grey}) { if (!mounted) return; ScaffoldMessenger.of(context).removeCurrentSnackBar(); ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onInverseSurface)), backgroundColor: backgroundColor, duration: const Duration(seconds: 2)) ); }
   void _showErrorSnackBar(String message) { _showSnackBar(message, backgroundColor: Theme.of(context).colorScheme.errorContainer.withOpacity(0.9)); }
   void _showSuccessSnackBar(String message) { _showSnackBar(message, backgroundColor: Colors.green.shade700.withOpacity(0.9)); }
   void _showInfoSnackBar(String message) { _showSnackBar(message, backgroundColor: Colors.blueGrey.shade700.withOpacity(0.9)); }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color iconWellBg = theme.colorScheme.tertiaryContainer; 
    final Color activeIconInWellColor = theme.colorScheme.onTertiaryContainer; 
    final Color inactiveIconColor = theme.bottomNavigationBarTheme.unselectedItemColor ?? theme.colorScheme.onSurfaceVariant.withOpacity(0.7);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitleForIndex(_selectedIndex)),
        actions: [
           _isPdfLoading
           ? Padding( padding: const EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: theme.appBarTheme.actionsIconTheme?.color ?? theme.colorScheme.primary)))
           : IconButton( icon: const Icon(Icons.picture_as_pdf_outlined), tooltip: 'PDF Olarak Dışa Aktar', onPressed: _exportPdf ),
           Builder( builder: (context) => IconButton( icon: const Icon(Icons.menu_rounded), tooltip: 'Menü', onPressed: () => Scaffold.of(context).openEndDrawer() ) ),
        ],
      ),
      endDrawer: const AppDrawer(),
      body: IndexedStack( 
        index: _selectedIndex,
        children: _screens,
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _createNewCv,
        tooltip: 'Yeni CV Oluştur',
        // FAB Stili temadan geliyor (main.dart içinde iconWellBackground ve primaryAppBlue olarak ayarlandı)
        // backgroundColor: iconWellBg, 
        // foregroundColor: activeIconInWellColor,
        // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, size: 28), // Boyut ayarı
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: AnimatedBottomNavigationBar.builder(
        itemCount: iconList.length,
        tabBuilder: (int index, bool isActive) {
          final Color iconColor = isActive ? activeIconInWellColor : inactiveIconColor;
          final double iconSize = isActive ? 26 : 22; 
          
          return Container(
            width: MediaQuery.of(context).size.width / (iconList.length + 1.2), // Genişlik ayarı (FAB için daha fazla yer)
            height: 56, // İkon ve yuvası için toplam yükseklik
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOutSine,
              width: isActive ? 46 : 40,  // Yuva genişliği
              height: isActive ? 46 : 40, // Yuva yüksekliği
              decoration: BoxDecoration(
                color: isActive ? iconWellBg : Colors.transparent,
                shape: BoxShape.circle, // Tam daire
                boxShadow: isActive ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2)
                  )
                ] : null,
              ),
              child: Icon(
                iconList[index],
                size: iconSize,
                color: iconColor,
              ),
            ),
          );
        },
        activeIndex: _selectedIndex,
        gapLocation: GapLocation.center,
        notchSmoothness: NotchSmoothness.softEdge, 
        leftCornerRadius: 0, 
        rightCornerRadius: 0,
        onTap: _onItemTapped,
        backgroundColor: theme.bottomNavigationBarTheme.backgroundColor, 
        shadow: theme.bottomNavigationBarTheme.elevation == 0 ? null : BoxShadow( // Temadan gölge veya özel
          color: Colors.black.withOpacity(0.1),
          offset: const Offset(0, -1),
          blurRadius: 2,
        ),
        height: 60, // Barın genel yüksekliği
      ),
    );
  }
}