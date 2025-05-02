import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum PdfTemplate { template1, template2 }

class PdfGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Uint8List?> generateCvPdf(String userId, String cvId, PdfTemplate templateId) async {
    if (userId.isEmpty || cvId.isEmpty) return null;
    final cvData = await _fetchSpecificCvData(userId, cvId);
    if (cvData == null) return null;

    final pdf = pw.Document();
    final font = await PdfGoogleFonts.poppinsRegular();
    final boldFont = await PdfGoogleFonts.poppinsBold();
    final italicFont = await PdfGoogleFonts.poppinsItalic();

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont( base: font, bold: boldFont, italic: italicFont, icons: await PdfGoogleFonts.materialIcons() ),
        pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          switch (templateId) {
            case PdfTemplate.template2: return [ _buildLayoutTemplate2(context, cvData) ];
            case PdfTemplate.template1: default: return [ _buildLayoutTemplate1(context, cvData) ];
          }
        },
      ),
    );
    try { return await pdf.save(); }
    catch (e) { print("PDF kaydedilirken hata: $e"); return null; }
  }

  Future<Uint8List?> generatePdfFromText(String cvText) async {
     final pdf = pw.Document(); final font = await PdfGoogleFonts.poppinsRegular();
     pdf.addPage( pw.MultiPage( theme: pw.ThemeData.withFont(base: font), pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(35), build: (pw.Context context) { return [ pw.Padding( padding: const pw.EdgeInsets.all(10), child: pw.Paragraph( text: cvText, style: const pw.TextStyle(lineSpacing: 2) ) ) ]; } ) );
     try { return await pdf.save(); } catch (e) { print("Metinden PDF kaydedilirken hata: $e"); return null; }
  }

  // Fonksiyon düzeltildi
  Future<Map<String, dynamic>?> _fetchSpecificCvData(String userId, String cvId) async {
     try {
        final cvDocSnapshot = await _firestore.collection('users').doc(userId).collection('cvs').doc(cvId).get();
        if(cvDocSnapshot.exists) {
           // Veriyi Map olarak döndür
           return cvDocSnapshot.data() as Map<String, dynamic>?; // Explicit cast
        } else { print("Belirtilen CV dokümanı bulunamadı: $cvId"); return null; }
     } catch (e) { print("Firestore'dan belirli CV verisi çekerken hata: $e"); return null; }
  }

   // --- PDF İçerik Oluşturma Fonksiyonları ---
   pw.Widget _buildLayoutTemplate1(pw.Context context, Map<String, dynamic> data) { /* ... İçerik aynı ... */ return pw.Column(/*...*/); }
   pw.Widget _buildLayoutTemplate2(pw.Context context, Map<String, dynamic> data) {
      return pw.Partition(
        // --- pw.Partition İÇERİĞİ DOLDURULDU ---
        child: pw.Row( // child: Row eklendi
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded( flex: 1, child: pw.Container( padding: const pw.EdgeInsets.only(right: 20), child: pw.Column(/* Sol kolon içeriği */) ) ),
            pw.Expanded( flex: 2, child: pw.Container( child: pw.Column(/* Sağ kolon içeriği */) ) )
          ]
        ) // --- ---
     );
  }
   // --- Yardımcı Fonksiyonlar (_buildSection, _buildExperienceItem vb.) ---
   List<pw.Widget> _buildSection(String title, pw.Widget content, pw.TextStyle titleStyle) { /* ... */ return []; }
   pw.Widget _buildExperienceItem(pw.Context context, Map<String, dynamic> exp) { /* ... */ return pw.Container();}
   pw.Widget _buildEducationItem(pw.Context context, Map<String, dynamic> edu) { /* ... */ return pw.Container();}
   pw.Widget _buildProjectItem(pw.Context context, Map<String, dynamic> proj) { /* ... */ return pw.Container();}
   pw.Widget _buildSkillsSection(pw.Context context, Map<String, dynamic> skillsMap) { /* ... */ return pw.Container();}

}