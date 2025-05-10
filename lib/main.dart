// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // BU IMPORT YOLUNUN DOĞRU VE DOSYANIN MEVCUT OLDUĞUNDAN EMİN OLUN!
import 'package:yeni_cv_uygulamasi/screens/auth_gate.dart'; // BU IMPORT YOLUNU KONTROL EDİN
import 'package:provider/provider.dart';
import 'package:yeni_cv_uygulamasi/providers/cv_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
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
    // --- RENK PALETİ (Referans Görsele Göre - Beyaz/Açık Gri Yuvalı İkonlar) ---
    const Color primaryAppBlue = Color(0xFF0A7AFF); 
    const Color appBackground = Color(0xFF000000); 
    const Color surfaceColor = Color(0xFF1C1C1E);   
    const Color surfaceVariantColor = Color(0xFF121212); 
    const Color iconWellBackground = Color(0xFFE5E5EA); // İkonların beyaz/açık gri oval zemini
    // const Color iconWellBackground = Color(0xFF2C2C2E); // Koyu tema için alternatif
    
    const Color onPrimaryColor = Colors.white;     
    const Color primaryTextColor = Color(0xFFFFFFFF);      
    const Color secondaryTextColor = Color(0xFF8A8E93); 
    const Color outlineColor = Color(0xFF3A3A3C); 
    const Color errorColor = Color(0xFFFF3B30);      
    const Color onErrorColor = Colors.white;

    return MaterialApp(
      title: 'AI CV Builder',
      themeMode: ThemeMode.dark,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('tr', 'TR'),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: primaryAppBlue, 
        scaffoldBackgroundColor: appBackground,
        
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: primaryAppBlue,
          onPrimary: onPrimaryColor,
          secondary: primaryAppBlue.withOpacity(0.85), 
          onSecondary: onPrimaryColor,
          error: errorColor,
          onError: onErrorColor,
          background: appBackground,
          onBackground: primaryTextColor,
          surface: surfaceColor, 
          onSurface: primaryTextColor, 
          surfaceVariant: surfaceVariantColor, 
          onSurfaceVariant: secondaryTextColor, 
          outline: outlineColor, 
          shadow: Colors.black.withOpacity(0.3),
          inverseSurface: primaryTextColor, 
          onInverseSurface: appBackground, 
          primaryContainer: Color.alphaBlend(primaryAppBlue.withOpacity(0.2), surfaceColor),
          onPrimaryContainer: primaryAppBlue,
          tertiaryContainer: iconWellBackground, 
          onTertiaryContainer: primaryAppBlue,  
        ),
        
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ).copyWith(
          bodyLarge: TextStyle(color: primaryTextColor, fontSize: 17, fontWeight: FontWeight.w400, height: 1.45),
          bodyMedium: TextStyle(color: primaryTextColor, fontSize: 15, fontWeight: FontWeight.w400, height: 1.4),
          headlineSmall: GoogleFonts.poppins(color: primaryTextColor, fontSize: 24, fontWeight: FontWeight.bold), // KPI değeri için küçültüldü
          titleLarge: GoogleFonts.poppins(color: primaryTextColor, fontSize: 20, fontWeight: FontWeight.w600), // Başlıklar için küçültüldü
          titleMedium: GoogleFonts.poppins(color: primaryTextColor, fontSize: 17, fontWeight: FontWeight.w600), 
          titleSmall: GoogleFonts.poppins(color: primaryTextColor, fontSize: 15, fontWeight: FontWeight.w500),
          labelLarge: GoogleFonts.poppins(color: onPrimaryColor, fontSize: 16, fontWeight: FontWeight.w600), // Buton yazısı
          bodySmall: TextStyle(color: secondaryTextColor, fontSize: 12.5, height: 1.3), // KPI başlığı için
        ),
        
        appBarTheme: AppBarTheme(
          backgroundColor: appBackground,
          foregroundColor: primaryTextColor,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: primaryTextColor),
          iconTheme: IconThemeData(color: primaryAppBlue),
          actionsIconTheme: IconThemeData(color: primaryAppBlue),
        ),
        
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          color: surfaceVariantColor, // Kartlar için daha koyu yüzey (referanstaki gibi)
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0), // Yatay margin'i MyCvsScreen'in padding'i yönetsin
        ),
        
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceVariantColor, // Kartlarla aynı zemin
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: primaryAppBlue, width: 1.5),
          ),
          labelStyle: GoogleFonts.poppins(color: secondaryTextColor, fontSize: 15),
          hintStyle: GoogleFonts.poppins(color: secondaryTextColor.withOpacity(0.7), fontSize: 15),
          prefixIconColor: secondaryTextColor,
          suffixIconColor: secondaryTextColor,
          errorStyle: GoogleFonts.poppins(color: errorColor, fontSize: 12),
        ),
        
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryAppBlue,
            foregroundColor: onPrimaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
            textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600), // Font boyutu ayarlandı
            elevation: 0,
          ),
        ),
        
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primaryAppBlue, // FAB ana vurgu rengi (mavi)
          foregroundColor: onPrimaryColor,
          elevation: 1, // Hafif bir gölge
          shape: const CircleBorder(),
        ),

        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: appBackground,
          selectedItemColor: primaryAppBlue, // Aktif ikon temadan (onTertiaryContainer) gelecek
          unselectedItemColor: secondaryTextColor.withOpacity(0.8), // Pasif ikon rengi
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          selectedIconTheme: const IconThemeData(size: 24), // Boyutları tabBuilder'da yöneteceğiz
          unselectedIconTheme: const IconThemeData(size: 22), // Pasif ikon biraz daha küçük
          elevation: 0,
        ),
        
        listTileTheme: ListTileThemeData(
          iconColor: secondaryTextColor,
          textColor: primaryTextColor,
          subtitleTextStyle: GoogleFonts.poppins(color: secondaryTextColor, fontSize: 12.5, height: 1.4), // Boyut ayarlandı
          dense: false,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),

        chipTheme: ChipThemeData(
          backgroundColor: primaryAppBlue.withOpacity(0.12),
          labelStyle: GoogleFonts.poppins(color: primaryAppBlue, fontWeight: FontWeight.w500, fontSize: 13),
          deleteIconColor: primaryAppBlue.withOpacity(0.7),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide.none,
        ),

        dividerTheme: DividerThemeData(
          color: outlineColor.withOpacity(0.5), // Daha yumuşak
          thickness: 0.8,
          space: 0,
          indent: 16,
          endIndent: 16,
        ),
        dialogTheme: DialogTheme(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
          titleTextStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: primaryTextColor),
          contentTextStyle: GoogleFonts.poppins(fontSize: 15, color: primaryTextColor.withOpacity(0.9)),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}