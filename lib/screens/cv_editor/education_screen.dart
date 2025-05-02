import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart'; // Provider import
import 'package:yeni_cv_uygulamasi/providers/cv_provider.dart'; // CvProvider import
import 'add_edit_education_screen.dart'; // Ekleme/Düzenleme ekranı
// import 'package:intl/intl.dart'; // Tarih formatı için (ListTile içinde kullanılabilir)

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _educationList = []; // Veriyi Map listesi olarak tutacağız
  bool _isLoading = true;
  String? _userId;
  String? _selectedCvId; // Seçili CV ID'si

  @override
  void initState() {
    super.initState();
    // İlk yükleme için didChangeDependencies'i bekle
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cvProvider = Provider.of<CvProvider>(context);
    final newSelectedCvId = cvProvider.selectedCvId;

    // Seçili CV değiştiyse veya ilk yükleme ise veriyi yükle
    // _isLoading kontrolü ekleyerek gereksiz yüklemeleri önleyebiliriz.
    if (newSelectedCvId != _selectedCvId) {
       _selectedCvId = newSelectedCvId;
       _userId = _auth.currentUser?.uid;
       print("EducationScreen: Loading data for CV ID: $_selectedCvId");
       _loadEducation();
    } else if (_isLoading && _selectedCvId == null){
      // Eğer hala yükleniyorsa ve CV ID null ise (ilk açılışta olabilir)
      // Kullanıcıya mesaj göster
       _handleMissingCvSelection();
    }
  }

  void _handleMissingCvSelection(){
     if(mounted) setState(() => _isLoading = false);
     WidgetsBinding.instance.addPostFrameCallback((_) {
         if(mounted) {
           _showInfoSnackBar('Lütfen önce bir CV seçin veya oluşturun.');
         }
       });
  }

  Future<void> _loadEducation() async {
    if (_userId == null || _selectedCvId == null) {
       if (mounted) setState(() { _educationList = []; _isLoading = false; });
       print("Eğitim yüklenemedi: Kullanıcı veya CV seçili değil.");
       return;
    }
    if (mounted) setState(() { _isLoading = true; });

    try {
      final DocumentSnapshot cvDocSnapshot = await _firestore
          .collection('users').doc(_userId)
          .collection('cvs').doc(_selectedCvId)
          .get();

      if (mounted) {
        List<Map<String, dynamic>> loadedEducation = [];
        if (cvDocSnapshot.exists && (cvDocSnapshot.data() as Map).containsKey('education')) {
          final List<dynamic> rawList = cvDocSnapshot.get('education');
          loadedEducation = List<Map<String, dynamic>>.from(
            rawList.map((item) => Map<String, dynamic>.from(item as Map))
          );
          print("Loaded ${loadedEducation.length} education entries.");
        } else {
           print("No 'education' field found or document doesn't exist.");
        }
        setState(() {
          _educationList = loadedEducation;
          _isLoading = false;
        });
      }
    } catch (e) {
       print("Eğitim bilgileri yüklenirken hata: $e");
        if (mounted) setState(() { _isLoading = false; });
       _showErrorSnackBar('Eğitim bilgileri yüklenirken bir hata oluştu.');
    }
    // finally bloğuna gerek yok, setState zaten isLoading'i false yapıyor
  }

  Future<void> _navigateToAddEducation() async {
    if (_userId == null || _selectedCvId == null || !mounted) { _showErrorSnackBar('İşlem için önce CV seçmelisiniz.'); return; }

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const AddEditEducationScreen()),
    );

    if (result != null && result.containsKey('data') && mounted) {
       await _addEducationToFirestore(result['data']);
    }
  }

  Future<void> _addEducationToFirestore(Map<String, dynamic> newData) async {
     if (_userId == null || _selectedCvId == null || !mounted) return;
     setState(() { _isLoading = true; });
     try {
       newData['id'] = _firestore.collection('_').doc().id; // Unique ID ekle
       newData['addedAt'] = FieldValue.serverTimestamp();

       await _firestore.collection('users').doc(_userId).collection('cvs').doc(_selectedCvId).update({
             'education': FieldValue.arrayUnion([newData]), // education listesine ekle
             'lastUpdated': FieldValue.serverTimestamp()
           });

       if (mounted) {
         setState(() { _educationList.insert(0, newData); }); // Başa ekle (varsayım)
         await _loadEducation(); // Firestore'dan güncel listeyi çekmek daha garanti
         _showSuccessSnackBar('Eğitim bilgisi başarıyla eklendi.');
       }
     } catch (e) { print("Eğitim eklenirken Firestore Hatası: $e"); _showErrorSnackBar('Eğitim eklenirken bir hata oluştu.'); }
     finally { if (mounted) { setState(() { _isLoading = false; }); } }
  }

  Future<void> _deleteEducation(Map<String, dynamic> educationToDelete) async {
    if (_userId == null || _selectedCvId == null || !mounted) return;

     final bool? confirmDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
           title: const Text('Eğitimi Sil'),
           content: Text('"${educationToDelete['institutionName'] ?? 'Bu'}" eğitim bilgisini silmek istediğinizden emin misiniz?'),
           actions: [
              TextButton(onPressed: ()=>Navigator.pop(context, false), child: const Text('İptal')),
              TextButton(onPressed: ()=>Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Sil')),
           ],
        )
     );
     if (confirmDelete != true) return;

    setState(() => _isLoading = true);
    try {
       await _firestore.collection('users').doc(_userId).collection('cvs').doc(_selectedCvId).update({
             'education': FieldValue.arrayRemove([educationToDelete]), // education listesinden çıkar
             'lastUpdated': FieldValue.serverTimestamp()
           });
        if(mounted){
           await _loadEducation(); // Tekrar yükle
           _showInfoSnackBar('Eğitim bilgisi silindi.');
        }
    } catch (e) { print("Eğitim silinirken Firestore Hatası: $e"); _showErrorSnackBar('Eğitim silinirken bir hata oluştu.'); }
    finally { if (mounted) { setState(() => _isLoading = false); } }
  }

  void _navigateToEditEducation(Map<String, dynamic> educationData) {
    _showInfoSnackBar('Düzenleme özelliği yakında eklenecek.');
     // TODO: Implement Edit Logic for Arrays
     // Navigator.push... AddEditEducationScreen(initialData: ...)
     // Gelen sonuca göre _updateEducationInFirestore çağır
  }
  // Future<void> _updateEducationInFirestore(...) async { /* ... */ }

  void _showSnackBar(String message, {Color backgroundColor = Colors.grey}) {
     if (!mounted) return;
     ScaffoldMessenger.of(context).removeCurrentSnackBar();
     ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(message), backgroundColor: backgroundColor, duration: const Duration(seconds: 2)) );
  }
  void _showErrorSnackBar(String message) { _showSnackBar(message, backgroundColor: Colors.red); }
  void _showSuccessSnackBar(String message) { _showSnackBar(message, backgroundColor: Colors.green); }
  void _showInfoSnackBar(String message) { _showSnackBar(message, backgroundColor: Colors.orange); }

  @override
  Widget build(BuildContext context) {
     if (_isLoading) { return Scaffold(appBar: AppBar(title: const Text("Eğitim Bilgileri")), body: const Center(child: CircularProgressIndicator())); }
     if (_selectedCvId == null) { return Scaffold(appBar: AppBar(title: const Text("Eğitim Bilgileri")), body: const Center(child: Text("Lütfen önce bir CV seçin."))); }

    return Scaffold(
      appBar: AppBar(
        title: Text('Eğitim Bilgileri', style: GoogleFonts.poppins()),
      ),
      body: RefreshIndicator(
         onRefresh: _loadEducation,
         child: _educationList.isEmpty
                ? LayoutBuilder(
                     builder: (context, constraints) => SingleChildScrollView(
                       physics: const AlwaysScrollableScrollPhysics(),
                       child: ConstrainedBox(
                         constraints: BoxConstraints(minHeight: constraints.maxHeight),
                         child: Center(
                             child: Column(
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                 Icon(Icons.school_outlined, size: 60, color: Colors.grey.shade400),
                                 const SizedBox(height: 16),
                                 const Text('Henüz eğitim bilgisi eklenmemiş.'),
                                 const SizedBox(height: 16),
                                 ElevatedButton.icon( icon: const Icon(Icons.add), label: const Text('İlk Eğitimi Ekle'), onPressed: _navigateToAddEducation ),
                               ],
                             ),
                           ),
                       ),
                     ),
                   )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80.0),
                    itemCount: _educationList.length,
                    itemBuilder: (context, index) {
                      final education = _educationList[index];
                      final String endDate = (education['isCurrent'] ?? false)
                                            ? 'Devam Ediyor'
                                            : (education['endDate']?.isNotEmpty == true ? education['endDate'] : '?');
                      final String dateRange = '${education['startDate'] ?? '?'} - $endDate';

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                           contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          title: Text(
                            education['degree'] ?? 'Derece Yok',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(education['institutionName'] ?? 'Okul Adı Yok'),
                               if (education['fieldOfStudy'] != null && (education['fieldOfStudy'] as String).isNotEmpty)
                                Padding( padding: const EdgeInsets.only(top: 2.0), child: Text( education['fieldOfStudy'], style: Theme.of(context).textTheme.bodySmall) ),
                              const SizedBox(height: 4),
                              Text( dateRange, style: Theme.of(context).textTheme.bodySmall ),
                              if (education['description'] != null && (education['description'] as String).isNotEmpty)
                               Padding( padding: const EdgeInsets.only(top: 6.0), child: Text( education['description'], maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall) ),
                            ],
                          ),
                           isThreeLine: true,
                           trailing: Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                                IconButton( icon: Icon(Icons.edit_outlined, size: 20, color: Theme.of(context).primaryColor.withOpacity(0.5)), tooltip: 'Düzenle (Yakında)', onPressed: () => _navigateToEditEducation(education) ),
                                IconButton( icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade700), tooltip: 'Sil', onPressed: () => _deleteEducation(education) ), // Map'i gönder
                             ],
                           ),
                          onTap: () => _navigateToEditEducation(education),
                        ),
                      );
                    },
                  ),
       ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Eğitim Ekle'),
        onPressed: _navigateToAddEducation,
      ),
    );
  }
}