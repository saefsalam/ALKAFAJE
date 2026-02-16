import 'package:flutter/material.dart';
import '../utls/constants.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final List<Map<String, dynamic>> _favorites = [
    {
      'title': 'عنصر مفضل 1',
      'subtitle': 'وصف العنصر الأول',
      'icon': Icons.favorite,
      'color': Colors.red,
    },
    {
      'title': 'عنصر مفضل 2',
      'subtitle': 'وصف العنصر الثاني',
      'icon': Icons.star,
      'color': Colors.yellow,
    },
    {
      'title': 'عنصر مفضل 3',
      'subtitle': 'وصف العنصر الثالث',
      'icon': Icons.bookmark,
      'color': Colors.green,
    },
    {
      'title': 'عنصر مفضل 4',
      'subtitle': 'وصف العنصر الرابع',
      'icon': Icons.thumb_up,
      'color': Colors.blue,
    },
  ];

  void _removeItem(int index) {
    setState(() {
      _favorites.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم الحذف من المفضلة'),
        backgroundColor: AppColors.primaryColor.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      body: _favorites.isEmpty
          ? Padding(
              padding: const EdgeInsets.only(bottom: 90.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(30),
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite_border_rounded,
                        size: 100,
                        color: AppColors.primaryColor,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'لا توجد عناصر في المفضلة',
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'ابدأ بإضافة العناصر المفضلة لديك',
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
              itemCount: _favorites.length,
              itemBuilder: (context, index) {
                final item = _favorites[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Dismissible(
                    key: Key(item['title']),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) => _removeItem(index),
                    background: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.delete_rounded,
                        color: Colors.white,
                        size: 35,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(15),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: item['color'].withOpacity(0.3),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: item['color'].withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          item['icon'],
                          color: AppColors.primaryColor,
                          size: 30,
                        ),
                      ),
                      title: Text(
                        item['title'],
                        style: const TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      subtitle: Text(
                        item['subtitle'],
                        style: TextStyle(
                          color: AppColors.primaryColor.withOpacity(0.7),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.favorite,
                          color: AppColors.primaryColor,
                          size: 28,
                        ),
                        onPressed: () => _removeItem(index),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
