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
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // تحويل من JSON
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      shopId: json['shop_id'],
      name: json['name'],
      icon: json['icon'],
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      updatedAt:
          json['updated_at'] != null
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
      createdAt:
          json['created_at'] != null
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
// 3. نموذج المنتج (Item)
// ═══════════════════════════════════════════════════════════
class Item {
  final int id; // bigint
  final String shopId; // uuid
  final String categoryId; // uuid
  final String title; // عنوان المنتج
  final String? description; // الوصف
  final double price; // السعر
  final bool isActive; // نشط؟
  final bool isDeleted; // محذوف؟
  final DateTime createdAt;
  final DateTime updatedAt;

  // علاقات
  final Category? category; // التصنيف
  final List<ItemImage> images; // الصور

  Item({
    required this.id,
    required this.shopId,
    required this.categoryId,
    required this.title,
    this.description,
    required this.price,
    this.isActive = true,
    this.isDeleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.category,
    this.images = const [],
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // تحويل من JSON
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      shopId: json['shop_id'],
      categoryId: json['category_id'],
      title: json['title'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      isActive: json['is_active'] ?? true,
      isDeleted: json['is_deleted'] ?? false,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : DateTime.now(),
      category:
          json['category'] != null ? Category.fromJson(json['category']) : null,
      images:
          json['images'] != null
              ? (json['images'] as List)
                  .map((img) => ItemImage.fromJson(img))
                  .toList()
              : [],
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
      'is_active': isActive,
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'category': category?.toJson(),
      'images': images.map((img) => img.toJson()).toList(),
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
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

// ═══════════════════════════════════════════════════════════
// 4. نموذج قديم للتوافق (Product) - deprecated
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

  // بيانات تجريبية للمنتجات
}
