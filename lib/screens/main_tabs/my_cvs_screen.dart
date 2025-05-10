// lib/screens/main_tabs/my_cvs_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:yeni_cv_uygulamasi/providers/cv_provider.dart';
import 'package:collection/collection.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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
    _userId = _auth.currentUser?.uid;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadDataBasedOnProvider();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cvProvider = Provider.of<CvProvider>(context);
    final newSelectedCvIdFromProvider = cvProvider.selectedCvId;

    if (newSelectedCvIdFromProvider != _selectedCvId) {
      setState(() {
        _selectedCvId = newSelectedCvIdFromProvider;
        _userId = _auth.currentUser?.uid;
        print("MyCvsScreen (didChangeDependencies): CV ID Değişti (Provider'dan): $_selectedCvId");
        _isLoading = true;
      });
      _loadCvs();
    } else if (_isLoading && _selectedCvId == null && _userId == null) { 
      _handleMissingUserSession();
    }
  }

  void _loadDataBasedOnProvider() {
    final cvProvider = Provider.of<CvProvider>(context, listen: false);
    setState(() {
      _selectedCvId = cvProvider.selectedCvId;
      _userId = _auth.currentUser?.uid;
      _isLoading = true;
    });
    if (_userId == null) {
      _handleMissingUserSession();
      return;
    }
    _loadCvs();
  }

  void _handleMissingUserSession() {
    if (mounted) {
      setState(() => _isLoading = false);
      _showInfoSnackBar("CV'leri görmek için lütfen giriş yapın.");
    }
  }

  void _handleMissingCvSelection() {
    if (mounted) {
      setState(() => _isLoading = false);
      _showInfoSnackBar('Lütfen önce bir CV seçin veya oluşturun.');
    }
  }

  Future<void> _loadCvs() async {
    if (!mounted) return;
    if (_userId == null) {
      setState(() { _isLoading = false; _cvDocs = []; _selectedCvData = null; });
      print("MyCvsScreen: Kullanıcı ID'si null, CV'ler yüklenemiyor.");
      return;
    }

    Map<String, dynamic>? newSelectedCvDataLocal;
    List<QueryDocumentSnapshot> newCvDocs = [];

    try {
      print("MyCvsScreen: _loadCvs başlatılıyor. UserID: $_userId, SelectedCvID (lokal): $_selectedCvId");
      final querySnapshot = await _firestore.collection('users').doc(_userId!).collection('cvs').get();
      if (!mounted) return;
      newCvDocs = querySnapshot.docs;

      newCvDocs.sort((a, b) {
        dynamic dataA = a.data();
        Timestamp tsA = Timestamp(0, 0);
        if (dataA is Map<String, dynamic> && dataA['lastUpdated'] is Timestamp) { tsA = dataA['lastUpdated']; }
        else if (dataA is Map<String, dynamic> && dataA['createdAt'] is Timestamp) { tsA = dataA['createdAt']; }

        dynamic dataB = b.data();
        Timestamp tsB = Timestamp(0, 0);
        if (dataB is Map<String, dynamic> && dataB['lastUpdated'] is Timestamp) { tsB = dataB['lastUpdated']; }
        else if (dataB is Map<String, dynamic> && dataB['createdAt'] is Timestamp) { tsB = dataB['createdAt']; }
        return tsB.compareTo(tsA);
      });

      final currentSelectedCvIdFromProvider = Provider.of<CvProvider>(context, listen: false).selectedCvId;
      print("MyCvsScreen: _loadCvs içinde Provider'dan alınan CV ID: $currentSelectedCvIdFromProvider");

      if (currentSelectedCvIdFromProvider != null) {
        QueryDocumentSnapshot<Object?>? selectedDocFromList = newCvDocs.firstWhereOrNull((doc) => doc.id == currentSelectedCvIdFromProvider);
        if (selectedDocFromList != null) {
          newSelectedCvDataLocal = selectedDocFromList.data() as Map<String, dynamic>?;
          print("MyCvsScreen: Seçili CV verisi yüklendi: ${newSelectedCvDataLocal?['cvName']}");
        } else {
          print("MyCvsScreen: Seçili CV ($currentSelectedCvIdFromProvider) listede bulunamadı. Provider'da seçim temizleniyor.");
          newSelectedCvDataLocal = null;
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Provider.of<CvProvider>(context, listen: false).clearSelection();
            });
          }
        }
      } else {
        newSelectedCvDataLocal = null;
        print("MyCvsScreen: Provider'da seçili CV yok.");
      }

      if (mounted) {
        setState(() {
          _cvDocs = newCvDocs;
          _selectedCvData = newSelectedCvDataLocal;
          _selectedCvId = currentSelectedCvIdFromProvider;
          _isLoading = false;
        });
      }
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
        builder: (context) => AlertDialog(
            title: Text('CV\'yi Sil', style: Theme.of(context).dialogTheme.titleTextStyle),
            content: Text('"${(doc.data() as Map<String, dynamic>?)?['cvName'] ?? 'Bu CV'}" silinecek. Emin misiniz?', style: Theme.of(context).dialogTheme.contentTextStyle),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
              TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error), child: const Text('Sil'))
            ]));
    if (confirmDelete != true) return;

    if (mounted) setState(() => _isLoading = true);
    try {
      await _firestore.collection('users').doc(_userId!).collection('cvs').doc(doc.id).delete();
      if (context.mounted && Provider.of<CvProvider>(context, listen: false).selectedCvId == doc.id) {
        Provider.of<CvProvider>(context, listen: false).clearSelection();
      }
      await _loadCvs();
      if (mounted) {
        _showInfoSnackBar('CV silindi.');
      }
    } catch (e) {
      print("CV silinirken Hata: $e");
      if (mounted) {
        _showErrorSnackBar('CV silinirken hata.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectCv(String cvId, String cvName) {
    print("MyCvsScreen: _selectCv çağrıldı. ID: $cvId, Name: $cvName");
    Provider.of<CvProvider>(context, listen: false).selectCv(cvId, cvName);
  }

  void _showSnackBar(String message, {Color backgroundColor = Colors.grey}) { 
    if (!mounted) return; 
    ScaffoldMessenger.of(context).removeCurrentSnackBar(); 
    ScaffoldMessenger.of(context).showSnackBar( 
      SnackBar(
        content: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onInverseSurface)), 
        backgroundColor: backgroundColor, 
        duration: const Duration(seconds: 2)
      ) 
    ); 
  }
  void _showErrorSnackBar(String message) { _showSnackBar(message, backgroundColor: Theme.of(context).colorScheme.errorContainer.withOpacity(0.9)); }
  void _showSuccessSnackBar(String message) { _showSnackBar(message, backgroundColor: Colors.green.shade700.withOpacity(0.9)); }
  void _showInfoSnackBar(String message) { _showSnackBar(message, backgroundColor: Colors.blueGrey.shade700.withOpacity(0.9)); }

  Widget _buildKpiCard(String title, String value, IconData icon, {Color? specificIconColor}) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 2.0), 
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 6.0), 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: specificIconColor ?? theme.colorScheme.primary), 
            const SizedBox(height: 5),
            Flexible( 
              child: Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith( // KPI Değeri için
                  color: theme.colorScheme.onSurface,
                  fontSize: 18, 
                  fontWeight: FontWeight.w700, 
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis, 
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant, 
                fontSize: 10.5, 
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedCvIdFromProvider = context.watch<CvProvider>().selectedCvId;
    final String aiScore = _selectedCvData?['aiScore'] as String? ?? '-';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadCvs,
        color: theme.colorScheme.primary,
        backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : AnimationLimiter(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 90.0), 
                  children: [
                    SizedBox( 
                      height: 105, 
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _buildKpiCard('AI Skoru', (_selectedCvId == null || _selectedCvData == null) ? "-" : aiScore, Icons.star_rounded, specificIconColor: theme.colorScheme.primary)),
                          const SizedBox(width: 6), 
                          Expanded(child: _buildKpiCard('Toplam CV', _cvDocs.length.toString(), Icons.article_rounded, specificIconColor: theme.colorScheme.secondary)), 
                          const SizedBox(width: 6),
                          Expanded(child: _buildKpiCard('Analizler', 'N/A', Icons.insights_rounded, specificIconColor: theme.colorScheme.onSurfaceVariant)), 
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text("CV Belgelerim", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 19)),
                        TextButton.icon(
                          icon: Icon(Icons.refresh_rounded, size: 18, color: theme.colorScheme.primary.withOpacity(0.8)),
                          label: Text("Yenile", style: TextStyle(color: theme.colorScheme.primary.withOpacity(0.8), fontWeight: FontWeight.w600, fontSize: 13.5)),
                          onPressed: _isLoading ? null : _loadCvs,
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3)),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_cvDocs.isEmpty && !_isLoading)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60.0),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_copy_outlined, size: 56, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                              const SizedBox(height: 20),
                              Text("Henüz CV oluşturulmamış.", style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                              const SizedBox(height: 10),
                              Text(
                                "Yeni bir CV oluşturmak için\naşağıdaki '+' butonunu kullanın.",
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8), height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _cvDocs.length,
                        itemBuilder: (context, index) {
                          final cvDoc = _cvDocs[index];
                          final cv = cvDoc.data() as Map<String, dynamic>? ?? {};
                          String cvName = cv['cvName'] ?? 'İsimsiz CV';
                          String lastUpdated = 'Bilinmiyor';
                          if (cv['lastUpdated'] is Timestamp) { lastUpdated = DateFormat('dd MMMM y, HH:mm', 'tr_TR').format((cv['lastUpdated'] as Timestamp).toDate().toLocal()); } 
                          else if (cv['createdAt'] is Timestamp) { lastUpdated = DateFormat('dd MMMM y, HH:mm', 'tr_TR').format((cv['createdAt'] as Timestamp).toDate().toLocal()); }

                          bool isSelected = cvDoc.id == _selectedCvId;

                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 400),
                            child: SlideAnimation(
                              verticalOffset: 60.0,
                              child: FadeInAnimation(
                                child: Card(
                                  color: isSelected ? theme.colorScheme.primaryContainer.withOpacity(0.8) : theme.cardTheme.color,
                                  margin: EdgeInsets.only( 
                                    left: (theme.cardTheme.margin as EdgeInsets?)?.left ?? 0,
                                    right: (theme.cardTheme.margin as EdgeInsets?)?.right ?? 0,
                                    top: 4, 
                                    bottom: 8, 
                                  ),
                                  elevation: isSelected ? 1.5 : theme.cardTheme.elevation, 
                                  shape: isSelected
                                      ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: theme.colorScheme.primary, width: 1.5))
                                      : theme.cardTheme.shape,
                                  child: ListTile(
                                    contentPadding: (theme.listTileTheme.contentPadding as EdgeInsets?)?.copyWith(top:10, bottom: 10, left: 12, right: 8) ?? const EdgeInsets.symmetric(horizontal:12, vertical: 10),
                                    leading: Container(
                                      padding: const EdgeInsets.all(10.0),
                                      decoration: BoxDecoration(
                                        color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : theme.colorScheme.surfaceVariant.withOpacity(0.4),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.article_outlined,
                                        size: 20, 
                                        color: isSelected ? theme.colorScheme.primary : theme.listTileTheme.iconColor,
                                      ),
                                    ),
                                    title: Text(
                                      cvName,
                                      style: (isSelected
                                          ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary) 
                                          : theme.textTheme.titleSmall)
                                          ?.copyWith(fontSize: 14.5), 
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      'Son Güncelleme: $lastUpdated',
                                      style: theme.listTileTheme.subtitleTextStyle?.copyWith(fontSize: 11.5), 
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(Icons.delete_outline_rounded, size: 20, color: theme.colorScheme.error.withOpacity(0.7)), 
                                      tooltip: 'Sil',
                                      padding: EdgeInsets.zero, 
                                      constraints: const BoxConstraints(), 
                                      onPressed: () => _deleteCv(cvDoc),
                                    ),
                                    onTap: () => _selectCv(cvDoc.id, cvName),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}