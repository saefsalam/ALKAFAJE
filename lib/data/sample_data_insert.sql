-- ═══════════════════════════════════════════════════════════════
-- 📋 استعلامات SQL لإضافة بيانات تجريبية لصفحة المنتجات
-- ═══════════════════════════════════════════════════════════════
-- قم بتنفيذ هذه الاستعلامات في Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════
-- 1️⃣ إنشاء متجر (Shop)
-- ═══════════════════════════════════════════════════════════════
INSERT INTO public.shops (
  id,
  display_name,
  phone,
  address,
  primary_color,
  logo_url,
  primary_language,
  facebook_url,
  instagram_url
) VALUES (
  '550e8400-e29b-41d4-a716-446655440001'::uuid,
  'الكفجي للمواد الغذائية',
  '+964 770 123 4567',
  'بغداد - الكرادة',
  '#2563eb',
  'https://example.com/logo.png',
  'ar',
  'https://facebook.com/alkafajy',
  'https://instagram.com/alkafajy'
);

-- ═══════════════════════════════════════════════════════════════
-- 2️⃣ إنشاء تصنيفات (Categories)
-- ═══════════════════════════════════════════════════════════════
INSERT INTO public.categories (id, shop_id, name, icon, created_at, updated_at) VALUES
-- تصنيف المشروبات
(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440001'::uuid, 'مشروبات', 'assets/img/categories/drinks.png', now(), now()),

-- تصنيف المعلبات
(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440001'::uuid, 'معلبات', 'assets/img/categories/canned.png', now(), now()),

-- تصنيف الحلويات
(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440001'::uuid, 'حلويات', 'assets/img/categories/sweets.png', now(), now()),

-- تصنيف الألبان
(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440001'::uuid, 'ألبان', 'assets/img/categories/dairy.png', now(), now()),

-- تصنيف البقوليات
(gen_random_uuid(), '550e8400-e29b-41d4-a716-446655440001'::uuid, 'بقوليات', 'assets/img/categories/legumes.png', now(), now());

-- ═══════════════════════════════════════════════════════════════
-- 3️⃣ إنشاء منتجات (Items/Products)
-- ═══════════════════════════════════════════════════════════════

-- الحصول على معرف تصنيف المشروبات
DO $$
DECLARE
  drinks_category_id uuid;
  canned_category_id uuid;
  sweets_category_id uuid;
  dairy_category_id uuid;
  legumes_category_id uuid;
  product1_id bigint;
  product2_id bigint;
  product3_id bigint;
  product4_id bigint;
  product5_id bigint;
  product6_id bigint;
BEGIN
  -- الحصول على معرفات التصنيفات
  SELECT id INTO drinks_category_id FROM public.categories WHERE shop_id = '550e8400-e29b-41d4-a716-446655440001'::uuid AND name = 'مشروبات' LIMIT 1;
  SELECT id INTO canned_category_id FROM public.categories WHERE shop_id = '550e8400-e29b-41d4-a716-446655440001'::uuid AND name = 'معلبات' LIMIT 1;
  SELECT id INTO sweets_category_id FROM public.categories WHERE shop_id = '550e8400-e29b-41d4-a716-446655440001'::uuid AND name = 'حلويات' LIMIT 1;
  SELECT id INTO dairy_category_id FROM public.categories WHERE shop_id = '550e8400-e29b-41d4-a716-446655440001'::uuid AND name = 'ألبان' LIMIT 1;
  SELECT id INTO legumes_category_id FROM public.categories WHERE shop_id = '550e8400-e29b-41d4-a716-446655440001'::uuid AND name = 'بقوليات' LIMIT 1;

  -- ═══════════════════════════════════════════════════════════════
  -- منتجات المشروبات
  -- ═══════════════════════════════════════════════════════════════
  
  -- منتج 1: بيبسي كولا
  INSERT INTO public.items (shop_id, category_id, title, description, price, is_active, is_deleted)
  VALUES (
    '550e8400-e29b-41d4-a716-446655440001'::uuid,
    drinks_category_id,
    'بيبسي كولا 330 مل',
    'مشروب غازي بنكهة الكولا الأصلية، عبوة 330 مل',
    1500,
    true,
    false
  ) RETURNING id INTO product1_id;

  -- إضافة صور للمنتج 1
  INSERT INTO public.item_images (item_id, image_path, sort_order, is_primary) VALUES
  (product1_id, 'assets/img/products/pepsi_330ml.png', 1, true),
  (product1_id, 'assets/img/products/pepsi_330ml_2.png', 2, false);

  -- منتج 2: عصير برتقال
  INSERT INTO public.items (shop_id, category_id, title, description, price, is_active, is_deleted)
  VALUES (
    '550e8400-e29b-41d4-a716-446655440001'::uuid,
    drinks_category_id,
    'عصير برتقال طبيعي 1 لتر',
    'عصير برتقال طبيعي 100%، غني بفيتامين C',
    3000,
    true,
    false
  ) RETURNING id INTO product2_id;

  -- إضافة صور للمنتج 2
  INSERT INTO public.item_images (item_id, image_path, sort_order, is_primary) VALUES
  (product2_id, 'assets/img/products/orange_juice.png', 1, true);

  -- ═══════════════════════════════════════════════════════════════
  -- منتجات المعلبات
  -- ═══════════════════════════════════════════════════════════════
  
  -- منتج 3: تونة معلبة
  INSERT INTO public.items (shop_id, category_id, title, description, price, is_active, is_deleted)
  VALUES (
    '550e8400-e29b-41d4-a716-446655440001'::uuid,
    canned_category_id,
    'تونة معلبة 160 جرام',
    'تونة معلبة بزيت الزيتون، غنية بالبروتين',
    2500,
    true,
    false
  ) RETURNING id INTO product3_id;

  -- إضافة صور للمنتج 3
  INSERT INTO public.item_images (item_id, image_path, sort_order, is_primary) VALUES
  (product3_id, 'assets/img/products/tuna.png', 1, true);

  -- منتج 4: معجون طماطم
  INSERT INTO public.items (shop_id, category_id, title, description, price, is_active, is_deleted)
  VALUES (
    '550e8400-e29b-41d4-a716-446655440001'::uuid,
    canned_category_id,
    'معجون طماطم 400 جرام',
    'معجون طماطم مركز، مثالي للطبخ',
    1000,
    true,
    false
  ) RETURNING id INTO product4_id;

  -- إضافة صور للمنتج 4
  INSERT INTO public.item_images (item_id, image_path, sort_order, is_primary) VALUES
  (product4_id, 'assets/img/products/tomato_paste.png', 1, true);

  -- ═══════════════════════════════════════════════════════════════
  -- منتجات الحلويات
  -- ═══════════════════════════════════════════════════════════════
  
  -- منتج 5: شوكولاتة جالكسي
  INSERT INTO public.items (shop_id, category_id, title, description, price, is_active, is_deleted)
  VALUES (
    '550e8400-e29b-41d4-a716-446655440001'::uuid,
    sweets_category_id,
    'شوكولاتة جالكسي 165 جرام',
    'شوكولاتة بالحليب الكريمية اللذيذة',
    3500,
    true,
    false
  ) RETURNING id INTO product5_id;

  -- إضافة صور للمنتج 5
  INSERT INTO public.item_images (item_id, image_path, sort_order, is_primary) VALUES
  (product5_id, 'assets/img/products/galaxy.png', 1, true);

  -- منتج 6: بسكويت أوريو
  INSERT INTO public.items (shop_id, category_id, title, description, price, is_active, is_deleted)
  VALUES (
    '550e8400-e29b-41d4-a716-446655440001'::uuid,
    sweets_category_id,
    'بسكويت أوريو 274 جرام',
    'بسكويت بالشوكولاتة مع كريمة الفانيليا',
    2750,
    true,
    false
  ) RETURNING id INTO product6_id;

  -- إضافة صور للمنتج 6
  INSERT INTO public.item_images (item_id, image_path, sort_order, is_primary) VALUES
  (product6_id, 'assets/img/products/oreo.png', 1, true);

END $$;

-- ═══════════════════════════════════════════════════════════════
-- 4️⃣ إنشاء عميل تجريبي (Customer)
-- ═══════════════════════════════════════════════════════════════
INSERT INTO public.customers (
  shop_id,
  name,
  phone,
  city,
  location,
  address,
  is_active,
  is_banned
) VALUES (
  '550e8400-e29b-41d4-a716-446655440001'::uuid,
  'أحمد محمد',
  '+964 770 123 4567',
  'بغداد',
  'الكرادة',
  'شارع الرشيد، بناية 12، الطابق الثالث',
  true,
  false
);

-- ═══════════════════════════════════════════════════════════════
-- 5️⃣ إنشاء مناطق التوصيل (Delivery Zones)
-- ═══════════════════════════════════════════════════════════════
INSERT INTO public.delivery_zones (shop_id, city, price) VALUES
('550e8400-e29b-41d4-a716-446655440001'::uuid, 'بغداد', 3000),
('550e8400-e29b-41d4-a716-446655440001'::uuid, 'الكرادة', 2000),
('550e8400-e29b-41d4-a716-446655440001'::uuid, 'الجادرية', 2500),
('550e8400-e29b-41d4-a716-446655440001'::uuid, 'الكاظمية', 4000),
('550e8400-e29b-41d4-a716-446655440001'::uuid, 'الأعظمية', 4000);

-- ═══════════════════════════════════════════════════════════════
-- 6️⃣ إضافة إعلانات البانر (Banner Ads)
-- ═══════════════════════════════════════════════════════════════
INSERT INTO public.banner_ads (shop_id, image_path, sort_order, is_active) VALUES
('550e8400-e29b-41d4-a716-446655440001'::uuid, 'assets/img/banners/banner1.png', 1, true),
('550e8400-e29b-41d4-a716-446655440001'::uuid, 'assets/img/banners/banner2.png', 2, true),
('550e8400-e29b-41d4-a716-446655440001'::uuid, 'assets/img/banners/banner3.png', 3, true);

-- ═══════════════════════════════════════════════════════════════
-- ✅ تم إدراج جميع البيانات بنجاح!
-- ═══════════════════════════════════════════════════════════════
-- الآن يمكنك تشغيل التطبيق ورؤية:
-- - 1 متجر (الكفجي)
-- - 5 تصنيفات (مشروبات، معلبات، حلويات، ألبان، بقوليات)
-- - 6 منتجات موزعة على التصنيفات المختلفة
-- - 1 عميل تجريبي
-- - 5 مناطق توصيل
-- - 3 إعلانات بانر
-- ═══════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════
-- 📝 ملاحظات مهمة:
-- ═══════════════════════════════════════════════════════════════
-- 1. تأكد من تحديث SupabaseConfig.shopId في التطبيق:
--    static const String shopId = '550e8400-e29b-41d4-a716-446655440001';
--
-- 2. الصور المستخدمة هي مسارات افتراضية، يمكنك تحديثها لاحقاً
--
-- 3. الأسعار بالدينار العراقي (IQD)
--
-- 4. جميع المنتجات نشطة (is_active = true)
-- ═══════════════════════════════════════════════════════════════
