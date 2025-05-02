import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Google Fonts ekleyelim başlık için
import 'package:yeni_cv_uygulamasi/screens/cv_editor/personal_info_screen.dart';
import 'package:yeni_cv_uygulamasi/screens/cv_editor/experience_screen.dart';
import 'package:yeni_cv_uygulamasi/screens/cv_editor/education_screen.dart';
import 'package:yeni_cv_uygulamasi/screens/cv_editor/skills_screen.dart';
import 'package:yeni_cv_uygulamasi/screens/cv_editor/projects_screen.dart';
import 'package:yeni_cv_uygulamasi/screens/cv_editor/summary_screen.dart'; // Özet ekranı importu

class EditorLandingScreen extends StatelessWidget {
  const EditorLandingScreen({super.key});

  // Buton stilini dışarı alabiliriz
  ButtonStyle _buttonStyle(BuildContext context) {
      return ElevatedButton.styleFrom(
           padding: const EdgeInsets.symmetric(vertical: 14.0), // Buton yüksekliği
           textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500), // Buton yazı stili
           shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
         );
  }

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _buttonStyle(context); // Stili al

    return Scaffold(
       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
       body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.edit_note_outlined, size: 60, color: Colors.grey.shade500),
                const SizedBox(height: 16),
                Text(
                  'CV Bölümlerini Düzenle', // Başlık güncellendi
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold) // Font kullanıldı
                ),
                const SizedBox(height: 32), // Boşluk artırıldı

                ElevatedButton.icon(
                  style: buttonStyle, // Stil uygulandı
                  icon: const Icon(Icons.person_outline, size: 20),
                  label: const Text('Kişisel Bilgiler'),
                  onPressed: () {
                     Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalInfoScreen()));
                  },
                ),
                 const SizedBox(height: 12),
                 ElevatedButton.icon(
                   style: buttonStyle,
                   icon: const Icon(Icons.work_outline, size: 20),
                   label: const Text('İş Deneyimi'),
                   onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ExperienceScreen()));
                   },
                 ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                   style: buttonStyle,
                   icon: const Icon(Icons.school_outlined, size: 20),
                   label: const Text('Eğitim Bilgileri'),
                   onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const EducationScreen()));
                   },
                 ),
                 const SizedBox(height: 12),
                 ElevatedButton.icon(
                   style: buttonStyle,
                   icon: const Icon(Icons.psychology_outlined, size: 20),
                   label: const Text('Yetenekler'),
                   onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SkillsScreen()));
                   },
                 ),
                 const SizedBox(height: 12),
                 ElevatedButton.icon(
                   style: buttonStyle,
                   icon: const Icon(Icons.folder_copy_outlined, size: 20),
                   label: const Text('Projeler'),
                   onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ProjectsScreen()));
                   },
                 ),
                 const SizedBox(height: 12),
                 ElevatedButton.icon(
                   style: buttonStyle,
                   icon: const Icon(Icons.subject_outlined, size: 20),
                   label: const Text('Özet / Kariyer Hedefi'),
                   onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SummaryScreen()));
                   },
                 ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}