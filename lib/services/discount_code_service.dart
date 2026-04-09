import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/discount_code_model.dart';
import 'auth_service.dart';

class DiscountCodeService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String _shopId = AuthService.DEFAULT_SHOP_ID;
  static const String schemaMigrationMessage =
      'قاعدة البيانات تحتاج تحديث دعم البرومو كود قبل تفعيل هذه الميزة.';

  static bool _isMissingSchemaError(Object error) {
    if (error is! PostgrestException) {
      return false;
    }

    final String details =
        '${error.code ?? ''} ${error.message} ${error.details ?? ''} ${error.hint ?? ''}'
            .toLowerCase();

    return details.contains('discount_codes') ||
        details.contains('discount_code_id') ||
        details.contains('discount_amount') ||
        details.contains('discount_code_snapshot') ||
        details.contains('42p01') ||
        details.contains('42703');
  }

  static String normalizeCode(String rawCode) {
    return rawCode.trim().toUpperCase();
  }

  static Future<DiscountCodeModel?> _fetchCodeByNormalizedValue(
    String normalizedCode,
  ) async {
    final Map<String, dynamic>? data = await _supabase
        .from('discount_codes')
        .select('*')
        .eq('shop_id', _shopId)
        .eq('code', normalizedCode)
        .maybeSingle();

    if (data == null) {
      return null;
    }

    return DiscountCodeModel.fromJson(data);
  }

  static DiscountCodeCalculation _buildCalculation({
    required DiscountCodeModel? discountCode,
    required bool isApplicable,
    required String? message,
    required double subtotal,
    required double discountAmount,
  }) {
    final double finalTotal =
        discountAmount >= subtotal ? 0 : subtotal - discountAmount;

    return DiscountCodeCalculation(
      discountCode: discountCode,
      isApplicable: isApplicable,
      message: message,
      subtotal: subtotal,
      discountAmount: discountAmount,
      finalTotal: finalTotal,
    );
  }

  static double _computeDiscountAmount({
    required DiscountCodeModel discountCode,
    required double subtotal,
  }) {
    double calculatedDiscount = 0;

    if (discountCode.isPercent) {
      calculatedDiscount =
          subtotal * ((discountCode.discountPercent ?? 0) / 100);
    } else {
      calculatedDiscount = discountCode.discountAmount ?? 0;
    }

    if (discountCode.maxDiscountAmount != null &&
        calculatedDiscount > discountCode.maxDiscountAmount!) {
      calculatedDiscount = discountCode.maxDiscountAmount!;
    }

    if (calculatedDiscount > subtotal) {
      calculatedDiscount = subtotal;
    }

    if (calculatedDiscount < 0) {
      calculatedDiscount = 0;
    }

    return calculatedDiscount;
  }

  static DiscountCodeCalculation calculateFromModel({
    required DiscountCodeModel discountCode,
    required double subtotal,
  }) {
    if (!discountCode.isActive) {
      return _buildCalculation(
        discountCode: discountCode,
        isApplicable: false,
        message: 'هذا البرومو كود غير مفعل حاليًا',
        subtotal: subtotal,
        discountAmount: 0,
      );
    }

    if (discountCode.expiryAtEndOfDay.isBefore(DateTime.now())) {
      return _buildCalculation(
        discountCode: discountCode,
        isApplicable: false,
        message: 'انتهت صلاحية البرومو كود',
        subtotal: subtotal,
        discountAmount: 0,
      );
    }

    if (discountCode.isExhausted) {
      return _buildCalculation(
        discountCode: discountCode,
        isApplicable: false,
        message: 'تم استهلاك هذا البرومو كود بالكامل',
        subtotal: subtotal,
        discountAmount: 0,
      );
    }

    if (subtotal < discountCode.minPurchaseAmount) {
      return _buildCalculation(
        discountCode: discountCode,
        isApplicable: false,
        message:
            'الحد الأدنى لتفعيل الكود هو ${discountCode.minPurchaseAmount.toStringAsFixed(0)} د.ع',
        subtotal: subtotal,
        discountAmount: 0,
      );
    }

    final double discountAmount = _computeDiscountAmount(
      discountCode: discountCode,
      subtotal: subtotal,
    );

    if (discountAmount <= 0) {
      return _buildCalculation(
        discountCode: discountCode,
        isApplicable: false,
        message: 'هذا البرومو كود لا يضيف خصمًا صالحًا على هذه السلة',
        subtotal: subtotal,
        discountAmount: 0,
      );
    }

    return _buildCalculation(
      discountCode: discountCode,
      isApplicable: true,
      message: 'تم تطبيق البرومو كود بنجاح',
      subtotal: subtotal,
      discountAmount: discountAmount,
    );
  }

  static Future<DiscountCodeCalculation> validateCode({
    required String rawCode,
    required double subtotal,
  }) async {
    final String normalizedCode = normalizeCode(rawCode);
    if (normalizedCode.isEmpty) {
      return _buildCalculation(
        discountCode: null,
        isApplicable: false,
        message: 'أدخل البرومو كود أولًا',
        subtotal: subtotal,
        discountAmount: 0,
      );
    }

    try {
      final DiscountCodeModel? discountCode =
          await _fetchCodeByNormalizedValue(normalizedCode);

      if (discountCode == null) {
        return _buildCalculation(
          discountCode: null,
          isApplicable: false,
          message: 'رمز الخصم غير موجود',
          subtotal: subtotal,
          discountAmount: 0,
        );
      }

      return calculateFromModel(discountCode: discountCode, subtotal: subtotal);
    } catch (error) {
      if (_isMissingSchemaError(error)) {
        return _buildCalculation(
          discountCode: null,
          isApplicable: false,
          message: schemaMigrationMessage,
          subtotal: subtotal,
          discountAmount: 0,
        );
      }

      return _buildCalculation(
        discountCode: null,
        isApplicable: false,
        message: 'تعذر التحقق من البرومو كود الآن. حاول مرة أخرى',
        subtotal: subtotal,
        discountAmount: 0,
      );
    }
  }
}
