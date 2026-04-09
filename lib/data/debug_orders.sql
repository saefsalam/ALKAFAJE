-- ═══════════════════════════════════════════════════════════════════════════
-- استعلامات للتحقق من الطلبات وسجل الحالات
-- نفّذ هذه الاستعلامات في SQL Editor في Supabase
-- ═══════════════════════════════════════════════════════════════════════════

-- 1. عرض آخر 10 طلبات
SELECT 
  o.id,
  o.shop_id,
  o.customer_id,
  o.status,
  o.total,
  o.created_at,
  c.name as customer_name,
  c.phone as customer_phone
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.id
WHERE o.shop_id = '550e8400-e29b-41d4-a716-446655440001'
ORDER BY o.created_at DESC
LIMIT 10;

-- 2. عرض سجل الحالات لآخر 10 طلبات
SELECT 
  osh.id,
  osh.order_id,
  osh.status,
  osh.notes,
  osh.created_at
FROM order_status_history osh
INNER JOIN orders o ON osh.order_id = o.id
WHERE o.shop_id = '550e8400-e29b-41d4-a716-446655440001'
ORDER BY osh.created_at DESC
LIMIT 20;

-- 3. عرض الطلبات التي ليس لها سجل حالة (المشكلة!)
SELECT 
  o.id,
  o.status,
  o.total,
  o.created_at
FROM orders o
LEFT JOIN order_status_history osh ON o.id = osh.order_id
WHERE o.shop_id = '550e8400-e29b-41d4-a716-446655440001'
  AND osh.id IS NULL
ORDER BY o.created_at DESC;

-- 4. إصلاح: إضافة سجل حالة للطلبات التي ليس لها سجل
INSERT INTO order_status_history (order_id, status, notes, created_at)
SELECT 
  o.id,
  o.status,
  'تم إضافة السجل تلقائياً (إصلاح)',
  o.created_at
FROM orders o
LEFT JOIN order_status_history osh ON o.id = osh.order_id
WHERE o.shop_id = '550e8400-e29b-41d4-a716-446655440001'
  AND osh.id IS NULL;

-- 5. التحقق من وجود Triggers على جدول orders
SELECT 
  trigger_name,
  event_manipulation,
  action_timing,
  action_statement
FROM information_schema.triggers
WHERE event_object_table = 'orders';

-- 6. عرض عناصر آخر طلب
SELECT 
  oi.*,
  i.title
FROM order_items oi
JOIN items i ON oi.item_id = i.id
WHERE oi.order_id = (
  SELECT id FROM orders 
  WHERE shop_id = '550e8400-e29b-41d4-a716-446655440001'
  ORDER BY created_at DESC 
  LIMIT 1
);

-- ═══════════════════════════════════════════════════════════════════════════
-- إذا كانت هناك طلبات بدون سجل حالة، نفّذ الاستعلام رقم 4 لإصلاحها
-- ═══════════════════════════════════════════════════════════════════════════
