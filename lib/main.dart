import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:yeni_cv_uygulamasi/screens/auth_gate.dart'; // Doğru import
import 'package:provider/provider.dart';
import 'package:yeni_cv_uygulamasi/providers/cv_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => CvProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Yeni Renk Paleti (Koyu Tema - Kırmızı Vurgu)
    const Color primaryRed = Color(0xFFE53935); // Canlı Kırmızı (Material Kırmızısı)
    const Color darkBackground = Color(0xFF121212); // Standart Koyu Gri/Siyah
    const Color surfaceColor = Color(0xFF1E1E1E); // Kartlar vb. için biraz daha açık koyu
    const Color lightTextColor = Colors.white; // Koyu arka plan üstü yazı
    const Color secondaryTextColor = Color(0xFFB0B0B0); // Daha az önemli yazılar için gri

    return MaterialApp(
      title: 'AI CV Builder',
      // Direkt koyu temayı ayarlayalım
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark, // Koyu tema
        primaryColor: primaryRed,
        scaffoldBackgroundColor: darkBackground, // Ana arka plan koyu
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryRed,
          brightness: Brightness.dark, // Önemli!
          background: darkBackground,
          surface: surfaceColor, // Kart vb. yüzeyler
          onSurface: lightTextColor, // Yüzey üzeri yazı
          primary: primaryRed,
          onPrimary: lightTextColor, // Kırmızı buton üzeri yazı
          secondary: Colors.redAccent,
          onSecondary: lightTextColor,
          error: Colors.redAccent.shade100,
          onError: Colors.black,
        ),
        // Font (Poppins iyi görünecektir)
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.apply( bodyColor: lightTextColor, displayColor: lightTextColor ) // Koyu temaya uygun
        ).copyWith( // Ekstra stil ayarları
           titleMedium: const TextStyle(color: secondaryTextColor),
           bodySmall: const TextStyle(color: secondaryTextColor),
        ),
        // AppBar Teması (Koyu)
        appBarTheme: AppBarTheme(
          backgroundColor: surfaceColor, // Hafif açık koyu
          foregroundColor: lightTextColor, // İkonlar ve varsayılan yazı beyaz/açık gri
          elevation: 0, // Gölge yok
          centerTitle: true, // Ortala
          titleTextStyle: GoogleFonts.poppins( fontSize: 18, fontWeight: FontWeight.w600, color: lightTextColor),
          iconTheme: const IconThemeData(color: lightTextColor),
          actionsIconTheme: const IconThemeData(color: lightTextColor), // Action ikonları da beyaz
        ),
        // Kart Teması (Koyu)
         cardTheme: CardTheme(
           elevation: 1.0, // Hafif gölge veya border eklenebilir
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
           color: surfaceColor, // Hafif açık koyu arka plan
           margin: const EdgeInsets.symmetric(vertical: 6.0), // Dikey boşluk
         ),
        // Input Teması (Koyu temaya uygun)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.black.withOpacity(0.15), // Daha koyu dolgu
          contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
          border: OutlineInputBorder( borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey.shade800) ), // Koyu kenarlık
          enabledBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey.shade800) ),
          focusedBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: primaryRed, width: 1.5) ), // Odaklanınca kırmızı
          labelStyle: GoogleFonts.poppins(color: secondaryTextColor, fontSize: 15),
          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 15),
          prefixIconColor: secondaryTextColor,
        ),
        // Buton Temaları
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryRed, foregroundColor: lightTextColor,
            shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(10.0) ),
            padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 24.0),
            textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600), elevation: 1,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom( foregroundColor: primaryRed, textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600) )
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
           style: OutlinedButton.styleFrom( foregroundColor: lightTextColor, side: BorderSide(color: Colors.grey.shade700), shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(10.0) ), padding: const EdgeInsets.symmetric(vertical: 15.0), textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600) )
        ),
        // Alt Navigasyon Bar Teması (Koyu)
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: surfaceColor, // Hafif açık koyu arka plan
          selectedItemColor: primaryRed, // Seçili ikon/yazı kırmızı
          unselectedItemColor: secondaryTextColor, // Seçili olmayan açık gri
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true, // Etiketleri gösterelim (resimdeki gibi)
          showUnselectedLabels: true,
          selectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
          elevation: 0, // Gölge yok
        ),
        dividerTheme: DividerThemeData( color: Colors.grey.shade800, thickness: 0.8 ),
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}