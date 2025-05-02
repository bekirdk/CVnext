import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yeni_cv_uygulamasi/screens/cv_editor/personal_info_screen.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:yeni_cv_uygulamasi/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:yeni_cv_uygulamasi/providers/cv_provider.dart';
import 'package:yeni_cv_uygulamasi/utils/api_key_provider.dart'; // API Key Helper

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _linkedinController = TextEditingController();
  bool _isAnalyzing = false;
  String? _analysisResult;
  String? _analysisError;

  @override
  void dispose() {
     _linkedinController.dispose();
     super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
     try {
       if (context.mounted) {
          Provider.of<CvProvider>(context, listen: false).clearSelection();
       }
       await _auth.signOut();
       print("Çıkış yapıldı.");
     } catch (e) {
       print("Çıkış yapılırken hata: $e");
        if(context.mounted){
           _showErrorSnackBar('Çıkış yapılırken bir hata oluştu.');
        }
     }
  }

  Future<void> _analyzeLinkedIn() async {
    final String url = _linkedinController.text.trim();
    // *** HATA DÜZELTİLDİ: != true kullanıldı ***
    if (url.isEmpty || Uri.tryParse(url)?.isAbsolute != true) {
      _showErrorSnackBar('Lütfen geçerli bir LinkedIn URL girin.');
      return;
    }
    if (!mounted) return;
    setState(() { _isAnalyzing = true; _analysisResult = null; _analysisError = null; });

    try {
      final apiKey = ApiKeyProvider.getApiKey();
      final model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: apiKey);
      final prompt = """Bir LinkedIn profil uzmanı gibi davran. Şu LinkedIn profil URL'sine ($url) sahip bir kişi için genel profil iyileştirme ipuçları ver. Profilin içeriğini göremediğini unutma. Şunlara odaklan: Profil fotoğrafı seçimi, başlık (headline) yazımı, 'Hakkında' bölümünün önemi, deneyim ve eğitim bölümlerini doldurma, yetenek ekleme ve onay alma, ve aktif olma önerileri.""";

      final response = await model.generateContent([Content.text(prompt)]);
      final String? textResponse = response.text;

      if (mounted) {
        if (textResponse != null && textResponse.isNotEmpty) {
          setState(() { _analysisResult = textResponse; });
        } else {
          setState(() { _analysisError = "AI modelinden analiz sonucu alınamadı."; });
        }
      }
    } catch (e) {
      _handleAiError(e, "LinkedIn Analizi");
    } finally {
      if (mounted) { setState(() { _isAnalyzing = false; }); }
    }
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
         setState(() { _analysisError = displayError; });
       }
    }

   Widget _buildListTile({ required BuildContext context, required IconData icon, required String title, String? subtitle, Widget? trailing, VoidCallback? onTap, }) {
      final Color primaryColor = Theme.of(context).primaryColor;
      final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;
      final Color secondaryTextColor = onSurfaceColor.withOpacity(0.7);
      return ListTile( leading: Icon(icon, color: primaryColor, size: 22), title: Text(title, style: GoogleFonts.poppins(fontSize: 15, color: onSurfaceColor)), subtitle: subtitle != null ? Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: secondaryTextColor)) : null, trailing: trailing ?? Icon(Icons.chevron_right, color: secondaryTextColor.withOpacity(0.5)), onTap: onTap ?? () { _showInfoSnackBar('$title özelliği henüz eklenmedi.'); }, dense: true, );
   }

   Widget _buildSectionHeader(String title) {
     return Padding( padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 24.0, bottom: 8.0), child: Text( title.toUpperCase(), style: GoogleFonts.poppins( fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), letterSpacing: 0.5, ), ), );
   }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;
    String displayName = user?.displayName ?? user?.email?.split('@')[0] ?? 'Kullanıcı';
    if (displayName.isEmpty) displayName = 'Kullanıcı';
    final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final Color errorColor = Theme.of(context).colorScheme.error;
    final Color primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        padding: const EdgeInsets.only(top: 20.0, bottom: 30.0),
        children: [
          Padding( padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0), child: Text( 'Merhaba, $displayName!', style: GoogleFonts.poppins( fontSize: 24, fontWeight: FontWeight.bold, color: onSurfaceColor ) ) ),
          Card( margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), elevation: 1, child: Column( children: [ _buildSectionHeader('Hesap Bilgileri'), _buildListTile( context: context, icon: Icons.person_outline, title: 'Kişisel Bilgilerimi Düzenle', subtitle: 'Ad, unvan, iletişim vb.', onTap: () { final selectedCvId = Provider.of<CvProvider>(context, listen: false).selectedCvId; if (selectedCvId == null) { _showInfoSnackBar("Lütfen önce düzenlenecek bir CV seçin."); } else { Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalInfoScreen())); } } ), ], ), ),
          Card( margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), elevation: 1, child: Padding( padding: const EdgeInsets.only(bottom: 16.0), child: Column( children: [ _buildSectionHeader('LinkedIn Analizi'), Padding( padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), child: Column( children: [ TextField( controller: _linkedinController, keyboardType: TextInputType.url, decoration: const InputDecoration( labelText: 'LinkedIn Profil URL\'niz', hintText: 'https://www.linkedin.com/in/...', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14), isDense: true, ) ), const SizedBox(height: 12), _isAnalyzing ? const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()) : ElevatedButton.icon( icon: const Icon(Icons.analytics_outlined, size: 18), label: const Text('Genel LinkedIn İpuçları Al'), onPressed: _isAnalyzing ? null : _analyzeLinkedIn, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45)) ), ], ), ), if (_analysisError != null) Padding( padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), child: Text(_analysisError!, style: TextStyle(color: errorColor), textAlign: TextAlign.center) ), if (_analysisResult != null) Padding( padding: const EdgeInsets.all(16.0), child: Container( padding: const EdgeInsets.all(12), decoration: BoxDecoration( color: Theme.of(context).colorScheme.surface.withOpacity(0.8), borderRadius: BorderRadius.circular(8), border: Border.all(color: Theme.of(context).dividerColor) ), child: SelectableText(_analysisResult!, style: TextStyle(color: onSurfaceColor)) ) ), ], ), ), ),
          Card( margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), elevation: 1, child: Column( children: [ _buildSectionHeader('Uygulama'), _buildListTile( context: context, icon: Icons.help_outline, title: 'Yardım / S.S.S', subtitle: 'Sıkça sorulan sorular ve ipuçları' ), _buildListTile( context: context, icon: Icons.settings_outlined, title: 'Ayarlar', subtitle: 'Uygulama ayarlarını yapılandırın', onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())); } ), _buildListTile( context: context, icon: Icons.delete_outline, title: 'Hesabımı Sil', onTap: () { _showInfoSnackBar('Hesap Silme henüz eklenmedi.'); } ), ListTile( contentPadding: const EdgeInsets.symmetric(horizontal: 16.0), leading: Icon(Icons.logout, color: errorColor, size: 22), title: Text( 'Çıkış Yap', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: errorColor) ), trailing: Icon(Icons.chevron_right, color: errorColor.withOpacity(0.5)), onTap: () => _logout(context), dense: true, ), const SizedBox(height: 8), ], ), ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}