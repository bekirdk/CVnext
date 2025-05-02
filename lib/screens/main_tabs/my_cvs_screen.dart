import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:yeni_cv_uygulamasi/providers/cv_provider.dart';
import 'package:collection/collection.dart';

class MyCvsScreen extends StatefulWidget {
  const MyCvsScreen({super.key});

  @override
  State<MyCvsScreen> createState() => _MyCvsScreenState();
}

class _MyCvsScreenState extends State<MyCvsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<QueryDocumentSnapshot> _cvDocs = [];
  bool _isLoading = true;
  String? _userId;
  String? _selectedCvId;
  Map<String, dynamic>? _selectedCvData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _loadDataBasedOnProvider();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cvProvider = Provider.of<CvProvider>(context);
    final newSelectedCvId = cvProvider.selectedCvId;
    if (newSelectedCvId != _selectedCvId) {
       _selectedCvId = newSelectedCvId;
       _userId = _auth.currentUser?.uid;
       print("MyCvsScreen: Reloading data for CV ID: $_selectedCvId");
       _loadCvs();
    } else if (_isLoading && _selectedCvId == null){
       _handleMissingCvSelection();
    }
  }

  void _loadDataBasedOnProvider() {
     final cvProvider = Provider.of<CvProvider>(context, listen: false);
     _selectedCvId = cvProvider.selectedCvId;
     _userId = _auth.currentUser?.uid;
     _loadCvs();
  }

  void _handleMissingCvSelection(){
     if(mounted) setState(() => _isLoading = false);
     WidgetsBinding.instance.addPostFrameCallback((_) {
         if(mounted) { _showInfoSnackBar('Lütfen önce bir CV seçin veya oluşturun.'); }
       });
  }

  Future<void> _loadCvs() async {
    if (_userId == null || !mounted) { if (mounted) setState(() { _isLoading = false; _cvDocs = []; _selectedCvData = null; }); return; }
    if (!_isLoading) setState(() { _isLoading = true; });

    Map<String, dynamic>? newSelectedCvData;
    List<QueryDocumentSnapshot> newCvDocs = [];

    try {
      final querySnapshot = await _firestore.collection('users').doc(_userId!).collection('cvs').get();
      if (!mounted) return; // Check after await
      newCvDocs = querySnapshot.docs;
      newCvDocs.sort((a, b) { Timestamp? tsA = (a.data() as Map<String, dynamic>?)?['lastUpdated']; Timestamp? tsB = (b.data() as Map<String, dynamic>?)?['lastUpdated']; return (tsB ?? Timestamp(0,0)).compareTo(tsA ?? Timestamp(0,0)); });

      // Get current selected ID from provider again inside async function
      _selectedCvId = Provider.of<CvProvider>(context, listen: false).selectedCvId;

      if (_selectedCvId != null) {
         QueryDocumentSnapshot<Object?>? selectedDocFromList = newCvDocs.firstWhereOrNull((doc) => doc.id == _selectedCvId);
         if (selectedDocFromList != null) {
             newSelectedCvData = selectedDocFromList.data() as Map<String, dynamic>?;
         } else {
             print("Selected CV document ($_selectedCvId) not found in loaded list, clearing selection.");
             _selectedCvId = null;
             WidgetsBinding.instance.addPostFrameCallback((_) { if(mounted) Provider.of<CvProvider>(context, listen: false).clearSelection(); });
         }
      }

      if (mounted) { setState(() { _cvDocs = newCvDocs; _selectedCvData = newSelectedCvData; _isLoading = false; }); }
    } catch (e, s) {
       print("MyCvsScreen yüklenirken HATA: $e");
       print(s);
       if (mounted) { setState(() { _isLoading = false; }); _showErrorSnackBar("CV'ler yüklenirken bir hata oluştu."); }
    }
  }

  Future<void> _deleteCv(QueryDocumentSnapshot doc) async {
    if (_userId == null || !mounted) return;
     final bool? confirmDelete = await showDialog<bool>(
       context: context,
       builder: (context) => AlertDialog( title: const Text('CV\'yi Sil'), content: Text('"${(doc.data() as Map<String,dynamic>?)?['cvName'] ?? 'Bu CV'}" silinecek. Emin misiniz?'), actions: [ TextButton(onPressed: ()=>Navigator.pop(context, false), child: const Text('İptal')), TextButton(onPressed: ()=>Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Sil')) ] )
     );
     if (confirmDelete != true) return;

    setState(() => _isLoading = true);
    try {
       await _firestore.collection('users').doc(_userId!).collection('cvs').doc(doc.id).delete();
       if (context.mounted && Provider.of<CvProvider>(context, listen: false).selectedCvId == doc.id) { Provider.of<CvProvider>(context, listen: false).clearSelection(); }
       await _loadCvs(); // Silme sonrası listeyi yenile
       if(mounted){ _showInfoSnackBar('CV silindi.'); }
    } catch (e) { print("CV silinirken Hata: $e"); if (mounted) { _showErrorSnackBar('CV silinirken hata.'); } }
    finally { if (mounted) { setState(() => _isLoading = false); } }
  }

  void _selectCv(String cvId, String cvName) { Provider.of<CvProvider>(context, listen: false).selectCv(cvId, cvName); }
  void _showSnackBar(String message, {Color backgroundColor = Colors.grey}) { if (!mounted) return; ScaffoldMessenger.of(context).removeCurrentSnackBar(); ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(message), backgroundColor: backgroundColor, duration: const Duration(seconds: 2)) ); }
  void _showErrorSnackBar(String message) { _showSnackBar(message, backgroundColor: Theme.of(context).colorScheme.error); }
  void _showSuccessSnackBar(String message) { _showSnackBar(message, backgroundColor: Colors.green); }
  void _showInfoSnackBar(String message) { _showSnackBar(message, backgroundColor: Colors.orangeAccent); }

  // --- _buildKpiCard FONKSİYON GÖVDESİ EKLENDİ ---
  Widget _buildKpiCard(String title, String value, IconData icon, Color iconColor) {
     return Card(
        elevation: 1,
        shape: Theme.of(context).cardTheme.shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Tema'dan gelen şekil
        color: Theme.of(context).cardTheme.color, // Tema'dan gelen renk
        child: Padding(
           padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center, // Ortala
             children: [
               Icon(icon, size: 28, color: iconColor),
               const SizedBox(height: 8),
               Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
               const SizedBox(height: 4),
               Text(title, style: GoogleFonts.poppins(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)), textAlign: TextAlign.center),
             ],
           ),
        ),
     );
  }
  // --- ---

  @override
  Widget build(BuildContext context) {
    final selectedCvIdFromProvider = context.watch<CvProvider>().selectedCvId;
    final String aiScore = _selectedCvData?['aiScore'] as String? ?? '-';
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final Color secondaryTextColor = onSurfaceColor.withOpacity(0.7);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
         onRefresh: _loadCvs,
         color: primaryColor,
         backgroundColor: Theme.of(context).cardTheme.color,
         child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                 padding: const EdgeInsets.all(16.0),
                 children: [
                    // --- KPI Kartları Çağrıları DOLDURULDU ---
                    Row( children: [
                       Expanded( child: _buildKpiCard( 'AI Skoru\n(Seçili)', aiScore, Icons.star_border_rounded, primaryColor ) ),
                       const SizedBox(width: 12),
                       Expanded( child: _buildKpiCard( 'Toplam CV', _cvDocs.length.toString(), Icons.description_outlined, Colors.green.shade400 ) ),
                       const SizedBox(width: 12),
                       Expanded( child: _buildKpiCard( 'Diğer Stat\n(Yakında)', 'N/A', Icons.analytics_outlined, Colors.orange.shade400 ) )
                    ]),
                    // --- ---
                    const SizedBox(height: 24),
                    Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Text( "CV Belgelerim", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: onSurfaceColor) ), TextButton( onPressed: _loadCvs, child: const Text("Yenile") ) ] ),
                    const SizedBox(height: 8),
                    if (_cvDocs.isEmpty) const Padding( padding: EdgeInsets.symmetric(vertical: 40.0), child: Center(child: Text("Henüz CV oluşturulmamış.\n '+' butonuna basarak başlayın.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))) )
                    else
                      ListView.builder(
                        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                        itemCount: _cvDocs.length,
                        itemBuilder: (context, index) {
                          final cvDoc = _cvDocs[index];
                          final cv = cvDoc.data() as Map<String, dynamic>? ?? {};
                          String cvName = cv['cvName'] ?? 'İsimsiz CV';
                          String lastUpdated = 'Bilinmiyor';
                          if (cv['lastUpdated'] is Timestamp) { lastUpdated = DateFormat('dd/MM/yy HH:mm').format((cv['lastUpdated'] as Timestamp).toDate()); }
                          bool isSelected = cvDoc.id == selectedCvIdFromProvider;
                          return Card(
                             color: isSelected ? primaryColor.withOpacity(0.15) : Theme.of(context).cardTheme.color, margin: const EdgeInsets.symmetric(vertical: 5.0), elevation: isSelected ? 2 : 1,
                             shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(10), side: isSelected ? BorderSide(color: primaryColor, width: 1.5) : BorderSide(color: Colors.grey.shade800) ),
                             child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                leading: Icon(Icons.article_outlined, size: 28, color: isSelected ? primaryColor : secondaryTextColor),
                                title: Text( cvName, style: GoogleFonts.poppins(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 15, color: onSurfaceColor) ),
                                subtitle: Text('Güncelleme: $lastUpdated', style: GoogleFonts.poppins(fontSize: 11, color: secondaryTextColor)),
                                trailing: IconButton( icon: Icon(Icons.delete_outline, size: 20, color: secondaryTextColor), tooltip: 'Sil', onPressed: () => _deleteCv(cvDoc) ),
                                onTap: () => _selectCv(cvDoc.id, cvName),
                             ),
                          );
                        },
                      ),
                     const SizedBox(height: 80),
                 ],
              ),
       ),
    );
  }
}