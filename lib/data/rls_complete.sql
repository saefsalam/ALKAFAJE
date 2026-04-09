-- ═══════════════════════════════════════════════════════════════════════════════════════
--                          🔐 RLS (Row Level Security) الشامل
--                              لمشروع ALKAFAJE
-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 
-- 📋 التعليمات:
-- 1. انسخ هذا الملف بالكامل
-- 2. افتح Supabase Dashboard → SQL Editor
-- 3. الصق الكود وشغّله
-- 4. تأكد من عدم وجود أخطاء
--
-- ⚠️ مهم: هذا الملف يحذف جميع السياسات القديمة ويُنشئ سياسات جديدة
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 📌 الخطوة 1: دالة مساعدة للحصول على customer_id من auth.uid()
-- ═══════════════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.get_my_customer_id()
RETURNS bigint
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT id FROM public.customers 
  WHERE auth_user_id = auth.uid() 
  LIMIT 1;
$$;

-- دالة للحصول على shop_id للمستخدم الحالي (للداشبورد)
CREATE OR REPLACE FUNCTION public.get_my_shop_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT shop_id FROM public.shop_users 
  WHERE user_id = auth.uid() 
  LIMIT 1;
$$;

-- دالة للتحقق من أن المستخدم موظف في المتجر
CREATE OR REPLACE FUNCTION public.is_shop_staff(check_shop_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.shop_users 
    WHERE user_id = auth.uid() 
    AND shop_id = check_shop_id
  );
$$;

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 📌 الخطوة 2: تفعيل RLS على جميع الجداول
-- ═══════════════════════════════════════════════════════════════════════════════════════

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

-- جداول عامة (للقراءة فقط للجميع)
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

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 📌 الخطوة 3: حذف جميع السياسات القديمة
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
-- 📌 الخطوة 4: سياسات جدول CUSTOMERS
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- العميل يقرأ بياناته فقط
CREATE POLICY "customers_select_own"
ON public.customers FOR SELECT
USING (auth_user_id = auth.uid());

-- العميل يُنشئ حسابه (أول مرة)
CREATE POLICY "customers_insert_own"
ON public.customers FOR INSERT
WITH CHECK (auth_user_id = auth.uid());

-- العميل يُحدّث بياناته فقط
CREATE POLICY "customers_update_own"
ON public.customers FOR UPDATE
USING (auth_user_id = auth.uid())
WITH CHECK (auth_user_id = auth.uid());

-- موظفو المتجر يقرأون جميع العملاء
CREATE POLICY "customers_select_staff"
ON public.customers FOR SELECT
USING (is_shop_staff(shop_id));

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 📌 الخطوة 5: سياسات جدول ORDERS
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- العميل يقرأ طلباته فقط
CREATE POLICY "orders_select_own"
ON public.orders FOR SELECT
USING (customer_id = get_my_customer_id());

-- العميل يُنشئ طلباً جديداً
CREATE POLICY "orders_insert_own"
ON public.orders FOR INSERT
WITH CHECK (customer_id = get_my_customer_id());

-- موظفو المتجر يقرأون جميع الطلبات
CREATE POLICY "orders_select_staff"
ON public.orders FOR SELECT
USING (is_shop_staff(shop_id));

-- موظفو المتجر يُحدّثون الطلبات
CREATE POLICY "orders_update_staff"
ON public.orders FOR UPDATE
USING (is_shop_staff(shop_id))
WITH CHECK (is_shop_staff(shop_id));

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 📌 الخطوة 6: سياسات جدول ORDER_ITEMS
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- العميل يقرأ عناصر طلباته
CREATE POLICY "order_items_select_own"
ON public.order_items FOR SELECT
USING (
  order_id IN (SELECT id FROM public.orders WHERE customer_id = get_my_customer_id())
);

-- العميل يُضيف عناصر لطلبه
CREATE POLICY "order_items_insert_own"
ON public.order_items FOR INSERT
WITH CHECK (
  order_id IN (SELECT id FROM public.orders WHERE customer_id = get_my_customer_id())
);

-- موظفو المتجر يقرأون جميع عناصر الطلبات
CREATE POLICY "order_items_select_staff"
ON public.order_items FOR SELECT
USING (
  order_id IN (SELECT id FROM public.orders WHERE is_shop_staff(shop_id))
);

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 📌 الخطوة 7: سياسات جدول ORDER_STATUS_HISTORY
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- العميل يقرأ سجل حالات طلباته
CREATE POLICY "order_status_history_select_own"
ON public.order_status_history FOR SELECT
USING (
  order_id IN (SELECT id FROM public.orders WHERE customer_id = get_my_customer_id())
);

