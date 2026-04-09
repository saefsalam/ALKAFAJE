import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utls/constants.dart';
import '../../widget/bubble_button.dart';
import '../../widget/custom_search_bar.dart';
import '../../widget/Mytext.dart';
import '../../widget/loading_animation.dart';
import '../product_detail_screen.dart';
import '../../models/product_model.dart';
import '../../main.dart'; // استيراد SupabaseConfig من main.dart
import '../../widget/product_card.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // بيانات التصنيفات والمنتجات
  List<Category> _categories = [];
  List<Item> _allItems = []; // جميع المنتجات
  List<Item> _filteredItems = []; // المنتجات المعروضة بعد التصفية

  int _selectedCategoryIndex = 0;
  bool _isLoading = true;
  String _searchQuery = '';

  // إعدادات البحث
  bool _searchInTitle = true; // البحث في العنوان
  bool _searchInDescription = true; // البحث في الوصف

  // إعدادات Pagination
  static const int _pageSize = 20; // عدد المنتجات في كل دفعة
  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _hasMoreItems = true;

  // إخفاء/إظهار التصنيفات عند التمرير
  bool _showCategories = true;
  double _lastScrollPosition = 0;

  // الحصول على Supabase Client
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadData();

    // الاستماع لتغييرات البحث
    _searchController.addListener(_onSearchChanged);

    // الاستماع للتمرير لتحميل المزيد
    _scrollController.addListener(_onScroll);
  }

  // عند التمرير للأسفل
  void _onScroll() {
    // تحميل المزيد عند الاقتراب من النهاية
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }

    // إخفاء/إظهار التصنيفات حسب اتجاه التمرير
    final currentPosition = _scrollController.position.pixels;
    if (currentPosition > _lastScrollPosition && currentPosition > 50) {
      // التمرير لأسفل - إخفاء
      if (_showCategories) {
        setState(() => _showCategories = false);
      }
    } else if (currentPosition < _lastScrollPosition) {
      // التمرير لأعلى - إظهار
      if (!_showCategories) {
        setState(() => _showCategories = true);
      }
    }
    _lastScrollPosition = currentPosition;
  }

  // عند تغيير نص البحث
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
    _applyFilters();
  }

  // تطبيق التصفية (البحث + التصنيف)
  void _applyFilters() {
    List<Item> filtered = _allItems;

    // تصفية حسب التصنيف
    if (_selectedCategoryIndex > 0) {
      final selectedCategory = _categories[_selectedCategoryIndex - 1];
      filtered = filtered
          .where((item) => item.categoryId == selectedCategory.id)
          .toList();
    }

    // تصفية حسب البحث
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        bool match = false;

        // البحث في العنوان
        if (_searchInTitle) {
          final titleMatch = item.title.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );
          match = match || titleMatch;
        }

        // البحث في الوصف
        if (_searchInDescription) {
          final descMatch = item.description?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
              false;
          match = match || descMatch;
        }

        return match;
      }).toList();
    }

    setState(() {
      _filteredItems = filtered;
    });
  }

  // جلب البيانات من قاعدة البيانات
  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // جلب التصنيفات من قاعدة البيانات
      final categoriesData = await _supabase
          .from('categories')
          .select()
          .eq('shop_id', SupabaseConfig.shopId)
          .order(
            'created_at',
          ); // ✅ حذف is_active لأنه غير موجود في جدول categories

      // تحويل البيانات إلى قائمة Category
      final categories = (categoriesData as List).map((cat) {
        // تحويل مسار الصورة إلى URL كامل
        String? iconUrl;
        if (cat['icon'] != null && (cat['icon'] as String).isNotEmpty) {
          final iconPath = cat['icon'] as String;
          // إذا كان المسار URL كامل، استخدمه كما هو
          if (iconPath.startsWith('http://') ||
              iconPath.startsWith('https://')) {
            iconUrl = iconPath;
          } else if (iconPath.startsWith('assets/')) {
            // إذا كان مسار محلي (assets)، اتركه فارغ لعرض الأيقونة الافتراضية
            iconUrl = null;
          } else {
            // تحويل المسار إلى URL كامل من Supabase Storage
            iconUrl = _supabase.storage.from('icon').getPublicUrl(iconPath);
          }
        }

        return Category(
          id: cat['id'], // ✅ اسم العمود الصحيح
          shopId: cat['shop_id'],
          name: cat['name'], // ✅ اسم العمود الصحيح
          icon: iconUrl, // ✅ URL كامل للصورة
          createdAt: cat['created_at'] != null
              ? DateTime.parse(cat['created_at'])
              : DateTime.now(),
          updatedAt: cat['updated_at'] != null
              ? DateTime.parse(cat['updated_at'])
              : DateTime.now(),
        );
      }).toList();

      // جلب المنتجات من قاعدة البيانات - أول دفعة
      _currentPage = 0;
      _hasMoreItems = true;
      final itemsData = await _supabase
          .from('items') // ✅ اسم الجدول الصحيح
          .select('''
            *,
            item_images(*),
            item_colors(*),
            item_sizes(*)
          ''') // ✅ اسم الجدول الصحيح للصور
          .eq('shop_id', SupabaseConfig.shopId)
          .eq('is_active', true)
          .eq('is_deleted', false) // ✅ إضافة فلتر للمنتجات المحذوفة
          .order('created_at', ascending: false)
          .range(0, _pageSize - 1); // تحميل أول 20 منتج

      // تحويل البيانات إلى قائمة Item
      final items = (itemsData as List).map<Item>((product) {
        return Item.fromJson(Map<String, dynamic>.from(product));
      }).toList();

      // التحقق إذا كان هناك المزيد من المنتجات
      if (items.length < _pageSize) {
        _hasMoreItems = false;
      }

      if (!mounted) return;
      setState(() {
        _categories = categories;
        _allItems = items;
        _filteredItems = items;
        _isLoading = false;
      });

      // تحميل صور التصنيفات مسبقاً (precache)
      _precacheCategoryImages(categories);
    } catch (e) {
      print('خطأ في تحميل البيانات: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // تحميل صور التصنيفات مسبقاً لتجنب التأخير
  void _precacheCategoryImages(List<Category> categories) {
    for (final category in categories) {
      if (category.icon != null &&
          category.icon!.isNotEmpty &&
          (category.icon!.startsWith('http://') ||
              category.icon!.startsWith('https://'))) {
        precacheImage(NetworkImage(category.icon!), context);
      }
    }
  }

  // تحميل المزيد من المنتجات
  Future<void> _loadMoreItems() async {
    if (_isLoadingMore || !_hasMoreItems || _searchQuery.isNotEmpty) return;

    if (!mounted) return;
    setState(() => _isLoadingMore = true);

    try {
      _currentPage++;
      final startIndex = _currentPage * _pageSize;
      final endIndex = startIndex + _pageSize - 1;

      final itemsData = await _supabase
          .from('items')
          .select('''
            *,
            item_images(*),
            item_colors(*),
            item_sizes(*)
          ''')
          .eq('shop_id', SupabaseConfig.shopId)
          .eq('is_active', true)
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .range(startIndex, endIndex);

      final newItems = (itemsData as List).map<Item>((product) {
        return Item.fromJson(Map<String, dynamic>.from(product));
      }).toList();

      if (newItems.length < _pageSize) {
        _hasMoreItems = false;
      }

      if (!mounted) return;
      setState(() {
        _allItems.addAll(newItems);
        _isLoadingMore = false;
      });
      _applyFilters();

      print(
        '📦 تم تحميل ${newItems.length} منتج إضافي - المجموع: ${_allItems.length}',
      );
    } catch (e) {
      print('خطأ في تحميل المزيد: $e');
      _currentPage--;
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // تصفية المنتجات حسب التصنيف
  void _filterItemsByCategory(int index) {
    setState(() {
      _selectedCategoryIndex = index;
    });
    _applyFilters();
  }

  // بناء صورة التصنيف (من الشبكة أو الأصول المحلية)
  Widget _buildCategoryImage(String? iconUrl) {
    // الأيقونة الافتراضية
    Widget defaultIcon = Container(
      color: AppColors.primaryColor.withOpacity(0.3),
      child: const Center(
        child: Icon(
          Icons.shopping_bag_outlined,
          color: Colors.white,
          size: 35,
        ),
      ),
    );

    // إذا لم يكن هناك صورة، نعرض أيقونة منتجات
    if (iconUrl == null || iconUrl.isEmpty) {
      return defaultIcon;
    }

    // إذا كانت الصورة من الشبكة (URL)
    if (iconUrl.startsWith('http://') || iconUrl.startsWith('https://')) {
      return FadeInImage(
        placeholder: const AssetImage('assets/img/main.png'),
        image: NetworkImage(iconUrl),
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 100),
        imageErrorBuilder: (context, error, stackTrace) {
          return defaultIcon;
        },
        placeholderErrorBuilder: (context, error, stackTrace) {
          return defaultIcon;
        },
      );
    }

    // إذا كانت الصورة من الأصول المحلية
    return Image.asset(
      iconUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return defaultIcon;
      },
    );
  }

  // عرض قائمة إعدادات البحث
  void showSearchSettingsMenu() {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      items: [
        PopupMenuItem<String>(
          enabled: false,
          child: Text(
            'إعدادات البحث',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'title',
          child: StatefulBuilder(
            builder: (context, setStateMenu) {
              return CheckboxListTile(
                value: _searchInTitle,
                onChanged: (value) {
                  setState(() {
                    _searchInTitle = value ?? true;
                  });
                  _applyFilters();
                },
                title: Text(
                  'البحث في اسم المنتج',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                activeColor: AppColors.primaryColor,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              );
            },
          ),
        ),
        PopupMenuItem<String>(
          value: 'description',
          child: StatefulBuilder(
            builder: (context, setStateMenu) {
              return CheckboxListTile(
                value: _searchInDescription,
                onChanged: (value) {
                  setState(() {
                    _searchInDescription = value ?? true;
                  });
                  _applyFilters();
                },
                title: Text(
                  'البحث في تفاصيل المنتج',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                activeColor: AppColors.primaryColor,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading && _categories.isEmpty
          ? const Center(
              child: LoadingAnimation(size: 200),
            )
          : Padding(
              padding: const EdgeInsets.only(
                left: 15.0,
                right: 15.0,
                top: 5.0,
              ),
              child: Column(
                children: [
                  // الهيدر الثابت
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Center(
                        child: const MyText(text: "المنتجات", fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  // شريط البحث الثابت مع زر
                  Row(
                    children: [
                      BubbleButton(
                        icon: Icons.tune_rounded,
                        onTap: showSearchSettingsMenu,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomSearchBar(
                          controller: _searchController,
                          hintText: 'ابحث عن منتج...',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // شريط التصنيفات الأفقي
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    height: _showCategories ? 110 : 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 100),
                      opacity: _showCategories ? 1.0 : 0.0,
                      child: SizedBox(
                        height: 110,
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            padding: const EdgeInsets.only(
                              left: 4,
                              right: 4,
                              top: 8,
                              bottom: 8,
                            ),
                            itemCount: _categories.length + 1, // +1 لزر "الكل"
                            itemBuilder: (context, index) {
                              final isAll = index == 0; // الزر الأول هو "الكل"
                              final isSelected =
                                  _selectedCategoryIndex == index;

                              // إذا كان زر "الكل"
                              if (isAll) {
                                return Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: GestureDetector(
                                    onTap: () => _filterItemsByCategory(index),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Stack(
                                          children: [
                                            AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 150),
                                              width: 72,
                                              height: 72,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isSelected
                                                    ? AppColors.primaryColor
                                                    : AppColors.primaryColor
                                                        .withOpacity(0.6),
                                                border: isSelected
                                                    ? Border.all(
                                                        color: Colors.white,
                                                        width: 3,
                                                      )
                                                    : null,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: isSelected
                                                        ? AppColors.primaryColor
                                                        : AppColors.primaryColor
                                                            .withOpacity(0.3),
                                                    blurRadius:
                                                        isSelected ? 12 : 6,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                'الكل',
                                                style: GoogleFonts.cairo(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            // علامة الاختيار
                                            if (isSelected)
                                              Positioned(
                                                top: 0,
                                                right: 0,
                                                child: Container(
                                                  width: 22,
                                                  height: 22,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.white,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.2),
                                                        blurRadius: 4,
                                                      ),
                                                    ],
                                                  ),
                                                  child: Icon(
                                                    Icons.check,
                                                    color:
                                                        AppColors.primaryColor,
                                                    size: 14,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              // التصنيفات الأخرى
                              final category = _categories[index - 1];
                              return Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: GestureDetector(
                                  onTap: () => _filterItemsByCategory(index),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Stack(
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 150),
                                            width: 72,
                                            height: 72,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.primaryColor,
                                              border: isSelected
                                                  ? Border.all(
                                                      color: Colors.white,
                                                      width: 3,
                                                    )
                                                  : null,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: isSelected
                                                      ? AppColors.primaryColor
                                                      : AppColors.primaryColor
                                                          .withOpacity(0.3),
                                                  blurRadius:
                                                      isSelected ? 12 : 6,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            child: ClipOval(
                                              child: Stack(
                                                children: [
                                                  Positioned.fill(
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                        1.5,
                                                      ),
                                                      child: ClipOval(
                                                        child:
                                                            _buildCategoryImage(
                                                                category.icon),
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    bottom: 0,
                                                    left: 0,
                                                    right: 0,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.only(
                                                        bottom: 6,
                                                        top: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            LinearGradient(
                                                          begin: Alignment
                                                              .bottomCenter,
                                                          end: Alignment
                                                              .topCenter,
                                                          stops: const [
                                                            0.0,
                                                            0.5,
                                                            1.0,
                                                          ],
                                                          colors: [
                                                            AppColors
                                                                .primaryColor
                                                                .withOpacity(
                                                              0.95,
                                                            ),
                                                            AppColors
                                                                .primaryColor
                                                                .withOpacity(
                                                                    0.7),
                                                            AppColors
                                                                .primaryColor
                                                                .withOpacity(
                                                                    0.0),
                                                          ],
                                                        ),
                                                      ),
                                                      child: Text(
                                                        category.name,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style:
                                                            GoogleFonts.cairo(
                                                          color: Colors.white,
                                                          fontSize: 9,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          // علامة الاختيار
                                          if (isSelected)
                                            Positioned(
                                              top: 0,
                                              right: 0,
                                              child: Container(
                                                width: 22,
                                                height: 22,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.white,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.2),
                                                      blurRadius: 4,
                                                    ),
                                                  ],
                                                ),
                                                child: Icon(
                                                  Icons.check,
                                                  color: AppColors.primaryColor,
                                                  size: 14,
                                                ),
                                              ),
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
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  // عرض عدد النتائج عند البحث
                  if (_searchQuery.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primaryColor.withOpacity(
                                  0.3,
                                ),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search,
                                  size: 16,
                                  color: AppColors.primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'تم العثور على ${_filteredItems.length} منتج',
                                  style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  // المحتوى المتحرك
                  Expanded(
                    child: _filteredItems.isEmpty
                        ? _buildEmptyState()
                        : SingleChildScrollView(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(bottom: 90.0),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // العمود الأيمن - العناصر الزوجية (0, 2, 4, ...)
                                    Expanded(
                                      child: Column(
                                        children: List.generate(
                                          (_filteredItems.length / 2).ceil(),
                                          (index) {
                                            final actualIndex = index * 2;
                                            if (actualIndex >=
                                                _filteredItems.length)
                                              return const SizedBox();
                                            return _buildCard(actualIndex);
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 25),
                                    // العمود الأيسر - العناصر الفردية (1, 3, 5, ...)
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8.0,
                                              bottom: 8.0,
                                            ),
                                            child: Container(
                                              height: 35,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 14,
                                              ),
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  18,
                                                ),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withOpacity(0.3),
                                                  width: 1.5,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.white
                                                        .withOpacity(0.25),
                                                    blurRadius: 8,
                                                    spreadRadius: 0,
                                                    offset: const Offset(
                                                      0,
                                                      0,
                                                    ),
                                                  ),
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.1),
                                                    blurRadius: 4,
                                                    spreadRadius: -1,
                                                    offset: const Offset(
                                                      0,
                                                      2,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                'المنتجات',
                                                style: GoogleFonts.cairo(
                                                  color: AppColors.primaryColor,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                          ...List.generate(
                                            (_filteredItems.length / 2).floor(),
                                            (index) {
                                              final actualIndex = index * 2 + 1;
                                              if (actualIndex >=
                                                  _filteredItems.length)
                                                return const SizedBox();
                                              return _buildCard(
                                                actualIndex,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                // مؤشر تحميل المزيد
                                if (_isLoadingMore)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 20,
                                    ),
                                    child: Center(
                                      child: LoadingAnimation(size: 80),
                                    ),
                                  ),
                                // رسالة نهاية المنتجات
                                if (!_hasMoreItems &&
                                    _filteredItems.isNotEmpty &&
                                    _searchQuery.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 20,
                                    ),
                                    child: Text(
                                      'لا يوجد منتجات أخرى',
                                      style: GoogleFonts.cairo(
                                        color: Colors.grey[500],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  // واجهة عند عدم وجود منتجات
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // أيقونة كبيرة
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryColor.withOpacity(0.1),
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 60,
              color: AppColors.primaryColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          // النص الرئيسي
          Text(
            'لا توجد منتجات حالياً',
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          // النص الفرعي
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _selectedCategoryIndex == 0
                  ? 'لم يتم إضافة أي منتجات بعد'
                  : 'لا توجد منتجات في هذا التصنيف',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          // زر (اختياري - يمكن استخدامه للعودة إلى الكل)
          if (_selectedCategoryIndex != 0)
            GestureDetector(
              onTap: () => _filterItemsByCategory(0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'عرض جميع المنتجات',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(int index) {
    final item = _filteredItems[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      child: ProductCard(
        item: item,
        onTap: () {
          // الانتقال إلى صفحة تفاصيل المنتج مع إخفاء شريط التنقل
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(item: item),
            ),
          );
        },
      ),
    );
  }
}
