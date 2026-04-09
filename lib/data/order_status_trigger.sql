-- ═══════════════════════════════════════════════════════════════════════════
-- Trigger لإضافة سجل تلقائي في order_status_history عند إنشاء طلب جديد
-- ═══════════════════════════════════════════════════════════════════════════
-- 
-- هذا الـ Trigger يضمن أن كل طلب جديد يتم إضافة سجل له في جدول order_status_history
-- بحالته الأولية (pending)، مما يجعل الطلب ظاهراً فوراً في الداشبورد.
--
-- ═══════════════════════════════════════════════════════════════════════════

-- 1. إنشاء دالة لإضافة سجل الحالة
CREATE OR REPLACE FUNCTION public.add_initial_order_status()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- إضافة سجل الحالة الأولية للطلب
  INSERT INTO public.order_status_history (
    order_id,
    status,
    notes,
    created_at
  ) VALUES (
    NEW.id,
    NEW.status,
    'تم إنشاء الطلب',
    NEW.created_at
  );

  RETURN NEW;
END;
$$;

-- 2. إنشاء Trigger يستدعي الدالة عند INSERT
DROP TRIGGER IF EXISTS trigger_add_initial_order_status ON public.orders;

CREATE TRIGGER trigger_add_initial_order_status
  AFTER INSERT ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.add_initial_order_status();

-- 3. تعليق توضيحي
COMMENT ON FUNCTION public.add_initial_order_status() IS 
'دالة تُستدعى تلقائياً عند إنشاء طلب جديد لإضافة سجل الحالة الأولية في order_status_history';

COMMENT ON TRIGGER trigger_add_initial_order_status ON public.orders IS 
'Trigger يضيف سجلاً تلقائياً في order_status_history عند إنشاء طلب جديد';

-- ═══════════════════════════════════════════════════════════════════════════
-- اختبار الـ Trigger (اختياري - للتأكد من عمله)
-- ═══════════════════════════════════════════════════════════════════════════

-- يمكنك إنشاء طلب تجريبي والتحقق من إضافة السجل تلقائياً:
-- 
-- INSERT INTO public.orders (shop_id, customer_id, status, subtotal, total)
-- VALUES (
--   '550e8400-e29b-41d4-a716-446655440001',
--   1,
--   'pending',
--   100.00,
--   100.00
-- )
-- RETURNING id;
--
-- ثم تحقق من جدول order_status_history:
-- SELECT * FROM public.order_status_history WHERE order_id = (الرقم المرجع);

-- ═══════════════════════════════════════════════════════════════════════════
-- ملاحظات مهمة
-- ═══════════════════════════════════════════════════════════════════════════
--
-- 1. هذا الـ Trigger يضمن أن جميع الطلبات الجديدة ستظهر في الداشبورد فوراً
-- 2. إذا تم تغيير حالة الطلب لاحقاً، يجب إضافة سجل جديد يدوياً في order_status_history
-- 3. الكود في التطبيق (order_service.dart) يضيف السجل يدوياً أيضاً كخطة احتياطية
--
-- ═══════════════════════════════════════════════════════════════════════════
