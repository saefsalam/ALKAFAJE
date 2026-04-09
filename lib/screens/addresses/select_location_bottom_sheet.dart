import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utls/constants.dart';
import '../../models/customer_location_model.dart';
import '../../services/location_service.dart';
import '../../services/auth_service.dart';
import '../../widget/loading_animation.dart';
import '../location_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Bottom Sheet لاختيار/إضافة موقع التوصيل
// ═══════════════════════════════════════════════════════════════════════════

class SelectLocationBottomSheet extends StatefulWidget {
  final CustomerLocation? currentLocation;

  const SelectLocationBottomSheet({
    super.key,
    this.currentLocation,
  });

  @override
  State<SelectLocationBottomSheet> createState() =>
      _SelectLocationBottomSheetState();
}

class _SelectLocationBottomSheetState extends State<SelectLocationBottomSheet> {
  List<CustomerLocation> _locations = [];
  bool _isLoading = true;
  int? _customerId;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() => _isLoading = true);

    try {
      // الحصول على customer_id
      final customerInfo = await AuthService.getCustomerInfo();
      if (customerInfo == null) {
        if (mounted) {
          Navigator.pop(context);
          _showError('الرجاء تسجيل الدخول أولاً');
        }
        return;
      }

      _customerId = customerInfo['id'] as int;

      // جلب المواقع المحفوظة
      final locations = await LocationService.getCustomerLocations(
        customerId: _customerId!,
      );

      if (mounted) {
        setState(() {
          _locations = locations;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ خطأ في تحميل المواقع: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(),
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(),
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // حذف موقع
  Future<void> _deleteLocation(CustomerLocation location) async {
    // عرض تأكيد الحذف
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'حذف الموقع',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_forever,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'هل أنت متأكد من حذف موقع "${location.name}"؟',
              style: GoogleFonts.cairo(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            if (location.isDefault) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'هذا هو الموقع الرئيسي',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'حذف',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // تنفيذ الحذف
      final result = await LocationService.deleteLocation(
        locationId: location.id!,
        customerId: _customerId!,
      );

      if (result['success'] == true) {
        _showSuccess(result['message'] ?? 'تم حذف الموقع بنجاح');
        // إعادة تحميل المواقع
        _loadLocations();
      } else {
        _showError(result['message'] ?? 'فشل في حذف الموقع');
      }
    }
  }

  // إضافة موقع جديد
  Future<void> _addNewLocation() async {
    if (_customerId == null) return;

    // الانتقال لشاشة الخريطة لاختيار الموقع
    // LocationScreen يقوم بحفظ الموقع مباشرة في قاعدة البيانات
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationScreen(),
      ),
    );

    if (result != null && mounted) {
      // LocationScreen قامت بحفظ الموقع بالفعل في قاعدة البيانات
      // لذلك نقوم فقط بإنشاء CustomerLocation من البيانات المرجعة
      final newLocation = CustomerLocation(
        id: result['id'] as int,
        shopId: LocationService.DEFAULT_SHOP_ID,
        customerId: _customerId!,
        name: result['name'] as String,
        latitude: result['latitude'] as double,
        longitude: result['longitude'] as double,
        locationName: result['locationName'] as String?,
        fullAddress: result['fullAddress'] as String?,
        notes: result['notes'] as String?,
        isDefault: _locations.isEmpty, // إذا كان أول موقع
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // إرجاع الموقع الجديد
      Navigator.pop(context, newLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.05),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppColors.primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'اختر موقع التوصيل',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: CenteredLoading(),
              )
            else if (_locations.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.location_off,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد مواقع محفوظة بعد',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'أضف موقعك الأول للتوصيل',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: _locations.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final location = _locations[index];
                    final isSelected =
                        widget.currentLocation?.id == location.id;

                    return InkWell(
                      onTap: () => Navigator.pop(context, location),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryColor.withOpacity(0.05)
                              : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            // أيقونة
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: location.isDefault
                                    ? AppColors.primaryColor
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                location.isDefault
                                    ? Icons.home
                                    : Icons.location_on,
                                color: location.isDefault
                                    ? Colors.white
                                    : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 16),

                            // المعلومات
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          location.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.cairo(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (location.isDefault) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryColor,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'رئيسي',
                                            style: GoogleFonts.cairo(
                                              fontSize: 11,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    location.displayText,
                                    style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (location.notes != null &&
                                      location.notes!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      location.notes!,
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // علامة الاختيار وزر الحذف
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // زر الحذف
                                IconButton(
                                  onPressed: () => _deleteLocation(location),
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red[400],
                                    size: 22,
                                  ),
                                  tooltip: 'حذف الموقع',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 36,
                                    minHeight: 36,
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: AppColors.primaryColor,
                                    size: 28,
                                  )
                                else
                                  Icon(
                                    Icons.chevron_left,
                                    color: Colors.grey[400],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // زر إضافة موقع جديد
            SafeArea(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: ElevatedButton.icon(
                  onPressed: _addNewLocation,
                  icon: const Icon(Icons.add_location_alt),
                  label: Text(
                    'إضافة موقع جديد',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
