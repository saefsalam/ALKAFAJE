-- ═══════════════════════════════════════════════════════════════════════════
-- تحديث جدول location لدعم العناوين المرتبطة بالعملاء
-- ═══════════════════════════════════════════════════════════════════════════

-- إضافة الأعمدة الجديدة لجدول location
ALTER TABLE public.location
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS customer_id BIGINT REFERENCES public.customers(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS full_address TEXT,
  ADD COLUMN IF NOT EXISTS notes TEXT,
  ADD COLUMN IF NOT EXISTS is_default BOOLEAN DEFAULT FALSE;

-- إنشاء فهرس للبحث السريع عن مواقع العملاء
CREATE INDEX IF NOT EXISTS idx_location_customer_id ON public.location(customer_id);
CREATE INDEX IF NOT EXISTS idx_location_customer_default ON public.location(customer_id, is_default) WHERE is_default = TRUE;

-- إنشاء دالة لضمان أن كل عميل لديه موقع رئيسي واحد فقط
CREATE OR REPLACE FUNCTION enforce_single_default_location()
RETURNS TRIGGER AS $$
BEGIN
  -- إذا كان الموقع الجديد رئيسي
  IF NEW.is_default = TRUE AND NEW.customer_id IS NOT NULL THEN
    -- إلغاء جميع المواقع الرئيسية الأخرى لنفس العميل
    UPDATE public.location
    SET is_default = FALSE
    WHERE customer_id = NEW.customer_id
      AND id != NEW.id
      AND is_default = TRUE;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- إنشاء Trigger لتطبيق الدالة عند الإدراج أو التحديث
DROP TRIGGER IF EXISTS trigger_enforce_single_default_location ON public.location;
CREATE TRIGGER trigger_enforce_single_default_location
  BEFORE INSERT OR UPDATE ON public.location
  FOR EACH ROW
  EXECUTE FUNCTION enforce_single_default_location();

-- تحديث updated_at تلقائياً
CREATE OR REPLACE FUNCTION update_location_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_location_timestamp ON public.location;
CREATE TRIGGER trigger_update_location_timestamp
  BEFORE UPDATE ON public.location
  FOR EACH ROW
  EXECUTE FUNCTION update_location_updated_at();

-- ─────────────────────────────────────────────────────────────────────────────
-- ملاحظات:
-- ─────────────────────────────────────────────────────────────────────────────
-- ✅ تم إضافة customer_id لربط المواقع بالعملاء
-- ✅ تم إضافة is_default لتحديد الموقع الرئيسي
-- ✅ تم إضافة full_address و notes للمعلومات الإضافية
-- ✅ تم إنشاء trigger لضمان موقع رئيسي واحد فقط لكل عميل
-- ✅ تم إنشاء فهارس للأداء الأفضل
--
-- ⚠️ مهم - أسماء الأعمدة في قاعدة البيانات:
-- - L_X (خط الطول - Longitude) - كل الحروف كبيرة
-- - L_y (خط العرض - Latitude) - L كبير، y صغير
--
-- الاستخدام:
-- - كل عميل يمكنه إضافة عدة مواقع
-- - موقع واحد فقط يمكن أن يكون رئيسي (is_default = TRUE)
-- - عند إنشاء الطلب، يتم إرسال location_id في assigned_location_id
