import 'package:yeni_cv_uygulamasi/screens/auth/login_screen.dart';
import 'package:yeni_cv_uygulamasi/screens/auth/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary; // Kırmızı
    final Color onPrimaryColor = Theme.of(context).colorScheme.onPrimary; // Beyaz
    final screenWidth = MediaQuery.of(context).size.width;

    // Buton stilleri (minimumSize önemli)
    final ButtonStyle loginButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.white.withOpacity(0.95), // Beyaz (opaklığa gerek kalmadı)
      foregroundColor: primaryColor,
      minimumSize: Size(screenWidth * 0.85, 52), // Biraz daha geniş
      shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(10.0) ),
      textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      elevation: 2, // Hafif gölge
    );

    final ButtonStyle signupButtonStyle = OutlinedButton.styleFrom(
      foregroundColor: onPrimaryColor,
      minimumSize: Size(screenWidth * 0.85, 52), // Biraz daha geniş
      side: BorderSide(color: onPrimaryColor.withOpacity(0.9), width: 1.5), // Kenarlık rengi
      shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(10.0) ),
      textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
    );

    return Scaffold(
      // Arka plan artık doğrudan kırmızı
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2), // Üst boşluk

              // Logo / Başlık (Ortalı)
              Text( 'AI CV Builder', textAlign: TextAlign.center, style: GoogleFonts.poppins( fontSize: 36, fontWeight: FontWeight.bold, color: onPrimaryColor, height: 1.3 ) ),
              const SizedBox(height: 12.0),
              Text( 'CV\'nizi Geleceğe Taşıyın', textAlign: TextAlign.center, style: GoogleFonts.poppins( fontSize: 18, color: onPrimaryColor.withOpacity(0.9) ) ),
              const SizedBox(height: 24.0),
              Text( 'Profesyonel CV\'ler oluşturmak ve AI desteği almak için giriş yapın veya kaydolun.', textAlign: TextAlign.center, style: GoogleFonts.poppins( fontSize: 15, color: onPrimaryColor.withOpacity(0.85), height: 1.5 ) ),

              const Spacer(flex: 3), // Butonlardan önce boşluk

              // Butonların olduğu Column (Stretch eklendi)
              Column(
                 crossAxisAlignment: CrossAxisAlignment.stretch, // Butonların genişlemesini sağlar
                 children: [
                    ElevatedButton( style: loginButtonStyle, onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())); }, child: const Text('Giriş Yap') ),
                    const SizedBox(height: 16.0),
                    OutlinedButton( style: signupButtonStyle, onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())); }, child: const Text('Kayıt Ol') ),
                 ],
              ),

              const Spacer(flex: 1), // En altta boşluk
            ],
          ),
        ),
      ),
    );
  }
}