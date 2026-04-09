// ═══════════════════════════════════════════════════════════
// 1. نموذج التصنيف (Category)
// ═══════════════════════════════════════════════════════════
class Category {
  final String id; // uuid
  final String shopId; // uuid
  final String name; // اسم التصنيف
  final String? icon; // مسار الأيقونة (اختياري)
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.shopId,
    required this.name,
    this.icon,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // تحويل من JSON
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      shopId: json['shop_id'],
      name: json['name'],
      icon: json['icon'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  // تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'name': name,
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// ═══════════════════════════════════════════════════════════
// 2. نموذج صورة المنتج (ItemImage)
// ═══════════════════════════════════════════════════════════
class ItemImage {
  final int id; // bigint
  final int itemId; // bigint
  final String imagePath; // مسار الصورة
  final int sortOrder; // ترتيب العرض
  final bool isPrimary; // صورة رئيسية؟
  final DateTime createdAt;

  ItemImage({
    required this.id,
    required this.itemId,
    required this.imagePath,
    this.sortOrder = 1,
    this.isPrimary = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // تحويل من JSON
  factory ItemImage.fromJson(Map<String, dynamic> json) {
    return ItemImage(
      id: json['id'],
      itemId: json['item_id'],
      imagePath: json['image_path'],
      sortOrder: json['sort_order'] ?? 1,
      isPrimary: json['is_primary'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  // تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': itemId,
      'image_path': imagePath,
      'sort_order': sortOrder,
      'is_primary': isPrimary,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// ═══════════════════════════════════════════════════════════
// 3. نموذج المنتج (Item) مع التخفيضات والتاغات
// ═══════════════════════════════════════════════════════════

/// أنواع التاغات للمنتجات
class ItemColorOption {
  final int id;
  final int itemId;
  final String name;
  final String? hexCode;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ItemColorOption({
    required this.id,
    required this.itemId,
    required this.name,
    this.hexCode,
    this.sortOrder = 1,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory ItemColorOption.fromJson(Map<String, dynamic> json) {
    return ItemColorOption(
      id: json['id'] as int,
      itemId: json['item_id'] as int,
      name: (json['name'] ?? '').toString(),
      hexCode: json['hex_code']?.toString(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 1,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': itemId,
      'name': name,
      'hex_code': hexCode,
      'sort_order': sortOrder,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ItemSizeOption {
  final int id;
  final int itemId;
  final String name;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ItemSizeOption({
    required this.id,
    required this.itemId,
    required this.name,
    this.sortOrder = 1,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory ItemSizeOption.fromJson(Map<String, dynamic> json) {
    return ItemSizeOption(
      id: json['id'] as int,
      itemId: json['item_id'] as int,
      name: (json['name'] ?? '').toString(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 1,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': itemId,
      'name': name,
      'sort_order': sortOrder,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

String buildProductSelectionKey({
  int? colorId,
  int? sizeId,
}) {
  return 'c:${colorId ?? 0}|s:${sizeId ?? 0}';
}

String formatProductSelectionLabel({
  String? colorName,
  String? sizeName,
}) {
  final List<String> parts = <String>[];
  final String? cleanColor = colorName?.trim();
  final String? cleanSize = sizeName?.trim();

  if (cleanColor != null && cleanColor.isNotEmpty) {
    parts.add('اللون: $cleanColor');
  }

  if (cleanSize != null && cleanSize.isNotEmpty) {
    parts.add('الحجم: $cleanSize');
  }

  return parts.join(' - ');
}

class ProductOptionSelection {
  final int? colorId;
  final String? colorName;
  final String? colorHex;
  final int? sizeId;
  final String? sizeName;

  const ProductOptionSelection({
    this.colorId,
    this.colorName,
    this.colorHex,
    this.sizeId,
    this.sizeName,
  });

  factory ProductOptionSelection.fromChoices({
    ItemColorOption? color,
    ItemSizeOption? size,
  }) {
    return ProductOptionSelection(
      colorId: color?.id,
      colorName: color?.name,
      colorHex: color?.hexCode,
      sizeId: size?.id,
      sizeName: size?.name,
    );
  }

  factory ProductOptionSelection.fromJson(Map<String, dynamic> json) {
    return ProductOptionSelection(
      colorId: (json['selected_color_id'] as num?)?.toInt(),
      colorName: json['selected_color_name']?.toString(),
      colorHex: json['selected_color_hex']?.toString(),
      sizeId: (json['selected_size_id'] as num?)?.toInt(),
      sizeName: json['selected_size_name']?.toString(),
    );
  }

  String get selectionKey => buildProductSelectionKey(
        colorId: colorId,
        sizeId: sizeId,
      );

  bool get isEmpty {
    return (colorId == null || colorId == 0) &&
        (sizeId == null || sizeId == 0) &&
        (colorName == null || colorName!.trim().isEmpty) &&
        (sizeName == null || sizeName!.trim().isEmpty);
  }

  String get label => formatProductSelectionLabel(
        colorName: colorName,
        sizeName: sizeName,
      );

  Map<String, dynamic> toCartPayload() {
    return {
      'selection_key': selectionKey,
      'selected_color_id': colorId,
      'selected_color_name': colorName,
      'selected_color_hex': colorHex,
      'selected_size_id': sizeId,
      'selected_size_name': sizeName,
    };
  }
}

enum ItemTag {
  discount, // تخفيض
  ramadan, // رمضان
  newArrival, // وصل حديثاً
  bestSeller, // الأكثر مبيعاً
  featured, // مميز
  limitedOffer, // عرض محدود
}

/// امتداد للحصول على معلومات التاغ
extension ItemTagExtension on ItemTag {
  String get label {
    switch (this) {
      case ItemTag.discount:
        return 'تخفيض';
      case ItemTag.ramadan:
        return 'رمضان';
      case ItemTag.newArrival:
        return 'جديد';
      case ItemTag.bestSeller:
        return 'الأكثر مبيعاً';
      case ItemTag.featured:
        return 'مميز';
      case ItemTag.limitedOffer:
        return 'عرض محدود';
    }
  }

  String get color {
    switch (this) {
      case ItemTag.discount:
        return '#E53935'; // أحمر
      case ItemTag.ramadan:
        return '#6A1B9A'; // بنفسجي
      case ItemTag.newArrival:
        return '#43A047'; // أخضر
      case ItemTag.bestSeller:
        return '#FB8C00'; // برتقالي
      case ItemTag.featured:
        return '#1E88E5'; // أزرق
      case ItemTag.limitedOffer:
        return '#D81B60'; // وردي
    }
  }
}

class Item {
  final int id; // bigint
  final String shopId; // uuid
  final String categoryId; // uuid
  final String title; // عنوان المنتج
  final String? description; // الوصف
  final double price; // السعر الأصلي
  final double? discountPrice; // سعر التخفيض (إذا كان هناك تخفيض)
  final int? discountPercent; // نسبة التخفيض
  final List<ItemTag> tags; // التاغات (تخفيض، رمضان، جديد، إلخ)
  final bool isActive; // نشط؟
  final bool isDeleted; // محذوف؟
  final DateTime createdAt;
  final DateTime updatedAt;

  // علاقات
  final Category? category; // التصنيف
  final List<ItemImage> images; // الصور
  final List<ItemColorOption> colors;
  final List<ItemSizeOption> sizes;

  Item({
    required this.id,
    required this.shopId,
    required this.categoryId,
    required this.title,
    this.description,
    required this.price,
    this.discountPrice,
    this.discountPercent,
    this.tags = const [],
    this.isActive = true,
    this.isDeleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.category,
    this.images = const [],
    this.colors = const [],
    this.sizes = const [],
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // هل المنتج عليه تخفيض؟
  bool get hasDiscount => finalPrice < price;

  // نسبة التخفيض الفعلية (من الحقل مباشرة أو محسوبة تلقائياً من الأسعار)
  int? get effectiveDiscountPercent {
    final int? fromField = discountPercent;
    if (fromField != null && fromField > 0) {
      return fromField;
    }

    if (discountPrice != null && discountPrice! < price && price > 0) {
      final double percent = ((price - discountPrice!) / price) * 100;
      return percent.round();
    }

    return null;
  }

  // السعر النهائي (بعد التخفيض إن وجد)
  double get finalPrice {
    if (discountPrice != null && discountPrice! < price) {
      return discountPrice!;
    }

    final int? percent = discountPercent;
    if (percent != null && percent > 0 && percent < 100) {
      return price * (1 - (percent / 100));
    }

    return price;
  }

  // هل المنتج من منتجات رمضان؟
  bool get isRamadan => tags.contains(ItemTag.ramadan);

  // هل المنتج جديد؟
  bool get isNew => tags.contains(ItemTag.newArrival);

  // هل المنتج مميز؟
  bool get isFeatured => tags.contains(ItemTag.featured);

  // هل المنتج الأكثر مبيعاً؟
  bool get isBestSeller => tags.contains(ItemTag.bestSeller);

  List<ItemColorOption> get availableColors =>
      colors.where((option) => option.isActive).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<ItemSizeOption> get availableSizes =>
      sizes.where((option) => option.isActive).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  bool get hasColorOptions => availableColors.isNotEmpty;

  bool get hasSizeOptions => availableSizes.isNotEmpty;

  bool get requiresOptionSelection => hasColorOptions || hasSizeOptions;

  // تحويل من JSON
  factory Item.fromJson(Map<String, dynamic> json, {List<ItemImage>? images}) {
    // معالجة الصور من JSON أو من parameter
    List<ItemImage> itemImages = images ?? [];
    if (itemImages.isEmpty && json['images'] != null) {
      itemImages = (json['images'] as List)
          .map((img) => ItemImage.fromJson(img))
          .toList();
    }
    if (itemImages.isEmpty && json['item_images'] != null) {
      itemImages = (json['item_images'] as List)
          .map((img) => ItemImage.fromJson(img))
          .toList();
    }

    final List<ItemColorOption> itemColors = json['item_colors'] != null
        ? (json['item_colors'] as List)
            .map((color) => ItemColorOption.fromJson(color))
            .toList()
        : const <ItemColorOption>[];

    final List<ItemSizeOption> itemSizes = json['item_sizes'] != null
        ? (json['item_sizes'] as List)
            .map((size) => ItemSizeOption.fromJson(size))
            .toList()
        : const <ItemSizeOption>[];

    return Item(
      id: json['id'],
      shopId: json['shop_id'],
      categoryId: json['category_id'],
      title: json['title'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      discountPrice: json['discount_price'] != null
          ? (json['discount_price'] as num).toDouble()
          : null,
      discountPercent: json['discount_percent'] != null
          ? (json['discount_percent'] as num).round()
          : null,
      tags: json['tags'] != null
          ? (json['tags'] as List)
              .map(
                (t) => ItemTag.values.firstWhere(
                  (e) => e.name == t,
                  orElse: () => ItemTag.featured,
                ),
              )
              .toList()
          : [],
      isActive: json['is_active'] ?? true,
      isDeleted: json['is_deleted'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      category:
          json['category'] != null ? Category.fromJson(json['category']) : null,
      images: itemImages,
      colors: itemColors,
      sizes: itemSizes,
    );
  }

  // تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'category_id': categoryId,
      'title': title,
      'description': description,
      'price': price,
      'discount_price': discountPrice,
      'discount_percent': discountPercent,
      'tags': tags.map((t) => t.name).toList(),
      'is_active': isActive,
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'category': category?.toJson(),
      'images': images.map((img) => img.toJson()).toList(),
      'item_colors': colors.map((color) => color.toJson()).toList(),
      'item_sizes': sizes.map((size) => size.toJson()).toList(),
    };
  }

  // الحصول على الصورة الرئيسية
  String get primaryImage {
    final primary = images.where((img) => img.isPrimary).firstOrNull;
    if (primary != null) return primary.imagePath;
    if (images.isNotEmpty) return images.first.imagePath;
    return 'assets/img/main.png'; // صورة افتراضية
  }

  // الحصول على كل مسارات الصور
  List<String> get imagePaths {
    if (images.isEmpty) return ['assets/img/main.png'];
    return images.map((img) => img.imagePath).toList();
  }

  // تنسيق السعر
  String get formattedPrice {
    return price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  // تنسيق السعر النهائي
  String get formattedFinalPrice {
    return finalPrice.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  // تنسيق سعر التخفيض
  String get formattedDiscountPrice {
    if (discountPrice == null) return formattedPrice;
    return discountPrice!.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

// ═══════════════════════════════════════════════════════════
// 4. نموذج المتجر (Shop)
// ═══════════════════════════════════════════════════════════
class Shop {
  final String id;
  final String displayName;
  final String? phone;
  final String? address;
  final String primaryColor;
  final String? logoUrl;
  final String primaryLanguage;
  final String? facebookUrl;
  final String? instagramUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Shop({
    required this.id,
    required this.displayName,
    this.phone,
    this.address,
    this.primaryColor = '#312F92',
    this.logoUrl,
    this.primaryLanguage = 'ar',
    this.facebookUrl,
    this.instagramUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'],
      displayName: json['display_name'],
      phone: json['phone'],
      address: json['address'],
      primaryColor: json['primary_color'] ?? '#312F92',
      logoUrl: json['logo_url'],
      primaryLanguage: json['primary_language'] ?? 'ar',
      facebookUrl: json['facebook_url'],
      instagramUrl: json['instagram_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'phone': phone,
      'address': address,
      'primary_color': primaryColor,
      'logo_url': logoUrl,
      'primary_language': primaryLanguage,
      'facebook_url': facebookUrl,
      'instagram_url': instagramUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// ═══════════════════════════════════════════════════════════
// 5. نموذج إعلان البانر (BannerAd)
// ═══════════════════════════════════════════════════════════
class BannerAd {
  final int id;
  final String shopId;
  final String imagePath;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  BannerAd({
    required this.id,
    required this.shopId,
    required this.imagePath,
    this.sortOrder = 1,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory BannerAd.fromJson(Map<String, dynamic> json) {
    return BannerAd(
      id: json['id'],
      shopId: json['shop_id'],
      imagePath: json['image_path'],
      sortOrder: json['sort_order'] ?? 1,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'image_path': imagePath,
      'sort_order': sortOrder,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// ═══════════════════════════════════════════════════════════
// 6. نموذج منطقة التوصيل (DeliveryZone)
// ═══════════════════════════════════════════════════════════
class DeliveryZone {
  final int id;
  final String shopId;
  final String city;
  final double price;
  final DateTime createdAt;
  final DateTime updatedAt;

  DeliveryZone({
    required this.id,
    required this.shopId,
    required this.city,
    this.price = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory DeliveryZone.fromJson(Map<String, dynamic> json) {
    return DeliveryZone(
      id: json['id'],
      shopId: json['shop_id'],
      city: json['city'],
      price: (json['price'] as num).toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'city': city,
      'price': price,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get formattedPrice {
    return price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

// ═══════════════════════════════════════════════════════════
// 7. نموذج قديم للتوافق (Product) - deprecated
// ═══════════════════════════════════════════════════════════
@Deprecated('استخدم Item بدلاً منه')
class Product {
  final String id;
  final String title;
  final String subtitle;
  final String price;
  final List<String> images;
  final String description;
  final String material;
  final String origin;
  final String condition;
  final int availableQuantity;
  final String category;

  Product({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.images,
    this.description = '',
    this.material = 'خزف عالي الجودة',
    this.origin = 'تركيا',
    this.condition = 'جديد',
    this.availableQuantity = 15,
    this.category = 'الكل',
  });
}

// ═══════════════════════════════════════════════════════════
// 8. نموذج البارت (Part) - أقسام الواجهة الرئيسية
// ═══════════════════════════════════════════════════════════
class Part {
  final int id;
  final String shopId;
  final String name;
  final int sortOrder; // ترتيب في الواجهة (1=أول, 2=ثاني...)
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Item> items; // المنتجات المرتبطة بهذا البارت

  Part({
    required this.id,
    required this.shopId,
    required this.name,
    this.sortOrder = 1,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.items = const [],
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // تحويل من JSON
  factory Part.fromJson(Map<String, dynamic> json, {List<Item>? items}) {
    return Part(
      id: json['id'],
      shopId: json['shop_id'],
      name: json['name'],
      sortOrder: json['sort_order'] ?? 1,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      items: items ?? [],
    );
  }

  // تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'name': name,
      'sort_order': sortOrder,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // نسخة معدلة
  Part copyWith({
    int? id,
    String? shopId,
    String? name,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Item>? items,
  }) {
    return Part(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 9. نموذج ربط المنتج بالبارت (PartItem)
// ═══════════════════════════════════════════════════════════
class PartItem {
  final int id;
  final int partId;
  final int itemId;
  final DateTime createdAt;

  PartItem({
    required this.id,
    required this.partId,
    required this.itemId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // تحويل من JSON
  factory PartItem.fromJson(Map<String, dynamic> json) {
    return PartItem(
      id: json['id'],
      partId: json['part_id'],
      itemId: json['item_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  // تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'part_id': partId,
      'item_id': itemId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
