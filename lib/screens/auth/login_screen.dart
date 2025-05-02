import 'package:yeni_cv_uygulamasi/screens/auth/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yeni_cv_uygulamasi/screens/home_screen.dart'; // HomeScreen importu (Başarılı girişte gerekebilir)
import 'package:provider/provider.dart'; // Provider
import 'package:yeni_cv_uygulamasi/providers/cv_provider.dart'; // Provider

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  void dispose() { _emailController.dispose(); _passwordController.dispose(); super.dispose(); }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    // Admin girişi (Hala aktif ama güvensiz!)
    if (email == "bekirdk" && password == "bekirdk09") {
      setState(() { _isLoading = true; }); print('!!! Admin girişi !!!'); await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        // Admin girişi direkt HomeScreen'e yönlendirebilir (AuthGate yerine)
        // Ama AuthGate'in yönetmesi daha doğru olur, provider'ı temizleyelim
        Provider.of<CvProvider>(context, listen: false).clearSelection();
        // Normalde AuthGate yönlendireceği için pushReplacement gereksiz
        // Sadece state'in değişmesini bekleyelim
         _showInfoSnackBar('Admin olarak giriş yapıldı!');
         // Belki admin için özel bir ekrana gidilir? Şimdilik AuthGate'e bırakalım.
      }
       if (mounted) setState(() { _isLoading = false; }); // Yönlendirme olmasa bile isLoading'i kapat
      return;
    }

    setState(() { _isLoading = true; });
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      // Başarılı giriş sonrası AuthGate zaten HomeScreen'e yönlendirecek
      // Provider'ı temizle (yeni kullanıcı için)
       if (mounted) Provider.of<CvProvider>(context, listen: false).clearSelection();
       print('Giriş Başarılı');
       // SnackBar göstermeye gerek yok, AuthGate yönlendirir.
    } on FirebaseAuthException catch (e) { _handleAuthError(e); }
    catch (e) { print('Beklenmedik Hata: $e'); _showErrorSnackBar('Beklenmedik bir hata oluştu.'); }
    finally { if (mounted) { setState(() { _isLoading = false; }); } }
  }

  void _handleAuthError(FirebaseAuthException e){
      print('Giriş Hatası: ${e.code} - ${e.message}');
      String errorMessage = 'E-posta veya şifre hatalı.';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password') {
         errorMessage = 'E-posta veya şifre hatalı.';
      } else if (e.code == 'invalid-email') {
         errorMessage = 'Geçersiz e-posta adresi formatı.';
      } else if (e.code == 'user-disabled') {
         errorMessage = 'Bu kullanıcı hesabı devre dışı bırakılmış.';
      }
      _showErrorSnackBar(errorMessage);
  }

  void _showSnackBar(String message, {Color backgroundColor = Colors.grey}) { if (!mounted) return; ScaffoldMessenger.of(context).removeCurrentSnackBar(); ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(message), backgroundColor: backgroundColor, duration: const Duration(seconds: 2)) ); }
  void _showErrorSnackBar(String message) { _showSnackBar(message, backgroundColor: Theme.of(context).colorScheme.error); }
  void _showSuccessSnackBar(String message) { _showSnackBar(message, backgroundColor: Colors.green); }
  void _showInfoSnackBar(String message) { _showSnackBar(message, backgroundColor: Colors.orangeAccent); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sade AppBar (isteğe bağlı, sadece geri butonu olabilir)
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Logo veya Başlık
                   Icon( Icons.lock_open, size: 60, color: Theme.of(context).primaryColor ),
                   const SizedBox(height: 20.0),
                   Text( 'Tekrar Hoş Geldiniz', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8.0),
                   Text( 'Giriş yapmak için bilgilerinizi girin', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                   const SizedBox(height: 40.0),
                  TextFormField( // Tema'dan stil alır
                    controller: _emailController, keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration( labelText: 'E-posta' ),
                    validator: (value) { if (value == null || value.isEmpty) return 'Lütfen e-posta girin.'; return null; },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField( // Tema'dan stil alır
                    controller: _passwordController, obscureText: true,
                    decoration: const InputDecoration( labelText: 'Şifre' ),
                    validator: (value) { if (value == null || value.isEmpty) return 'Lütfen şifre girin.'; return null; },
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _isLoading ? null : _login(),
                  ),
                  Align( alignment: Alignment.centerRight, child: TextButton( onPressed: () { print('Şifremi unuttum tıklandı'); }, child: const Text('Şifremi Unuttum?') ) ),
                  const SizedBox(height: 24.0),
                  _isLoading
                      ? const Center(child: Padding( padding: EdgeInsets.symmetric(vertical: 16.0), child: CircularProgressIndicator() ))
                      : ElevatedButton( onPressed: _login, child: const Text('Giriş Yap') ), // Tema'dan stil alır
                  const SizedBox(height: 30.0),
                  Row( mainAxisAlignment: MainAxisAlignment.center, children: [ const Text("Hesabınız yok mu?"), TextButton( onPressed: () { Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RegisterScreen())); }, child: const Text('Kayıt Ol') ) ] ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}