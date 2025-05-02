import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:yeni_cv_uygulamasi/screens/settings_screen.dart'; // Import sonra eklenecek

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      if(Navigator.canPop(context)) Navigator.pop(context);
      await FirebaseAuth.instance.signOut();
    } catch (e) { print("Drawer'dan çıkış yapılırken hata: $e"); }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    String displayName = user?.displayName ?? user?.email?.split('@')[0] ?? 'Kullanıcı';
    if(displayName.isEmpty) displayName = 'Kullanıcı';
    String displayEmail = user?.email ?? '';

    final Color primaryColor = Theme.of(context).primaryColor;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      // Drawer arkaplanını da tema ile uyumlu yapalım
      backgroundColor: colorScheme.surface, // Koyu tema kart rengi
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Sadeleştirilmiş Header (Arka plan resmi kaldırıldı)
          Container(
            padding: const EdgeInsets.fromLTRB(16.0, 50.0, 16.0, 20.0), // Üst boşluk arttı
            // Arka plan rengi hafif farklı olabilir
            color: colorScheme.surfaceVariant.withOpacity(0.2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 CircleAvatar(
                  radius: 35,
                  backgroundColor: primaryColor, // Kırmızı
                  child: Icon( Icons.person, size: 40, color: colorScheme.onPrimary ), // Beyaz ikon
                ),
                const SizedBox(height: 12),
                Text(
                  displayName,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.onSurface), // Açık renk yazı
                ),
                 if (displayEmail.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text( displayEmail, style: GoogleFonts.poppins(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.7))), // Soluk yazı
                    ),
              ],
            )
          ),
          // Menü Elemanları (Renkler tema'dan alınacak)
          ListTile(
            leading: Icon(Icons.settings_outlined, color: colorScheme.onSurfaceVariant), // Daha soluk ikon
            title: Text('Ayarlar', style: TextStyle(color: colorScheme.onSurface)), // Açık renk yazı
            onTap: () {
              Navigator.pop(context);
              // Navigator.pushNamed(context, '/settings'); // Rota eklenince
              ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Ayarlar ekranı henüz tam bağlanmadı.'), duration: Duration(seconds: 1)) );
            },
          ),
           ListTile(
            leading: Icon(Icons.help_outline, color: colorScheme.onSurfaceVariant),
            title: Text('Yardım / S.S.S', style: TextStyle(color: colorScheme.onSurface)),
            onTap: () { Navigator.pop(context); /* TODO */ },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: colorScheme.error), // Kırmızı tema rengi
            title: Text('Çıkış Yap', style: TextStyle(color: colorScheme.error)), // Kırmızı tema rengi
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}