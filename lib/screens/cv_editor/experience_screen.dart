import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:yeni_cv_uygulamasi/providers/cv_provider.dart';
import 'add_edit_experience_screen.dart';
import 'package:intl/intl.dart'; // Silme dialogu için tarih formatı

class ExperienceScreen extends StatefulWidget {
  const ExperienceScreen({super.key});

  @override
  State<ExperienceScreen> createState() => _ExperienceScreenState();
}

class _ExperienceScreenState extends State<ExperienceScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _experiences = [];
  bool _isLoading = true;
  String? _userId;
  String? _selectedCvId;

  @override
  void initState() {
    super.initState();
    // İlk yükleme didChangeDependencies'de tetiklenecek
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
      print("ExperienceScreen: Reloading data for CV ID: $_selectedCvId");
      _loadExperiences();
    } else if (_isLoading && _selectedCvId == null) {
      _handleMissingCvSelection();
    }
  }

  void _loadDataBasedOnProvider() {
    final cvProvider = Provider.of<CvProvider>(context, listen: false);
    _selectedCvId = cvProvider.selectedCvId;
    _userId = _auth.currentUser?.uid;
    _loadExperiences();
  }

  void _handleMissingCvSelection() {
    if (mounted) setState(() => _isLoading = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showInfoSnackBar('Lütfen önce bir CV seçin veya oluşturun.');
      }
    });
  }

  Future<void> _loadExperiences() async {
    if (!mounted) return;
    if (_userId == null || _selectedCvId == null) {
      setState(() { _experiences = []; _isLoading = false; });
      print("Deneyim yüklenemedi: Kullanıcı veya CV seçili değil.");
      // Gerekirse _handleMissingCvSelection çağrılabilir ama didChangeDependencies hallediyor olmalı
      return;
    }
    setState(() { _isLoading = true; });
    try {
      final DocumentSnapshot cvDocSnapshot = await _firestore.collection('users').doc(_userId).collection('cvs').doc(_selectedCvId).get();
      if (mounted) {
        List<Map<String, dynamic>> loadedExperiences = [];
        if (cvDocSnapshot.exists && (cvDocSnapshot.data() as Map).containsKey('experiences')) {
          final List<dynamic> rawList = cvDocSnapshot.get('experiences');
          loadedExperiences = List<Map<String, dynamic>>.from( rawList.map((item) => Map<String, dynamic>.from(item as Map)) );
          // Deneyimleri sırala (varsa 'startDate' veya 'addedAt' göre)
          // Örnek: Başlangıç tarihine göre (string olduğu için basit sıralama, daha iyisi Timestamp kullanmak)
          loadedExperiences.sort((a, b) {
             // Daha iyi sıralama için tarihleri parse etmek gerekebilir
             String dateA = a['startDate'] ?? '';
             String dateB = b['startDate'] ?? '';
             // Veya 'addedAt' Timestamp'ına göre:
             // Timestamp tsA = a['addedAt'] ?? Timestamp(0,0);
             // Timestamp tsB = b['addedAt'] ?? Timestamp(0,0);
             // return tsB.compareTo(tsA); // En yeni başa
             return dateB.compareTo(dateA); // Basit string karşılaştırması (hatalı olabilir)
          });
        }
        setState(() { _experiences = loadedExperiences; });
      }
    } catch (e) {
      print("Deneyimler yüklenirken hata: $e");
      _showErrorSnackBar('Deneyimler yüklenirken bir hata oluştu.');
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _navigateToAddExperience() async {
    if (_userId == null || _selectedCvId == null || !mounted) { _showErrorSnackBar('İşlem için önce CV seçmelisiniz.'); return; }
    final result = await Navigator.push<Map<String, dynamic>>( context, MaterialPageRoute(builder: (context) => const AddEditExperienceScreen()));
    if (result != null && result.containsKey('data') && mounted) { await _addExperienceToFirestore(result['data']); }
  }

  Future<void> _addExperienceToFirestore(Map<String, dynamic> newData) async {
    if (_userId == null || _selectedCvId == null || !mounted) return;
    setState(() { _isLoading = true; });
    try {
      newData['id'] = _firestore.collection('_').doc().id; // Benzersiz ID
      newData['addedAt'] = FieldValue.serverTimestamp(); // Ekleme zamanı
      await _firestore.collection('users').doc(_userId).collection('cvs').doc(_selectedCvId).update({
            'experiences': FieldValue.arrayUnion([newData]), 'lastUpdated': FieldValue.serverTimestamp() });
      if (mounted) {
        await _loadExperiences(); // Ekleme sonrası listeyi yenile
        _showSuccessSnackBar('Deneyim başarıyla eklendi.');
      }
    } catch (e) { print("Deneyim eklenirken Firestore Hatası: $e"); _showErrorSnackBar('Deneyim eklenirken bir hata oluştu.'); }
    finally { if (mounted) { setState(() { _isLoading = false; }); } }
  }

  // *** YENİ/GÜNCELLENMİŞ Fonksiyon: Düzenlemeye Git ***
  void _navigateToEditExperience(Map<String, dynamic> experienceData) {
    if (_userId == null || _selectedCvId == null || !mounted) {
      _showErrorSnackBar('İşlem için önce CV seçmelisiniz.');
      return;
    }
    final String? experienceId = experienceData['id'] as String?;
    if (experienceId == null) {
       _showErrorSnackBar('Düzenlenecek deneyimin kimliği bulunamadı.');
       return;
    }

    Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditExperienceScreen(
          initialData: experienceData,
          experienceId: experienceId,
        ),
      ),
    ).then((result) {
      // Düzenleme ekranından geri dönüldüğünde
      if (result != null && result.containsKey('data') && result.containsKey('experienceId') && mounted) {
        final String returnedExperienceId = result['experienceId'];
        final Map<String, dynamic> updatedData = result['data'];

        // Orijinal (eski) veriyi bulmak için lokal listeyi kullanabiliriz
        // VEYA Firestore'dan çekip sonra güncelleme yapabiliriz.
        // Şimdilik eski veriyi de fonksiyona gönderelim (opsiyonel)
        final Map<String, dynamic>? oldData = _experiences.firstWhere(
              (exp) => exp['id'] == returnedExperienceId,
              orElse: () => experienceData // Bulunamazsa ilk gönderilen veriyi kullan (nadiren olmalı)
           );

        _updateExperienceInFirestore(returnedExperienceId, updatedData, oldData); // Yeni fonksiyonu çağır
      }
    });
  }

  // *** YENİ Fonksiyon: Firestore'da Güncelleme ***
  Future<void> _updateExperienceInFirestore(String experienceId, Map<String, dynamic> updatedData, Map<String, dynamic>? oldData) async {
     if (_userId == null || _selectedCvId == null || !mounted) return;
     if (oldData == null) { _showErrorSnackBar('Güncellenecek eski veri bulunamadı!'); return; }

     setState(() => _isLoading = true);
     try {
         // Önce eski veriyi sil, sonra yeni veriyi ekle (arrayUpdate olmadığı için)
         await _firestore.collection('users').doc(_userId).collection('cvs').doc(_selectedCvId).update({
           'experiences': FieldValue.arrayRemove([oldData]),
         });
         // Not: 'id' ve 'addedAt' alanlarının güncellenen veride korunmuş olması önemli
         await _firestore.collection('users').doc(_userId).collection('cvs').doc(_selectedCvId).update({
           'experiences': FieldValue.arrayUnion([updatedData]),
           'lastUpdated': FieldValue.serverTimestamp(),
         });

         if (mounted) {
           await _loadExperiences(); // Listeyi yenile
           _showSuccessSnackBar('Deneyim başarıyla güncellendi.');
         }
     } catch (e) {
       print("Deneyim güncellenirken Firestore Hatası: $e");
       _showErrorSnackBar('Deneyim güncellenirken bir hata oluştu.');
       // Hata durumunda eski veriyi geri eklemeyi deneyebiliriz (karmaşıklaşır)
     } finally {
       if (mounted) setState(() => _isLoading = false);
     }
  }

  Future<void> _deleteExperience(Map<String, dynamic> experienceToDelete) async {
    if (_userId == null || _selectedCvId == null || !mounted) return;
    final bool? confirmDelete = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Deneyimi Sil'),
            content: Text('"${experienceToDelete['jobTitle'] ?? 'Bu'}" deneyimini silmek istediğinizden emin misiniz?'),
            actions: <Widget>[
              TextButton( onPressed: () { Navigator.of(context).pop(false); }, child: const Text('İptal') ),
              TextButton( style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Sil'), onPressed: () { Navigator.of(context).pop(true); } ),
            ],
          );
        },
    );
    if (confirmDelete != true) return;
    setState(() => _isLoading = true);
    try {
      // Silinecek öğenin Firestore'daki tam halini bulmak önemli (timestamp vb. için)
      // Ancak ID'si varsa ve ID'ye göre silme yapıyorsak, arrayRemove'a sadece ID'li map vermek yeterli olabilir.
      // Emin olmak için, silmeden önce Firestore'dan tekrar okuyup tam eşleşen map'i bulmak daha güvenli olabilir.
      // Şimdilik elimizdeki Map ile deniyoruz:
       await _firestore.collection('users').doc(_userId).collection('cvs').doc(_selectedCvId).update({
             'experiences': FieldValue.arrayRemove([experienceToDelete]), 'lastUpdated': FieldValue.serverTimestamp() });
        if(mounted){
           await _loadExperiences();
           _showInfoSnackBar('Deneyim silindi.');
        }
    } catch (e) { print("Deneyim silinirken Firestore Hatası: $e"); _showErrorSnackBar('Deneyim silinirken bir hata oluştu.'); }
    finally { if (mounted) { setState(() => _isLoading = false); } }
  }

  void _showSnackBar(String message, {Color backgroundColor = Colors.grey}) {
     if (!mounted) return;
     ScaffoldMessenger.of(context).removeCurrentSnackBar();
     ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(message), backgroundColor: backgroundColor, duration: const Duration(seconds: 2)) );
  }
  void _showErrorSnackBar(String message) { _showSnackBar(message, backgroundColor: Theme.of(context).colorScheme.error); }
  void _showSuccessSnackBar(String message) { _showSnackBar(message, backgroundColor: Colors.green); }
  void _showInfoSnackBar(String message) { _showSnackBar(message, backgroundColor: Colors.orangeAccent); }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(appBar: AppBar(title: const Text("İş Deneyimi")), body: const Center(child: CircularProgressIndicator()));
    }
    if (_selectedCvId == null) {
      return Scaffold(appBar: AppBar(title: const Text("İş Deneyimi")), body: const Center(child: Text("Lütfen önce bir CV seçin.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('İş Deneyimi', style: GoogleFonts.poppins()),
      ),
      body: RefreshIndicator(
        onRefresh: _loadExperiences,
        child: _experiences.isEmpty
            ? LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.work_history_outlined, size: 60, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text('Henüz iş deneyimi eklenmemiş.'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon( icon: const Icon(Icons.add), label: const Text('İlk Deneyimi Ekle'), onPressed: _navigateToAddExperience ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 80.0),
                itemCount: _experiences.length,
                itemBuilder: (context, index) {
                  final experience = _experiences[index];
                  final String endDate = (experience['isCurrentJob'] ?? false) ? 'Halen' : (experience['endDate']?.isNotEmpty == true ? experience['endDate'] : '?');
                  final String dateRange = '${experience['startDate'] ?? '?'} - $endDate';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      title: Text( experience['jobTitle'] ?? 'Başlık Yok', style: const TextStyle(fontWeight: FontWeight.w600) ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(experience['companyName'] ?? 'Şirket Yok'),
                          if (experience['location'] != null && (experience['location'] as String).isNotEmpty)
                            Padding( padding: const EdgeInsets.only(top: 2.0), child: Text( experience['location'], style: Theme.of(context).textTheme.bodySmall)),
                          const SizedBox(height: 4),
                          Text( dateRange, style: Theme.of(context).textTheme.bodySmall),
                          if (experience['description'] != null && (experience['description'] as String).isNotEmpty)
                            Padding( padding: const EdgeInsets.only(top: 6.0), child: Text( experience['description'], maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall)),
                        ],
                      ),
                      isThreeLine: (experience['description'] != null && (experience['description'] as String).isNotEmpty) || (experience['location'] != null && (experience['location'] as String).isNotEmpty),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           // *** GÜNCELLENDİ: Edit IconButton ***
                           IconButton(
                              icon: Icon(Icons.edit_outlined, size: 20, color: Theme.of(context).primaryColor), // Daha belirgin ikon
                              tooltip: 'Düzenle',
                              onPressed: () => _navigateToEditExperience(experience) // Artık düzenlemeye gidiyor
                           ),
                           IconButton( icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade700), tooltip: 'Sil', onPressed: () => _deleteExperience(experience) ),
                        ],
                      ),
                      onTap: () => _navigateToEditExperience(experience), // Tıklayınca da düzenlemeye git
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Deneyim Ekle'),
        onPressed: _navigateToAddExperience,
      ),
    );
  }
}