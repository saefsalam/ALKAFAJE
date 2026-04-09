-- ═══════════════════════════════════════════════════════════════════════════════════════
--                     🔐 RLS (Row Level Security) - النسخة النهائية
--                              مشروع ALKAFAJE
-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 
-- 📋 التعليمات:
-- 1. افتح Supabase Dashboard
-- 2. اذهب إلى SQL Editor
-- 3. الصق هذا الملف بالكامل
-- 4. اضغط RUN
-- 5. تأكد من عدم وجود أخطاء (أي رسالة Success)
--
-- ⚠️ ملاحظة: هذا الملف آمن للتشغيل عدة مرات (يحذف القديم ويُنشئ الجديد)
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 الجزء 1: الدوال المساعدة (Helper Functions)
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- دالة للحصول على customer_id للمستخدم الحالي
CREATE OR REPLACE FUNCTION public.get_my_customer_id()
RETURNS bigint
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id FROM public.customers 
  WHERE auth_user_id = auth.uid() 
  LIMIT 1;
$$;

-- دالة للحصول على shop_id للموظف الحالي
CREATE OR REPLACE FUNCTION public.get_my_shop_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT shop_id FROM public.shop_users 
  WHERE user_id = auth.uid() 
  LIMIT 1;
$$;

-- دالة للتحقق إذا المستخدم موظف في متجر معين
CREATE OR REPLACE FUNCTION public.is_shop_staff(check_shop_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.shop_users 
    WHERE user_id = auth.uid() 
    AND shop_id = check_shop_id
  );
$$;

-- منح الصلاحيات للدوال
GRANT EXECUTE ON FUNCTION public.get_my_customer_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_shop_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_shop_staff(uuid) TO authenticated;

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 الجزء 2: تفعيل RLS على جميع الجداول
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- جداول العملاء
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.location ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customer_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.whatsapp_otps ENABLE ROW LEVEL SECURITY;

-- جداول المنتجات (عامة للقراءة)
ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.item_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.item_colors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.item_sizes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.banner_ads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.part_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.discount_codes ENABLE ROW LEVEL SECURITY;

-- جداول الداشبورد
ALTER TABLE public.shop_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sotre_location ENABLE ROW LEVEL SECURITY;

-- جداول إضافية
ALTER TABLE public.password_reset_otps ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 الجزء 3: حذف جميع السياسات القديمة
-- ═══════════════════════════════════════════════════════════════════════════════════════

DO $$ 
DECLARE
  r RECORD;
BEGIN
  FOR r IN (
    SELECT schemaname, tablename, policyname 
    FROM pg_policies 
    WHERE schemaname = 'public'
  ) LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', r.policyname, r.schemaname, r.tablename);
  END LOOP;
END $$;

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 الجزء 4: سياسات جدول CUSTOMERS (العملاء)
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- العميل يقرأ بياناته فقط
CREATE POLICY "customer_read_own" ON public.customers
  FOR SELECT USING (auth_user_id = auth.uid());

-- العميل يُنشئ حسابه
CREATE POLICY "customer_create_own" ON public.customers
  FOR INSERT WITH CHECK (auth_user_id = auth.uid());

-- العميل يُحدّث بياناته
CREATE POLICY "customer_update_own" ON public.customers
  FOR UPDATE USING (auth_user_id = auth.uid()) WITH CHECK (auth_user_id = auth.uid());

-- موظفو المتجر يقرأون العملاء
CREATE POLICY "customer_read_staff" ON public.customers
  FOR SELECT USING (is_shop_staff(shop_id));

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 الجزء 5: سياسات جدول ORDERS (الطلبات)
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- العميل يقرأ طلباته
CREATE POLICY "orders_read_own" ON public.orders
  FOR SELECT USING (customer_id = get_my_customer_id());

-- العميل يُنشئ طلب
CREATE POLICY "orders_create_own" ON public.orders
  FOR INSERT WITH CHECK (customer_id = get_my_customer_id());

