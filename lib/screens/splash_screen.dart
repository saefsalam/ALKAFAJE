import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import 'home/home_controller.dart';
import 'no_connection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  bool _isVideoFinished = false;
  bool _showMainScreen = false;
  bool _hasError = false;
  bool _isSplashVisible = true;
  bool _isTransitioning = false;
  bool _fadeOut = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ).drive(Tween(begin: 1.0, end: 0.0));

    // إخفاء شريط الحالة أثناء السبلاش
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _initializeAndPlayVideo();
  }

  Future<void> _initializeAndPlayVideo() async {
    try {
      _videoController = VideoPlayerController.asset('assets/video/start.MOV');

      await _videoController!.initialize();
      if (!mounted) return;

      setState(() {});
      _videoController!.addListener(_onVideoUpdate);

      // تشغيل الفيديو
      await _videoController!.play();

      // انتظار انتهاء الفيديو
    } catch (e) {
      debugPrint('Video initialization failed: $e');
      await _onVideoComplete();
    }
  }

  void _onVideoUpdate() {
    if (!mounted || _videoController == null) return;

    final value = _videoController!.value;

    // التحقق من انتهاء الفيديو
    if (value.position >= value.duration && value.duration > Duration.zero) {
      if (!_isVideoFinished) {
        _isVideoFinished = true;
        _videoController!.removeListener(_onVideoUpdate);
        _onVideoComplete();
      }
    }
  }

  Future<void> _onVideoComplete() async {
    if (_isTransitioning) return;
    _isTransitioning = true;
    debugPrint('Splash video finished, loading app data.');

    // إيقاف الفيديو وتنظيفه
    _videoController?.pause();

    // تحميل البيانات الآن (بعد انتهاء الفيديو)
    try {
      final homeController = Get.put(HomeController());
      await homeController.loadData();
      _hasError = homeController.hasError.value;
    } catch (e) {
      _hasError = true;
    }

    if (!mounted) return;

    debugPrint('App data is ready, starting splash fade.');

    // إعادة شريط الحالة
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // عرض الواجهة الرئيسية + بدء التلاشي
    setState(() {
      _showMainScreen = true;
      _fadeOut = true;
    });

    await _fadeController.forward();
    if (!mounted) return;

    setState(() {
      _isSplashVisible = false;
    });
  }

  @override
  void dispose() {
    _videoController?.removeListener(_onVideoUpdate);
    _videoController?.dispose();
    _fadeController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // الطبقة السفلى: الواجهة الرئيسية
          if (_showMainScreen)
            Positioned.fill(
              child:
                  _hasError ? const NoConnectionScreen() : const MainScreen(),
            ),

          // الطبقة العليا: الفيديو (يتلاشى)
          if (_isSplashVisible)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: _fadeOut,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Stack(
                    children: [
                      // الفيديو
                      ColoredBox(
                        color: Colors.black,
                        child: _videoController != null &&
                                _videoController!.value.isInitialized
                            ? SizedBox.expand(
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: _videoController!.value.size.width,
                                    height: _videoController!.value.size.height,
                                    child: VideoPlayer(_videoController!),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      // نص تفاصيل الشركة في الأسفل
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: MediaQuery.of(context).padding.bottom + 24,
                        child: Text(
                          'شركة القرش ®',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            color: const Color(0xFF312F92),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
