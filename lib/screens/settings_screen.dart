import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkModeEnabled = false;
  bool _notificationsEnabled = true;

  // ListTile oluşturan yardımcı fonksiyon (DÜZELTİLDİ)
  Widget _buildSettingsTile({
    required BuildContext context, // <-- EKSİK PARAMETRE EKLENDİ
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    // Fonksiyonun içeriği aynı kalıyor, sadece tanımı düzeltildi
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: GoogleFonts.poppins(fontSize: 15)),
      subtitle: subtitle != null ? Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)) : null,
      trailing: trailing,
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title özelliği henüz eklenmedi.'), duration: const Duration(seconds: 1)),
        );
      },
    );
  }

  // Bölüm başlığı (Bu fonksiyon doğruydu)
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.poppins( fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade600 ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ayarlar', style: GoogleFonts.poppins()),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Colors.black87,
        elevation: 1,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Görünüm'),
          SwitchListTile(
            secondary: Icon(Icons.dark_mode_outlined, color: Theme.of(context).colorScheme.primary),
            title: Text('Koyu Tema', style: GoogleFonts.poppins(fontSize: 15)),
            value: _darkModeEnabled,
            onChanged: (bool value) {
              setState(() { _darkModeEnabled = value; });
              ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Tema değiştirme henüz eklenmedi. (${value ? "Koyu" : "Açık"})'), duration: const Duration(seconds: 1)) );
            },
          ),

          _buildSectionHeader('Bildirimler'),
           SwitchListTile(
            secondary: Icon(Icons.notifications_outlined, color: Theme.of(context).colorScheme.primary),
            title: Text('Bildirimlere İzin Ver', style: GoogleFonts.poppins(fontSize: 15)),
            value: _notificationsEnabled,
            onChanged: (bool value) {
              setState(() { _notificationsEnabled = value; });
               ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Bildirim ayarı (${value ? "Açık" : "Kapalı"}) henüz kaydedilmiyor.'), duration: const Duration(seconds: 1)) );
            },
          ),

           _buildSectionHeader('Hesap'),
            _buildSettingsTile( // Artık context hatası vermemeli
              context: context,
              icon: Icons.password_outlined,
              title: 'Şifre Değiştir',
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () { /* TODO */ ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Şifre değiştirme henüz eklenmedi.'), duration: Duration(seconds: 1)) ); },
            ),
             _buildSettingsTile( // Artık context hatası vermemeli
              context: context,
              icon: Icons.delete_forever_outlined,
              title: 'Hesabımı Sil',
               trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () { /* TODO */ ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Hesap Silme henüz eklenmedi.'), duration: Duration(seconds: 1)) ); },
            ),

           _buildSectionHeader('Hakkında'),
            _buildSettingsTile( context: context, icon: Icons.info_outline, title: 'Hakkında', trailing: const Icon(Icons.chevron_right, color: Colors.grey), onTap: () { /* TODO */ } ),
             _buildSettingsTile( context: context, icon: Icons.privacy_tip_outlined, title: 'Gizlilik Politikası', trailing: const Icon(Icons.chevron_right, color: Colors.grey), onTap: () { /* TODO */ } ),
              _buildSettingsTile( context: context, icon: Icons.description_outlined, title: 'Kullanım Şartları', trailing: const Icon(Icons.chevron_right, color: Colors.grey), onTap: () { /* TODO */ } ),
             _buildSettingsTile( context: context, icon: Icons.alternate_email, title: 'İletişim / Geri Bildirim', trailing: const Icon(Icons.chevron_right, color: Colors.grey), onTap: () { /* TODO */ } ),

             Padding(
               padding: const EdgeInsets.only(top: 30.0, bottom: 20.0),
               child: Text( 'Uygulama Versiyonu: 1.0.0', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 12) ),
             )
        ],
      ),
    );
  }
}