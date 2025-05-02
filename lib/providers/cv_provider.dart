import 'package:flutter/foundation.dart'; // ChangeNotifier için

class CvProvider with ChangeNotifier {
  String? _selectedCvId;
  String? _selectedCvName;

  String? get selectedCvId => _selectedCvId;
  String? get selectedCvName => _selectedCvName;

  // Yeni bir CV seçildiğinde çağrılacak fonksiyon
  void selectCv(String cvId, String cvName) {
    if (_selectedCvId != cvId) { // Sadece farklı bir CV seçilirse güncelle
      _selectedCvId = cvId;
      _selectedCvName = cvName;
      print('CvProvider: Selected CV -> ID: $cvId, Name: $cvName');
      notifyListeners(); // Dinleyen widget'ları bilgilendir
    }
  }

  // Seçimi temizle (örn: kullanıcı çıkış yaptığında)
  void clearSelection() {
    _selectedCvId = null;
    _selectedCvName = null;
     print('CvProvider: Selection cleared.');
    notifyListeners();
  }
}