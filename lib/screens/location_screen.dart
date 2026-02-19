import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../utls/constants.dart';
import '../widget/bubble_button.dart';

// نموذج لحفظ الموقع
class SavedLocation {
  final String name;
  final String notes;
  final LatLng position;
  final DateTime savedAt;

  SavedLocation({
    required this.name,
    required this.notes,
    required this.position,
    required this.savedAt,
  });
}

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final TextEditingController _locationNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final MapController _mapController = MapController();
  LatLng _currentPosition = LatLng(33.3152, 44.3661); // بغداد
  LatLng? _selectedPosition;
  String _selectedLocationName = '';
  bool isLocationSelected = false;
  bool _isLoadingLocation = false;

  // قائمة المواقع المحفوظة
  final List<SavedLocation> _savedLocations = [];

  @override
  void initState() {
    super.initState();
    // لا نطلب الموقع تلقائياً لتجنب مشاكل Windows
  }

  @override
  void dispose() {
    _locationNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // للتطوير على Windows - استخدام موقع افتراضي (بغداد)
      if (Theme.of(context).platform == TargetPlatform.windows) {
        // محاكاة تأخير للحصول على الموقع
        await Future.delayed(const Duration(seconds: 1));

        setState(() {
          // يمكنك تغيير الموقع الافتراضي هنا
          _currentPosition = LatLng(33.3152, 44.3661); // بغداد
          _selectedPosition = _currentPosition;
          isLocationSelected = true;
          _isLoadingLocation = false;
        });

        _mapController.move(_currentPosition, 15);
        await _getAddressFromLatLng(_currentPosition);

        Get.snackbar(
          'تم تحديد الموقع',
          'تم استخدام موقع افتراضي (Windows)',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          icon: const Icon(Icons.info, color: Colors.white),
          duration: const Duration(seconds: 3),
        );
        return;
      }

      // للأجهزة الحقيقية (Android/iOS)
      // التحقق من تفعيل خدمة الموقع
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingLocation = false;
        });
        Get.snackbar(
          'خدمة الموقع معطلة',
          'يرجى تفعيل GPS من إعدادات الجهاز',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          icon: const Icon(Icons.location_off, color: Colors.white),
          duration: const Duration(seconds: 4),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoadingLocation = false;
          });
          Get.snackbar(
            'تم رفض الصلاحية',
            'يرجى السماح بالوصول إلى الموقع',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
            icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
            duration: const Duration(seconds: 4),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingLocation = false;
        });
        Get.snackbar(
          'الصلاحية محظورة',
          'يرجى تفعيل صلاحيات الموقع من إعدادات التطبيق',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          icon: const Icon(Icons.block, color: Colors.white),
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // الحصول على الموقع مع timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _selectedPosition = _currentPosition;
        isLocationSelected = true;
        _isLoadingLocation = false;
      });

      _mapController.move(_currentPosition, 15);
      await _getAddressFromLatLng(_currentPosition);

      Get.snackbar(
        'تم تحديد الموقع',
        'تم الحصول على موقعك الحالي بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.check_circle, color: Colors.white),
        duration: const Duration(seconds: 2),
      );
    } on TimeoutException {
      setState(() {
        _isLoadingLocation = false;
      });
      Get.snackbar(
        'انتهت المهلة',
        'استغرق الحصول على الموقع وقتاً طويلاً. تأكد من اتصال GPS',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.timer_off, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
    } on LocationServiceDisabledException {
      setState(() {
        _isLoadingLocation = false;
      });
      Get.snackbar(
        'خدمة الموقع معطلة',
        'يرجى تفعيل GPS من إعدادات الجهاز',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.location_off, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
    } on PermissionDeniedException {
      setState(() {
        _isLoadingLocation = false;
      });
      Get.snackbar(
        'تم رفض الصلاحية',
        'لا يمكن الوصول إلى موقعك بدون الصلاحية',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.block, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });

      // إذا كان الخطأ MissingPluginException على Windows
      if (e.toString().contains('MissingPluginException') ||
          e.toString().contains('No implementation found')) {
        // استخدام موقع افتراضي
        setState(() {
          _currentPosition = LatLng(33.3152, 44.3661); // بغداد
          _selectedPosition = _currentPosition;
          isLocationSelected = true;
        });
        _mapController.move(_currentPosition, 15);
        await _getAddressFromLatLng(_currentPosition);

        Get.snackbar(
          'تنبيه',
          'تم استخدام موقع افتراضي (المكتبة لا تدعم Windows)',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          icon: const Icon(Icons.info, color: Colors.white),
          duration: const Duration(seconds: 4),
        );
        return;
      }

      String errorMessage = 'حدث خطأ غير متوقع';
      if (e.toString().contains('PERMISSION')) {
        errorMessage = 'مشكلة في صلاحيات الموقع';
      } else if (e.toString().contains('network') ||
          e.toString().contains('internet')) {
        errorMessage = 'تحقق من اتصال الإنترنت';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'انتهت المهلة الزمنية';
      }

      Get.snackbar(
        'خطأ',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.error, color: Colors.white),
        duration: const Duration(seconds: 4),
      );

      // طباعة الخطأ للمطور
      debugPrint('خطأ في الحصول على الموقع: $e');
    }
  }

  Future<String> _getLocationName(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String locationName = '';

        if (place.street != null && place.street!.isNotEmpty) {
          locationName += place.street!;
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          if (locationName.isNotEmpty) locationName += '، ';
          locationName += place.subLocality!;
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          if (locationName.isNotEmpty) locationName += '، ';
          locationName += place.locality!;
        }

        return locationName.isNotEmpty ? locationName : 'موقع على الخريطة';
      }
      return 'موقع على الخريطة';
    } catch (e) {
      return 'موقع على الخريطة';
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          ).timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('انتهت مهلة الحصول على اسم الموقع');
              return [];
            },
          );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String locationName = '';

        // بناء اسم الموقع من المعلومات المتاحة
        if (place.street != null && place.street!.isNotEmpty) {
          locationName += place.street!;
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          if (locationName.isNotEmpty) locationName += '، ';
          locationName += place.subLocality!;
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          if (locationName.isNotEmpty) locationName += '، ';
          locationName += place.locality!;
        }
        if (place.country != null && place.country!.isNotEmpty) {
          if (locationName.isNotEmpty) locationName += '، ';
          locationName += place.country!;
        }

        setState(() {
          _selectedLocationName = locationName.isNotEmpty
              ? locationName
              : 'موقع على الخريطة';
          _locationNameController.text = _selectedLocationName;
        });
      } else {
        setState(() {
          _selectedLocationName =
              'موقع على الخريطة (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
          _locationNameController.text = _selectedLocationName;
        });
      }
    } on TimeoutException {
      setState(() {
        _selectedLocationName =
            'موقع على الخريطة (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
        _locationNameController.text = _selectedLocationName;
      });
      debugPrint('انتهت مهلة تحويل الإحداثيات إلى عنوان');
    } catch (e) {
      setState(() {
        _selectedLocationName =
            'موقع على الخريطة (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
        _locationNameController.text = _selectedLocationName;
      });
      debugPrint('خطأ في الحصول على اسم الموقع: $e');
    }
  }

  void _onMapTapped(TapPosition tapPosition, LatLng position) {
    setState(() {
      _selectedPosition = position;
      isLocationSelected = true;
    });
    _getAddressFromLatLng(position);
  }

  void _onMapLongPressed(TapPosition tapPosition, LatLng position) {
    // عرض Bottom Sheet للتأكيد
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // أيقونة الموقع
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on,
                color: AppColors.primaryColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            // العنوان
            Text(
              'تحديد الموقع',
              style: GoogleFonts.cairo(
                color: AppColors.primaryColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            // السؤال
            Text(
              'هل تريد اختيار هذا الموقع؟',
              style: GoogleFonts.cairo(
                color: Colors.grey[700],
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // اسم الموقع
            FutureBuilder<String>(
              future: _getLocationName(position),
              builder: (context, snapshot) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_city,
                        size: 20,
                        color: AppColors.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          snapshot.hasData
                              ? snapshot.data!
                              : 'جاري تحديد الموقع...',
                          style: GoogleFonts.cairo(
                            color: AppColors.primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            // الإحداثيات
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.place, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        'خط العرض: ${position.latitude.toStringAsFixed(6)}',
                        style: GoogleFonts.cairo(
                          color: Colors.grey[700],
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.place, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        'خط الطول: ${position.longitude.toStringAsFixed(6)}',
                        style: GoogleFonts.cairo(
                          color: Colors.grey[700],
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // الأزرار
            Row(
              children: [
                // زر الإلغاء
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Get.back();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                    ),
                    child: Text(
                      'إلغاء',
                      style: GoogleFonts.cairo(
                        color: Colors.grey[700],
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // زر التأكيد
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Get.back();
                      setState(() {
                        _selectedPosition = position;
                        isLocationSelected = true;
                      });
                      await _getAddressFromLatLng(position);
                      Get.snackbar(
                        'تم التحديد',
                        'تم تحديد الموقع بنجاح',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.primaryColor,
                        colorText: Colors.white,
                        margin: const EdgeInsets.all(16),
                        borderRadius: 12,
                        duration: const Duration(seconds: 2),
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'تأكيد',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isDismissible: true,
      enableDrag: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/img/main.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: AppColors.primaryColor.withOpacity(0.1)),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 5.0),
            child: Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        BubbleButton(
                          icon: Icons.arrow_back,
                          onTap: () {
                            Get.back();
                          },
                        ),
                        Text(
                          'الموقع',
                          style: GoogleFonts.cairo(
                            color: AppColors.primaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 50),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 90),
                    child: Column(
                      children: [
                        // عنوان القسم
                        Row(
                          children: [
                            Icon(
                              Icons.add_location_alt,
                              color: AppColors.primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'إضافة موقع جديد',
                              style: GoogleFonts.cairo(
                                color: AppColors.primaryColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // خريطة تفاعلية
                        Container(
                          height: 350,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // الخريطة
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: FlutterMap(
                                  mapController: _mapController,
                                  options: MapOptions(
                                    initialCenter: _currentPosition,
                                    initialZoom: 14,
                                    onTap: _onMapTapped,
                                    onLongPress: _onMapLongPressed,
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName: 'com.alkafage.app',
                                    ),
                                    if (_selectedPosition != null)
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: _selectedPosition!,
                                            width: 50,
                                            height: 50,
                                            child: Icon(
                                              Icons.location_on,
                                              size: 50,
                                              color: AppColors.primaryColor,
                                              shadows: const [
                                                Shadow(
                                                  blurRadius: 4,
                                                  color: Colors.black26,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              // زر الموقع الحالي
                              Positioned(
                                top: 12,
                                left: 12,
                                child: InkWell(
                                  onTap: _isLoadingLocation
                                      ? null
                                      : _getCurrentLocation,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryColor,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryColor
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_isLoadingLocation)
                                          const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        else
                                          const Icon(
                                            Icons.my_location,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _isLoadingLocation
                                              ? 'جاري التحميل...'
                                              : 'موقعي الحالي',
                                          style: GoogleFonts.cairo(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // تعليمات للمستخدم
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.touch_app,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'اضغط مطولاً على الخريطة لتحديد موقع بدقة',
                              style: GoogleFonts.cairo(
                                color: Colors.grey[600],
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // بطاقة التفاصيل
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تفاصيل الموقع',
                                style: GoogleFonts.cairo(
                                  color: AppColors.primaryColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 20),
                              // اسم الموقع
                              _buildLabel('اسم الموقع'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _locationNameController,
                                hint: 'مثال: المنزل، العمل، مطعمي المفضل',
                                icon: Icons.bookmark_border,
                              ),
                              const SizedBox(height: 16),
                              // الملاحظات
                              _buildLabel('ملاحظات (اختياري)'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _notesController,
                                hint: 'أي تفاصيل إضافية تساعد في الوصول',
                                icon: Icons.note_alt_outlined,
                                maxLines: 3,
                              ),
                              const SizedBox(height: 24),
                              // زر الحفظ
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: isLocationSelected
                                      ? () {
                                          if (_locationNameController
                                              .text
                                              .isEmpty) {
                                            Get.snackbar(
                                              'تنبيه',
                                              'الرجاء إدخال اسم الموقع',
                                              snackPosition:
                                                  SnackPosition.BOTTOM,
                                              backgroundColor: Colors.orange,
                                              colorText: Colors.white,
                                              margin: const EdgeInsets.all(16),
                                              borderRadius: 12,
                                              icon: const Icon(
                                                Icons.warning_amber_rounded,
                                                color: Colors.white,
                                              ),
                                            );
                                            return;
                                          }

                                          // حفظ الموقع في القائمة
                                          setState(() {
                                            _savedLocations.add(
                                              SavedLocation(
                                                name: _locationNameController
                                                    .text,
                                                notes: _notesController.text,
                                                position: _selectedPosition!,
                                                savedAt: DateTime.now(),
                                              ),
                                            );

                                            // إعادة تعيين النموذج
                                            _locationNameController.clear();
                                            _notesController.clear();
                                            _selectedPosition = null;
                                            isLocationSelected = false;
                                          });

                                          Get.snackbar(
                                            'تم الحفظ',
                                            'تم إضافة الموقع إلى قائمتك',
                                            snackPosition: SnackPosition.BOTTOM,
                                            backgroundColor: Colors.green,
                                            colorText: Colors.white,
                                            margin: const EdgeInsets.all(16),
                                            borderRadius: 12,
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                            icon: const Icon(
                                              Icons.check_circle,
                                              color: Colors.white,
                                            ),
                                          );
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryColor,
                                    disabledBackgroundColor: Colors.grey[300],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    isLocationSelected
                                        ? 'حفظ الموقع'
                                        : 'حدد موقعاً من الخريطة',
                                    style: GoogleFonts.cairo(
                                      color: isLocationSelected
                                          ? Colors.white
                                          : Colors.grey[600],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // قسم المواقع المحفوظة
                        if (_savedLocations.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: AppColors.primaryColor,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'مواقعي المحفوظة',
                                style: GoogleFonts.cairo(
                                  color: AppColors.primaryColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_savedLocations.length}',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // عرض المواقع المحفوظة
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _savedLocations.length,
                            itemBuilder: (context, index) {
                              final location = _savedLocations[index];
                              return _buildLocationCard(location, index);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(SavedLocation location, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // أيقونة الموقع
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // اسم الموقع
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      style: GoogleFonts.cairo(
                        color: AppColors.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${location.position.latitude.toStringAsFixed(4)}, ${location.position.longitude.toStringAsFixed(4)}',
                      style: GoogleFonts.cairo(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // زر الحذف
              IconButton(
                onPressed: () {
                  _showDeleteConfirmation(index);
                },
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.red[400],
                  size: 22,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          // الملاحظات إذا كانت موجودة
          if (location.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      location.notes,
                      style: GoogleFonts.cairo(
                        color: Colors.grey[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // التاريخ
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                'تم الحفظ: ${_formatDate(location.savedAt)}',
                style: GoogleFonts.cairo(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inHours < 1) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inDays < 1) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showDeleteConfirmation(int index) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline,
                color: Colors.red[400],
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'حذف الموقع',
              style: GoogleFonts.cairo(
                color: AppColors.primaryColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'هل أنت متأكد من حذف "${_savedLocations[index].name}"؟',
              style: GoogleFonts.cairo(
                color: Colors.grey[700],
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Get.back();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                    ),
                    child: Text(
                      'إلغاء',
                      style: GoogleFonts.cairo(
                        color: Colors.grey[700],
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _savedLocations.removeAt(index);
                      });
                      Get.back();
                      Get.snackbar(
                        'تم الحذف',
                        'تم حذف الموقع من قائمتك',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red[400],
                        colorText: Colors.white,
                        margin: const EdgeInsets.all(16),
                        borderRadius: 12,
                        duration: const Duration(seconds: 2),
                        icon: const Icon(Icons.delete, color: Colors.white),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.red[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'حذف',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isDismissible: true,
      enableDrag: true,
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.cairo(
        color: AppColors.primaryColor,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      textAlign: TextAlign.right,
      style: GoogleFonts.cairo(
        color: AppColors.primaryColor,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.cairo(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.primaryColor, size: 22),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
