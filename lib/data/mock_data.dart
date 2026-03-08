import '../models/product_model.dart';

// ═══════════════════════════════════════════════════════════
// البيانات الوهمية (Mock Data) - بناءً على السكيما الفعلية
// ═══════════════════════════════════════════════════════════

class MockData {
  // معرف المتجر الوهمي
  static const String shopId = 'shop-alkafajy-001';

  // ═══════════════════════════════════════════════════════════
  // التصنيفات (Categories)
  // ═══════════════════════════════════════════════════════════
  static List<Category> getCategories() {
    return [
      Category(
        id: 'cat-001',
        shopId: shopId,
        name: 'الصحون',
        icon: 'assets/img/main.png',
      ),
      Category(
        id: 'cat-002',
        shopId: shopId,
        name: 'أكواب',
        icon: 'assets/img/main.png',
      ),
      Category(
        id: 'cat-003',
        shopId: shopId,
        name: 'الأكرلك',
        icon: 'assets/img/main.png',
      ),
      Category(
        id: 'cat-004',
        shopId: shopId,
        name: 'دلال',
        icon: 'assets/img/main.png',
      ),
      Category(
        id: 'cat-005',
        shopId: shopId,
        name: 'أطقم',
        icon: 'assets/img/main.png',
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════
  // المنتجات مع الصور (Items with Images)
  // ═══════════════════════════════════════════════════════════
  static List<Item> getItems() {
    final categories = getCategories();

    return [
      // ─────── منتجات الصحون ───────
      Item(
        id: 1,
        shopId: shopId,
        categoryId: 'cat-001',
        title: 'صحن تقديم فاخر',
        description:
            'صحن تقديم من الخزف الياباني الفاخر، مثالي لتقديم الحلويات والمكسرات.',
        price: 8500,
        category: categories[0],
        images: [
          ItemImage(
            id: 101,
            itemId: 1,
            imagePath: 'assets/img/88888.png',
            sortOrder: 1,
            isPrimary: true,
          ),
          ItemImage(
            id: 102,
            itemId: 1,
            imagePath: 'assets/img/main.png',
            sortOrder: 2,
          ),
          ItemImage(
            id: 103,
            itemId: 1,
            imagePath: 'assets/img/main.png',
            sortOrder: 3,
          ),
        ],
      ),
      Item(
        id: 2,
        shopId: shopId,
        categoryId: 'cat-001',
        title: 'صحن ديكور مزخرف',
        description: 'صحن ديكور فني مزخرف يدوياً بألوان زاهية.',
        price: 12000,
        category: categories[0],
        images: [
          ItemImage(
            id: 201,
            itemId: 2,
            imagePath: 'assets/img/main.png',
            sortOrder: 1,
            isPrimary: true,
          ),
          ItemImage(
            id: 202,
            itemId: 2,
            imagePath: 'assets/img/main.png',
            sortOrder: 2,
          ),
        ],
      ),

      // ─────── منتجات الأكواب ───────
      Item(
        id: 3,
        shopId: shopId,
        categoryId: 'cat-002',
        title: 'كوب شاي كريستال',
        description: 'كوب شاي من الزجاج الكريستالي الشفاف.',
        price: 5000,
        category: categories[1],
        images: [
          ItemImage(
            id: 301,
            itemId: 3,
            imagePath: 'assets/img/main.png',
            sortOrder: 1,
            isPrimary: true,
          ),
          ItemImage(
            id: 302,
            itemId: 3,
            imagePath: 'assets/img/main.png',
            sortOrder: 2,
          ),
        ],
      ),
      Item(
        id: 4,
        shopId: shopId,
        categoryId: 'cat-002',
        title: 'كوب قهوة سيراميك',
        description: 'كوب قهوة من السيراميك بطباعة ملونة جذابة.',
        price: 7000,
        category: categories[1],
        images: [
          ItemImage(
            id: 401,
            itemId: 4,
            imagePath: 'assets/img/main.png',
            sortOrder: 1,
            isPrimary: true,
          ),
          ItemImage(
            id: 402,
            itemId: 4,
            imagePath: 'assets/img/main.png',
            sortOrder: 2,
          ),
        ],
      ),

      // ─────── منتجات الأكرلك ───────
      Item(
        id: 5,
        shopId: shopId,
        categoryId: 'cat-003',
        title: 'صينية تقديم أكرلك',
        description: 'صينية تقديم عصرية من الأكرلك الشفاف.',
        price: 15000,
        category: categories[2],
        images: [
          ItemImage(
            id: 501,
            itemId: 5,
            imagePath: 'assets/img/main.png',
            sortOrder: 1,
            isPrimary: true,
          ),
          ItemImage(
            id: 502,
            itemId: 5,
            imagePath: 'assets/img/main.png',
            sortOrder: 2,
          ),
        ],
      ),

      // ─────── منتجات الدلال ───────
      Item(
        id: 6,
        shopId: shopId,
        categoryId: 'cat-004',
        title: 'دلة تركية فاخرة',
        description:
            'دلة فاخرة بتصميم تركي أصيل، مصنوعة من النحاس المطلي بالذهب.',
        price: 10000,
        category: categories[3],
        images: [
          ItemImage(
            id: 601,
            itemId: 6,
            imagePath: 'assets/img/main.png',
            sortOrder: 1,
            isPrimary: true,
          ),
          ItemImage(
            id: 602,
            itemId: 6,
            imagePath: 'assets/img/main.png',
            sortOrder: 2,
          ),
          ItemImage(
            id: 603,
            itemId: 6,
            imagePath: 'assets/img/main.png',
            sortOrder: 3,
          ),
        ],
      ),
      Item(
        id: 7,
        shopId: shopId,
        categoryId: 'cat-004',
        title: 'دلة عربية نحاسية',
        description: 'دلة قهوة عربية تقليدية من النحاس الأصلي.',
        price: 30000,
        category: categories[3],
        images: [
          ItemImage(
            id: 701,
            itemId: 7,
            imagePath: 'assets/img/main.png',
            sortOrder: 1,
            isPrimary: true,
          ),
          ItemImage(
            id: 702,
            itemId: 7,
            imagePath: 'assets/img/main.png',
            sortOrder: 2,
          ),
        ],
      ),

      // ─────── منتجات الأطقم ───────
      Item(
        id: 8,
        shopId: shopId,
        categoryId: 'cat-005',
        title: 'طقم فناجين قهوة',
        description: 'طقم فناجين قهوة فاخر من البورسلان التركي.',
        price: 25000,
        category: categories[4],
        images: [
          ItemImage(
            id: 801,
            itemId: 8,
            imagePath: 'assets/img/main.png',
            sortOrder: 1,
            isPrimary: true,
          ),
          ItemImage(
            id: 802,
            itemId: 8,
            imagePath: 'assets/img/main.png',
            sortOrder: 2,
          ),
        ],
      ),
      Item(
        id: 9,
        shopId: shopId,
        categoryId: 'cat-005',
        title: 'طقم شاي صيني',
        description: 'طقم شاي صيني فاخر يتكون من إبريق و6 أكواب.',
        price: 45000,
        category: categories[4],
        images: [
          ItemImage(
            id: 901,
            itemId: 9,
            imagePath: 'assets/img/main.png',
            sortOrder: 1,
            isPrimary: true,
          ),
          ItemImage(
            id: 902,
            itemId: 9,
            imagePath: 'assets/img/main.png',
            sortOrder: 2,
          ),
        ],
      ),
      Item(
        id: 10,
        shopId: shopId,
        categoryId: 'cat-005',
        title: 'طقم ضيافة كامل',
        description:
            'طقم ضيافة متكامل يحتوي على دلة، فناجين، صحون تقديم، وصينية.',
        price: 75000,
        category: categories[4],
        images: [
          ItemImage(
            id: 1001,
            itemId: 10,
            imagePath: 'assets/img/main.png',
            sortOrder: 1,
            isPrimary: true,
          ),
          ItemImage(
            id: 1002,
            itemId: 10,
            imagePath: 'assets/img/main.png',
            sortOrder: 2,
          ),
        ],
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════
  // دوال مساعدة
  // ═══════════════════════════════════════════════════════════

  // جلب المنتجات حسب التصنيف
  static List<Item> getItemsByCategory(String categoryId) {
    return getItems().where((item) => item.categoryId == categoryId).toList();
  }

  // جلب المنتجات النشطة فقط
  static List<Item> getActiveItems() {
    return getItems()
        .where((item) => item.isActive && !item.isDeleted)
        .toList();
  }

  // البحث في المنتجات
  static List<Item> searchItems(String query) {
    final lowerQuery = query.toLowerCase();
    return getItems().where((item) {
      return item.title.toLowerCase().contains(lowerQuery) ||
          (item.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }
}
