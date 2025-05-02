import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';
import 'package:yeni_cv_uygulamasi/providers/cv_provider.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _summaryController = TextEditingController();
  bool _isLoading = true;
  bool _isGenerating = false;
  String? _userId;
  String? _selectedCvId;

  final String _apiKey = "YOUR_API_KEY"; // API Anahtarını kontrol et!

  @override
  void initState() { super.initState(); /* didChangeDependencies halledecek */ }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cvProvider = Provider.of<CvProvider>(context);
    final newSelectedCvId = cvProvider.selectedCvId;
    if (newSelectedCvId != _selectedCvId) {
      _selectedCvId = newSelectedCvId;
      _userId = _auth.currentUser?.uid;
      print("SummaryScreen: Loading data for CV ID: $_selectedCvId");
      _loadSummary();
    } else if (_isLoading && _selectedCvId == null) {
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
  void dispose() { _summaryController.dispose(); super.dispose(); }

  Future<void> _loadSummary() async {
    if (_userId == null || _selectedCvId == null) { if(mounted) setState(() { _summaryController.clear(); _isLoading = false; }); return; }
     if (!mounted) return; setState(() => _isLoading = true);
    try {
      final docSnapshot = await _firestore.collection('users').doc(_userId).collection('cvs').doc(_selectedCvId).get();
      if (mounted) {
        if (docSnapshot.exists && docSnapshot.data()!.containsKey('summary')) {
          setState(() { _summaryController.text = docSnapshot.data()!['summary'] ?? ''; });
        } else { setState(() { _summaryController.clear(); }); }
      }
    } catch (e) { print("Özet yüklenirken hata: $e"); _showErrorSnackBar('Özet yüklenirken bir hata oluştu.'); }
    finally { if (mounted) setState(() { _isLoading = false; }); }
  }

  Future<void> _saveSummary() async {
    if (_userId == null || _selectedCvId == null || !mounted) { _showErrorSnackBar('Kaydedilecek CV seçilmedi!'); return; }
    setState(() { _isLoading = true; });
     try {
        await _firestore.collection('users').doc(_userId).collection('cvs').doc(_selectedCvId).set(
          { 'summary': _summaryController.text.trim(), 'lastUpdated': FieldValue.serverTimestamp() }, SetOptions(merge: true) );
         if (mounted) { _showSuccessSnackBar('Özet başarıyla kaydedildi.'); }
     } catch (e) { print("Özet kaydedilirken hata: $e"); _showErrorSnackBar('Özet kaydedilirken bir hata oluştu.'); }
     finally { if (mounted) setState(() { _isLoading = false; }); }
  }

  Future<void> _generateSummaryWithAI() async {
     if (_apiKey == "YOUR_API_KEY" || _apiKey.isEmpty) { _showErrorSnackBar('API Anahtarı ayarlanmamış!'); return; }
     if (_userId == null || _selectedCvId == null || !mounted) { _showErrorSnackBar('Önce bir CV seçmelisiniz.'); return; }
     setState(() { _isGenerating = true; });

     String? contextData = await _fetchDataForAISummary(); // Artık nullable String?

     if (contextData == null || contextData.isEmpty || !mounted) {
        setState(() { _isGenerating = false; });
        _showInfoSnackBar('Özet oluşturmak için yeterli veri (Deneyim, Yetenek vb.) bulunamadı.'); return; }
     if (!mounted) return;

     final model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: _apiKey);
     final prompt = """[... CV Özeti Yazma Promptu ...]"""; // Prompt aynı

      try {
        final response = await model.generateContent([Content.text(prompt)]);
        final String? generatedSummary = response.text;
        if (generatedSummary != null && generatedSummary.trim().isNotEmpty && mounted) {
           setState(() { _summaryController.text = generatedSummary.trim(); });
           _showInfoSnackBar('AI ile özet oluşturuldu! Kaydetmeyi unutmayın.');
        } else if (mounted) { _showErrorSnackBar('AI modelinden geçerli bir özet alınamadı.'); }
      } catch (e) { _handleAiError(e, "AI Özet Oluşturma"); } // Hata yönetimi için helper kullan
      finally { if (mounted) { setState(() { _isGenerating = false; }); } }
  }

  // Dönüş tipi String? olarak değiştirildi ve null/hata durumları düzeltildi
  Future<String?> _fetchDataForAISummary() async {
    if (_userId == null || _selectedCvId == null) return null; // Null döndür
    StringBuffer contextText = StringBuffer();
     try {
        final cvDocSnapshot = await _firestore.collection('users').doc(_userId).collection('cvs').doc(_selectedCvId).get();
        if (!cvDocSnapshot.exists) return null; // Null döndür
        final cvData = cvDocSnapshot.data() ?? {};
        // Verileri formatla... (Önceki kodla aynı, cvData kullanıyor)
        final personalInfo = cvData['personalInfo'] as Map<String, dynamic>? ?? {}; if(personalInfo.isNotEmpty){ /* ... */ }
        final experiences = cvData['experiences'] as List<dynamic>? ?? []; if(experiences.isNotEmpty){ /* ... */ }
        final skillsMap = cvData['skills'] as Map<String, dynamic>? ?? {}; if(skillsMap.isNotEmpty){ /* ... */ }
     } catch (e) { print("AI özeti için veri çekme hatası: $e"); _showErrorSnackBar("CV verisi çekilirken hata oluştu."); return null; } // Null döndür
     // Eğer contextText boşsa null döndürmek daha mantıklı olabilir
     return contextText.isEmpty ? null : contextText.toString();
  }

  void _showSnackBar(String message, {Color backgroundColor = Colors.grey}) { if (!mounted) return; ScaffoldMessenger.of(context).removeCurrentSnackBar(); ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(message), backgroundColor: backgroundColor, duration: const Duration(seconds: 2)) ); }
  void _showErrorSnackBar(String message) { _showSnackBar(message, backgroundColor: Colors.red); }
  void _showSuccessSnackBar(String message) { _showSnackBar(message, backgroundColor: Colors.green); }
  void _showInfoSnackBar(String message) { _showSnackBar(message, backgroundColor: Colors.orange); }
   void _handleAiError(Object e, String operation) { /* ... Hata yönetimi ... */ }

  // --- BUILD METODU DOLDURULDU ---
  @override
  Widget build(BuildContext context) {
     // Seçili CV yoksa veya yükleniyorsa farklı UI göster
     // Bu kontrolü build içinde yapmak state'i daha doğru yansıtabilir
     final currentSelectedCvId = context.watch<CvProvider>().selectedCvId;
      if (currentSelectedCvId == null) {
        return Scaffold(appBar: AppBar(title: const Text("Özet / Kariyer Hedefi")), body: const Center(child: Text("Lütfen önce bir CV seçin.")));
      }
       // Eğer state'deki ID provider'dan farklıysa (ilk yükleme veya değişim)
      if (_isLoading || _selectedCvId != currentSelectedCvId) {
         // State'i güncellemek ve yüklemeyi tetiklemek için addPostFrameCallback kullanılabilir veya
         // doğrudan yüklemeyi tetikle (build içinde setState riskli olabilir)
         // Şimdilik sadece yükleme göstergesi gösterelim
         // didChangeDependencies zaten yüklemeyi tetikliyor olmalı.
         return Scaffold(appBar: AppBar(title: const Text("Özet / Kariyer Hedefi")), body: const Center(child: CircularProgressIndicator()));
      }


    return Scaffold(
      appBar: AppBar(
        title: Text('Özet / Kariyer Hedefi', style: GoogleFonts.poppins()),
        actions: [
            _isLoading || _isGenerating // Yükleme veya AI üretimi varsa butonu pasif yap
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
             )
           : IconButton(
               icon: const Icon(Icons.save_outlined),
               tooltip: 'Özeti Kaydet',
               onPressed: _isLoading || _isGenerating ? null : _saveSummary, // Kaydetme sırasında da pasif yap
             )
        ],
      ),
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _summaryController,
                    decoration: const InputDecoration(
                      labelText: 'Profesyonel Özet veya Kariyer Hedefi',
                      hintText: 'Kendinizi, hedeflerinizi ve en önemli yetenek/deneyimlerinizi burada özetleyin veya AI\'dan yardım alın.',
                      border: OutlineInputBorder(), // Kutu şeklinde yapalım
                      alignLabelWithHint: true,
                    ),
                    maxLines: 10, // Satır sayısını artıralım
                    keyboardType: TextInputType.multiline,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: _isGenerating
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_awesome, size: 18),
                    label: Text(_isGenerating ? 'Oluşturuluyor...' : 'AI ile Özet Oluştur/Güncelle'),
                    onPressed: _isLoading || _isGenerating ? null : _generateSummaryWithAI, // Yükleme/Oluşturma sırasında pasif yap
                  ),
                   const SizedBox(height: 12),
                   Padding( // Küçük bir not
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Not: "AI ile Oluştur" butonu mevcut özetinizi günceller. Kaydetmek için sağ üstteki ikonu kullanın.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        textAlign: TextAlign.center,
                       ),
                    )
                ],
              ),
            ),
    );
  } // --- BUILD METODU SONU ---
} // --- State Sınıfı Sonu ---