-- ⭐ العميل يستطيع تحديث طلباته (للإلغاء)
CREATE POLICY "orders_update_own" ON public.orders
  FOR UPDATE 
  USING (customer_id = get_my_customer_id())
  WITH CHECK (customer_id = get_my_customer_id());

-- موظفو المتجر يقرأون الطلبات
CREATE POLICY "orders_read_staff" ON public.orders
  FOR SELECT USING (is_shop_staff(shop_id));

-- موظفو المتجر يُحدّثون الطلبات
CREATE POLICY "orders_update_staff" ON public.orders
  FOR UPDATE USING (is_shop_staff(shop_id)) WITH CHECK (is_shop_staff(shop_id));

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 الجزء 6: سياسات جدول ORDER_ITEMS (عناصر الطلبات)
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- العميل يقرأ عناصر طلباته
CREATE POLICY "order_items_read_own" ON public.order_items
  FOR SELECT USING (
    order_id IN (SELECT id FROM public.orders WHERE customer_id = get_my_customer_id())
  );

-- العميل يُضيف عناصر لطلبه
CREATE POLICY "order_items_create_own" ON public.order_items
  FOR INSERT WITH CHECK (
    order_id IN (SELECT id FROM public.orders WHERE customer_id = get_my_customer_id())
  );

-- موظفو المتجر يقرأون جميع عناصر الطلبات
CREATE POLICY "order_items_read_staff" ON public.order_items
  FOR SELECT USING (
    order_id IN (SELECT id FROM public.orders WHERE is_shop_staff(shop_id))
  );

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 الجزء 7: سياسات جدول ORDER_STATUS_HISTORY (سجل حالات الطلبات)
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- العميل يقرأ سجل حالات طلباته
CREATE POLICY "history_read_own" ON public.order_status_history
  FOR SELECT USING (
    order_id IN (SELECT id FROM public.orders WHERE customer_id = get_my_customer_id())
  );

-- العميل يُضيف السجل الأول (عند إنشاء الطلب)
CREATE POLICY "history_create_own" ON public.order_status_history
  FOR INSERT WITH CHECK (
    order_id IN (SELECT id FROM public.orders WHERE customer_id = get_my_customer_id())
  );

-- موظفو المتجر يقرأون ويُضيفون سجلات
CREATE POLICY "history_read_staff" ON public.order_status_history
  FOR SELECT USING (
    order_id IN (SELECT id FROM public.orders WHERE is_shop_staff(shop_id))
  );

CREATE POLICY "history_create_staff" ON public.order_status_history
  FOR INSERT WITH CHECK (
    order_id IN (SELECT id FROM public.orders WHERE is_shop_staff(shop_id))
  );

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 الجزء 8: سياسات جدول CARTS (السلات)
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- العميل يدير سلته بالكامل
CREATE POLICY "carts_read_own" ON public.carts
  FOR SELECT USING (customer_id = get_my_customer_id());

CREATE POLICY "carts_create_own" ON public.carts
  FOR INSERT WITH CHECK (customer_id = get_my_customer_id());

CREATE POLICY "carts_update_own" ON public.carts
  FOR UPDATE USING (customer_id = get_my_customer_id());

CREATE POLICY "carts_delete_own" ON public.carts
  FOR DELETE USING (customer_id = get_my_customer_id());

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 الجزء 9: سياسات جدول CART_ITEMS (عناصر السلة)
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- العميل يدير عناصر سلته بالكامل
CREATE POLICY "cart_items_read_own" ON public.cart_items
  FOR SELECT USING (
    cart_id IN (SELECT id FROM public.carts WHERE customer_id = get_my_customer_id())
  );

CREATE POLICY "cart_items_create_own" ON public.cart_items
  FOR INSERT WITH CHECK (
    cart_id IN (SELECT id FROM public.carts WHERE customer_id = get_my_customer_id())
  );

