-- ═══════════════════════════════════════════════════════════════════════════════════════
--              🔐 إصلاح الجدولين المتبقيين - شغّل هذا فقط
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 1. جدول PASSWORD_RESET_OTPS
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
-- 2. VIEW: customers_with_auth
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
-- ✅ تم!
-- ═══════════════════════════════════════════════════════════════════════════════════════
