import '../models/product_model.dart';

// ═══════════════════════════════════════════════════════════
// البيانات الوهمية (Mock Data) - بناءً على السكيما الفعلية
// ═══════════════════════════════════════════════════════════

class MockData {
  // معرف المتجر الوهمي
  static const String shopId = 'shop-alkafajy-001';

  // ═══════════════════════════════════════════════════════════
  // بيانات المتجر (Shop)
  // ═══════════════════════════════════════════════════════════
  static Shop getShop() {
    return Shop(
      id: shopId,
      displayName: 'الكفاجي',
      phone: '+964 770 123 4567',
      address: 'بغداد، العراق - شارع الرشيد',
      primaryColor: '#312F92',
      logoUrl: 'assets/img/main.png',
      primaryLanguage: 'ar',
      facebookUrl: 'https://facebook.com/alkafajy',
      instagramUrl: 'https://instagram.com/alkafajy',
    );
  }

  // ═══════════════════════════════════════════════════════════
  // إعلانات البانر (Banner Ads) - يتحكم بها الأدمن
  // ═══════════════════════════════════════════════════════════
  static List<BannerAd> getBannerAds() {
    return [
      BannerAd(
        id: 1,
        shopId: shopId,
        imagePath: 'assets/img/main.png',
        sortOrder: 1,
        isActive: true,
      ),
      BannerAd(
        id: 2,
        shopId: shopId,
        imagePath: 'assets/img/main.png',
        sortOrder: 2,
        isActive: true,
      ),
      BannerAd(
        id: 3,
        shopId: shopId,
        imagePath: 'assets/img/main.png',
        sortOrder: 3,
        isActive: true,
      ),
    ];
  }

