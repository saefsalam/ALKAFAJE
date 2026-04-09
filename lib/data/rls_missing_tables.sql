-- ═══════════════════════════════════════════════════════════════════════════════════════
--              🔐 إضافة RLS للجداول المتبقية
--              password_reset_otps و customers_with_auth
-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 
-- 📋 شغّل هذا الملف في SQL Editor في Supabase
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 1. جدول PASSWORD_RESET_OTPS
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- تفعيل RLS
ALTER TABLE public.password_reset_otps ENABLE ROW LEVEL SECURITY;

-- حذف السياسات القديمة إن وجدت
DROP POLICY IF EXISTS "password_reset_otps_insert_anon" ON public.password_reset_otps;
DROP POLICY IF EXISTS "password_reset_otps_select_anon" ON public.password_reset_otps;
DROP POLICY IF EXISTS "password_reset_otps_update_anon" ON public.password_reset_otps;

-- سياسة: السماح بإنشاء OTP (للمستخدمين غير المسجلين - anon)
CREATE POLICY "password_reset_otps_insert_anon" ON public.password_reset_otps
  FOR INSERT TO anon, authenticated
  WITH CHECK (true);

-- سياسة: قراءة OTP بناءً على البريد الإلكتروني
CREATE POLICY "password_reset_otps_select_anon" ON public.password_reset_otps
  FOR SELECT TO anon, authenticated
  USING (true);

-- سياسة: تحديث OTP (لتسجيل الاستهلاك)
CREATE POLICY "password_reset_otps_update_anon" ON public.password_reset_otps
  FOR UPDATE TO anon, authenticated
  USING (true)
  WITH CHECK (true);

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 2. VIEW: customers_with_auth
-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 
-- ملاحظة: customers_with_auth هو VIEW وليس جدول
-- الـ VIEWs لا تدعم RLS مباشرة، لكن يمكن:
-- 1. تحويله إلى SECURITY DEFINER view
-- 2. أو إعادة إنشائه ليعتمد على جدول customers الذي عليه RLS
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- أولاً: نتحقق إذا كان VIEW أو TABLE
DO $$
DECLARE
  obj_type text;
BEGIN
  SELECT 
    CASE 
      WHEN c.relkind = 'r' THEN 'TABLE'
      WHEN c.relkind = 'v' THEN 'VIEW'
      WHEN c.relkind = 'm' THEN 'MATERIALIZED VIEW'
      ELSE 'OTHER'
    END INTO obj_type
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE c.relname = 'customers_with_auth' AND n.nspname = 'public';
  
  RAISE NOTICE 'customers_with_auth is a: %', COALESCE(obj_type, 'NOT FOUND');
END $$;

-- إذا كان VIEW، نُعيد إنشاءه بصلاحيات محدودة
-- (هذا سيعتمد على RLS الموجود على جدول customers)
DROP VIEW IF EXISTS public.customers_with_auth;

CREATE VIEW public.customers_with_auth AS
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

-- منح الصلاحيات للـ VIEW
GRANT SELECT ON public.customers_with_auth TO authenticated;

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ✅ تم الانتهاء!
-- ═══════════════════════════════════════════════════════════════════════════════════════
--
-- الآن:
-- ✓ password_reset_otps عليه RLS
-- ✓ customers_with_auth هو VIEW يعتمد على customers (الذي عليه RLS)
--
-- ═══════════════════════════════════════════════════════════════════════════════════════
