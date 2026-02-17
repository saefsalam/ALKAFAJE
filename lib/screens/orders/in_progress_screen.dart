import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utls/constants.dart';

class InProgressScreen extends StatelessWidget {
  const InProgressScreen({super.key});

  final List<Map<String, String>> _inProgressOrders = const [
    {
      'title': 'طلب #1002',
      'date': '2026/02/10',
      'status': 'جاري التوصيل',
      'progress': '75',
    },
    {
      'title': 'طلب #1003',
      'date': '2026/02/12',
      'status': 'جاري التجهيز',
      'progress': '40',
    },
    {
      'title': 'طلب #1006',
      'date': '2026/02/14',
      'status': 'جاري الشحن',
      'progress': '60',
    },
    {
      'title': 'طلب #1009',
      'date': '2026/02/15',
      'status': 'تم التغليف',
      'progress': '50',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return _inProgressOrders.isEmpty
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sync_rounded,
                  size: 80,
                  color: AppColors.primaryColor.withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد طلبات جارية',
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
            itemCount: _inProgressOrders.length,
            itemBuilder: (context, index) {
              final order = _inProgressOrders[index];
              final progress = int.parse(order['progress']!) / 100;
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
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.withOpacity(0.15),
                          ),
                          child: const Icon(
                            Icons.local_shipping_rounded,
                            color: Colors.blue,
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
                              Text(
                                order['status']!,
                                style: GoogleFonts.cairo(
                                  color: Colors.blue,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          order['date']!,
                          style: GoogleFonts.cairo(
                            color: AppColors.primaryColor.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppColors.primaryColor.withOpacity(
                          0.1,
                        ),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${order['progress']}%',
                        style: GoogleFonts.cairo(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
  }
}
