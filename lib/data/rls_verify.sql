-- ═══════════════════════════════════════════════════════════════════════════════════════
--                     🔍 استعلامات التحقق والتصحيح بعد تفعيل RLS
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 1. التحقق من تفعيل RLS على الجداول
-- ═══════════════════════════════════════════════════════════════════════════════════════

SELECT 
  tablename,
  CASE WHEN rowsecurity THEN '✅ مفعّل' ELSE '❌ غير مفعّل' END as rls_status
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY tablename;

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 2. عرض جميع السياسات الموجودة
-- ═══════════════════════════════════════════════════════════════════════════════════════

SELECT 
  tablename,
  policyname,
  cmd as operation,
  permissive
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 3. التحقق من ارتباط العملاء بـ auth_user_id
-- ═══════════════════════════════════════════════════════════════════════════════════════

SELECT 
  id,
  name,
  phone,
  auth_user_id,
  CASE WHEN auth_user_id IS NOT NULL THEN '✅ مرتبط' ELSE '❌ غير مرتبط' END as auth_status
FROM customers
ORDER BY id DESC
LIMIT 20;

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 4. التحقق من ارتباط موظفي المتجر
-- ═══════════════════════════════════════════════════════════════════════════════════════

SELECT 
  su.id,
  su.name,
  su.role,
  su.user_id,
  su.shop_id,
  s.display_name as shop_name
FROM shop_users su
LEFT JOIN shops s ON s.id = su.shop_id
ORDER BY su.id;

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 5. التحقق من الطلبات وسجل الحالات
-- ═══════════════════════════════════════════════════════════════════════════════════════

SELECT 
  o.id as order_id,
  o.status,
  o.created_at,
  c.name as customer_name,
  (SELECT COUNT(*) FROM order_status_history WHERE order_id = o.id) as history_count
FROM orders o
LEFT JOIN customers c ON c.id = o.customer_id
ORDER BY o.created_at DESC
LIMIT 20;

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 6. إصلاح الطلبات التي ليس لها سجل حالة
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- أولاً، عرض الطلبات بدون سجل
SELECT 
  o.id,
  o.status,
  o.created_at
FROM orders o
WHERE NOT EXISTS (
  SELECT 1 FROM order_status_history h WHERE h.order_id = o.id
);

-- ثم، إضافة السجل المفقود (شغّل هذا إذا كانت هناك طلبات بدون سجل)
/*
INSERT INTO order_status_history (order_id, status, notes, created_at)
SELECT 
  o.id,
  o.status,
  'تم إضافة السجل يدوياً',
  o.created_at
FROM orders o
WHERE NOT EXISTS (
  SELECT 1 FROM order_status_history h WHERE h.order_id = o.id
);
*/

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 7. التحقق من الدوال المساعدة
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- عرض الدوال الموجودة
SELECT 
  routine_name,
  routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name IN ('get_my_customer_id', 'get_my_shop_id', 'is_shop_staff');

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 8. اختبار الدوال (شغّلها بعد تسجيل الدخول)
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- سيُرجع null إذا لم تكن مسجل دخول أو إذا لم يكن لديك سجل
SELECT get_my_customer_id() as my_customer_id;
SELECT get_my_shop_id() as my_shop_id;

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 9. التحقق من المنتجات النشطة
-- ═══════════════════════════════════════════════════════════════════════════════════════

SELECT 
  COUNT(*) as total_items,
  COUNT(*) FILTER (WHERE is_active = true AND is_deleted = false) as active_items,
  COUNT(*) FILTER (WHERE is_active = false) as inactive_items,
  COUNT(*) FILTER (WHERE is_deleted = true) as deleted_items
FROM items;

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 10. التحقق من السلات
-- ═══════════════════════════════════════════════════════════════════════════════════════

SELECT 
  c.id as cart_id,
  cu.name as customer_name,
  (SELECT COUNT(*) FROM cart_items WHERE cart_id = c.id) as items_count
FROM carts c
LEFT JOIN customers cu ON cu.id = c.customer_id
ORDER BY c.created_at DESC
LIMIT 20;

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 11. إحصائيات عامة
-- ═══════════════════════════════════════════════════════════════════════════════════════

SELECT 
  (SELECT COUNT(*) FROM customers) as total_customers,
  (SELECT COUNT(*) FROM orders) as total_orders,
  (SELECT COUNT(*) FROM items WHERE is_active = true AND is_deleted = false) as active_items,
  (SELECT COUNT(*) FROM shop_users) as total_staff,
  (SELECT COUNT(*) FROM carts) as total_carts;

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 12. البحث عن مشاكل محتملة
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- عملاء بدون auth_user_id (لن يعمل RLS معهم)
SELECT id, name, phone FROM customers WHERE auth_user_id IS NULL;

-- طلبات بدون customer_id صحيح
SELECT o.id, o.customer_id FROM orders o 
WHERE NOT EXISTS (SELECT 1 FROM customers c WHERE c.id = o.customer_id);

-- عناصر سلة بدون سلة
SELECT ci.id FROM cart_items ci
WHERE NOT EXISTS (SELECT 1 FROM carts c WHERE c.id = ci.cart_id);

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ✅ انتهى التحقق
-- ═══════════════════════════════════════════════════════════════════════════════════════
