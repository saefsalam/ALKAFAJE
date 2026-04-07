import 'dart:async';

/// خدمة لإرسال إشعارات بتحديثات السلة
class CartUpdateService {
  // StreamController لإرسال إشعارات بالتغييرات
  static final _cartChangeController = StreamController<bool>.broadcast();

  // Stream للاستماع للتغييرات
  static Stream<bool> get cartChangeStream => _cartChangeController.stream;

  // دالة لإرسال إشعار بالتغيير
  static void notifyCartChanged() {
    print('📢 [CartUpdateService] إرسال إشعار بتغيير السلة');
    if (!_cartChangeController.isClosed) {
      _cartChangeController.add(true);
    }
  }
}
