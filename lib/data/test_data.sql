-- ═══════════════════════════════════════════════════════════════════════════
-- بيانات تجريبية للاختبار - ALKAFAJE
-- شغل هذا الكود في Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════════════════════

-- معرف المتجر (تأكد إنه نفس الموجود عندك)
-- shop_id = '550e8400-e29b-41d4-a716-446655440001'

-- ═══════════════════════════════════════════════════════════════════════════
-- 1. إنشاء جدول البارتات (إذا لم يكن موجوداً)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.parts (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  shop_id uuid NOT NULL,
  name text NOT NULL,
  sort_order smallint NOT NULL DEFAULT 1,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT parts_pkey PRIMARY KEY (id),
  CONSTRAINT parts_shop_id_fkey FOREIGN KEY (shop_id) REFERENCES public.shops(id)
);

CREATE TABLE IF NOT EXISTS public.part_items (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  part_id bigint NOT NULL,
  item_id bigint NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT part_items_pkey PRIMARY KEY (id),
  CONSTRAINT part_items_part_id_fkey FOREIGN KEY (part_id) REFERENCES public.parts(id),
  CONSTRAINT part_items_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id),
  CONSTRAINT part_items_unique UNIQUE (part_id, item_id)
);

-- ═══════════════════════════════════════════════════════════════════════════
-- 2. إضافة التصنيفات
-- ═══════════════════════════════════════════════════════════════════════════

INSERT INTO categories (shop_id, name, icon) VALUES
  ('550e8400-e29b-41d4-a716-446655440001', 'الصحون', 'assets/icons/plates.png'),
  ('550e8400-e29b-41d4-a716-446655440001', 'الأكواب', 'assets/icons/cups.png'),
  ('550e8400-e29b-41d4-a716-446655440001', 'الأطقم', 'assets/icons/sets.png'),
  ('550e8400-e29b-41d4-a716-446655440001', 'الدلال', 'assets/icons/pots.png'),
  ('550e8400-e29b-41d4-a716-446655440001', 'الهدايا', 'assets/icons/gifts.png')
ON CONFLICT DO NOTHING;

-- ═══════════════════════════════════════════════════════════════════════════
-- 3. إضافة المنتجات (Items)
-- ═══════════════════════════════════════════════════════════════════════════

-- جلب معرفات التصنيفات
DO $$
DECLARE
  cat_plates uuid;
  cat_cups uuid;
  cat_sets uuid;
  cat_pots uuid;
  cat_gifts uuid;
  shop uuid := '550e8400-e29b-41d4-a716-446655440001';
