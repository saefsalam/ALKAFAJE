import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../utls/constants.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';
import '../widget/bubble_button.dart';

// ═══════════════════════════════════════════════════════════════════════════
// شاشة إضافة موقع جديد - تصميم محسّن
// ═══════════════════════════════════════════════════════════════════════════

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  // ─── Controllers ────────────────────────────────────────────────────────
  final MapController _mapController = MapController();
  final _formKey = GlobalKey<FormState>();

  // Required fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _fullAddressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Optional fields
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _buildingController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _apartmentController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();

  // ─── State ──────────────────────────────────────────────────────────────
  LatLng _currentPosition = const LatLng(33.3152, 44.3661); // بغداد
  LatLng? _selectedPosition;
  bool _isLocationConfirmed = false;
  bool _isLoadingLocation = false;
  bool _isSaving = false;
  String _locationName = '';

  @override
  void dispose() {
    _nameController.dispose();
    _fullAddressController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _buildingController.dispose();
    _floorController.dispose();
    _apartmentController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // الحصول على الموقع الحالي
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // للتطوير على Windows - استخدام موقع افتراضي (بغداد)
      if (Theme.of(context).platform == TargetPlatform.windows) {
        await Future.delayed(const Duration(seconds: 1));

        setState(() {
          _currentPosition = const LatLng(33.3152, 44.3661);
          _selectedPosition = _currentPosition;
          _isLoadingLocation = false;
        });

        _mapController.move(_currentPosition, 15);
        await _getAddressFromLatLng(_currentPosition);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم استخدام موقع افتراضي (Windows)',
                style: GoogleFonts.cairo(),
                textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // للأجهزة الحقيقية (Android/iOS)
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        _showMessage('يرجى تفعيل GPS من إعدادات الجهاز', isError: true);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          _showMessage('يرجى السماح بالوصول إلى الموقع', isError: true);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        _showMessage('يرجى تفعيل صلاحيات الموقع من الإعدادات', isError: true);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _selectedPosition = _currentPosition;
        _isLoadingLocation = false;
      });

      _mapController.move(_currentPosition, 15);
      await _getAddressFromLatLng(_currentPosition);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تحديد موقعك الحالي بنجاح',
              style: GoogleFonts.cairo(),
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoadingLocation = false);

      // استخدام موقع افتراضي في حالة الخطأ
      setState(() {
        _currentPosition = const LatLng(33.3152, 44.3661);
        _selectedPosition = _currentPosition;
      });
      _mapController.move(_currentPosition, 15);
      await _getAddressFromLatLng(_currentPosition);

      debugPrint('خطأ في الحصول على الموقع: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // الحصول على اسم الموقع من الإحداثيات
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 5));

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '';

        if (place.street != null && place.street!.isNotEmpty) {
          address += place.street!;
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          if (address.isNotEmpty) address += '، ';
          address += place.subLocality!;
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          if (address.isNotEmpty) address += '، ';
          address += place.locality!;
        }

        setState(() {
          _locationName = address.isNotEmpty ? address : 'موقع على الخريطة';
          // ملء الحقل تلقائياً
          if (_fullAddressController.text.isEmpty) {
            _fullAddressController.text = _locationName;
          }
        });
      }
    } catch (e) {
      setState(() {
        _locationName =
            'موقع (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
      });
      debugPrint('خطأ في الحصول على اسم الموقع: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // عند الضغط على الخريطة
  // ═══════════════════════════════════════════════════════════════════════════
  void _onMapTapped(TapPosition tapPosition, LatLng position) {
    setState(() {
      _selectedPosition = position;
    });
    _getAddressFromLatLng(position);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // تأكيد الموقع
  // ═══════════════════════════════════════════════════════════════════════════
  void _confirmLocation() {
    if (_selectedPosition == null) {
      _showMessage('الرجاء اختيار موقع من الخريطة', isError: true);
      return;
    }

    setState(() {
      _isLocationConfirmed = true;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // حفظ الموقع
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _saveLocation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPosition == null) {
      _showMessage('لم يتم تحديد الموقع', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final customerInfo = await AuthService.getCustomerInfo();
      if (customerInfo == null) {
        setState(() => _isSaving = false);
        _showMessage('الرجاء تسجيل الدخول أولاً', isError: true);
        return;
      }

      final customerId = customerInfo['id'] as int;

      // بناء الملاحظات من الحقول الاختيارية
      final notesBuilder = <String>[];
      if (_streetController.text.isNotEmpty) {
        notesBuilder.add('الشارع: ${_streetController.text}');
      }
      if (_buildingController.text.isNotEmpty) {
        notesBuilder.add('البناية: ${_buildingController.text}');
      }
      if (_floorController.text.isNotEmpty) {
        notesBuilder.add('الطابق: ${_floorController.text}');
      }
      if (_apartmentController.text.isNotEmpty) {
        notesBuilder.add('الشقة: ${_apartmentController.text}');
      }
      if (_landmarkController.text.isNotEmpty) {
        notesBuilder.add('أقرب نقطة دالة: ${_landmarkController.text}');
      }

      final notes = notesBuilder.isNotEmpty ? notesBuilder.join(' | ') : null;

      // إضافة الموقع
      final result = await LocationService.addLocation(
        customerId: customerId,
        name: _nameController.text.trim(),
        latitude: _selectedPosition!.latitude,
        longitude: _selectedPosition!.longitude,
        locationName: _locationName,
        fullAddress: _fullAddressController.text.trim(),
        notes: notes,
      );

      setState(() => _isSaving = false);

      if (result != null) {
        if (mounted) {
          // إرجاع البيانات للشاشة السابقة
          Navigator.pop(context, {
            'id': result.id,
            'name': result.name,
            'fullAddress': result.fullAddress ?? result.locationName ?? '',
            'latitude': result.latitude,
            'longitude': result.longitude,
            'locationName': result.locationName,
            'notes': result.notes,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم حفظ الموقع بنجاح ✓',
                style: GoogleFonts.cairo(),
                textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _showMessage('فشل في حفظ الموقع', isError: true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showMessage('حدث خطأ غير متوقع', isError: true);
      debugPrint('خطأ في حفظ الموقع: $e');
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.cairo(),
            textAlign: TextAlign.center,
          ),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // البناء
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // الخلفية
          Positioned.fill(
            child: Image.asset('assets/img/main.png', fit: BoxFit.cover),
          ),
          // المحتوى
          _isLocationConfirmed ? _buildDetailsForm() : _buildMapView(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // عرض الخريطة (المرحلة الأولى)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMapView() {
    return Stack(
      children: [
        // صورة الخلفية
        Positioned.fill(
          child: Image.asset(
            'assets/img/main.png',
            fit: BoxFit.cover,
          ),
        ),
        // المحتوى
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
                left: 15.0, right: 15.0, top: 5.0, bottom: 90.0),
            child: Column(
              children: [
                // الهيدر
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      BubbleButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.pop(context),
                      ),
                      Text(
                        'اختر الموقع',
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
                const SizedBox(height: 20),
                // الخريطة
                Expanded(
                  child: Stack(
                    children: [
                      // الخريطة في Container مع تقويس
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              spreadRadius: 2,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _currentPosition,
                              initialZoom: 14,
                              onTap: _onMapTapped,
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
                                      child: const Icon(
                                        Icons.location_on,
                                        size: 50,
                                        color: Colors.red,
                                        shadows: [
                                          Shadow(
                                              blurRadius: 4,
                                              color: Colors.black26),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),

                      // زر الموقع الحالي
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Material(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(16),
                          elevation: 8,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap:
                                _isLoadingLocation ? null : _getCurrentLocation,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              child: _isLoadingLocation
                                  ? const SizedBox(
                                      width: 30,
                                      height: 30,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.my_location,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                            ),
                          ),
                        ),
                      ),

                      // معلومات الموقع المحدد
                      if (_selectedPosition != null)
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 90,
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          color: Colors.red, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _locationName.isNotEmpty
                                              ? _locationName
                                              : 'موقع محدد',
                                          style: GoogleFonts.cairo(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'خط العرض: ${_selectedPosition!.latitude.toStringAsFixed(6)}',
                                    style: GoogleFonts.cairo(
                                        fontSize: 11, color: Colors.grey[600]),
                                  ),
                                  Text(
                                    'خط الطول: ${_selectedPosition!.longitude.toStringAsFixed(6)}',
                                    style: GoogleFonts.cairo(
                                        fontSize: 11, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
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
        // زر التأكيد في أسفل الشاشة
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _selectedPosition == null ? null : _confirmLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 8,
                ),
                child: Text(
                  _selectedPosition == null
                      ? 'اضغط على الخريطة لتحديد الموقع'
                      : 'تأكيد الموقع والمتابعة',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _selectedPosition == null
                        ? Colors.grey[600]
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // نموذج التفاصيل (المرحلة الثانية)  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDetailsForm() {
    return Stack(
      children: [
        // صورة الخلفية
        Positioned.fill(
          child: Image.asset(
            'assets/img/main.png',
            fit: BoxFit.cover,
          ),
        ),
        // المحتوى
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
                left: 15.0, right: 15.0, top: 5.0, bottom: 90.0),
            child: Column(
              children: [
                // الهيدر
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      BubbleButton(
                        icon: Icons.arrow_forward,
                        onTap: () {
                          setState(() {
                            _isLocationConfirmed = false;
                          });
                        },
                      ),
                      Text(
                        'تفاصيل العنوان',
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
                const SizedBox(height: 20),
                // المحتوى
                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
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
                            // الخريطة الصغيرة
                            Container(
                              height: 180,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      AppColors.primaryColor.withOpacity(0.2),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: FlutterMap(
                                  options: MapOptions(
                                    initialCenter: _selectedPosition!,
                                    initialZoom: 15,
                                    interactionOptions:
                                        const InteractionOptions(
                                      flags: InteractiveFlag.none,
                                    ),
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName: 'com.alkafage.app',
                                    ),
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: _selectedPosition!,
                                          width: 40,
                                          height: 40,
                                          child: const Icon(
                                            Icons.location_on,
                                            size: 40,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            //الحقول المطلوبة
                            Text(
                              'المعلومات الأساسية *',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 12),

                            _buildTextField(
                              controller: _nameController,
                              label: 'اسم العنوان *',
                              hint: 'مثال: المنزل، العمل، بيت العائلة',
                              icon: Icons.label_outline,
                              isRequired: true,
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              controller: _fullAddressController,
                              label: 'تفاصيل العنوان *',
                              hint:
                                  'مثال: حي الكرامة، شارع 20، بجانب مستشفى...',
                              icon: Icons.location_on_outlined,
                              isRequired: true,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              controller: _phoneController,
                              label: 'رقم الاتصال *',
                              hint: '07xxxxxxxxx',
                              icon: Icons.phone_outlined,
                              isRequired: true,
                              keyboardType: TextInputType.phone,
                            ),

                            const SizedBox(height: 32),

                            // الحقول الاختيارية
                            Text(
                              'معلومات إضافية (اختياري)',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 12),

                            _buildTextField(
                              controller: _streetController,
                              label: 'اسم الشارع',
                              hint: 'مثال: شارع الكندي',
                              icon: Icons.signpost_outlined,
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _buildingController,
                                    label: 'رقم البناية',
                                    hint: 'مثال: 25',
                                    icon: Icons.business_outlined,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _floorController,
                                    label: 'رقم الطابق',
                                    hint: 'مثال: 3',
                                    icon: Icons.layers_outlined,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              controller: _apartmentController,
                              label: 'رقم الشقة',
                              hint: 'مثال: 12',
                              icon: Icons.door_front_door_outlined,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              controller: _landmarkController,
                              label: 'أقرب نقطة دالة',
                              hint: 'مثال: مقابل صيدلية الشفاء',
                              icon: Icons.place_outlined,
                              maxLines: 2,
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // زر الحفظ في الأسفل
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 8,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'حفظ العنوان',
                        style: GoogleFonts.cairo(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // حقل نصي مخصص
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.cairo(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.cairo(
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: AppColors.primaryColor, size: 22),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'هذا الحقل مطلوب';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }
}
