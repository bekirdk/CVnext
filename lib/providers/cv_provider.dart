import 'package:flutter/foundation.dart';

class CvProvider with ChangeNotifier {
  String? _selectedCvId;
  String? _selectedCvName;

  String? get selectedCvId => _selectedCvId;
  String? get selectedCvName => _selectedCvName;

  void selectCv(String cvId, String cvName) {
    // Sadece farklı bir CV seçilirse veya mevcut seçim null ise güncelle
    if (_selectedCvId != cvId || _selectedCvName != cvName) { // Koşulu biraz değiştirdim
      _selectedCvId = cvId;
      _selectedCvName = cvName;
      print('CvProvider: Selected CV -> ID: $cvId, Name: $cvName');
      notifyListeners();
    } else if (_selectedCvId == cvId && _selectedCvName == cvName) {
      // Eğer zaten seçili olan CV'ye tekrar tıklanırsa bir şey yapma veya seçimi kaldır (isteğe bağlı)
      print('CvProvider: CV $cvId is already selected.');
      // İsterseniz burada seçimi kaldırma mantığı eklenebilir:
      // clearSelection();
    }
  }

  void clearSelection() {
    if (_selectedCvId != null || _selectedCvName != null) { // Sadece bir seçim varsa temizle
      _selectedCvId = null;
      _selectedCvName = null;
      print('CvProvider: Selection cleared.');
      notifyListeners();
    }
  }
}