BEGIN
  -- جلب معرفات التصنيفات
  SELECT id INTO cat_plates FROM categories WHERE shop_id = shop AND name = 'الصحون' LIMIT 1;
  SELECT id INTO cat_cups FROM categories WHERE shop_id = shop AND name = 'الأكواب' LIMIT 1;
  SELECT id INTO cat_sets FROM categories WHERE shop_id = shop AND name = 'الأطقم' LIMIT 1;
  SELECT id INTO cat_pots FROM categories WHERE shop_id = shop AND name = 'الدلال' LIMIT 1;
  SELECT id INTO cat_gifts FROM categories WHERE shop_id = shop AND name = 'الهدايا' LIMIT 1;

  -- إضافة المنتجات
  INSERT INTO items (shop_id, category_id, title, description, price, is_active, is_deleted) VALUES
    -- صحون
    (shop, cat_plates, 'صحن تقديم كريستال', 'صحن تقديم فاخر من الكريستال التركي', 25000, true, false),
    (shop, cat_plates, 'صحن فواكه ذهبي', 'صحن فواكه بحواف ذهبية أنيقة', 18000, true, false),
    (shop, cat_plates, 'طقم صحون 6 قطع', 'طقم صحون سيراميك إيطالي 6 قطع', 45000, true, false),
    (shop, cat_plates, 'صحن سلطة زجاجي', 'صحن سلطة زجاج شفاف كبير', 12000, true, false),
    
    -- أكواب
    (shop, cat_cups, 'طقم فناجين قهوة', 'طقم 6 فناجين قهوة عربية مع صحون', 35000, true, false),
    (shop, cat_cups, 'كوب شاي كريستال', 'كوب شاي من الكريستال البوهيمي', 8000, true, false),
    (shop, cat_cups, 'طقم استكانات', 'طقم 12 استكان شاي مع صحون', 28000, true, false),
    (shop, cat_cups, 'كوب قهوة تركية', 'كوب قهوة تركية مع زخارف عثمانية', 15000, true, false),
    
    -- أطقم
    (shop, cat_sets, 'طقم ضيافة فاخر', 'طقم ضيافة كامل 24 قطعة', 120000, true, false),
    (shop, cat_sets, 'طقم شاي وقهوة', 'طقم شاي وقهوة 18 قطعة ذهبي', 85000, true, false),
    (shop, cat_sets, 'طقم رمضان', 'طقم رمضاني خاص للضيافة', 95000, true, false),
    (shop, cat_sets, 'طقم عروس', 'طقم عروس فاخر 36 قطعة', 150000, true, false),
    
    -- دلال
    (shop, cat_pots, 'دلة قهوة نحاسية', 'دلة قهوة نحاس أصلي مع نقوش', 55000, true, false),
    (shop, cat_pots, 'طقم دلال 3 قطع', 'طقم 3 دلال قهوة بأحجام مختلفة', 75000, true, false),
    (shop, cat_pots, 'دلة رسلان', 'دلة قهوة رسلان ستيل', 40000, true, false),
    
    -- هدايا
    (shop, cat_gifts, 'صندوق هدية فاخر', 'صندوق هدية مع طقم فناجين', 65000, true, false),
    (shop, cat_gifts, 'هدية رمضان', 'صندوق هدية رمضاني مميز', 80000, true, false),
    (shop, cat_gifts, 'هدية زواج', 'طقم هدية للعروسين', 180000, true, false);

END $$;

-- ═══════════════════════════════════════════════════════════════════════════
-- 4. إضافة صور المنتجات
-- ═══════════════════════════════════════════════════════════════════════════

INSERT INTO item_images (item_id, image_path, sort_order, is_primary)
SELECT id, 'assets/img/main.png', 1, true FROM items 
WHERE shop_id = '550e8400-e29b-41d4-a716-446655440001'
ON CONFLICT DO NOTHING;

-- ═══════════════════════════════════════════════════════════════════════════
-- 5. إضافة البانرات (حذف القديم أولاً)
-- ═══════════════════════════════════════════════════════════════════════════

DELETE FROM banner_ads WHERE shop_id = '550e8400-e29b-41d4-a716-446655440001';

INSERT INTO banner_ads (shop_id, image_path, sort_order, is_active) VALUES
  ('550e8400-e29b-41d4-a716-446655440001', 'assets/img/main.png', 1, true),
  ('550e8400-e29b-41d4-a716-446655440001', 'assets/img/main.png', 2, true),
  ('550e8400-e29b-41d4-a716-446655440001', 'assets/img/main.png', 3, true);

-- ═══════════════════════════════════════════════════════════════════════════
-- 6. إضافة البارتات (حذف القديم أولاً)
-- ═══════════════════════════════════════════════════════════════════════════

DELETE FROM part_items WHERE part_id IN (SELECT id FROM parts WHERE shop_id = '550e8400-e29b-41d4-a716-446655440001');
DELETE FROM parts WHERE shop_id = '550e8400-e29b-41d4-a716-446655440001';

INSERT INTO parts (shop_id, name, sort_order, is_active) VALUES
  ('550e8400-e29b-41d4-a716-446655440001', 'عروض رمضان 🌙', 1, true),
  ('550e8400-e29b-41d4-a716-446655440001', 'تخفيضات 🔥', 2, true),
  ('550e8400-e29b-41d4-a716-446655440001', 'الأكثر مبيعاً ⭐', 3, true),
  ('550e8400-e29b-41d4-a716-446655440001', 'وصل حديثاً 🆕', 4, true);

-- ═══════════════════════════════════════════════════════════════════════════
-- 7. ربط المنتجات بالبارتات
-- ═══════════════════════════════════════════════════════════════════════════

