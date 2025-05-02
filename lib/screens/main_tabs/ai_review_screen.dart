import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';
import 'package:yeni_cv_uygulamasi/providers/cv_provider.dart';
import 'package:yeni_cv_uygulamasi/utils/pdf_generator.dart';
import 'package:yeni_cv_uygulamasi/screens/pdf_preview_screen.dart';
import 'package:yeni_cv_uygulamasi/utils/api_key_provider.dart'; // API Key Helper

class AiReviewScreen extends StatefulWidget {
  const AiReviewScreen({super.key});

  @override
  State<AiReviewScreen> createState() => _AiReviewScreenState();
}

class _AiReviewScreenState extends State<AiReviewScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PdfGenerator _pdfGenerator = PdfGenerator();

  bool _isLoadingReview = false;
  bool _isLoadingGenerate = false;
  String? _aiFeedback;
  String? _aiScore;
  String? _errorMessage;
  String? _userId;
  String? _selectedCvId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cvProvider = Provider.of<CvProvider>(context);
    final newSelectedCvId = cvProvider.selectedCvId;
    if(newSelectedCvId != _selectedCvId) {
       _selectedCvId = newSelectedCvId;
       _userId = _auth.currentUser?.uid;
        if (mounted) { setState(() { _aiFeedback=null; _aiScore=null; _errorMessage=null; });}
       print("AIReviewScreen: Selected CV ID: $_selectedCvId");
    }
  }

   bool _checkPrerequisites() {
     _selectedCvId = Provider.of<CvProvider>(context, listen: false).selectedCvId;
     _userId = _auth.currentUser?.uid;
     if (_userId == null || _selectedCvId == null) { _showInfoSnackBar('Lütfen önce bir CV seçin.'); return false; }
     return true;
  }

   void _handleDataError(String message){ if(mounted) { _showInfoSnackBar(message); } }

   // *** HATA DÜZELTİLDİ: e.message.toString() kullanıldı ***
   void _handleAiError(Object e, String operation) {
       print("$operation Hatası: $e");
       if (mounted) {
         String displayError = "$operation sırasında bir hata oluştu.";
          // API anahtarı bulunamadı hatasını özel olarak yakala
          if (e is AssertionError && e.message != null && e.message.toString().contains('API_KEY')) {
             displayError = "AI servis anahtarı bulunamadı. Uygulama doğru şekilde başlatılmamış olabilir.";
          } else if (e is GenerativeAIException) { displayError += " Detay: ${e.message}"; }
          else { displayError += " Detay: ${e.toString()}"; }
        setState(() { _errorMessage = displayError; });
       }
   }

   void _showSnackBar(String message, {Color backgroundColor = Colors.grey}) { if (!mounted) return; ScaffoldMessenger.of(context).removeCurrentSnackBar(); ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(message), backgroundColor: backgroundColor, duration: const Duration(seconds: 2)) ); }
   void _showErrorSnackBar(String message) { _showSnackBar(message, backgroundColor: Theme.of(context).colorScheme.error); }
   void _showSuccessSnackBar(String message) { _showSnackBar(message, backgroundColor: Colors.green); }
   void _showInfoSnackBar(String message) { _showSnackBar(message, backgroundColor: Colors.orangeAccent); }

  Future<void> _analyzeCv() async {
    if (!_checkPrerequisites() || !mounted) return;
    setState(() { _isLoadingReview = true; _errorMessage = null; _aiFeedback = null; _aiScore = null; });
    final String? cvContent = await _fetchAndFormatCvData();
    if (cvContent == null || cvContent.trim().length < 50) { _handleDataError("Analiz için yeterli CV verisi bulunamadı."); setState(() => _isLoadingReview = false ); return; }
    if (!mounted) { setState(() => _isLoadingReview = false ); return; }

    try {
      final apiKey = ApiKeyProvider.getApiKey();
      final model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: apiKey);
      final prompt = """Bir uzman CV/İK danışmanı gibi davran. Aşağıdaki CV metnini analiz et. CV Metni: --- $cvContent --- Analiz sonucunda: 1.  Bu CV için 100 üzerinden bir puan ver. Puanlamayı yaparken ATS uyumluluğu, anahtar kelime kullanımı, okunabilirlik, etki gücü (ölçülebilir başarılar, güçlü fiiller), ve genel profesyonellik gibi kriterleri dikkate al. 2.  Detaylı geri bildirim ver. CV'nin güçlü ve zayıf yönlerini belirt. Her bölüm için (Kişisel Bilgiler, Deneyim, Eğitim, Yetenekler, Projeler vb.) somut ve uygulanabilir iyileştirme önerileri sun. Özellikle zayıf veya eksik görünen noktalara odaklan. Daha etkili ifadeler veya eklenmesi gereken bilgiler öner. Cevabını şu formatta ver: İlk satırda sadece "PUAN: [puan]/100" yazsın. (Örnek: PUAN: 75/100) Bir sonraki satırdan itibaren geri bildirimi ve önerileri yaz. Geri bildirimi Markdown formatında (* liste, **kalın** vb.) yazabilirsin.""";

      final response = await model.generateContent([Content.text(prompt)]);
      final String? textResponse = response.text;
      if (textResponse != null && mounted) {
         _parseReviewResponse(textResponse);
         if (_userId != null && _selectedCvId != null && _aiScore != null && _aiScore != "Puan alınamadı") {
            try {
                await _firestore.collection('users').doc(_userId).collection('cvs').doc(_selectedCvId).set(
                   {'aiScore': _aiScore, 'lastUpdated': FieldValue.serverTimestamp()}, SetOptions(merge: true) );
                print("AI Skoru Firestore'a kaydedildi: $_aiScore");
             } catch (saveError) { print("AI Skoru kaydedilirken hata: $saveError"); }
         }
      } else if (mounted) { setState(() { _errorMessage = "AI modelinden boş cevap alındı."; }); }
    } catch (e) { _handleAiError(e, "AI İnceleme"); }
    finally { if (mounted) { setState(() { _isLoadingReview = false; }); } }
  }

  void _parseReviewResponse(String textResponse){
     final lines = textResponse.split('\n'); String score = "Puan alınamadı"; String feedback = textResponse;
     if (lines.isNotEmpty && lines[0].toUpperCase().contains('PUAN:')) { RegExp scoreRegex = RegExp(r'(\d+)\s*/\s*100'); Match? match = scoreRegex.firstMatch(lines[0]); if (match != null && match.groupCount >= 1) { score = "${match.group(1)!}/100"; } else { score = lines[0].substring(lines[0].toUpperCase().indexOf('PUAN:') + 5).trim(); } feedback = lines.skip(1).join('\n').trim(); }
     if(mounted) {
       setState(() { _aiScore = score; _aiFeedback = feedback; });
     }
  }

  Future<void> _generateAndExportAiCv() async {
    if (!_checkPrerequisites() || !mounted) return;
    setState(() { _isLoadingGenerate = true; _errorMessage = null; _aiFeedback = null; _aiScore = null; });
    final String? cvContent = await _fetchAndFormatCvData();
     if (cvContent == null || cvContent.trim().length < 50) { _handleDataError("Profesyonel CV oluşturmak için yeterli veri bulunamadı."); setState(() => _isLoadingGenerate = false ); return; }
    if (!mounted) { setState(() => _isLoadingGenerate = false ); return; }

      try {
        final apiKey = ApiKeyProvider.getApiKey();
        final model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: apiKey);
        final prompt = """Bir uzman CV yazarı gibi davran. Aşağıdaki ham CV bilgilerini kullanarak, baştan sona profesyonel, akıcı ve etkileyici bir dilde tam bir CV metni oluştur. Standart CV bölümlerini (Özet, İş Deneyimi, Eğitim, Yetenekler, Projeler) kullan. İş deneyimi ve projelerdeki sorumlulukları/başarıları madde işaretleri (*) veya kısa paragraflar halinde, güçlü eylem fiilleriyle (developed, managed, created, implemented vb.) yaz. Yetenekleri ilgili kategoriler altında grupla. Genel olarak okunabilirliği yüksek ve profesyonel bir ton kullan. Sadece oluşturulan CV metnini döndür, başına veya sonuna ek açıklama yazma. Ham Veriler: --- $cvContent --- Oluşturulacak CV Metni:""";

        final response = await model.generateContent([Content.text(prompt)]);
        final String? generatedCvText = response.text;
        if (generatedCvText != null && generatedCvText.trim().isNotEmpty && mounted) {
           final Uint8List? pdfBytes = await _pdfGenerator.generatePdfFromText(generatedCvText.trim());
           if(pdfBytes != null && mounted){ Navigator.push( context, MaterialPageRoute(builder: (_) => PdfPreviewScreen(pdfBytes: pdfBytes)) ); }
           else if (mounted) { _showErrorSnackBar("Oluşturulan CV metni ile PDF dosyası oluşturulamadı."); }
        } else if (mounted) { _showErrorSnackBar("AI modelinden geçerli bir CV metni oluşturulamadı."); }
      } catch (e) { _handleAiError(e, "AI CV Oluşturma"); }
      finally { if (mounted) { setState(() { _isLoadingGenerate = false; }); } }
  }

  Future<String?> _fetchAndFormatCvData() async {
    if (_userId == null || _selectedCvId == null) return null;
    StringBuffer cvText = StringBuffer();
    try {
       final cvDocSnapshot = await _firestore.collection('users').doc(_userId).collection('cvs').doc(_selectedCvId).get();
       if (!cvDocSnapshot.exists) {
         print("CV dokümanı bulunamadı: $_selectedCvId");
         return '';
       }
       final cvData = cvDocSnapshot.data() ?? {};
       final personalInfo = cvData['personalInfo'] as Map<String, dynamic>? ?? {};
       if (personalInfo.isNotEmpty) { cvText.writeln("## Kişisel Bilgiler"); if (personalInfo['fullName'] != null) cvText.writeln("- Ad Soyad: ${personalInfo['fullName']}"); if (personalInfo['jobTitle'] != null) cvText.writeln("- Unvan: ${personalInfo['jobTitle']}"); if (personalInfo['email'] != null) cvText.writeln("- Eposta: ${personalInfo['email']}"); if (personalInfo['phone'] != null) cvText.writeln("- Telefon: ${personalInfo['phone']}"); if (personalInfo['address'] != null) cvText.writeln("- Konum: ${personalInfo['address']}"); if (personalInfo['linkedinUrl'] != null) cvText.writeln("- LinkedIn: ${personalInfo['linkedinUrl']}"); if (personalInfo['portfolioUrl'] != null) cvText.writeln("- Portfolyo: ${personalInfo['portfolioUrl']}"); cvText.writeln(); }
       final summary = cvData['summary'] as String? ?? ''; if (summary.isNotEmpty) { cvText.writeln("## Özet/Kariyer Hedefi\n$summary\n"); }
       final experiences = cvData['experiences'] as List<dynamic>? ?? []; if (experiences.isNotEmpty) { cvText.writeln("## İş Deneyimi"); for (var expMap in experiences) { final exp = Map<String, dynamic>.from(expMap); cvText.writeln("- ${exp['jobTitle'] ?? ''} / ${exp['companyName'] ?? ''} (${exp['location'] ?? ''})"); final endDate = (exp['isCurrentJob'] ?? false) ? 'Halen' : (exp['endDate'] ?? ''); cvText.writeln("  (${exp['startDate'] ?? ''} - $endDate)"); if (exp['description'] != null && exp['description'].isNotEmpty) cvText.writeln("  Açıklama: ${exp['description']}"); cvText.writeln(); } cvText.writeln(); }
       final educationList = cvData['education'] as List<dynamic>? ?? []; if (educationList.isNotEmpty) { cvText.writeln("## Eğitim Bilgileri"); for (var eduMap in educationList) { final edu = Map<String, dynamic>.from(eduMap); cvText.writeln("- ${edu['degree'] ?? ''} - ${edu['institutionName'] ?? ''} (${edu['fieldOfStudy'] ?? ''})"); final endDate = (edu['isCurrent'] ?? false) ? 'Devam Ediyor' : (edu['endDate'] ?? ''); cvText.writeln("  (${edu['startDate'] ?? ''} - $endDate)"); if (edu['description'] != null && edu['description'].isNotEmpty) cvText.writeln("  Notlar: ${edu['description']}"); cvText.writeln(); } cvText.writeln(); }
       final skills = cvData['skills'] as Map<String, dynamic>? ?? {}; if (skills.isNotEmpty) { cvText.writeln("## Yetenekler"); skills.forEach((cat, list) { if (list is List && list.isNotEmpty) { String categoryName = cat.replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}').trim(); categoryName = categoryName[0].toUpperCase() + categoryName.substring(1); cvText.writeln("- $categoryName: ${List<String>.from(list).join(', ')}"); } }); cvText.writeln(); }
       final projects = cvData['projects'] as List<dynamic>? ?? []; if (projects.isNotEmpty) { cvText.writeln("## Projeler"); for (var projMap in projects) { final proj = Map<String, dynamic>.from(projMap); cvText.writeln("- ${proj['projectName'] ?? ''}"); if (proj['description'] != null && proj['description'].isNotEmpty) cvText.writeln("  Açıklama: ${proj['description']}"); if (proj['technologies'] is List && proj['technologies'].isNotEmpty) cvText.writeln("  Teknolojiler: ${List<String>.from(proj['technologies']).join(', ')}"); if (proj['link'] != null && proj['link'].isNotEmpty) cvText.writeln("  Link: ${proj['link']}"); cvText.writeln(); } cvText.writeln(); }
    } catch (e) { print("AI için veri çekme hatası: $e"); if(mounted) _showErrorSnackBar("CV verisi çekilirken hata oluştu."); return null; }
    return cvText.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.rate_review_outlined, size: 50, color: Theme.of(context).primaryColor),
                const SizedBox(height: 16),
                Text('AI CV İnceleme', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Mevcut CV verilerinizi analiz ettirip puan ve geri bildirim alın.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 20),
                _isLoadingReview
                ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                : ElevatedButton.icon( icon: const Icon(Icons.analytics_outlined), label: const Text('İncele ve Puanla'), onPressed: _isLoadingGenerate ? null : _analyzeCv, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)) ),
                 const SizedBox(height: 12),
                 if (_aiScore != null || _aiFeedback != null) Container( padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(top: 10, bottom: 10), decoration: BoxDecoration( color: Theme.of(context).colorScheme.surface.withOpacity(0.5), borderRadius: BorderRadius.circular(8), border: Border.all(color: Theme.of(context).dividerColor) ), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ if (_aiScore != null) SelectableText( 'AI Puanı: $_aiScore', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor) ), if (_aiScore != null && _aiFeedback != null) const Divider(height: 24, thickness: 1), if (_aiFeedback != null) Text( 'AI Geri Bildirimi ve Öneriler:', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600) ), if (_aiFeedback != null) const SizedBox(height: 8), if (_aiFeedback != null) SelectableText(_aiFeedback!) ]) ),
                 if (_errorMessage != null && !_isLoadingReview && !_isLoadingGenerate) Padding( padding: const EdgeInsets.only(top: 16.0), child: Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error), textAlign: TextAlign.center) ),
                 const Divider(height: 40, thickness: 1),
                 Icon(Icons.auto_fix_high, size: 50, color: Theme.of(context).primaryColor),
                 const SizedBox(height: 16),
                 Text('AI Profesyonel CV Oluşturucu', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                 Text('Girdiğiniz bilgilere dayanarak AI\'nın sizin için profesyonel bir CV metni oluşturmasını ve PDF olarak dışa aktarmasını sağlayın.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                 const SizedBox(height: 20),
                 _isLoadingGenerate
                 ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                 : ElevatedButton.icon( icon: const Icon(Icons.picture_as_pdf_outlined), label: const Text('AI ile CV Oluştur ve İndir'), onPressed: _isLoadingReview ? null : _generateAndExportAiCv, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)) ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}