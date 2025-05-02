// lib/utils/api_key_provider.dart

class ApiKeyProvider {
  // API anahtarını ortam değişkenlerinden oku ('API_KEY' adıyla)
  static const String _geminiApiKey = String.fromEnvironment('API_KEY');

  // Anahtarı almak için kullanılacak metod
  static String getApiKey() {
    // Eğer anahtar bulunamazsa (yani --dart-define ile sağlanmadıysa) hata fırlat
    if (_geminiApiKey.isEmpty) {
      print("HATA: API_KEY ortam değişkeni bulunamadı!"); // Konsola log bas
      throw AssertionError('API_KEY ortam değişkeni bulunamadı! '
          'Uygulamayı --dart-define=API_KEY=SENIN_ANAHTARIN şeklinde çalıştırdığınızdan emin olun.');
    }
    return _geminiApiKey;
  }
}