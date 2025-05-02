import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ÖNEMLİ: Aşağıdaki import yollarının projenle eşleştiğinden emin ol
import 'package:yeni_cv_uygulamasi/screens/auth/welcome_screen.dart';
import 'package:yeni_cv_uygulamasi/screens/home_screen.dart'; // Yeni eklediğimiz HomeScreen

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Firebase Authentication state değişikliklerini dinle
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Henüz bağlantı kurulmadıysa veya bekleniyorsa bekleme ekranı göster
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Basit bir bekleme göstergesi
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Eğer snapshot'ta veri varsa (User nesnesi null değilse), kullanıcı giriş yapmış demektir
        if (snapshot.hasData) {
          // Ana ekrana yönlendir
          return const HomeScreen();
        }

        // Eğer snapshot'ta veri yoksa (User nesnesi null ise), kullanıcı giriş yapmamış demektir
        // Giriş/Kayıt ekranlarına yönlendir (WelcomeScreen üzerinden)
        return const WelcomeScreen();
      },
    );
  }
}