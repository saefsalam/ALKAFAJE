import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/local_cart_service.dart';
import '../utls/constants.dart';

// ═══════════════════════════════════════════════════════════════════════════
// شاشة التحقق من رمز OTP
// ═══════════════════════════════════════════════════════════════════════════

class OtpScreen extends StatefulWidget {
  final String phone;
  final String fullName;
  final int customerId;
  final String authUserId;

  const OtpScreen({
    super.key,
    required this.phone,
    required this.fullName,
    required this.customerId,
    required this.authUserId,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with TickerProviderStateMixin {
  // Controllers لكل خانة من خانات OTP (5 خانات)
  final List<TextEditingController> _otpControllers =
      List.generate(5, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(5, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;

  // مؤقت إعادة الإرسال
  int _resendSeconds = 60;
  Timer? _resendTimer;

  // عدد المحاولات
  int _attempts = 0;
  static const int _maxAttempts = 5;

  // Animation controller
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _focusNodes[0].requestFocus();

    // Animation للهز عند خطأ
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(
          CurveTween(curve: Curves.elasticIn),
        )
        .animate(_shakeController);
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _shakeController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  // التحقق من الرمز
  Future<void> _verifyOtp() async {
    final code = _otpCode;

    if (code.length != 5) {
      _showError('الرجاء إدخال الرمز كاملاً (5 أرقام)');
      return;
    }

    if (_attempts >= _maxAttempts) {
      _showError('لقد تجاوزت عدد المحاولات المسموحة. حاول لاحقاً');
      return;
    }

    setState(() {
      _isLoading = true;
      _attempts++;
    });

    try {
      final result = await AuthService.verifyOtp(
        phone: widget.phone,
        otp: code,
        customerId: widget.customerId,
      );

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        // نقل السلة المحلية إلى قاعدة البيانات
        await LocalCartService.syncCartToDatabase(widget.authUserId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم التحقق بنجاح! مرحباً ${widget.fullName} 🎉',
                style: GoogleFonts.cairo(),
                textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // الرجوع لشاشة التسجيل مع إرسال true كنتيجة
          // auth_screen سيتلقى النتيجة ويعمل pop بنفسه
          Navigator.of(context).pop(true);
        }
      } else {
        // رمز خاطئ - هز الحقول
        _shakeController.forward(from: 0);
        _clearOtpFields();

        final errorMsg = result['message'] ?? 'الرمز غير صحيح';
        _showError(errorMsg);

        if (_attempts >= _maxAttempts) {
          _showError(
              'لقد تجاوزت عدد المحاولات المسموحة (${_maxAttempts} محاولات)');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('خطأ غير متوقع. حاول مرة أخرى');
    }
  }

  // إعادة إرسال الرمز
  Future<void> _resendOtp() async {
    if (_resendSeconds > 0) return;

    setState(() => _isResending = true);

    try {
      final result = await AuthService.resendOtp(
        phone: widget.phone,
        customerId: widget.customerId,
      );

      setState(() => _isResending = false);

      if (result['success'] == true) {
        _startResendTimer();
        _clearOtpFields();
        _attempts = 0; // إعادة تعيين المحاولات عند إعادة الإرسال

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم إرسال رمز جديد إلى ${widget.phone} ✅',
                style: GoogleFonts.cairo(),
                textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _showError(result['message'] ?? 'فشل في إعادة إرسال الرمز');
      }
    } catch (e) {
      setState(() => _isResending = false);
      _showError('فشل في إعادة إرسال الرمز');
    }
  }

  void _clearOtpFields() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.cairo(),
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryColor),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          'التحقق من الرقم',
          style: GoogleFonts.cairo(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // أيقونة التحقق
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_user_rounded,
                  size: 50,
                  color: AppColors.primaryColor,
                ),
              ),

              const SizedBox(height: 32),

              // عنوان
              Text(
                'أدخل رمز التحقق',
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),

              const SizedBox(height: 12),

              // وصف
              Text(
                'تم إرسال رمز التحقق إلى رقم الهاتف',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // رقم الهاتف
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.phone,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                    letterSpacing: 1.5,
                  ),
                  textDirection: TextDirection.ltr,
                ),
              ),

              const SizedBox(height: 40),

              // حقول OTP
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: child,
                  );
                },
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 55,
                        height: 65,
                        child: TextFormField(
                          controller: _otpControllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: GoogleFonts.cairo(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: _otpControllers[index].text.isNotEmpty
                                ? AppColors.primaryColor.withOpacity(0.05)
                                : Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: _otpControllers[index].text.isNotEmpty
                                    ? AppColors.primaryColor
                                    : Colors.grey[300]!,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: _otpControllers[index].text.isNotEmpty
                                    ? AppColors.primaryColor
                                    : Colors.grey[300]!,
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: AppColors.primaryColor,
                                width: 2.5,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {}); // لتحديث لون الحقول
                            if (value.isNotEmpty && index < 4) {
                              _focusNodes[index + 1].requestFocus();
                            }
                            // التحقق التلقائي عند إكمال 5 أرقام
                            if (index == 4 && value.isNotEmpty) {
                              final code = _otpCode;
                              if (code.length == 5) {
                                _verifyOtp();
                              }
                            }
                          },
                          onTap: () {
                            _otpControllers[index].selection =
                                TextSelection.fromPosition(
                              TextPosition(
                                  offset: _otpControllers[index].text.length),
                            );
                          },
                        ),
                      );
                    }),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // عدد المحاولات المتبقية
              if (_attempts > 0)
                Text(
                  'المحاولات المتبقية: ${_maxAttempts - _attempts}',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: _attempts >= _maxAttempts - 1
                        ? Colors.red
                        : Colors.grey[500],
                  ),
                ),

              const SizedBox(height: 32),

              // زر التحقق
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading || _attempts >= _maxAttempts
                      ? null
                      : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'تأكيد الرمز',
                          style: GoogleFonts.cairo(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // إعادة الإرسال
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'لم تستلم الرمز؟',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 4),
                  _isResending
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton(
                          onPressed: _resendSeconds > 0 ? null : _resendOtp,
                          child: Text(
                            _resendSeconds > 0
                                ? 'إعادة الإرسال (${_resendSeconds}ث)'
                                : 'إعادة الإرسال',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _resendSeconds > 0
                                  ? Colors.grey[400]
                                  : AppColors.primaryColor,
                            ),
                          ),
                        ),
                ],
              ),

              const SizedBox(height: 20),

              // معلومة
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.amber[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'سيتم إرسال رمز التحقق عبر WhatsApp أو SMS',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.amber[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
