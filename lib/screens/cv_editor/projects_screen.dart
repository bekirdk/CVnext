import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_edit_project_screen.dart'; // Ekleme/Düzenleme ekranı

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<QueryDocumentSnapshot> _projectDocs = [];
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUser?.uid;
    if (_userId != null) {
       _loadProjects();
    } else {
       if(mounted) setState(() => _isLoading = false);
       print("Projeler yüklenemedi: Kullanıcı ID'si yok.");
       WidgetsBinding.instance.addPostFrameCallback((_) {
         if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Projeleri yüklemek için kullanıcı oturumu gerekli.'), backgroundColor: Colors.red),
            );
         }
       });
    }
  }

  Future<void> _loadProjects() async {
    if (_userId == null || !mounted) return;
    setState(() { _isLoading = true; });

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_userId!)
          .collection('projects')
          .orderBy('createdAt', descending: true) // En son eklenen üste gelsin
          .get();

      if (mounted) {
        setState(() {
          _projectDocs = querySnapshot.docs;
          _isLoading = false;
        });
      }
    } catch (e) {
       print("Projeler yüklenirken hata: $e");
       if (mounted) {
         setState(() { _isLoading = false; });
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Projeler yüklenirken bir hata oluştu.'), backgroundColor: Colors.red),
          );
       }
    }
  }

  Future<void> _navigateToAddProject() async {
     if (_userId == null || !mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşlem için kullanıcı oturumu gerekli.'), backgroundColor: Colors.red),
       );
       return;
     }

     final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(builder: (context) => const AddEditProjectScreen()),
     );

     if (result != null && result.containsKey('data') && mounted) {
        await _addProjectToFirestore(result['data']);
     }
  }

   Future<void> _addProjectToFirestore(Map<String, dynamic> data) async {
     if (_userId == null || !mounted) return;
     setState(() { _isLoading = true; });
     try {
        await _firestore
            .collection('users')
            .doc(_userId!)
            .collection('projects')
            .add({ ...data, 'createdAt': FieldValue.serverTimestamp() });
        await _loadProjects();
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Proje başarıyla eklendi.'), backgroundColor: Colors.green),
            );
         }
      } catch (e) {
         print("Proje eklenirken hata: $e");
         if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Proje eklenirken bir hata oluştu.'), backgroundColor: Colors.red),
           );
         }
      } finally { if (mounted) { setState(() { _isLoading = false; }); } }
  }


  Future<void> _navigateToEditProject(QueryDocumentSnapshot doc) async {
      if (_userId == null || !mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşlem için kullanıcı oturumu gerekli.'), backgroundColor: Colors.red),
        );
        return;
      }

      // Düzenleme ekranına mevcut veriyi ve doküman ID'sini gönder
      final result = await Navigator.push<Map<String, dynamic>>(
         context,
         MaterialPageRoute(builder: (context) => AddEditProjectScreen(
            // Veriyi Map<String, dynamic> olarak cast etmeye çalış, olmazsa null kalsın
            initialData: doc.data() is Map<String, dynamic> ? doc.data() as Map<String, dynamic> : null,
            docId: doc.id // Doküman ID'sini gönder
         )),
      );

      // Eğer kullanıcı güncellenmiş veriyle geri döndüyse
      if (result != null && result.containsKey('data') && result.containsKey('docId') && mounted) {
         final String returnedDocId = result['docId'];
         final Map<String, dynamic> updatedData = result['data'];
         // Firestore'u güncellemek için yeni fonksiyonu çağır
         await _updateProjectInFirestore(returnedDocId, updatedData);
      }
  }

   // Firestore'daki proje dokümanını güncelleyen fonksiyon
   Future<void> _updateProjectInFirestore(String docId, Map<String, dynamic> data) async {
      if (_userId == null || !mounted) return;
      setState(() { _isLoading = true; });
       try {
         await _firestore
             .collection('users')
             .doc(_userId!)
             .collection('projects')
             .doc(docId) // Güncellenecek dokümanın ID'si
             .update({ // Update kullanıyoruz
                ...data,
                'lastUpdated': FieldValue.serverTimestamp(), // Güncelleme zamanı
              });
         await _loadProjects(); // Listeyi yenile
         if(mounted){
           ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Proje başarıyla güncellendi.'), backgroundColor: Colors.green),
           );
         }
       } catch (e) {
         print("Proje güncellenirken hata: $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Proje güncellenirken bir hata oluştu.'), backgroundColor: Colors.red),
           );
          }
       } finally {
         if (mounted) { setState(() { _isLoading = false; }); }
       }
   }

  Future<void> _deleteProject(QueryDocumentSnapshot doc) async {
     if (_userId == null || !mounted) return;

      final bool? confirmDelete = await showDialog<bool>(
         context: context,
         builder: (context) => AlertDialog(
            title: const Text('Projeyi Sil'),
            content: Text('"${(doc.data() as Map<String,dynamic>?)?['projectName'] ?? 'Bu'}" projesini silmek istediğinizden emin misiniz?'),
            actions: [
               TextButton(onPressed: ()=>Navigator.pop(context, false), child: const Text('İptal')),
               TextButton(onPressed: ()=>Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Sil')),
            ],
         )
      );
      if (confirmDelete != true) return;

     setState(() { _isLoading = true; });
     try {
        await _firestore
            .collection('users')
            .doc(_userId!)
            .collection('projects')
            .doc(doc.id)
            .delete();
        await _loadProjects();
        if(mounted){
           ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Proje silindi.'), backgroundColor: Colors.orange),
           );
        }
     } catch (e) {
        print("Proje silinirken hata: $e");
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Proje silinirken bir hata oluştu.'), backgroundColor: Colors.red),
            );
          }
     } finally {
        if (mounted) {
           setState(() { _isLoading = false; });
        }
     }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Projeler', style: GoogleFonts.poppins()),
      ),
      body: RefreshIndicator(
         onRefresh: _loadProjects,
         child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _projectDocs.isEmpty
                ? LayoutBuilder(
                     builder: (context, constraints) => SingleChildScrollView(
                       physics: const AlwaysScrollableScrollPhysics(),
                       child: ConstrainedBox(
                         constraints: BoxConstraints(minHeight: constraints.maxHeight),
                         child: Center(
                             child: Column(
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                 Icon(Icons.folder_copy_outlined, size: 60, color: Colors.grey.shade400),
                                 const SizedBox(height: 16),
                                 const Text('Henüz proje eklenmemiş.'),
                                 const SizedBox(height: 16),
                                 ElevatedButton.icon(
                                   icon: const Icon(Icons.add),
                                   label: const Text('İlk Projeyi Ekle'),
                                   onPressed: _navigateToAddProject,
                                 ),
                               ],
                             ),
                           ),
                       ),
                     ),
                   )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80.0),
                    itemCount: _projectDocs.length,
                    itemBuilder: (context, index) {
                      final projectDoc = _projectDocs[index];
                      final project = projectDoc.data() as Map<String, dynamic>?;
                      if (project == null) return const SizedBox.shrink();

                      final technologies = (project['technologies'] as List<dynamic>?)?.join(', ') ?? '';

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                           contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          title: Text(
                            project['projectName'] ?? 'Proje Adı Yok',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (project['description'] != null && (project['description'] as String).isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                                  child: Text(
                                    project['description'],
                                    maxLines: 3, // Daha fazla açıklama gösterebiliriz
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              if (technologies.isNotEmpty)
                                Padding(
                                   padding: const EdgeInsets.only(top: 4.0),
                                   child: Text(
                                    'Teknolojiler: $technologies',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                                  ),
                                ),
                                // İsteğe bağlı: Proje linkini göster
                                if (project['link'] != null && (project['link'] as String).isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: InkWell( // Tıklanabilir link
                                      // TODO: url_launcher paketi ile linki açtır
                                      onTap: () => print("Link tıklandı: ${project['link']}"),
                                      child: Text(
                                         project['link'],
                                         style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.blue, decoration: TextDecoration.underline),
                                         maxLines: 1,
                                         overflow: TextOverflow.ellipsis,
                                      ),
                                   ),
                                ),
                            ],
                          ),
                           isThreeLine: (project['description'] != null && (project['description'] as String).isNotEmpty)
                                       || (project['link'] != null && (project['link'] as String).isNotEmpty), // 3 satır kontrolü
                           trailing: Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                                IconButton(
                                  icon: Icon(Icons.edit_outlined, size: 20, color: Theme.of(context).primaryColor),
                                  tooltip: 'Düzenle', // Artık çalışıyor
                                  onPressed: () => _navigateToEditProject(projectDoc), // Düzenleme fonksiyonu çağrılır
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade700),
                                  tooltip: 'Sil',
                                  onPressed: () => _deleteProject(projectDoc),
                                ),
                             ],
                           ),
                          onTap: () => _navigateToEditProject(projectDoc), // Tıklayınca düzenlemeye git
                        ),
                      );
                    },
                  ),
       ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Proje Ekle'),
        onPressed: _navigateToAddProject,
      ),
    );
  }
}