import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:yeni_cv_uygulamasi/providers/cv_provider.dart';
// Tüm düzenleyici ekranlarını import et
import 'package:yeni_cv_uygulamasi/screens/cv_editor/personal_info_screen.dart';
import 'package:yeni_cv_uygulamasi/screens/cv_editor/experience_screen.dart';
import 'package:yeni_cv_uygulamasi/screens/cv_editor/education_screen.dart';
import 'package:yeni_cv_uygulamasi/screens/cv_editor/skills_screen.dart';
import 'package:yeni_cv_uygulamasi/screens/cv_editor/projects_screen.dart';
import 'package:yeni_cv_uygulamasi/screens/cv_editor/summary_screen.dart';


class CvEditorMainScreen extends StatefulWidget {
  const CvEditorMainScreen({super.key});

  @override
  State<CvEditorMainScreen> createState() => _CvEditorMainScreenState();
}

class _CvEditorMainScreenState extends State<CvEditorMainScreen> {
  int _selectedSectionIndex = 0;
  final PageController _pageController = PageController();

  final List<Map<String, dynamic>> sections = [
    {'title': 'Kişisel Bilgiler', 'icon': Icons.person_outline},
    {'title': 'Deneyim', 'icon': Icons.work_outline},
    {'title': 'Eğitim', 'icon': Icons.school_outlined},
    {'title': 'Yetenekler', 'icon': Icons.psychology_outlined},
    {'title': 'Projeler', 'icon': Icons.folder_copy_outlined},
    {'title': 'Özet', 'icon': Icons.subject_outlined},
  ];

  // --- sectionWidgets listesi GÜNCELLENDİ ---
  // Her bölüme ait tam ekran widget'larını içerir
   final List<Widget> sectionWidgets = [
     const PersonalInfoScreen(),
     const ExperienceScreen(),
     const EducationScreen(),
     const SkillsScreen(),
     const ProjectsScreen(),
     const SummaryScreen(),
   ];
  // --- ---

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCvName = context.watch<CvProvider>().selectedCvName;
    final selectedCvId = context.watch<CvProvider>().selectedCvId;

    // Eğer CV seçilmemişse, kullanıcıya bilgi ver ve boş bir container göster
    if (selectedCvId == null) {
       return Scaffold(
           // Bu ekranda AppBar olmamalı, çünkü HomeScreen'de var.
           // AppBar(title: Text("Düzenleyici")),
           body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Icon(Icons.folder_off_outlined, size: 60, color: Colors.grey),
                     SizedBox(height: 16),
                     Text(
                        "Lütfen önce 'CVlerim' sekmesinden düzenlemek veya oluşturmak için bir CV seçin.",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                     ),
                  ],
                ),
              ),
           )
       );
    }

    // CV Seçiliyse gösterilecek UI
    return Scaffold(
      // Bu ekrana özel AppBar eklemeyelim, HomeScreen'deki yeterli
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Yatay Kaydırılabilir Bölüm Seçici
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: List.generate(sections.length, (index) {
                  bool isSelected = _selectedSectionIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                       avatar: Icon(
                         sections[index]['icon'],
                         color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.primary,
                         size: 18,
                       ),
                       label: Text(sections[index]['title']),
                       labelStyle: TextStyle(
                         color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).textTheme.bodyLarge?.color,
                         fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                       ),
                       backgroundColor: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
                       onPressed: () {
                         // setState(() { _selectedSectionIndex = index; }); // PageView onPageChanged halledecek
                         _pageController.animateToPage(
                           index,
                           duration: const Duration(milliseconds: 300),
                           curve: Curves.easeInOut,
                         );
                       },
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                       padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                       side: BorderSide.none,
                     ),
                  );
                }),
              ),
            ),
          ),

          // Seçili Bölümün İçeriği (PageView ile)
          Expanded(
            child: PageView(
                   controller: _pageController,
                   onPageChanged: (index) {
                     setState(() { _selectedSectionIndex = index; });
                   },
                   // --- GÜNCELLENDİ: Gerçek ekranlar ---
                   children: sectionWidgets,
                   // --- ---
                 )
          ),
        ],
      ),
    );
  }
}