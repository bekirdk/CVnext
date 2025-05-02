import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yeni_cv_uygulamasi/screens/cv_editor/personal_info_screen.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:yeni_cv_uygulamasi/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:yeni_cv_uygulamasi/providers/cv_provider.dart';

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

  final String _apiKey = "YOUR_API_KEY"; // API Key

  @override
  void dispose() { _linkedinController.dispose(); super.dispose(); }

  Future<void> _logout(BuildContext context) async { try { if(Navigator.canPop(context)) Navigator.pop(context); await _auth.signOut(); print("Çıkış yapıldı."); } catch (e) { print("Çıkış yapılırken hata: $e"); } }
  Future<void> _analyzeLinkedIn() async { /* ... Önceki kod ... */ }
  void _showSnackBar(String message, {Color backgroundColor = Colors.grey}) { if (!mounted) return; ScaffoldMessenger.of(context).removeCurrentSnackBar(); ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(message), backgroundColor: backgroundColor, duration: const Duration(seconds: 2)) ); }
  void _showErrorSnackBar(String message) { _showSnackBar(message, backgroundColor: Theme.of(context).colorScheme.error); }
  void _showSuccessSnackBar(String message) { _showSnackBar(message, backgroundColor: Colors.green); }
  void _showInfoSnackBar(String message) { _showSnackBar(message, backgroundColor: Colors.orangeAccent); }
  void _handleAiError(Object e, String operation) { /* ... Hata yönetimi ... */ }


  // --- YARDIMCI FONKSİYONLAR (DÜZELTİLDİ) ---
   Widget _buildListTile({
      required BuildContext context, // context parametresi eklendi
      required IconData icon,
      required String title,
      String? subtitle,
      Widget? trailing,
      VoidCallback? onTap,
   }) {
      final Color primaryColor = Theme.of(context).primaryColor;
      final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;
      final Color secondaryTextColor = onSurfaceColor.withOpacity(0.7);
      return ListTile(
         leading: Icon(icon, color: primaryColor, size: 22),
         title: Text(title, style: GoogleFonts.poppins(fontSize: 15, color: onSurfaceColor)),
         subtitle: subtitle != null ? Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: secondaryTextColor)) : null,
         trailing: trailing ?? Icon(Icons.chevron_right, color: secondaryTextColor), // Null ise chevron göster
         onTap: onTap ?? () { _showInfoSnackBar('$title özelliği henüz eklenmedi.'); },
      );
   }

   Widget _buildSectionHeader(String title) {
     return Padding(
       padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 24.0, bottom: 8.0),
       child: Text( title, style: GoogleFonts.poppins( fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6) ), ),
     );
   }
   // --- ---

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;
    String displayName = user?.displayName ?? user?.email?.split('@')[0] ?? 'Kullanıcı';
    if(displayName.isEmpty) displayName = 'Kullanıcı';
    final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final Color secondaryTextColor = onSurfaceColor.withOpacity(0.7);
    final Color errorColor = Theme.of(context).colorScheme.error;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
        children: [
          Padding( padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0), child: Text( 'Merhaba, ${displayName}!', style: GoogleFonts.poppins( fontSize: 24, fontWeight: FontWeight.bold, color: onSurfaceColor ) ) ),

          _buildSectionHeader('Hesap'),
          // --- _buildListTile ÇAĞRILARI DÜZELTİLDİ (context eklendi) ---
          _buildListTile( context: context, icon: Icons.person_outline, title: 'Bilgilerim', onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalInfoScreen())); } ),

          _buildSectionHeader('LinkedIn Analizi'),
          // --- Padding İÇERİĞİ DOLDURULDU ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
               children: [
                 TextField( controller: _linkedinController, keyboardType: TextInputType.url, decoration: const InputDecoration( labelText: 'LinkedIn Profil URL\'nizi Yapıştırın', hintText: 'https://www.linkedin.com/in/...', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14), isDense: true ) ),
                 const SizedBox(height: 12),
                 _isAnalyzing ? const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()) : ElevatedButton.icon( icon: const Icon(Icons.analytics_outlined, size: 18), label: const Text('LinkedIn Profil İpuçları Al'), onPressed: _isAnalyzing ? null : _analyzeLinkedIn, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45)) ),
               ],
            ),
          ),
          // --- ---
          if (_analysisError != null) Padding( padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), child: Text(_analysisError!, style: TextStyle(color: errorColor), textAlign: TextAlign.center) ),
          if (_analysisResult != null) Padding( padding: const EdgeInsets.all(16.0), child: Container( padding: const EdgeInsets.all(12), decoration: BoxDecoration( color: Theme.of(context).primaryColor.withOpacity(0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)) ), child: SelectableText(_analysisResult!, style: TextStyle(color: onSurfaceColor)) ) ),

          _buildSectionHeader('Uygulama'),
           // --- _buildListTile ÇAĞRILARI DÜZELTİLDİ (context eklendi) ---
          _buildListTile(context: context, icon: Icons.help_outline, title: 'S.S.S / Yardım'),
          _buildListTile( context: context, icon: Icons.settings_outlined, title: 'Ayarlar', onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())); } ),

          _buildSectionHeader('Hesap Yönetimi'),
          _buildListTile( context: context, icon: Icons.delete_outline, title: 'Hesabımı Sil', onTap: () { _showInfoSnackBar('Hesap Silme henüz eklenmedi.'); } ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            leading: Icon(Icons.logout, color: errorColor, size: 22), // Boyut ayarlandı
            title: Text( 'Çıkış Yap', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: errorColor) ),
            trailing: Icon(Icons.chevron_right, color: errorColor),
            onTap: () => _logout(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}