  // جلب البانرات النشطة فقط
  static List<BannerAd> getActiveBannerAds() {
    return getBannerAds().where((banner) => banner.isActive).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  // ═══════════════════════════════════════════════════════════
  // مناطق التوصيل (Delivery Zones) - يتحكم بها الأدمن
  // ═══════════════════════════════════════════════════════════
  static List<DeliveryZone> getDeliveryZones() {
    return [
      DeliveryZone(id: 1, shopId: shopId, city: 'بغداد - الكرخ', price: 5000),
      DeliveryZone(id: 2, shopId: shopId, city: 'بغداد - الرصافة', price: 5000),
      DeliveryZone(id: 3, shopId: shopId, city: 'البصرة', price: 10000),
      DeliveryZone(id: 4, shopId: shopId, city: 'أربيل', price: 15000),
      DeliveryZone(id: 5, shopId: shopId, city: 'النجف', price: 8000),
      DeliveryZone(id: 6, shopId: shopId, city: 'كربلاء', price: 8000),
      DeliveryZone(id: 7, shopId: shopId, city: 'الموصل', price: 12000),
      DeliveryZone(id: 8, shopId: shopId, city: 'السليمانية', price: 15000),
    ];
  }

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
        tags: [ItemTag.bestSeller],
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
        discountPrice: 9000,
        discountPercent: 25,
        tags: [ItemTag.discount],
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
        tags: [ItemTag.newArrival],
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
        discountPrice: 5500,
        discountPercent: 21,
        tags: [ItemTag.discount, ItemTag.ramadan],
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
        tags: [ItemTag.featured],
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
        tags: [ItemTag.ramadan, ItemTag.featured],
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
        discountPrice: 22000,
        discountPercent: 27,
        tags: [ItemTag.discount, ItemTag.ramadan],
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
        tags: [ItemTag.ramadan],
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
        discountPrice: 35000,
        discountPercent: 22,
        tags: [ItemTag.discount, ItemTag.bestSeller],
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
        tags: [ItemTag.ramadan, ItemTag.featured],
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

      // ─────── منتجات رمضان الإضافية ───────
      Item(
        id: 11,
        shopId: shopId,
        categoryId: 'cat-004',
        title: 'طقم دلال رمضان',
        description: 'طقم دلال خاص بشهر رمضان المبارك، تصميم تقليدي فاخر.',
        price: 55000,
        discountPrice: 45000,
        discountPercent: 18,
        tags: [ItemTag.ramadan, ItemTag.discount, ItemTag.limitedOffer],
        category: categories[3],
        images: [
          ItemImage(
            id: 1101,
            itemId: 11,
            imagePath: 'assets/img/main.png',
            sortOrder: 1,
            isPrimary: true,
          ),
        ],
      ),
      Item(
        id: 12,
        shopId: shopId,
        categoryId: 'cat-001',
        title: 'صحون تمر رمضان',
        description: 'صحون تقديم خاصة للتمر في شهر رمضان.',
        price: 18000,
        tags: [ItemTag.ramadan, ItemTag.newArrival],
        category: categories[0],
        images: [
          ItemImage(
            id: 1201,
            itemId: 12,
            imagePath: 'assets/img/main.png',
            sortOrder: 1,
            isPrimary: true,
          ),
        ],
      ),
      Item(
        id: 13,
        shopId: shopId,
        categoryId: 'cat-002',
        title: 'فناجين قهوة رمضان',
        description: 'طقم فناجين قهوة بتصميم رمضاني مميز.',
        price: 22000,
        discountPrice: 17000,
        discountPercent: 23,
        tags: [ItemTag.ramadan, ItemTag.discount],
        category: categories[1],
        images: [
          ItemImage(
            id: 1301,
            itemId: 13,
            imagePath: 'assets/img/main.png',
            sortOrder: 1,
            isPrimary: true,
          ),
        ],
      ),

      // ─────── منتجات التخفيضات الإضافية ───────
      Item(
        id: 14,
        shopId: shopId,
        categoryId: 'cat-003',
        title: 'صينية أكرلك دائرية',
        description: 'صينية تقديم أكرلك شفافة بتصميم دائري أنيق.',
        price: 12000,
        discountPrice: 8500,
        discountPercent: 29,
        tags: [ItemTag.discount],
        category: categories[2],
        images: [
          ItemImage(
            id: 1401,
            itemId: 14,
            imagePath: 'assets/img/main.png',
            sortOrder: 1,
            isPrimary: true,
          ),
        ],
      ),
      Item(
        id: 15,
        shopId: shopId,
        categoryId: 'cat-001',
        title: 'صحن سيراميك ملون',
        description: 'صحن سيراميك بألوان زاهية وتصميم عصري.',
        price: 9500,
        discountPrice: 6000,
        discountPercent: 37,
        tags: [ItemTag.discount, ItemTag.limitedOffer],
        category: categories[0],
        images: [
          ItemImage(
            id: 1501,
            itemId: 15,
            imagePath: 'assets/img/main.png',
            sortOrder: 1,
            isPrimary: true,
          ),
        ],
      ),
      Item(
        id: 16,
        shopId: shopId,
        categoryId: 'cat-005',
        title: 'طقم ضيافة صغير',
        description: 'طقم ضيافة مكون من دلة صغيرة و4 فناجين.',
        price: 35000,
        discountPrice: 25000,
        discountPercent: 29,
        tags: [ItemTag.discount, ItemTag.bestSeller],
        category: categories[4],
        images: [
          ItemImage(
            id: 1601,
            itemId: 16,
            imagePath: 'assets/img/main.png',
            sortOrder: 1,
            isPrimary: true,
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

  // ═══════════════════════════════════════════════════════════
  // دوال الأقسام الخاصة (يتحكم بها الأدمن)
  // ═══════════════════════════════════════════════════════════

  /// جلب منتجات التخفيضات
  static List<Item> getDiscountedItems() {
    return getItems()
        .where((item) => item.hasDiscount && item.isActive && !item.isDeleted)
        .toList();
  }

  /// جلب منتجات رمضان
  static List<Item> getRamadanItems() {
    return getItems()
        .where((item) => item.isRamadan && item.isActive && !item.isDeleted)
        .toList();
  }

  /// جلب المنتجات الجديدة
  static List<Item> getNewArrivals() {
    return getItems()
        .where((item) => item.isNew && item.isActive && !item.isDeleted)
        .toList();
  }

  /// جلب المنتجات المميزة
  static List<Item> getFeaturedItems() {
    return getItems()
        .where((item) => item.isFeatured && item.isActive && !item.isDeleted)
        .toList();
  }

  /// جلب المنتجات الأكثر مبيعاً
  static List<Item> getBestSellers() {
    return getItems()
        .where((item) => item.isBestSeller && item.isActive && !item.isDeleted)
        .toList();
  }

  /// جلب المنتجات حسب تاغ معين
  static List<Item> getItemsByTag(ItemTag tag) {
    return getItems()
        .where(
          (item) => item.tags.contains(tag) && item.isActive && !item.isDeleted,
        )
        .toList();
  }

  // ═══════════════════════════════════════════════════════════
  // البارتات (Parts) - أقسام الواجهة الرئيسية - يتحكم بها الأدمن
  // ═══════════════════════════════════════════════════════════

  /// جلب جميع البارتات مع منتجاتها
  static List<Part> getParts() {
    final allItems = getItems();

    return [
      Part(
        id: 1,
        shopId: shopId,
        name: 'عروض رمضان',
        sortOrder: 1,
        isActive: true,
        items: [
          allItems[0],
          allItems[3],
          allItems[6],
          allItems[9],
        ], // منتجات رمضان
      ),
      Part(
        id: 2,
        shopId: shopId,
        name: 'تخفيضات',
        sortOrder: 2,
        isActive: true,
        items: [
          allItems[1],
          allItems[4],
          allItems[7],
          allItems[10],
        ], // منتجات التخفيضات
      ),
      Part(
        id: 3,
        shopId: shopId,
        name: 'الأكثر مبيعاً',
        sortOrder: 3,
        isActive: true,
        items: [
          allItems[2],
          allItems[5],
          allItems[8],
          allItems[11],
        ], // الأكثر مبيعاً
      ),
      Part(
        id: 4,
        shopId: shopId,
        name: 'وصل حديثاً',
        sortOrder: 4,
        isActive: true,
        items: [allItems[12], allItems[13], allItems[14], allItems[15]], // جديد
      ),
      Part(
        id: 5,
        shopId: shopId,
        name: 'عروض محدودة',
        sortOrder: 5,
        isActive: false, // غير فعال - مثال على بارت موقوف
        items: [allItems[0], allItems[1]],
      ),
    ];
  }

  /// جلب البارتات النشطة فقط مرتبة حسب sortOrder
  static List<Part> getActiveParts() {
    return getParts().where((part) => part.isActive).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// جلب بارت معين بالـ id
  static Part? getPartById(int id) {
    try {
      return getParts().firstWhere((part) => part.id == id);
    } catch (e) {
      return null;
    }
  }
}