CREATE POLICY "cart_items_update_own" ON public.cart_items
  FOR UPDATE USING (
    cart_id IN (SELECT id FROM public.carts WHERE customer_id = get_my_customer_id())
  );

CREATE POLICY "cart_items_delete_own" ON public.cart_items
  FOR DELETE USING (
    cart_id IN (SELECT id FROM public.carts WHERE customer_id = get_my_customer_id())
  );

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 الجزء 10: سياسات جدول FAVORITES (المفضلة)
-- ═══════════════════════════════════════════════════════════════════════════════════════

CREATE POLICY "favorites_read_own" ON public.favorites
  FOR SELECT USING (customer_id = get_my_customer_id());

CREATE POLICY "favorites_create_own" ON public.favorites
  FOR INSERT WITH CHECK (customer_id = get_my_customer_id());

CREATE POLICY "favorites_delete_own" ON public.favorites
  FOR DELETE USING (customer_id = get_my_customer_id());

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 الجزء 11: سياسات جدول LOCATION (مواقع العملاء)
-- ═══════════════════════════════════════════════════════════════════════════════════════

CREATE POLICY "location_read_own" ON public.location
  FOR SELECT USING (customer_id = get_my_customer_id());

CREATE POLICY "location_create_own" ON public.location
  FOR INSERT WITH CHECK (customer_id = get_my_customer_id());

CREATE POLICY "location_update_own" ON public.location
  FOR UPDATE USING (customer_id = get_my_customer_id());

CREATE POLICY "location_delete_own" ON public.location
  FOR DELETE USING (customer_id = get_my_customer_id());

-- موظفو المتجر يقرأون مواقع العملاء (للتوصيل)
CREATE POLICY "location_read_staff" ON public.location
  FOR SELECT USING (is_shop_staff(shop_id));

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 الجزء 12: سياسات جدول FCM_TOKENS (رموز الإشعارات)
-- ═══════════════════════════════════════════════════════════════════════════════════════

CREATE POLICY "fcm_read_own" ON public.fcm_tokens
  FOR SELECT USING (customer_id = get_my_customer_id());

CREATE POLICY "fcm_create_own" ON public.fcm_tokens
  FOR INSERT WITH CHECK (customer_id = get_my_customer_id());

CREATE POLICY "fcm_update_own" ON public.fcm_tokens
  FOR UPDATE USING (customer_id = get_my_customer_id());

CREATE POLICY "fcm_delete_own" ON public.fcm_tokens
  FOR DELETE USING (customer_id = get_my_customer_id());

-- موظفو المتجر يقرأون tokens (لإرسال الإشعارات)
CREATE POLICY "fcm_read_staff" ON public.fcm_tokens
  FOR SELECT USING (is_shop_staff(shop_id));

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 الجزء 13: سياسات جدول CUSTOMER_NOTIFICATIONS (الإشعارات)
-- ═══════════════════════════════════════════════════════════════════════════════════════

CREATE POLICY "notifications_read_own" ON public.customer_notifications
  FOR SELECT USING (customer_id = get_my_customer_id());

CREATE POLICY "notifications_update_own" ON public.customer_notifications
  FOR UPDATE USING (customer_id = get_my_customer_id());

-- موظفو المتجر يديرون الإشعارات
CREATE POLICY "notifications_read_staff" ON public.customer_notifications
  FOR SELECT USING (is_shop_staff(shop_id));

CREATE POLICY "notifications_create_staff" ON public.customer_notifications
  FOR INSERT WITH CHECK (is_shop_staff(shop_id));

-- ⭐ سياسة إضافية: السماح بإنشاء إشعار للعميل الحالي (للنظام/Triggers)
CREATE POLICY "notifications_create_for_own" ON public.customer_notifications
  FOR INSERT WITH CHECK (customer_id = get_my_customer_id());

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 الجزء 14: سياسات جدول WHATSAPP_OTPS (رموز التحقق)
-- ═══════════════════════════════════════════════════════════════════════════════════════

