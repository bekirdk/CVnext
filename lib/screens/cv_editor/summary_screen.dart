import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';
import 'package:yeni_cv_uygulamasi/providers/cv_provider.dart';
import 'package:yeni_cv_uygulamasi/utils/api_key_provider.dart'; // API Key Helper

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

  @override
  void initState() {
    super.initState();
  }

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
  void dispose() {
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    if (_userId == null || _selectedCvId == null) {
       if(mounted) setState(() { _summaryController.clear(); _isLoading = false; });
       print("Özet yüklenemedi: Kullanıcı veya CV ID'si null.");
       return;
    }
     if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final docSnapshot = await _firestore.collection('users').doc(_userId).collection('cvs').doc(_selectedCvId).get();
      if (mounted) {
        if (docSnapshot.exists && (docSnapshot.data() as Map).containsKey('summary')) {
          setState(() {
            _summaryController.text = docSnapshot.data()!['summary'] ?? '';
          });
        } else {
          setState(() {
            _summaryController.clear();
          });
          print("Summary alanı bulunamadı veya doküman mevcut değil.");
        }
      }
    } catch (e) {
       print("Özet yüklenirken hata: $e");
       if (mounted) _showErrorSnackBar('Özet yüklenirken bir hata oluştu.');
    } finally {
       if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _saveSummary() async {
    if (_userId == null || _selectedCvId == null || !mounted) {
       _showErrorSnackBar('Kaydedilecek CV seçilmedi!');
       return;
    }
    if (!mounted) return;
    setState(() { _isLoading = true; });
     try {
        await _firestore.collection('users').doc(_userId).collection('cvs').doc(_selectedCvId).set(
          {
             'summary': _summaryController.text.trim(),
             'lastUpdated': FieldValue.serverTimestamp()
          },
          SetOptions(merge: true)
        );
         if (mounted) {
           _showSuccessSnackBar('Özet başarıyla kaydedildi.');
         }
     } catch (e) {
        print("Özet kaydedilirken hata: $e");
        if (mounted) _showErrorSnackBar('Özet kaydedilirken bir hata oluştu.');
     } finally {
        if (mounted) setState(() { _isLoading = false; });
     }
  }

  Future<void> _generateSummaryWithAI() async {
     if (_userId == null || _selectedCvId == null || !mounted) {
        _showErrorSnackBar('Önce bir CV seçmelisiniz.');
        return;
     }
     setState(() { _isGenerating = true; });

     String? contextData = await _fetchDataForAISummary();

     if (contextData == null || contextData.isEmpty) {
        if(mounted) {
          setState(() { _isGenerating = false; });
          _showInfoSnackBar('Özet oluşturmak için yeterli veri (Deneyim, Yetenek vb.) bulunamadı.');
        }
        return;
     }
     if (!mounted) return;

     try {
        final apiKey = ApiKeyProvider.getApiKey();
        final model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: apiKey);
        final prompt = """Aşağıdaki CV verilerini analiz et ve bu bilgilere dayanarak profesyonel, kısa (3-5 cümle), ve adayın en güçlü yönlerini vurgulayan bir CV özeti veya kariyer hedefi oluştur. Kullanılacak ton, başvurulan pozisyona uygun olmalı (genel bir profesyonel ton kullan). Güçlü fiiller kullanmaya özen göster. Sadece oluşturulan metni döndür.

CV Verileri:
---
$contextData
---

Oluşturulacak Özet/Kariyer Hedefi:""";

        final response = await model.generateContent([Content.text(prompt)]);
        final String? generatedSummary = response.text;

        if (generatedSummary != null && generatedSummary.trim().isNotEmpty && mounted) {
           setState(() {
             _summaryController.text = generatedSummary.trim();
           });
           _showInfoSnackBar('AI ile özet oluşturuldu! Kaydetmeyi unutmayın.');
        } else if (mounted) {
           _showErrorSnackBar('AI modelinden geçerli bir özet alınamadı.');
        }
      } catch (e) {
         _handleAiError(e, "AI Özet Oluşturma");
      } finally {
         if (mounted) {
           setState(() { _isGenerating = false; });
         }
      }
  }

  Future<String?> _fetchDataForAISummary() async {
     if (_userId == null || _selectedCvId == null) return null;
     StringBuffer contextText = StringBuffer();
      try {
         final cvDocSnapshot = await _firestore.collection('users').doc(_userId).collection('cvs').doc(_selectedCvId).get();
         if (!cvDocSnapshot.exists) { print("AI özeti için veri çekilemedi: CV dokümanı yok."); return null; }
         final cvData = cvDocSnapshot.data() ?? {};
         final personalInfo = cvData['personalInfo'] as Map<String, dynamic>? ?? {}; if (personalInfo['jobTitle'] != null && (personalInfo['jobTitle'] as String).isNotEmpty) { contextText.writeln("Mevcut Unvan: ${personalInfo['jobTitle']}"); }
         final experiences = cvData['experiences'] as List<dynamic>? ?? []; if (experiences.isNotEmpty) { contextText.writeln("\nDeneyimler:"); for (var expMap in experiences.take(3)) { final exp = Map<String, dynamic>.from(expMap); contextText.writeln("- ${exp['jobTitle']} (${exp['companyName']})"); } }
         final skillsMap = cvData['skills'] as Map<String, dynamic>? ?? {}; if (skillsMap.isNotEmpty) { contextText.writeln("\nÖne Çıkan Yetenekler:"); skillsMap.forEach((category, skills) { if (skills is List && skills.isNotEmpty) { contextText.writeln("- ${category.toUpperCase()}: ${List<String>.from(skills).take(5).join(', ')}"); } }); }
      } catch (e) { print("AI özeti için veri çekme hatası: $e"); if(mounted) _showErrorSnackBar("CV verisi çekilirken hata oluştu."); return null; }
      return contextText.isEmpty ? null : contextText.toString();
  }

  void _showSnackBar(String message, {Color backgroundColor = Colors.grey}) { if (!mounted) return; ScaffoldMessenger.of(context).removeCurrentSnackBar(); ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(message), backgroundColor: backgroundColor, duration: const Duration(seconds: 2)) ); }
  void _showErrorSnackBar(String message) { _showSnackBar(message, backgroundColor: Theme.of(context).colorScheme.error); }
  void _showSuccessSnackBar(String message) { _showSnackBar(message, backgroundColor: Colors.green); }
  void _showInfoSnackBar(String message) { _showSnackBar(message, backgroundColor: Colors.orangeAccent); }

   // *** HATA DÜZELTİLDİ: e.message.toString() kullanıldı ***
   void _handleAiError(Object e, String operation) {
       print("$operation Hatası: $e");
       if (mounted) {
         String displayError = "$operation sırasında bir hata oluştu.";
         if (e is AssertionError && e.message != null && e.message.toString().contains('API_KEY')) {
            displayError = "AI servis anahtarı bulunamadı. Uygulama doğru şekilde başlatılmamış olabilir.";
         } else if (e is GenerativeAIException) { displayError += " Detay: ${e.message}"; }
         else { displayError += " Detay: ${e.toString()}"; }
         _showErrorSnackBar(displayError);
       }
    }

  @override
  Widget build(BuildContext context) {
     final currentSelectedCvId = context.watch<CvProvider>().selectedCvId;
      if (currentSelectedCvId == null) {
        return Scaffold( appBar: AppBar(title: const Text("Özet / Kariyer Hedefi")), body: const Center( child: Padding( padding: EdgeInsets.all(20.0), child: Text("Bu bölümü düzenlemek için lütfen önce 'CVlerim' sekmesinden bir CV seçin.", textAlign: TextAlign.center), ) ) );
      }
      if (_isLoading || _selectedCvId != currentSelectedCvId) {
          return Scaffold(appBar: AppBar(title: const Text("Özet / Kariyer Hedefi")), body: const Center(child: CircularProgressIndicator()));
      }

    return Scaffold(
      appBar: AppBar(
        title: Text('Özet / Kariyer Hedefi', style: GoogleFonts.poppins()),
        actions: [
            _isLoading || _isGenerating
            ? const Padding( padding: EdgeInsets.symmetric(horizontal: 16.0), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))), )
           : IconButton( icon: const Icon(Icons.save_outlined), tooltip: 'Özeti Kaydet', onPressed: _saveSummary, )
        ],
      ),
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField( controller: _summaryController, decoration: InputDecoration( labelText: 'Profesyonel Özet veya Kariyer Hedefi', hintText: 'Kendinizi, hedeflerinizi ve en önemli yetenek/deneyimlerinizi burada özetleyin veya AI\'dan yardım alın.', border: const OutlineInputBorder(), alignLabelWithHint: true, suffixIcon: IconButton( icon: const Icon(Icons.clear, size: 20), tooltip: 'Temizle', onPressed: () => _summaryController.clear(), ) ), minLines: 8, maxLines: null, keyboardType: TextInputType.multiline, ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon( icon: _isGenerating ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome, size: 18), label: Text(_isGenerating ? 'Oluşturuluyor...' : 'AI ile Özet Oluştur/Güncelle'), onPressed: _isLoading || _isGenerating ? null : _generateSummaryWithAI, ),
                   const SizedBox(height: 12),
                   Padding( padding: const EdgeInsets.only(top: 8.0), child: Text( 'Not: "AI ile Oluştur" mevcut özeti günceller. Değişiklikleri kalıcı yapmak için sağ üstteki Kaydet ikonunu kullanın.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)), textAlign: TextAlign.center, ), )
                ],
              ),
            ),
    );
  }
}