-- العميل يُضيف سجل الحالة الأولية
CREATE POLICY "order_status_history_insert_own"
ON public.order_status_history FOR INSERT
WITH CHECK (
  order_id IN (SELECT id FROM public.orders WHERE customer_id = get_my_customer_id())
);

-- موظفو المتجر يقرأون ويُحدّثون سجل الحالات
CREATE POLICY "order_status_history_select_staff"
ON public.order_status_history FOR SELECT
USING (
  order_id IN (SELECT id FROM public.orders WHERE is_shop_staff(shop_id))
);

CREATE POLICY "order_status_history_insert_staff"
ON public.order_status_history FOR INSERT
WITH CHECK (
  order_id IN (SELECT id FROM public.orders WHERE is_shop_staff(shop_id))
);

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 📌 الخطوة 8: سياسات جدول CARTS
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- العميل يقرأ سلته فقط
CREATE POLICY "carts_select_own"
ON public.carts FOR SELECT
USING (customer_id = get_my_customer_id());

-- العميل يُنشئ سلة جديدة
CREATE POLICY "carts_insert_own"
ON public.carts FOR INSERT
WITH CHECK (customer_id = get_my_customer_id());

-- العميل يُحدّث سلته
CREATE POLICY "carts_update_own"
ON public.carts FOR UPDATE
USING (customer_id = get_my_customer_id());

-- العميل يحذف سلته
CREATE POLICY "carts_delete_own"
ON public.carts FOR DELETE
USING (customer_id = get_my_customer_id());

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 📌 الخطوة 9: سياسات جدول CART_ITEMS
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- العميل يقرأ عناصر سلته
CREATE POLICY "cart_items_select_own"
ON public.cart_items FOR SELECT
USING (
  cart_id IN (SELECT id FROM public.carts WHERE customer_id = get_my_customer_id())
);

-- العميل يُضيف عناصر لسلته
CREATE POLICY "cart_items_insert_own"
ON public.cart_items FOR INSERT
WITH CHECK (
  cart_id IN (SELECT id FROM public.carts WHERE customer_id = get_my_customer_id())
);

-- العميل يُحدّث عناصر سلته
CREATE POLICY "cart_items_update_own"
ON public.cart_items FOR UPDATE
USING (
  cart_id IN (SELECT id FROM public.carts WHERE customer_id = get_my_customer_id())
);

-- العميل يحذف عناصر من سلته
CREATE POLICY "cart_items_delete_own"
ON public.cart_items FOR DELETE
USING (
  cart_id IN (SELECT id FROM public.carts WHERE customer_id = get_my_customer_id())
);

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 📌 الخطوة 10: سياسات جدول FAVORITES
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- العميل يقرأ مفضلاته
CREATE POLICY "favorites_select_own"
ON public.favorites FOR SELECT
USING (customer_id = get_my_customer_id());

-- العميل يُضيف للمفضلة
CREATE POLICY "favorites_insert_own"
ON public.favorites FOR INSERT
WITH CHECK (customer_id = get_my_customer_id());

-- العميل يحذف من المفضلة
CREATE POLICY "favorites_delete_own"
ON public.favorites FOR DELETE
USING (customer_id = get_my_customer_id());

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 📌 الخطوة 11: سياسات جدول LOCATION (مواقع العملاء)
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- العميل يقرأ مواقعه
CREATE POLICY "location_select_own"
ON public.location FOR SELECT
USING (customer_id = get_my_customer_id());

-- العميل يُضيف موقعاً
CREATE POLICY "location_insert_own"
ON public.location FOR INSERT
WITH CHECK (customer_id = get_my_customer_id());

-- العميل يُحدّث مواقعه
CREATE POLICY "location_update_own"
ON public.location FOR UPDATE
USING (customer_id = get_my_customer_id());

-- العميل يحذف مواقعه
CREATE POLICY "location_delete_own"
ON public.location FOR DELETE
USING (customer_id = get_my_customer_id());

