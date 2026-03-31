-- ═══════════════════════════════════════════════════════════════════════════
-- تعطيل RLS مؤقتاً أثناء التطوير
-- نفّذ هذا في Supabase SQL Editor
-- ⚠️ تذكّر: فعّل RLS مرة ثانية قبل نشر التطبيق!
-- ═══════════════════════════════════════════════════════════════════════════

-- تعطيل RLS على جدول الإشعارات
ALTER TABLE public.customer_notifications DISABLE ROW LEVEL SECURITY;

-- تعطيل RLS على جدول التوكنات
ALTER TABLE public.fcm_tokens DISABLE ROW LEVEL SECURITY;

-- منح كل الصلاحيات
GRANT ALL ON public.customer_notifications TO authenticated;
GRANT ALL ON public.fcm_tokens TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;


-- ═══════════════════════════════════════════════════════════════════════════
-- 🔒 عند الانتهاء من المشروع، نفّذ هذا لإعادة تفعيل RLS:
-- ═══════════════════════════════════════════════════════════════════════════
--
-- ALTER TABLE public.customer_notifications ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;
--
-- ثم نفّذ محتوى ملف fix_rls_policies.sql لإضافة الـ Policies الصحيحة
-- ═══════════════════════════════════════════════════════════════════════════
