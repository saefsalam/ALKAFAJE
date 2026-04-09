-- ═══════════════════════════════════════════════════════════════════════════
-- إضافة عمود selection_key لجدول cart_items
-- ═══════════════════════════════════════════════════════════════════════════
-- 
-- هذا العمود ضروري لتمييز المنتجات المختلفة بناءً على اللون والحجم المختار
--
-- ═══════════════════════════════════════════════════════════════════════════

-- 1. إضافة عمود selection_key
ALTER TABLE public.cart_items 
ADD COLUMN IF NOT EXISTS selection_key text NOT NULL DEFAULT 'c:0|s:0';

-- 2. إضافة الأعمدة الخاصة بالألوان والأحجام إذا لم تكن موجودة
ALTER TABLE public.cart_items 
ADD COLUMN IF NOT EXISTS selected_color_id bigint,
ADD COLUMN IF NOT EXISTS selected_color_name text,
ADD COLUMN IF NOT EXISTS selected_color_hex text,
ADD COLUMN IF NOT EXISTS selected_size_id bigint,
ADD COLUMN IF NOT EXISTS selected_size_name text;

-- 3. إضافة قيد للتحقق من صيغة الـ hex للون
ALTER TABLE public.cart_items 
DROP CONSTRAINT IF EXISTS cart_items_selected_color_hex_check;

ALTER TABLE public.cart_items 
ADD CONSTRAINT cart_items_selected_color_hex_check 
CHECK (selected_color_hex IS NULL OR selected_color_hex ~ '^#[0-9A-Fa-f]{6}$');

-- 4. إضافة Foreign Keys إذا لم تكن موجودة
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'cart_items_selected_color_id_fkey'
  ) THEN
    ALTER TABLE public.cart_items 
    ADD CONSTRAINT cart_items_selected_color_id_fkey 
    FOREIGN KEY (selected_color_id) REFERENCES public.item_colors(id);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'cart_items_selected_size_id_fkey'
  ) THEN
    ALTER TABLE public.cart_items 
    ADD CONSTRAINT cart_items_selected_size_id_fkey 
    FOREIGN KEY (selected_size_id) REFERENCES public.item_sizes(id);
  END IF;
END $$;

-- 5. تحديث selection_key للسجلات الموجودة
UPDATE public.cart_items
SET selection_key = 
  'c:' || COALESCE(selected_color_id::text, '0') || 
  '|s:' || COALESCE(selected_size_id::text, '0')
WHERE selection_key = 'c:0|s:0' 
  AND (selected_color_id IS NOT NULL OR selected_size_id IS NOT NULL);

-- ═══════════════════════════════════════════════════════════════════════════
-- التحقق من نجاح العملية
-- ═══════════════════════════════════════════════════════════════════════════

-- عرض أعمدة جدول cart_items
-- SELECT column_name, data_type, column_default 
-- FROM information_schema.columns 
-- WHERE table_name = 'cart_items' 
-- ORDER BY ordinal_position;

-- ═══════════════════════════════════════════════════════════════════════════
-- ملاحظة: نفّذ هذا الكود في SQL Editor في Supabase
-- ═══════════════════════════════════════════════════════════════════════════
