-- ═══════════════════════════════════════════════════════════════════════════════════════
--              🔧 إصلاح سياسة customer_notifications
--              لحل خطأ: "new row violates row-level security policy"
-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 
-- المشكلة: عند إنشاء طلب جديد، يتم إنشاء إشعار تلقائياً
--          لكن السياسة الحالية لا تسمح إلا للموظفين بإنشاء الإشعارات
-- 
-- الحل: إضافة سياسة تسمح بإنشاء الإشعارات للعميل نفسه
--       أو عبر Trigger بصلاحيات مرتفعة
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- حذف السياسات القديمة
DROP POLICY IF EXISTS "notifications_read_own" ON public.customer_notifications;
DROP POLICY IF EXISTS "notifications_update_own" ON public.customer_notifications;
DROP POLICY IF EXISTS "notifications_read_staff" ON public.customer_notifications;
DROP POLICY IF EXISTS "notifications_create_staff" ON public.customer_notifications;
DROP POLICY IF EXISTS "notifications_create_system" ON public.customer_notifications;
DROP POLICY IF EXISTS "notifications_create_own" ON public.customer_notifications;

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- سياسات جديدة
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- 1. العميل يقرأ إشعاراته
CREATE POLICY "notifications_read_own" ON public.customer_notifications
  FOR SELECT 
  USING (customer_id = get_my_customer_id());

-- 2. العميل يُحدّث إشعاراته (مثلاً: تحديد كمقروءة)
CREATE POLICY "notifications_update_own" ON public.customer_notifications
  FOR UPDATE 
  USING (customer_id = get_my_customer_id())
  WITH CHECK (customer_id = get_my_customer_id());

-- 3. موظفو المتجر يقرأون الإشعارات
CREATE POLICY "notifications_read_staff" ON public.customer_notifications
  FOR SELECT 
  USING (is_shop_staff(shop_id));

-- 4. موظفو المتجر يُنشئون إشعارات
CREATE POLICY "notifications_create_staff" ON public.customer_notifications
  FOR INSERT 
  WITH CHECK (is_shop_staff(shop_id));

-- 5. ⭐ سياسة جديدة: السماح بإنشاء إشعار للعميل الحالي
--    (هذا يسمح للنظام/Trigger بإنشاء إشعارات للعميل عند إنشاء طلب)
CREATE POLICY "notifications_create_for_own" ON public.customer_notifications
  FOR INSERT 
  WITH CHECK (customer_id = get_my_customer_id());

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- بديل: إذا كان هناك Trigger يُنشئ الإشعارات، اجعله SECURITY DEFINER
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- تحقق من وجود Trigger على orders يُنشئ إشعارات
SELECT 
  trigger_name,
  event_manipulation,
  action_statement
FROM information_schema.triggers
WHERE event_object_table = 'orders';

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ✅ تم!
-- ═══════════════════════════════════════════════════════════════════════════════════════