-- موظفو المتجر يقرأون مواقع العملاء (للتوصيل)
CREATE POLICY "location_select_staff"
ON public.location FOR SELECT
USING (is_shop_staff(shop_id));

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 📌 الخطوة 12: سياسات جدول FCM_TOKENS
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- العميل يدير tokens الخاصة به
CREATE POLICY "fcm_tokens_select_own"
ON public.fcm_tokens FOR SELECT
USING (customer_id = get_my_customer_id());

CREATE POLICY "fcm_tokens_insert_own"
ON public.fcm_tokens FOR INSERT
WITH CHECK (customer_id = get_my_customer_id());

CREATE POLICY "fcm_tokens_update_own"
ON public.fcm_tokens FOR UPDATE
USING (customer_id = get_my_customer_id());

CREATE POLICY "fcm_tokens_delete_own"
ON public.fcm_tokens FOR DELETE
USING (customer_id = get_my_customer_id());

-- موظفو المتجر يقرأون tokens للإشعارات
CREATE POLICY "fcm_tokens_select_staff"
ON public.fcm_tokens FOR SELECT
USING (is_shop_staff(shop_id));

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 📌 الخطوة 13: سياسات جدول CUSTOMER_NOTIFICATIONS
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- العميل يقرأ إشعاراته
CREATE POLICY "customer_notifications_select_own"
ON public.customer_notifications FOR SELECT
USING (customer_id = get_my_customer_id());

-- العميل يُحدّث إشعاراته (قراءة)
CREATE POLICY "customer_notifications_update_own"
ON public.customer_notifications FOR UPDATE
USING (customer_id = get_my_customer_id());

-- موظفو المتجر يُنشئون إشعارات
CREATE POLICY "customer_notifications_insert_staff"
ON public.customer_notifications FOR INSERT
WITH CHECK (is_shop_staff(shop_id));

CREATE POLICY "customer_notifications_select_staff"
ON public.customer_notifications FOR SELECT
USING (is_shop_staff(shop_id));

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 📌 الخطوة 14: سياسات جدول WHATSAPP_OTPS
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- العميل يقرأ OTPs الخاصة به
CREATE POLICY "whatsapp_otps_select_own"
ON public.whatsapp_otps FOR SELECT
USING (customer_id = get_my_customer_id());

-- العميل يُنشئ OTP
CREATE POLICY "whatsapp_otps_insert_own"
ON public.whatsapp_otps FOR INSERT
WITH CHECK (customer_id = get_my_customer_id());

-- العميل يُحدّث OTP
CREATE POLICY "whatsapp_otps_update_own"
ON public.whatsapp_otps FOR UPDATE
USING (customer_id = get_my_customer_id());

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 📌 الخطوة 15: سياسات الجداول العامة (للقراءة فقط)
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- ITEMS - الجميع يقرأ المنتجات النشطة
CREATE POLICY "items_select_public"
ON public.items FOR SELECT
USING (is_active = true AND is_deleted = false);

-- موظفو المتجر يديرون المنتجات
CREATE POLICY "items_all_staff"
ON public.items FOR ALL
USING (is_shop_staff(shop_id))
WITH CHECK (is_shop_staff(shop_id));

-- ITEM_IMAGES - الجميع يقرأ صور المنتجات
CREATE POLICY "item_images_select_public"
ON public.item_images FOR SELECT
USING (
  item_id IN (SELECT id FROM public.items WHERE is_active = true AND is_deleted = false)
);

CREATE POLICY "item_images_all_staff"
ON public.item_images FOR ALL
USING (
  item_id IN (SELECT id FROM public.items WHERE is_shop_staff(shop_id))
);

-- ITEM_COLORS - الجميع يقرأ الألوان
CREATE POLICY "item_colors_select_public"
ON public.item_colors FOR SELECT
USING (is_active = true);

CREATE POLICY "item_colors_all_staff"
ON public.item_colors FOR ALL
USING (
  item_id IN (SELECT id FROM public.items WHERE is_shop_staff(shop_id))
);

-- ITEM_SIZES - الجميع يقرأ الأحجام
CREATE POLICY "item_sizes_select_public"
ON public.item_sizes FOR SELECT
USING (is_active = true);

CREATE POLICY "item_sizes_all_staff"
ON public.item_sizes FOR ALL
USING (
  item_id IN (SELECT id FROM public.items WHERE is_shop_staff(shop_id))
);

-- CATEGORIES - الجميع يقرأ التصنيفات
CREATE POLICY "categories_select_public"
ON public.categories FOR SELECT
USING (true);