-- جلب معرفات البارتات والمنتجات وربطها
DO $$
DECLARE
  part_ramadan bigint;
  part_discount bigint;
  part_bestseller bigint;
  part_new bigint;
  shop uuid := '550e8400-e29b-41d4-a716-446655440001';
  item_ids bigint[];
BEGIN
  -- جلب معرفات البارتات
  SELECT id INTO part_ramadan FROM parts WHERE shop_id = shop AND name LIKE '%رمضان%' LIMIT 1;
  SELECT id INTO part_discount FROM parts WHERE shop_id = shop AND name LIKE '%تخفيضات%' LIMIT 1;
  SELECT id INTO part_bestseller FROM parts WHERE shop_id = shop AND name LIKE '%مبيعاً%' LIMIT 1;
  SELECT id INTO part_new FROM parts WHERE shop_id = shop AND name LIKE '%حديثاً%' LIMIT 1;

  -- جلب معرفات المنتجات
  SELECT array_agg(id ORDER BY id) INTO item_ids FROM items WHERE shop_id = shop LIMIT 18;

  -- ربط المنتجات بـ عروض رمضان (أول 4 منتجات)
  IF part_ramadan IS NOT NULL AND array_length(item_ids, 1) >= 4 THEN
    INSERT INTO part_items (part_id, item_id) VALUES 
      (part_ramadan, item_ids[1]),
      (part_ramadan, item_ids[2]),
      (part_ramadan, item_ids[3]),
      (part_ramadan, item_ids[4])
    ON CONFLICT DO NOTHING;
  END IF;

  -- ربط المنتجات بـ تخفيضات (منتجات 5-8)
  IF part_discount IS NOT NULL AND array_length(item_ids, 1) >= 8 THEN
    INSERT INTO part_items (part_id, item_id) VALUES 
      (part_discount, item_ids[5]),
      (part_discount, item_ids[6]),
      (part_discount, item_ids[7]),
      (part_discount, item_ids[8])
    ON CONFLICT DO NOTHING;
  END IF;

  -- ربط المنتجات بـ الأكثر مبيعاً (منتجات 9-12)
  IF part_bestseller IS NOT NULL AND array_length(item_ids, 1) >= 12 THEN
    INSERT INTO part_items (part_id, item_id) VALUES 
      (part_bestseller, item_ids[9]),
      (part_bestseller, item_ids[10]),
      (part_bestseller, item_ids[11]),
      (part_bestseller, item_ids[12])
    ON CONFLICT DO NOTHING;
  END IF;

  -- ربط المنتجات بـ وصل حديثاً (منتجات 13-16)
  IF part_new IS NOT NULL AND array_length(item_ids, 1) >= 16 THEN
    INSERT INTO part_items (part_id, item_id) VALUES 
      (part_new, item_ids[13]),
      (part_new, item_ids[14]),
      (part_new, item_ids[15]),
      (part_new, item_ids[16])
    ON CONFLICT DO NOTHING;
  END IF;

END $$;

-- ═══════════════════════════════════════════════════════════════════════════
-- 8. التحقق من البيانات
-- ═══════════════════════════════════════════════════════════════════════════

-- عدد البانرات
SELECT 'البانرات' as table_name, COUNT(*) as count FROM banner_ads WHERE shop_id = '550e8400-e29b-41d4-a716-446655440001';

-- عدد البارتات
SELECT 'البارتات' as table_name, COUNT(*) as count FROM parts WHERE shop_id = '550e8400-e29b-41d4-a716-446655440001';

-- عدد المنتجات
SELECT 'المنتجات' as table_name, COUNT(*) as count FROM items WHERE shop_id = '550e8400-e29b-41d4-a716-446655440001';

-- البارتات مع عدد المنتجات
SELECT p.name, COUNT(pi.id) as items_count 
FROM parts p 
LEFT JOIN part_items pi ON p.id = pi.part_id 
WHERE p.shop_id = '550e8400-e29b-41d4-a716-446655440001'
GROUP BY p.id, p.name
ORDER BY p.sort_order;