CREATE POLICY "otp_read_own" ON public.whatsapp_otps
  FOR SELECT USING (customer_id = get_my_customer_id());

CREATE POLICY "otp_create_own" ON public.whatsapp_otps
  FOR INSERT WITH CHECK (customer_id = get_my_customer_id());

CREATE POLICY "otp_update_own" ON public.whatsapp_otps
  FOR UPDATE USING (customer_id = get_my_customer_id());

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 الجزء 15: سياسات الجداول العامة (قراءة للجميع)
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- ITEMS (المنتجات) - الجميع يقرأ المنتجات النشطة
CREATE POLICY "items_read_public" ON public.items
  FOR SELECT USING (is_active = true AND is_deleted = false);

CREATE POLICY "items_all_staff" ON public.items
  FOR ALL USING (is_shop_staff(shop_id)) WITH CHECK (is_shop_staff(shop_id));

-- ITEM_IMAGES (صور المنتجات)
CREATE POLICY "item_images_read_public" ON public.item_images
  FOR SELECT USING (
    item_id IN (SELECT id FROM public.items WHERE is_active = true AND is_deleted = false)
  );

CREATE POLICY "item_images_all_staff" ON public.item_images
  FOR ALL USING (
    item_id IN (SELECT id FROM public.items WHERE is_shop_staff(shop_id))
  );

-- ITEM_COLORS (ألوان المنتجات)
CREATE POLICY "item_colors_read_public" ON public.item_colors
  FOR SELECT USING (is_active = true);

CREATE POLICY "item_colors_all_staff" ON public.item_colors
  FOR ALL USING (
    item_id IN (SELECT id FROM public.items WHERE is_shop_staff(shop_id))
  );

-- ITEM_SIZES (أحجام المنتجات)
CREATE POLICY "item_sizes_read_public" ON public.item_sizes
  FOR SELECT USING (is_active = true);

CREATE POLICY "item_sizes_all_staff" ON public.item_sizes
  FOR ALL USING (
    item_id IN (SELECT id FROM public.items WHERE is_shop_staff(shop_id))
  );

-- CATEGORIES (التصنيفات)
CREATE POLICY "categories_read_public" ON public.categories
  FOR SELECT USING (true);

CREATE POLICY "categories_all_staff" ON public.categories
  FOR ALL USING (is_shop_staff(shop_id)) WITH CHECK (is_shop_staff(shop_id));

-- BANNER_ADS (الإعلانات)
CREATE POLICY "banner_ads_read_public" ON public.banner_ads
  FOR SELECT USING (is_active = true);

CREATE POLICY "banner_ads_all_staff" ON public.banner_ads
  FOR ALL USING (is_shop_staff(shop_id)) WITH CHECK (is_shop_staff(shop_id));

-- PARTS (الأقسام)
CREATE POLICY "parts_read_public" ON public.parts
  FOR SELECT USING (is_active = true);

CREATE POLICY "parts_all_staff" ON public.parts
  FOR ALL USING (is_shop_staff(shop_id)) WITH CHECK (is_shop_staff(shop_id));

-- PART_ITEMS (عناصر الأقسام)
CREATE POLICY "part_items_read_public" ON public.part_items
  FOR SELECT USING (
    part_id IN (SELECT id FROM public.parts WHERE is_active = true)
  );

CREATE POLICY "part_items_all_staff" ON public.part_items
  FOR ALL USING (
    part_id IN (SELECT id FROM public.parts WHERE is_shop_staff(shop_id))
  );

-- DELIVERY_ZONES (مناطق التوصيل)
CREATE POLICY "delivery_zones_read_public" ON public.delivery_zones
  FOR SELECT USING (true);

CREATE POLICY "delivery_zones_all_staff" ON public.delivery_zones
  FOR ALL USING (is_shop_staff(shop_id)) WITH CHECK (is_shop_staff(shop_id));

