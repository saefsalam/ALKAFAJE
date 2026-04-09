# 📋 تتبع حالة الطلب من البداية إلى النهاية

## 🔄 دورة حياة الطلب الكاملة

### 1️⃣ **إنشاء الطلب (من التطبيق)**

**الملف:** `lib/services/order_service.dart` → `createOrder()`

**الخطوات:**
1. ✅ التحقق من تسجيل الدخول
2. ✅ الحصول على `customer_id`
3. ✅ جلب عناصر السلة من قاعدة البيانات
4. ✅ حساب المبلغ الإجمالي (`subtotal`, `total`)
5. ✅ إنشاء سجل في جدول `orders` بحالة `pending`
6. ✅ إضافة عناصر الطلب في جدول `order_items`
7. ✅ **إضافة سجل الحالة الأولية في `order_status_history`** ← **هذا كان مفقوداً!**
8. ✅ تفريغ السلة

**الجداول المتأثرة:**
- `orders` ← سجل جديد
- `order_items` ← عدة سجلات
- `order_status_history` ← سجل واحد بحالة `pending`

---

### 2️⃣ **ظهور الطلب في الداشبورد**

**الملف:** `alkhafajdashboard/lib/data/api/supabaseApi.dart` → `getOrders()`

**الاستعلام:**
```dart
await supabase
  .from('orders')
  .select('*, customers(name, phone), order_items(*), order_status_history(*)')
  .eq('shop_id', shopId)
  .order('created_at', ascending: false);
```

**الشروط لظهور الطلب:**
- ✅ يجب أن يكون هناك سجل في جدول `orders`
- ✅ يجب أن يكون هناك سجل في جدول `order_status_history` ← **كان مفقوداً!**
- ✅ يجب أن يكون `shop_id` صحيح

---

### 3️⃣ **حالات الطلب المختلفة**

| الحالة | الوصف | من يقوم بالتغيير |
|-------|-------|------------------|
| `pending` | في انتظار التأكيد | تلقائي عند الإنشاء |
| `confirmed` | تم التأكيد | الداشبورد |
| `preparing` | قيد التحضير | الداشبورد |
| `shipped` | تم الشحن | الداشبورد |
| `delivered` | تم التوصيل | الداشبورد |
| `cancelled` | ملغي | الداشبورد أو العميل |

---

### 4️⃣ **تغيير حالة الطلب (من الداشبورد)**

**الملف:** `alkhafajdashboard/lib/data/api/supabaseApi.dart` → `updateOrderStatus()`

**الخطوات:**
1. ✅ تحديث حقل `status` في جدول `orders`
2. ✅ إضافة سجل جديد في `order_status_history` مع الحالة الجديدة
3. ✅ إرسال إشعار للعميل (FCM)

**مثال:**
```dart
// تحديث الحالة في جدول orders
await supabase.from('orders').update({'status': 'confirmed'}).eq('id', orderId);

// إضافة سجل في order_status_history
await supabase.from('order_status_history').insert({
  'order_id': orderId,
  'status': 'confirmed',
  'changed_by': userId,
  'notes': 'تم التأكيد من الداشبورد',
});
```

---

### 5️⃣ **متابعة الطلب (من التطبيق)**

**الملف:** `lib/screens/orders/order_detail_screen.dart`

**الاستعلام:**
```dart
await _supabase
  .from('order_status_history')
  .select('*')
  .eq('order_id', orderId)
  .order('created_at', ascending: true);
```

**الناتج:**
- قائمة بجميع حالات الطلب من البداية للنهاية
- كل سجل يحتوي على: `status`, `notes`, `created_at`, `changed_by`

---

## 🐛 المشكلة التي تم إصلاحها

### ❌ **قبل الإصلاح:**
```
إنشاء طلب → orders ✅ + order_items ✅ + order_status_history ❌
                ↓
         الداشبورد لا يرى الطلب! 🚫
```

### ✅ **بعد الإصلاح:**
```
إنشاء طلب → orders ✅ + order_items ✅ + order_status_history ✅
                ↓
         الداشبورد يرى الطلب فوراً! ✅
```

---

## 🔧 الحلول المطبقة

### 1. **إضافة السجل يدوياً في الكود**
**الملف:** `lib/services/order_service.dart` (السطر 158-164)

```dart
// إضافة سجل الحالة الأولى للطلب
await _supabase.from('order_status_history').insert({
  'order_id': orderId,
  'status': 'pending',
  'notes': 'تم إنشاء الطلب من قبل العميل',
  'created_at': DateTime.now().toIso8601String(),
});
```

### 2. **إنشاء Trigger في قاعدة البيانات**
**الملف:** `lib/data/order_status_trigger.sql`

هذا الـ Trigger يضمن إضافة سجل تلقائياً في `order_status_history` عند إنشاء أي طلب جديد.

---

## 📝 خطوات تطبيق الإصلاح

### في قاعدة البيانات (Supabase):
1. افتح **SQL Editor** في لوحة تحكم Supabase
2. نفّذ الكود الموجود في `lib/data/order_status_trigger.sql`
3. تأكد من نجاح التنفيذ

### في التطبيق:
1. الكود تم تحديثه تلقائياً في `order_service.dart`
2. أعد تشغيل التطبيق
3. جرب إنشاء طلب جديد

---

## ✅ اختبار النظام

### 1. **من التطبيق:**
```
1. أضف منتجات للسلة
2. اذهب للخروج (Checkout)
3. أنشئ طلباً جديداً
4. تحقق من ظهور الطلب في "متابعة الطلبات"
```

### 2. **من الداشبورد:**
```
1. افتح الداشبورد
2. اذهب لصفحة الطلبات
3. تحقق من ظهور الطلب الجديد بحالة "pending"
4. غيّر حالة الطلب إلى "confirmed"
```

### 3. **التحقق من قاعدة البيانات:**
```sql
-- عرض الطلب
SELECT * FROM orders WHERE id = <order_id>;

-- عرض سجلات الحالة
SELECT * FROM order_status_history WHERE order_id = <order_id>;

-- يجب أن يكون هناك سجل واحد على الأقل بحالة 'pending'
```

---

## 📊 الجداول ذات العلاقة

### `orders`
- يحتوي على بيانات الطلب الأساسية
- `id`, `customer_id`, `status`, `total`, `created_at`

### `order_items`
- يحتوي على عناصر كل طلب
- `order_id`, `item_id`, `quantity`, `unit_price`

### `order_status_history`
- يحتوي على سجل جميع حالات الطلب
- `order_id`, `status`, `notes`, `changed_by`, `created_at`

---

## 🎯 الخلاصة

✅ **المشكلة:** الطلبات لا تظهر في الداشبورد عند إنشائها  
✅ **السبب:** عدم إضافة سجل في `order_status_history`  
✅ **الحل:** إضافة السجل يدوياً في الكود + Trigger تلقائي في قاعدة البيانات  
✅ **النتيجة:** الطلبات تظهر فوراً في الداشبورد بعد الإنشاء  

---

## 📞 دعم إضافي

إذا واجهت أي مشاكل:
1. تحقق من وجود سجل في `order_status_history`
2. تأكد من تطابق `shop_id` في جميع الجداول
3. تحقق من أخطاء قاعدة البيانات في Console
