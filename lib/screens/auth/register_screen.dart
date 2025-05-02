import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart'; // Login ekranına dönmek için

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  void dispose() { _emailController.dispose(); _passwordController.dispose(); _confirmPasswordController.dispose(); super.dispose(); }

  Future<void> _register() async {
     FocusScope.of(context).unfocus();
     if (!_formKey.currentState!.validate()) return;
     setState(() { _isLoading = true; });
     try {
       await _firebaseAuth.createUserWithEmailAndPassword( email: _emailController.text.trim(), password: _passwordController.text.trim() );
       print('Kayıt Başarılı: ${_emailController.text}');
       if (mounted) {
         _showSuccessSnackBar('Kayıt başarıyla tamamlandı! Şimdi giriş yapabilirsiniz.');
         await Future.delayed(const Duration(seconds: 1)); // Mesajın görünmesi için kısa bekleme
         // Kayıt sonrası direkt Login'e yönlendir (pop yerine)
         Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> const LoginScreen()));
       }
     } on FirebaseAuthException catch (e) { _handleAuthError(e); }
     catch (e) { print('Beklenmedik Hata: $e'); _showErrorSnackBar('Beklenmedik bir hata oluştu.'); }
     finally { if (mounted) { setState(() { _isLoading = false; }); } }
  }

  void _handleAuthError(FirebaseAuthException e){
      print('Kayıt Hatası: ${e.code} - ${e.message}');
      String errorMessage = 'Bir hata oluştu, lütfen tekrar deneyin.';
      if (e.code == 'weak-password') { errorMessage = 'Şifre çok zayıf (en az 6 karakter olmalı).'; }
      else if (e.code == 'email-already-in-use') { errorMessage = 'Bu e-posta adresi zaten kullanılıyor.'; }
      else if (e.code == 'invalid-email') { errorMessage = 'Geçersiz e-posta adresi formatı.'; }
      _showErrorSnackBar(errorMessage);
  }

   void _showSnackBar(String message, {Color backgroundColor = Colors.grey}) { if (!mounted) return; ScaffoldMessenger.of(context).removeCurrentSnackBar(); ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(message), backgroundColor: backgroundColor, duration: const Duration(seconds: 2)) ); }
   void _showErrorSnackBar(String message) { _showSnackBar(message, backgroundColor: Theme.of(context).colorScheme.error); }
   void _showSuccessSnackBar(String message) { _showSnackBar(message, backgroundColor: Colors.green); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         // Geri butonu otomatik eklenir, stile dokunmayalım
         // title: Text("Kayıt Ol"), // Başlık kaldırıldı, daha sade
      ),
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
                    Icon( Icons.person_add_alt_1_outlined, size: 60, color: Theme.of(context).primaryColor ),
                    const SizedBox(height: 20.0),
                    Text( 'Yeni Hesap Oluştur', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8.0),
                    Text( 'Başlamak için bilgilerinizi girin', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                    const SizedBox(height: 40.0),
                   TextFormField(
                     controller: _emailController, keyboardType: TextInputType.emailAddress,
                     decoration: const InputDecoration( labelText: 'E-posta' ),
                     validator: (value) { if (value == null || value.isEmpty || !value.contains('@')) return 'Geçerli e-posta girin.'; return null; },
                     textInputAction: TextInputAction.next,
                   ),
                   const SizedBox(height: 16.0),
                   TextFormField(
                     controller: _passwordController, obscureText: true,
                     decoration: const InputDecoration( labelText: 'Şifre' ),
                     validator: (value) { if (value == null || value.isEmpty || value.length < 6) return 'Şifre en az 6 karakter olmalı.'; return null; },
                     textInputAction: TextInputAction.next,
                   ),
                   const SizedBox(height: 16.0),
                   TextFormField(
                     controller: _confirmPasswordController, obscureText: true,
                     decoration: const InputDecoration( labelText: 'Şifreyi Doğrula' ),
                     validator: (value) { if (value != _passwordController.text) return 'Şifreler eşleşmiyor.'; return null; },
                     textInputAction: TextInputAction.done,
                     onFieldSubmitted: (_) => _isLoading ? null : _register(),
                   ),
                   const SizedBox(height: 32.0),
                   _isLoading
                       ? const Center(child: Padding( padding: EdgeInsets.symmetric(vertical: 16.0), child: CircularProgressIndicator() ))
                       : ElevatedButton( onPressed: _register, child: const Text('Kayıt Ol') ),
                    const SizedBox(height: 30.0),
                   Row( mainAxisAlignment: MainAxisAlignment.center, children: [ const Text("Zaten hesabınız var mı?"), TextButton( onPressed: () { Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())); }, child: const Text('Giriş Yap') ) ] ),
                 ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}