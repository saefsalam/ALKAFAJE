import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../utls/constants.dart';
import 'otp_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// شاشة تسجيل الدخول والتسجيل (عبر رقم الهاتف فقط)
// ═══════════════════════════════════════════════════════════════════════════

class AuthScreen extends StatefulWidget {
  final bool isFromCart; // هل تم الدخول من السلة؟

  const AuthScreen({super.key, this.isFromCart = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true; // تبديل بين تسجيل الدخول والتسجيل
  bool _isLoading = false;

  // Controllers
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Form Key
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // تسجيل الدخول عبر رقم الهاتف
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.signInWithPhone(
        phone: _phoneController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        // الانتقال لشاشة OTP
        if (mounted) {
          final otpResult = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => OtpScreen(
                phone: _phoneController.text.trim(),
                fullName: result['customerName'] ?? '',
                customerId: result['customerId'] as int,
                authUserId: result['authUserId'] as String,
              ),
            ),
          );

          // إذا نجح التحقق، نرجع للشاشة السابقة
          if (otpResult == true && mounted) {
            Navigator.pop(context, true);
          }
        }
      } else {
        _showError(result['message'] ?? 'خطأ في تسجيل الدخول');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('خطأ غير متوقع. حاول مرة أخرى');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // إنشاء حساب جديد عبر رقم الهاتف
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.signUpWithPhone(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        // الانتقال لشاشة OTP
        if (mounted) {
          final otpResult = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => OtpScreen(
                phone: _phoneController.text.trim(),
                fullName: _fullNameController.text.trim(),
                customerId: result['customerId'] as int,
                authUserId: result['authUserId'] as String,
              ),
            ),
          );

          // إذا نجح التحقق، نرجع للشاشة السابقة
          if (otpResult == true && mounted) {
            Navigator.pop(context, true);
          }
        }
      } else {
        _showError(result['message'] ?? 'خطأ في إنشاء الحساب');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('خطأ غير متوقع. حاول مرة أخرى');
    }
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
          duration: const Duration(seconds: 4),
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // الشعار أو الصورة
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isLogin ? Icons.login_rounded : Icons.person_add_rounded,
                      size: 60,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // العنوان
                Text(
                  _isLogin ? 'تسجيل الدخول' : 'إنشاء حساب جديد',
                  style: GoogleFonts.cairo(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // الوصف
                Text(
                  _isLogin
                      ? 'أدخل رقم هاتفك لتسجيل الدخول'
                      : 'أدخل اسمك ورقم هاتفك لإنشاء حساب جديد',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // حقل الاسم (للتسجيل فقط)
                if (!_isLogin) ...[
                  _buildTextField(
                    controller: _fullNameController,
                    label: 'الاسم الكامل',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'الرجاء إدخال الاسم';
                      }
                      if (value.trim().length < 2) {
                        return 'الاسم يجب أن يكون حرفين على الأقل';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // حقل رقم الهاتف (دائماً)
                _buildTextField(
                  controller: _phoneController,
                  label: 'رقم الهاتف',
                  icon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال رقم الهاتف';
                    }
                    // إزالة المسافات و + للتحقق من الطول
                    final cleanPhone =
                        value.trim().replaceAll('+', '').replaceAll(' ', '');
                    if (cleanPhone.length < 10 || cleanPhone.length > 15) {
                      return 'رقم الهاتف يجب أن يكون بين 10 و 15 رقماً';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // زر تسجيل الدخول/التسجيل
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : (_isLogin ? _handleSignIn : _handleSignUp),
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
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isLogin
                                    ? Icons.sms_rounded
                                    : Icons.person_add_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isLogin
                                    ? 'إرسال رمز التحقق'
                                    : 'إنشاء حساب وإرسال الرمز',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // التبديل بين تسجيل الدخول والتسجيل
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin ? 'ليس لديك حساب؟' : 'لديك حساب بالفعل؟',
                      style: GoogleFonts.cairo(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                          _formKey.currentState?.reset();
                          _fullNameController.clear();
                          _phoneController.clear();
                        });
                      },
                      child: Text(
                        _isLogin ? 'إنشاء حساب' : 'تسجيل الدخول',
                        style: GoogleFonts.cairo(
                          color: AppColors.primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                // رسالة للقادمين من السلة
                if (widget.isFromCart) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shopping_cart_checkout,
                          color: AppColors.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'سجل دخولك لإتمام عملية الشراء. سلتك محفوظة!',
                            style: GoogleFonts.cairo(
                              color: AppColors.primaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // معلومة عن طريقة التحقق
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.security_rounded,
                        color: Colors.grey[500],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'سيتم إرسال رمز تحقق إلى رقم هاتفك عبر WhatsApp أو SMS',
                          style: GoogleFonts.cairo(
                            color: Colors.grey[600],
                            fontSize: 11,
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
      ),
    );
  }

  // بناء حقل الإدخال
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: GoogleFonts.cairo(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: AppColors.primaryColor),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}
