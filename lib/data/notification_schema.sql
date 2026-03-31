-- إشعارات الطلبات الداخلية والخارجية
-- طبّق هذا الملف على Supabase لإضافة صندوق إشعارات موحّد ودعم push لاحقًا.

CREATE TABLE IF NOT EXISTS public.customer_device_tokens (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id bigint NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  device_token text NOT NULL UNIQUE,
  platform text NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  device_name text,
  is_active boolean NOT NULL DEFAULT true,
  last_seen_at timestamp with time zone NOT NULL DEFAULT now(),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_customer_device_tokens_customer_id
  ON public.customer_device_tokens(customer_id);

CREATE TABLE IF NOT EXISTS public.customer_notifications (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id bigint NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  order_id bigint REFERENCES public.orders(id) ON DELETE CASCADE,
  notification_type text NOT NULL DEFAULT 'order_status',
  order_status text,
  title text NOT NULL,
  body text NOT NULL,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  is_read boolean NOT NULL DEFAULT false,
  push_sent_at timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_customer_notifications_customer_created
  ON public.customer_notifications(customer_id, created_at DESC);

CREATE OR REPLACE FUNCTION public.build_order_notification_title(
  order_status text,
  order_id_value bigint
) RETURNS text
LANGUAGE plpgsql
AS $$
BEGIN
  CASE order_status
    WHEN 'pending' THEN
      RETURN 'تم استلام طلبك #' || order_id_value;
    WHEN 'confirmed' THEN
      RETURN 'تم تأكيد طلبك #' || order_id_value;
    WHEN 'preparing' THEN
      RETURN 'طلبك #' || order_id_value || ' قيد التحضير';
    WHEN 'shipped' THEN
      RETURN 'طلبك #' || order_id_value || ' في الطريق';
    WHEN 'delivered' THEN
      RETURN 'تم تسليم طلبك #' || order_id_value;
    WHEN 'cancelled' THEN
      RETURN 'تم إلغاء طلبك #' || order_id_value;
    ELSE
      RETURN 'تحديث على طلبك #' || order_id_value;
  END CASE;
END;
$$;

CREATE OR REPLACE FUNCTION public.build_order_notification_body(
  order_status text,
  notes_value text
) RETURNS text
LANGUAGE plpgsql
AS $$
BEGIN
  IF notes_value IS NOT NULL AND btrim(notes_value) <> '' THEN
    RETURN notes_value;
  END IF;

  CASE order_status
    WHEN 'pending' THEN
      RETURN 'وصلنا طلبك وسيتم مراجعته وتأكيده خلال وقت قصير.';
    WHEN 'confirmed' THEN
      RETURN 'تم اعتماد الطلب وبدأنا تجهيز الخطوة التالية له.';
    WHEN 'preparing' THEN
      RETURN 'يتم الآن تجهيز المنتجات استعدادًا لإرسالها.';
    WHEN 'shipped' THEN
      RETURN 'تم شحن الطلب وهو الآن في طريقه إليك.';
    WHEN 'delivered' THEN
      RETURN 'اكتمل الطلب بنجاح. نتمنى أن تكون التجربة ممتازة.';
    WHEN 'cancelled' THEN
      RETURN 'تم إلغاء الطلب. إذا لم تطلب الإلغاء، تواصل معنا.';
    ELSE
      RETURN 'تم تحديث حالة طلبك.';
  END CASE;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_customer_notification_from_status_history()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  order_customer_id bigint;
BEGIN
  SELECT customer_id
  INTO order_customer_id
  FROM public.orders
  WHERE id = NEW.order_id;

  IF order_customer_id IS NULL THEN
    RETURN NEW;
  END IF;

  INSERT INTO public.customer_notifications (
    customer_id,
    order_id,
    notification_type,
    order_status,
    title,
    body,
    payload
  ) VALUES (
    order_customer_id,
    NEW.order_id,
    'order_status',
    NEW.status,
    public.build_order_notification_title(NEW.status, NEW.order_id),
    public.build_order_notification_body(NEW.status, NEW.notes),
    jsonb_build_object(
      'history_id', NEW.id,
      'changed_by', NEW.changed_by,
      'location_id', NEW.location_id
    )
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_customer_notification_from_order_status ON public.order_status_history;

CREATE TRIGGER trg_customer_notification_from_order_status
AFTER INSERT ON public.order_status_history
FOR EACH ROW
EXECUTE FUNCTION public.create_customer_notification_from_status_history();

-- الإرسال الخارجي عند إغلاق التطبيق:
-- 1) طبّق هذا الملف.
-- 2) احفظ FCM token في customer_device_tokens من التطبيق.
-- 3) نفّذ Edge Function أو cron job يقرأ customer_notifications حيث push_sent_at IS NULL.
-- 4) يرسل push عبر Firebase Cloud Messaging ثم يحدّث push_sent_at.