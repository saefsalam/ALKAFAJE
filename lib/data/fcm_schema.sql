-- ═══════════════════════════════════════════════════════════════════════════
-- جدول FCM Tokens - لحفظ توكنات الأجهزة
-- نفّذ هذا في Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.fcm_tokens (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    shop_id uuid NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
    customer_id bigint NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
    token text NOT NULL,
    platform text CHECK (platform IN ('android', 'ios', 'web', 'unknown')),
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(customer_id, token)
);

-- فهرس للبحث السريع
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_customer ON public.fcm_tokens(customer_id, is_active);
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_shop ON public.fcm_tokens(shop_id, is_active);

-- RLS Policies
ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;

-- العملاء يمكنهم إضافة/تحديث توكنهم فقط
CREATE POLICY "customers_manage_own_tokens" ON public.fcm_tokens
    FOR ALL
    USING (
        customer_id IN (
            SELECT id FROM public.customers 
            WHERE auth_user_id = auth.uid()
        )
    )
    WITH CHECK (
        customer_id IN (
            SELECT id FROM public.customers 
            WHERE auth_user_id = auth.uid()
        )
    );

-- ═══════════════════════════════════════════════════════════════════════════
-- جدول إشعارات العملاء (إذا لم يكن موجوداً)
-- يدعم: إشعارات الحالة + العروض + الإعلانات اليدوية
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.customer_notifications (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    shop_id uuid NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
    customer_id bigint REFERENCES public.customers(id) ON DELETE CASCADE,  -- NULL = لكل العملاء
    
    -- نوع الإشعار
    type text NOT NULL DEFAULT 'order_status' 
        CHECK (type IN ('order_status', 'promotion', 'announcement', 'welcome')),
    
    -- المحتوى
    title text NOT NULL,
    body text NOT NULL,
    image_url text,
    
    -- بيانات مرتبطة
    order_id bigint REFERENCES public.orders(id) ON DELETE SET NULL,
    order_status text,
    payload jsonb DEFAULT '{}',
    
    -- حالة الإشعار
    is_read boolean NOT NULL DEFAULT false,
    is_sent_fcm boolean NOT NULL DEFAULT false,  -- هل تم إرسال FCM Push؟
    
    created_at timestamptz NOT NULL DEFAULT now()
);