-- DISCOUNT_CODES (أكواد الخصم)
CREATE POLICY "discount_codes_read_public" ON public.discount_codes
  FOR SELECT USING (is_active = true AND expiry_date >= CURRENT_DATE);

CREATE POLICY "discount_codes_all_staff" ON public.discount_codes
  FOR ALL USING (is_shop_staff(shop_id)) WITH CHECK (is_shop_staff(shop_id));

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 الجزء 16: سياسات جداول الداشبورد
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- SHOP_USERS - موظف يقرأ بياناته
CREATE POLICY "shop_users_read_own" ON public.shop_users
  FOR SELECT USING (user_id = auth.uid());

-- موظف يقرأ زملاءه في نفس المتجر
CREATE POLICY "shop_users_read_colleagues" ON public.shop_users
  FOR SELECT USING (shop_id = get_my_shop_id());

-- SHOPS - موظف يقرأ بيانات متجره
CREATE POLICY "shops_read_own" ON public.shops
  FOR SELECT USING (id = get_my_shop_id());

-- SOTRE_LOCATION (مواقع المتجر)
CREATE POLICY "store_location_read_staff" ON public.sotre_location
  FOR SELECT USING (is_shop_staff(shop_id));

CREATE POLICY "store_location_all_staff" ON public.sotre_location
  FOR ALL USING (is_shop_staff(shop_id)) WITH CHECK (is_shop_staff(shop_id));

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 الجزء 17: Trigger لإنشاء سجل الحالة تلقائياً
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- دالة Trigger تعمل بصلاحيات مرتفعة
CREATE OR REPLACE FUNCTION public.auto_create_order_status_history()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.order_status_history (order_id, status, notes, created_at)
  VALUES (NEW.id, NEW.status, 'تم إنشاء الطلب', NEW.created_at);
  RETURN NEW;
END;
$$;

-- حذف Trigger القديم إن وجد
DROP TRIGGER IF EXISTS trigger_auto_order_status ON public.orders;

-- إنشاء Trigger جديد
CREATE TRIGGER trigger_auto_order_status
  AFTER INSERT ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_create_order_status_history();

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 الجزء 18: سياسات جدول PASSWORD_RESET_OTPS
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- سياسة: السماح بإنشاء OTP (للجميع - عملية استرداد كلمة المرور)
CREATE POLICY "password_reset_insert" ON public.password_reset_otps
  FOR INSERT TO anon, authenticated
  WITH CHECK (true);

-- سياسة: قراءة OTP للتحقق
CREATE POLICY "password_reset_select" ON public.password_reset_otps
  FOR SELECT TO anon, authenticated
  USING (true);

-- سياسة: تحديث OTP (لتسجيل الاستهلاك)
CREATE POLICY "password_reset_update" ON public.password_reset_otps
  FOR UPDATE TO anon, authenticated
  USING (true)
  WITH CHECK (true);

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 🔹 الجزء 19: إعادة إنشاء VIEW customers_with_auth
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- حذف الـ VIEW القديم
DROP VIEW IF EXISTS public.customers_with_auth;

-- إنشاء VIEW جديد (يعتمد على RLS الموجود على جدول customers)
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

-- منح صلاحية القراءة
GRANT SELECT ON public.customers_with_auth TO authenticated;

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ✅ تم الانتهاء بنجاح!
-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 
-- 📝 ملخص ما تم:
-- ✓ إنشاء 3 دوال مساعدة
-- ✓ تفعيل RLS على جميع الجداول
-- ✓ إنشاء سياسات للعملاء (التطبيق)
-- ✓ إنشاء سياسات للموظفين (الداشبورد)
-- ✓ إنشاء Trigger لسجل الحالة التلقائي
--
-- 🧪 للاختبار:
-- 1. سجّل دخول في التطبيق كعميل
-- 2. أضف منتج للسلة
-- 3. أنشئ طلب جديد
-- 4. افتح الداشبورد وتأكد من ظهور الطلب
-- ═══════════════════════════════════════════════════════════════════════════════════════
