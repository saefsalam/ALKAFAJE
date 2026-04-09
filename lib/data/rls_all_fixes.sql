-- ═══════════════════════════════════════════════════════════════════════════════════════
--              🔧 ملف الإصلاحات الشامل - شغّل هذا الملف كاملاً
--              يحتوي على جميع الإصلاحات المطلوبة لـ RLS
-- ═══════════════════════════════════════════════════════════════════════════════════════
--
-- ✅ الإصلاحات المشمولة:
-- 1. السماح للعميل بإلغاء طلبه (orders_update_own)
-- 2. السماح للعميل بإنشاء إشعار لنفسه (notifications_create_for_own)
-- 3. إصلاح password_reset_otps
-- 4. إصلاح customers_with_auth (VIEW)
--
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 1. السماح للعميل بإلغاء طلبه
-- ═══════════════════════════════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "orders_update_own" ON public.orders;

CREATE POLICY "orders_update_own" ON public.orders
  FOR UPDATE 
  USING (customer_id = get_my_customer_id())
  WITH CHECK (customer_id = get_my_customer_id());

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 2. السماح للعميل بإنشاء إشعار لنفسه
-- ═══════════════════════════════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "notifications_create_for_own" ON public.customer_notifications;

CREATE POLICY "notifications_create_for_own" ON public.customer_notifications
  FOR INSERT 
  WITH CHECK (customer_id = get_my_customer_id());

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 3. إصلاح password_reset_otps
-- ═══════════════════════════════════════════════════════════════════════════════════════

ALTER TABLE public.password_reset_otps ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "password_reset_insert" ON public.password_reset_otps;
DROP POLICY IF EXISTS "password_reset_select" ON public.password_reset_otps;
DROP POLICY IF EXISTS "password_reset_update" ON public.password_reset_otps;

CREATE POLICY "password_reset_insert" ON public.password_reset_otps
  FOR INSERT TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY "password_reset_select" ON public.password_reset_otps
  FOR SELECT TO anon, authenticated
  USING (true);

CREATE POLICY "password_reset_update" ON public.password_reset_otps
  FOR UPDATE TO anon, authenticated
  USING (true)
  WITH CHECK (true);

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 4. إصلاح customers_with_auth (VIEW)
-- ═══════════════════════════════════════════════════════════════════════════════════════

DROP VIEW IF EXISTS public.customers_with_auth;

CREATE VIEW public.customers_with_auth 
WITH (security_invoker = true)
AS
SELECT 
  c.id,
  c.shop_id,
  c.name,
  c.phone,
  c.city,
  c.location,
  c.address,
  c.is_active,
  c.is_banned,
  c.created_at,
  c.updated_at,
  c.auth_user_id
FROM public.customers c
WHERE c.auth_user_id IS NOT NULL;

GRANT SELECT ON public.customers_with_auth TO authenticated;

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ✅ تم الانتهاء!
-- ═══════════════════════════════════════════════════════════════════════════════════════
--
-- الآن:
-- ✓ العميل يستطيع إلغاء طلباته
-- ✓ العميل يستطيع إنشاء إشعارات لنفسه
-- ✓ password_reset_otps لديه RLS
-- ✓ customers_with_auth يعمل بشكل صحيح
--
-- 🧪 اختبر:
-- 1. إلغاء طلب من التطبيق
-- 2. تأكد من ظهوره كـ "ملغي" في الداشبورد
-- ═══════════════════════════════════════════════════════════════════════════════════════
