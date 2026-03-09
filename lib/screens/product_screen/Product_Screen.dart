import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utls/constants.dart';
import '../../widget/bubble_button.dart';
import '../../widget/custom_search_bar.dart';
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

  // الحصول على Supabase Client
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadData();

    // الاستماع لتغييرات البحث
    _searchController.addListener(_onSearchChanged);
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
      filtered =
          filtered
              .where((item) => item.categoryId == selectedCategory.id)
              .toList();
    }

    // تصفية حسب البحث
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered.where((item) {
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
              final descMatch =
                  item.description?.toLowerCase().contains(
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
      final categories =
          (categoriesData as List).map((cat) {
            return Category(
              id: cat['id'], // ✅ اسم العمود الصحيح
              shopId: cat['shop_id'],
              name: cat['name'], // ✅ اسم العمود الصحيح
              icon: cat['icon'], // ✅ اسم العمود الصحيح
              createdAt:
                  cat['created_at'] != null
                      ? DateTime.parse(cat['created_at'])
                      : DateTime.now(),
              updatedAt:
                  cat['updated_at'] != null
                      ? DateTime.parse(cat['updated_at'])
                      : DateTime.now(),
            );
          }).toList();

      // جلب المنتجات من قاعدة البيانات
      final itemsData = await _supabase
          .from('items') // ✅ اسم الجدول الصحيح
          .select('''
            *,
            item_images(*) 
          ''') // ✅ اسم الجدول الصحيح للصور
          .eq('shop_id', SupabaseConfig.shopId)
          .eq('is_active', true)
          .eq('is_deleted', false) // ✅ إضافة فلتر للمنتجات المحذوفة
          .order('created_at', ascending: false);

      // تحويل البيانات إلى قائمة Item
      final items =
          (itemsData as List).map((product) {
            // معالجة الصور
            final images =
                (product['item_images'] as List?)?.map((img) {
                  // ✅ اسم الجدول الصحيح
                  return ItemImage(
                    id: img['id'] ?? 0, // ✅ اسم العمود الصحيح
                    itemId: img['item_id'] ?? 0, // ✅ اسم العمود الصحيح
                    imagePath:
                        img['image_path'] ??
                        'assets/img/main.png', // ✅ اسم العمود الصحيح
                    sortOrder: img['sort_order'] ?? 1,
                    isPrimary: img['is_primary'] ?? false,
                    createdAt:
                        img['created_at'] != null
                            ? DateTime.parse(img['created_at'])
                            : DateTime.now(),
                  );
                }).toList() ??
                [];

            // إذا لم توجد صور، أضف صورة افتراضية
            if (images.isEmpty) {
              images.add(
                ItemImage(
                  id: 0,
                  itemId: product['id'] ?? 0, // ✅ اسم العمود الصحيح
                  imagePath: 'assets/img/main.png',
                  sortOrder: 1,
                  isPrimary: true,
                ),
              );
            }

            return Item(
              id: product['id'], // ✅ اسم العمود الصحيح
              shopId: product['shop_id'],
              title: product['title'], // ✅ اسم العمود الصحيح
              description: product['description'],
              price: (product['price'] as num).toDouble(),
              categoryId: product['category_id'],
              isActive: product['is_active'] ?? true,
              isDeleted: product['is_deleted'] ?? false,
              createdAt:
                  product['created_at'] != null
                      ? DateTime.parse(product['created_at'])
                      : DateTime.now(),
              updatedAt:
                  product['updated_at'] != null
                      ? DateTime.parse(product['updated_at'])
                      : DateTime.now(),
              images: images,
            );
          }).toList();

      setState(() {
        _categories = categories;
        _allItems = items;
        _filteredItems = items;
        _isLoading = false;
      });
    } catch (e) {
      print('خطأ في تحميل البيانات: $e');
      setState(() => _isLoading = false);
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
      body:
          _isLoading && _categories.isEmpty
              ? Center(
                child: CircularProgressIndicator(color: AppColors.primaryColor),
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // زر الرجوع على اليسار
                            BubbleButton(
                              icon: Icons.arrow_back,
                              onTap: () {
                                // وظيفة زر الرجوع
                              },
                            ),
                            // النص في الوسط
                            Text(
                              "المنتجات",
                              style: GoogleFonts.cairo(
                                color: AppColors.primaryColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            // مساحة فارغة للتوازن
                            BubbleButton(
                              icon: Icons.person,
                              onTap: () {
                                // وظيفة زر الرجوع
                              },
                            ),
                          ],
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
                        const SizedBox(width: 5),
                        Expanded(
                          child: CustomSearchBar(
                            controller: _searchController,
                            hintText: 'ابحث عن منتج...',
                          ),
                        ),
                        // زر مسح البحث
                        if (_searchQuery.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: BubbleButton(
                              icon: Icons.close,
                              onTap: () {
                                _searchController.clear();
                              },
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // شريط التصنيفات الأفقي
                    SizedBox(
                      height: 100,
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          itemCount: _categories.length + 1, // +1 لزر "الكل"
                          itemBuilder: (context, index) {
                            final isAll = index == 0; // الزر الأول هو "الكل"
                            final isSelected = _selectedCategoryIndex == index;

                            // إذا كان زر "الكل"
                            if (isAll) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: GestureDetector(
                                  onTap: () => _filterItemsByCategory(index),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 72,
                                        height: 72,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color:
                                              isSelected
                                                  ? AppColors.primaryColor
                                                  : AppColors.primaryColor
                                                      .withOpacity(0.6),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primaryColor
                                                  .withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
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
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.primaryColor,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primaryColor
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: Stack(
                                          children: [
                                            Positioned.fill(
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  1.5,
                                                ),
                                                child: ClipOval(
                                                  child: Image.asset(
                                                    category.icon ??
                                                        'assets/img/main.png',
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return Icon(
                                                        Icons.image,
                                                        color: Colors.white
                                                            .withOpacity(0.5),
                                                        size: 30,
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 0,
                                              left: 0,
                                              right: 0,
                                              child: Container(
                                                padding: const EdgeInsets.only(
                                                  bottom: 8,
                                                  top: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin:
                                                        Alignment.bottomCenter,
                                                    end: Alignment.topCenter,
                                                    stops: const [
                                                      0.0,
                                                      0.5,
                                                      1.0,
                                                    ],
                                                    colors: [
                                                      AppColors.primaryColor
                                                          .withOpacity(0.95),
                                                      AppColors.primaryColor
                                                          .withOpacity(0.7),
                                                      AppColors.primaryColor
                                                          .withOpacity(0.0),
                                                    ],
                                                  ),
                                                ),
                                                child: Text(
                                                  category.name,
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.cairo(
                                                    color: Colors.white,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w700,
                                                  ),
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
                          },
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
                      child:
                          _filteredItems.isEmpty
                              ? _buildEmptyState()
                              : SingleChildScrollView(
                                controller: _scrollController,
                                padding: const EdgeInsets.only(bottom: 90.0),
                                child: Row(
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
                                                    BorderRadius.circular(18),
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
                                                    offset: const Offset(0, 0),
                                                  ),
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.1),
                                                    blurRadius: 4,
                                                    spreadRadius: -1,
                                                    offset: const Offset(0, 2),
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
                                              return _buildCard(actualIndex);
                                            },
                                          ),
                                        ],
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
