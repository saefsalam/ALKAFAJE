-- ═══════════════════════════════════════════════════════════════════════════
-- إصلاح RLS Policies لجدول customer_notifications
-- نفّذ هذا الكود في Supabase SQL Editor → New Query → Run
-- ═══════════════════════════════════════════════════════════════════════════

-- 1) السماح لمديري المتجر (shop_users) بإرسال إشعارات (INSERT)
CREATE POLICY "shop_admins_insert_notifications" ON public.customer_notifications
    FOR INSERT
    WITH CHECK (
        shop_id IN (
            SELECT su.shop_id FROM public.shop_users su
            WHERE su.user_id = auth.uid()
        )
    );

-- 2) السماح لمديري المتجر بقراءة إشعارات متجرهم
CREATE POLICY "shop_admins_read_notifications" ON public.customer_notifications
    FOR SELECT
    USING (
        shop_id IN (
            SELECT su.shop_id FROM public.shop_users su
            WHERE su.user_id = auth.uid()
        )
    );

-- 3) السماح لمديري المتجر بتحديث إشعارات متجرهم
CREATE POLICY "shop_admins_update_notifications" ON public.customer_notifications
    FOR UPDATE
    USING (
        shop_id IN (
            SELECT su.shop_id FROM public.shop_users su
            WHERE su.user_id = auth.uid()
        )
    )
    WITH CHECK (
        shop_id IN (
            SELECT su.shop_id FROM public.shop_users su
            WHERE su.user_id = auth.uid()
        )
    );

-- 4) السماح لمديري المتجر بحذف إشعارات متجرهم
CREATE POLICY "shop_admins_delete_notifications" ON public.customer_notifications
    FOR DELETE
    USING (
        shop_id IN (
            SELECT su.shop_id FROM public.shop_users su
            WHERE su.user_id = auth.uid()
        )
    );

-- 5) السماح لمديري المتجر بقراءة توكنات FCM لمتجرهم
CREATE POLICY "shop_admins_read_tokens" ON public.fcm_tokens
    FOR SELECT
    USING (
        shop_id IN (
            SELECT su.shop_id FROM public.shop_users su
            WHERE su.user_id = auth.uid()
        )
    );

-- 6) تحديث صلاحيات GRANT لتشمل INSERT و DELETE
GRANT INSERT, DELETE ON public.customer_notifications TO authenticated;

-- ═══════════════════════════════════════════════════════════════════════════
-- ✅ بعد تنفيذ هذا الكود، سيتمكن الداشبورد من:
--   - إرسال إشعارات جماعية (INSERT)
--   - قراءة جميع الإشعارات المرسلة (SELECT)
--   - حذف إشعارات (DELETE)
--   - قراءة توكنات FCM للعملاء (SELECT)
-- ═══════════════════════════════════════════════════════════════════════════