CREATE POLICY "categories_all_staff"
ON public.categories FOR ALL
USING (is_shop_staff(shop_id))
WITH CHECK (is_shop_staff(shop_id));

-- BANNER_ADS - الجميع يقرأ الإعلانات
CREATE POLICY "banner_ads_select_public"
ON public.banner_ads FOR SELECT
USING (is_active = true);

CREATE POLICY "banner_ads_all_staff"
ON public.banner_ads FOR ALL
USING (is_shop_staff(shop_id))
WITH CHECK (is_shop_staff(shop_id));

-- PARTS - الجميع يقرأ الأقسام
CREATE POLICY "parts_select_public"
ON public.parts FOR SELECT
USING (is_active = true);

CREATE POLICY "parts_all_staff"
ON public.parts FOR ALL
USING (is_shop_staff(shop_id))
WITH CHECK (is_shop_staff(shop_id));

-- PART_ITEMS - الجميع يقرأ عناصر الأقسام
CREATE POLICY "part_items_select_public"
ON public.part_items FOR SELECT
USING (
  part_id IN (SELECT id FROM public.parts WHERE is_active = true)
);

CREATE POLICY "part_items_all_staff"
ON public.part_items FOR ALL
USING (
  part_id IN (SELECT id FROM public.parts WHERE is_shop_staff(shop_id))
);

-- DELIVERY_ZONES - الجميع يقرأ مناطق التوصيل
CREATE POLICY "delivery_zones_select_public"
ON public.delivery_zones FOR SELECT
USING (true);

CREATE POLICY "delivery_zones_all_staff"
ON public.delivery_zones FOR ALL
USING (is_shop_staff(shop_id))
WITH CHECK (is_shop_staff(shop_id));

-- DISCOUNT_CODES - الجميع يقرأ الأكواد النشطة
CREATE POLICY "discount_codes_select_public"
ON public.discount_codes FOR SELECT
USING (is_active = true AND expiry_date >= CURRENT_DATE);

CREATE POLICY "discount_codes_all_staff"
ON public.discount_codes FOR ALL
USING (is_shop_staff(shop_id))
WITH CHECK (is_shop_staff(shop_id));

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 📌 الخطوة 16: سياسات جداول الداشبورد
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- SHOP_USERS - موظفو المتجر
CREATE POLICY "shop_users_select_own"
ON public.shop_users FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "shop_users_select_same_shop"
ON public.shop_users FOR SELECT
USING (shop_id = get_my_shop_id());

-- SHOPS - موظفو المتجر يقرأون بيانات متجرهم
CREATE POLICY "shops_select_own"
ON public.shops FOR SELECT
USING (id = get_my_shop_id());

-- SOTRE_LOCATION - مواقع المتجر (للموظفين)
CREATE POLICY "sotre_location_select_staff"
ON public.sotre_location FOR SELECT
USING (is_shop_staff(shop_id));

CREATE POLICY "sotre_location_all_staff"
ON public.sotre_location FOR ALL
USING (is_shop_staff(shop_id))
WITH CHECK (is_shop_staff(shop_id));

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 📌 الخطوة 17: Trigger لإنشاء سجل order_status_history تلقائياً
-- ═══════════════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.add_initial_order_status()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.order_status_history (order_id, status, notes, created_at)
  VALUES (NEW.id, NEW.status, 'تم إنشاء الطلب', NEW.created_at);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_add_initial_order_status ON public.orders;

CREATE TRIGGER trigger_add_initial_order_status
  AFTER INSERT ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.add_initial_order_status();

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- 📌 الخطوة 18: منح الصلاحيات للـ anon و authenticated
-- ═══════════════════════════════════════════════════════════════════════════════════════

-- منح صلاحية تنفيذ الدوال
GRANT EXECUTE ON FUNCTION public.get_my_customer_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_shop_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_shop_staff(uuid) TO authenticated;

-- ═══════════════════════════════════════════════════════════════════════════════════════
-- ✅ تم الانتهاء!
-- ═══════════════════════════════════════════════════════════════════════════════════════
--
-- الآن RLS مفعّل على جميع الجداول مع السياسات المناسبة.
--
-- للاختبار:
-- 1. سجّل دخول كعميل في التطبيق
-- 2. حاول إنشاء طلب
-- 3. تحقق من ظهور الطلب في الداشبورد
--
-- ═══════════════════════════════════════════════════════════════════════════════════════
