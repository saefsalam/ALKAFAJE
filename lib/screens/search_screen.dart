import 'package:flutter/material.dart';
import '../utls/constants.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _items = [
    'عنصر 1',
    'عنصر 2',
    'عنصر 3',
    'عنصر 4',
    'عنصر 5',
    'عنصر 6',
    'عنصر 7',
    'عنصر 8',
  ];
  List<String> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = _items;
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = _items;
      } else {
        _filteredItems = _items
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      body: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 90.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterItems,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 18,
                ),
                decoration: InputDecoration(
                  hintText: 'ابحث هنا...',
                  hintStyle: TextStyle(
                    color: AppColors.primaryColor.withOpacity(0.6),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.primaryColor,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(15),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _filteredItems.isEmpty
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
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
                              Icons.search_off,
                              size: 60,
                              color: AppColors.primaryColor,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'لا توجد نتائج',
                              style: TextStyle(
                                color: AppColors.primaryColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.star,
                              color: AppColors.primaryColor,
                            ),
                            title: Text(
                              _filteredItems[index],
                              style: const TextStyle(
                                color: AppColors.primaryColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.right,
                            ),
                            trailing: const Icon(
                              Icons.arrow_back_ios,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
