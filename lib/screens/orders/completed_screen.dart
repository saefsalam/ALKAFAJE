import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utls/constants.dart';

class CompletedScreen extends StatelessWidget {
  const CompletedScreen({super.key});

  final List<Map<String, String>> _completedOrders = const [
    {
      'title': 'طلب #1000',
      'date': '2026/01/20',
      'total': '25,000 د.ع',
      'items': '3 منتجات',
    },
    {
      'title': 'طلب #998',
      'date': '2026/01/15',
      'total': '42,500 د.ع',
      'items': '5 منتجات',
    },
    {
      'title': 'طلب #995',
      'date': '2026/01/10',
      'total': '18,000 د.ع',
      'items': '2 منتجات',
    },
    {
      'title': 'طلب #990',
      'date': '2026/01/05',
      'total': '60,000 د.ع',
      'items': '8 منتجات',
    },
    {
      'title': 'طلب #985',
      'date': '2025/12/28',
      'total': '33,750 د.ع',
      'items': '4 منتجات',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return _completedOrders.isEmpty
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 80,
                  color: AppColors.primaryColor.withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد طلبات مكتملة',
                  style: GoogleFonts.cairo(
                    color: AppColors.primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.only(bottom: 90),
            itemCount: _completedOrders.length,
            itemBuilder: (context, index) {
              final order = _completedOrders[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.25),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 0),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      spreadRadius: -1,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green.withOpacity(0.15),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['title']!,
                            style: GoogleFonts.cairo(
                              color: AppColors.primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                order['items']!,
                                style: GoogleFonts.cairo(
                                  color: AppColors.primaryColor.withOpacity(
                                    0.6,
                                  ),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryColor.withOpacity(
                                    0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                order['total']!,
                                style: GoogleFonts.cairo(
                                  color: Colors.green,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          order['date']!,
                          style: GoogleFonts.cairo(
                            color: AppColors.primaryColor.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'مكتمل',
                            style: GoogleFonts.cairo(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
  }
}