-- فهارس
CREATE INDEX IF NOT EXISTS idx_customer_notifications_customer 
    ON public.customer_notifications(customer_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_customer_notifications_shop 
    ON public.customer_notifications(shop_id, type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_customer_notifications_unsent 
    ON public.customer_notifications(is_sent_fcm) WHERE is_sent_fcm = false;

-- RLS Policies
ALTER TABLE public.customer_notifications ENABLE ROW LEVEL SECURITY;

-- العملاء يمكنهم قراءة إشعاراتهم فقط
CREATE POLICY "customers_read_own_notifications" ON public.customer_notifications
    FOR SELECT
    USING (
        customer_id IN (
            SELECT id FROM public.customers 
            WHERE auth_user_id = auth.uid()
        )
        OR customer_id IS NULL  -- الإشعارات العامة
    );

-- العملاء يمكنهم تحديث is_read فقط
CREATE POLICY "customers_update_own_notifications" ON public.customer_notifications
    FOR UPDATE
    USING (
        customer_id IN (
            SELECT id FROM public.customers 
            WHERE auth_user_id = auth.uid()
        )
    )
    WITH CHECK (
        customer_id IN (
            SELECT id FROM public.customers 
            WHERE auth_user_id = auth.uid()
        )
    );

-- ═══════════════════════════════════════════════════════════════════════════
-- Trigger: عند تغيير حالة الطلب → إنشاء إشعار تلقائياً
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION create_order_status_notification()
RETURNS TRIGGER AS $$
DECLARE
    v_customer_id bigint;
    v_shop_id uuid;
    v_title text;
    v_body text;
BEGIN
    -- الحصول على بيانات الطلب
    SELECT customer_id, shop_id INTO v_customer_id, v_shop_id
    FROM public.orders WHERE id = NEW.order_id;

    -- تجهيز العنوان والمحتوى حسب الحالة
    CASE NEW.status
        WHEN 'pending' THEN
            v_title := 'تم استلام طلبك #' || NEW.order_id;
            v_body := COALESCE(NULLIF(TRIM(NEW.notes), ''), 'وصلنا طلبك وسيتم مراجعته وتأكيده خلال وقت قصير.');
        WHEN 'confirmed' THEN
            v_title := 'تم تأكيد طلبك #' || NEW.order_id;
            v_body := COALESCE(NULLIF(TRIM(NEW.notes), ''), 'تم اعتماد الطلب وبدأنا تجهيز الخطوة التالية له.');
        WHEN 'preparing' THEN
            v_title := 'طلبك #' || NEW.order_id || ' قيد التحضير';
            v_body := COALESCE(NULLIF(TRIM(NEW.notes), ''), 'يتم الآن تجهيز المنتجات استعدادًا لإرسالها.');
        WHEN 'shipped' THEN
            v_title := 'طلبك #' || NEW.order_id || ' في الطريق';
            v_body := COALESCE(NULLIF(TRIM(NEW.notes), ''), 'تم شحن الطلب وهو الآن في طريقه إليك.');
        WHEN 'delivered' THEN
            v_title := 'تم تسليم طلبك #' || NEW.order_id;
            v_body := COALESCE(NULLIF(TRIM(NEW.notes), ''), 'اكتمل الطلب بنجاح. نتمنى أن تكون التجربة ممتازة.');
        WHEN 'cancelled' THEN
            v_title := 'تم إلغاء طلبك #' || NEW.order_id;
            v_body := COALESCE(NULLIF(TRIM(NEW.notes), ''), 'تم إلغاء الطلب. إذا لم تطلب الإلغاء، تواصل معنا.');
        ELSE
            v_title := 'تحديث على طلبك #' || NEW.order_id;
            v_body := 'حالة الطلب: ' || NEW.status;
    END CASE;

    -- إدراج الإشعار
    INSERT INTO public.customer_notifications (
        shop_id, customer_id, type, title, body, 
        order_id, order_status, payload, is_sent_fcm
    ) VALUES (
        v_shop_id, v_customer_id, 'order_status', v_title, v_body,
        NEW.order_id, NEW.status, 
        jsonb_build_object('history_id', NEW.id, 'notes', NEW.notes),
        false
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- حذف الـ trigger القديم إذا كان موجوداً
DROP TRIGGER IF EXISTS trg_order_status_notification ON public.order_status_history;

-- إنشاء الـ trigger
CREATE TRIGGER trg_order_status_notification
    AFTER INSERT ON public.order_status_history
    FOR EACH ROW
    EXECUTE FUNCTION create_order_status_notification();

-- ═══════════════════════════════════════════════════════════════════════════
-- RLS Policies: السماح لمديري المتجر (shop_users) بالإدارة الكاملة
-- ═══════════════════════════════════════════════════════════════════════════

-- مديرو المتجر يمكنهم قراءة إشعارات متجرهم
CREATE POLICY "shop_admins_read_notifications" ON public.customer_notifications
    FOR SELECT
    USING (
        shop_id IN (
            SELECT su.shop_id FROM public.shop_users su
            WHERE su.user_id = auth.uid()
        )
    );

-- مديرو المتجر يمكنهم إرسال إشعارات (INSERT)
CREATE POLICY "shop_admins_insert_notifications" ON public.customer_notifications
    FOR INSERT
    WITH CHECK (
        shop_id IN (
            SELECT su.shop_id FROM public.shop_users su
            WHERE su.user_id = auth.uid()
        )
    );

-- مديرو المتجر يمكنهم تحديث إشعارات متجرهم
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

-- مديرو المتجر يمكنهم حذف إشعارات متجرهم
CREATE POLICY "shop_admins_delete_notifications" ON public.customer_notifications
    FOR DELETE
    USING (
        shop_id IN (
            SELECT su.shop_id FROM public.shop_users su
            WHERE su.user_id = auth.uid()
        )
    );

-- ═══════════════════════════════════════════════════════════════════════════
-- RLS Policies: السماح لمديري المتجر بقراءة توكنات FCM
-- ═══════════════════════════════════════════════════════════════════════════

CREATE POLICY "shop_admins_read_tokens" ON public.fcm_tokens
    FOR SELECT
    USING (
        shop_id IN (
            SELECT su.shop_id FROM public.shop_users su
            WHERE su.user_id = auth.uid()
        )
    );

-- ═══════════════════════════════════════════════════════════════════════════
-- منح الصلاحيات
-- ═══════════════════════════════════════════════════════════════════════════

GRANT SELECT, INSERT, UPDATE ON public.fcm_tokens TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.customer_notifications TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;
