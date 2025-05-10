import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:yeni_cv_uygulamasi/screens/auth_gate.dart';
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
    // --- YENİ RENK PALETİ: Gri Tonları, Teknoloji Mavisi ve Enerjik Kırmızı ---
    const Color primaryBlue = Color(0xFF4A90E2); // Ana vurgu - Canlı ama sofistike bir mavi
    const Color secondaryRed = Color(0xFFE53935); // İkincil vurgu - Mevcut enerjik kırmızı
    
    const Color darkBackground = Color(0xFF1C1E1F); // Çok koyu, hafif dokulu gri
    const Color surfaceColor = Color(0xFF242729);   // Kartlar, yüzeyler için biraz daha açık
    
    const Color onPrimaryColor = Colors.white; // Mavi buton üzeri
    const Color onSecondaryColor = Colors.white; // Kırmızı buton üzeri
    
    const Color onSurfaceColor = Color(0xFFE1E3E6);      // Ana metin (kırık beyaz)
    const Color onSurfaceVariantColor = Color(0xFFA0A7AF); // İkincil metin, pasif ikonlar
    
    const Color outlineColor = Color(0xFF3C4043);    // Kenarlıklar, ayırıcılar
    const Color errorColor = Color(0xFFCF6679);      // Hata rengi (Material Dark)

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
        primaryColor: primaryBlue, // Ana tema rengi mavi oldu
        scaffoldBackgroundColor: darkBackground,
        
        colorScheme: ColorScheme( // ColorScheme'i manuel tanımlamak daha fazla kontrol sağlar
          brightness: Brightness.dark,
          primary: primaryBlue,
          onPrimary: onPrimaryColor,
          secondary: secondaryRed, // Kırmızı artık ikincil vurgu
          onSecondary: onSecondaryColor,
          error: errorColor,
          onError: darkBackground,
          background: darkBackground,
          onBackground: onSurfaceColor,
          surface: surfaceColor,
          onSurface: onSurfaceColor,
          surfaceVariant: Color.alphaBlend(Colors.white.withOpacity(0.05), surfaceColor), // Yüzeyin hafif bir varyantı
          onSurfaceVariant: onSurfaceVariantColor,
          outline: outlineColor,
          shadow: Colors.black.withOpacity(0.2),
          inverseSurface: onSurfaceColor, // Koyu tema için açık renkli yüzey
          onInverseSurface: darkBackground, // Açık yüzey üzeri koyu metin
          primaryContainer: Color.alphaBlend(primaryBlue.withOpacity(0.1), surfaceColor),
          onPrimaryContainer: primaryBlue,
        ),
        
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ).copyWith(
          bodyLarge: TextStyle(color: onSurfaceColor, fontSize: 16, fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(color: onSurfaceColor, fontSize: 14, fontWeight: FontWeight.w400),
          titleLarge: GoogleFonts.poppins(color: onSurfaceColor, fontSize: 22, fontWeight: FontWeight.w600),
          titleMedium: GoogleFonts.poppins(color: onSurfaceColor, fontSize: 18, fontWeight: FontWeight.w600),
          titleSmall: GoogleFonts.poppins(color: onSurfaceColor, fontSize: 16, fontWeight: FontWeight.w500),
          labelLarge: GoogleFonts.poppins(color: onPrimaryColor, fontSize: 15, fontWeight: FontWeight.w600), // Mavi buton metni
          bodySmall: TextStyle(color: onSurfaceVariantColor, fontSize: 12),
        ),
        
        appBarTheme: AppBarTheme(
          backgroundColor: surfaceColor, // Veya darkBackground.withOpacity(0.9) gibi
          foregroundColor: onSurfaceColor,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: onSurfaceColor),
          iconTheme: IconThemeData(color: onSurfaceVariantColor), // AppBar ikonları biraz daha soluk
          actionsIconTheme: IconThemeData(color: onSurfaceVariantColor),
        ),
        
        cardTheme: CardTheme(
          elevation: 1.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
             side: BorderSide(color: outlineColor.withOpacity(0.5), width: 0.5), // İnce kenarlık
          ),
          color: surfaceColor,
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Tutarlı boşluk
        ),
        
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color.alphaBlend(Colors.white.withOpacity(0.03), darkBackground), // Çok hafif farklı dolgu
          contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: outlineColor.withOpacity(0.5)), // Daha yumuşak kenarlık
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: outlineColor.withOpacity(0.7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: primaryBlue, width: 1.5), // Odaklanınca mavi
          ),
          labelStyle: GoogleFonts.poppins(color: onSurfaceVariantColor, fontSize: 15),
          hintStyle: GoogleFonts.poppins(color: onSurfaceVariantColor.withOpacity(0.7), fontSize: 15),
          prefixIconColor: onSurfaceVariantColor,
          suffixIconColor: onSurfaceVariantColor,
          errorStyle: GoogleFonts.poppins(color: errorColor, fontSize: 12),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: errorColor, width: 1.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: errorColor, width: 1.5),
          ),
        ),
        
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue, // Ana butonlar mavi
            foregroundColor: onPrimaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
            padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 28.0),
            textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.5),
            elevation: 2,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryBlue, // Metin butonları mavi
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          )
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
           style: OutlinedButton.styleFrom(
             foregroundColor: onSurfaceColor,
             side: BorderSide(color: outlineColor),
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
             padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
             textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)
           )
        ),
        
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          // AnimatedBottomNavigationBar kendi stilini alır, bu genel bir fallback
          backgroundColor: surfaceColor, 
          selectedItemColor: primaryBlue, // Seçili ikon mavi
          unselectedItemColor: onSurfaceVariantColor,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          selectedIconTheme: const IconThemeData(size: 26),
          unselectedIconTheme: const IconThemeData(size: 22),
          elevation: 0,
        ),

        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: secondaryRed, // FAB kırmızı
          foregroundColor: onSecondaryColor,
          elevation: 4,
          shape: const CircleBorder(),
        ),

        dialogTheme: DialogTheme(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          titleTextStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: onSurfaceColor),
          contentTextStyle: GoogleFonts.poppins(fontSize: 15, color: onSurfaceColor.withOpacity(0.9)),
        ),

        listTileTheme: ListTileThemeData(
          iconColor: onSurfaceVariantColor,
          textColor: onSurfaceColor,
          subtitleTextStyle: GoogleFonts.poppins(color: onSurfaceVariantColor.withOpacity(0.9), fontSize: 13),
          dense: false, // Biraz daha ferah listeler için false deneyebiliriz
          contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0), // Padding ayarı
        ),

        chipTheme: ChipThemeData(
          backgroundColor: primaryBlue.withOpacity(0.15), // Chip arkaplanı mavi tonu
          labelStyle: GoogleFonts.poppins(color: primaryBlue, fontWeight: FontWeight.w500, fontSize: 13),
          secondaryLabelStyle: GoogleFonts.poppins(color: primaryBlue, fontWeight: FontWeight.w500),
          deleteIconColor: primaryBlue.withOpacity(0.7),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          side: BorderSide.none,
        ),

        dividerTheme: DividerThemeData(
          color: outlineColor.withOpacity(0.3), // Daha yumuşak ayırıcı
          thickness: 0.8,
          space: 1,
          indent: 16,
          endIndent: 16,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}