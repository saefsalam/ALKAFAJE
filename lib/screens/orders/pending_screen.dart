import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utls/constants.dart';

class PendingScreen extends StatelessWidget {
  const PendingScreen({super.key});

  final List<Map<String, String>> _pendingOrders = const [
    {'title': 'طلب #1001', 'date': '2026/02/15', 'status': 'بانتظار الموافقة'},
    {'title': 'طلب #1005', 'date': '2026/02/16', 'status': 'بانتظار الدفع'},
    {'title': 'طلب #1008', 'date': '2026/02/17', 'status': 'بانتظار التأكيد'},
  ];

  @override
  Widget build(BuildContext context) {
    return _pendingOrders.isEmpty
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.hourglass_empty_rounded,
                  size: 80,
                  color: AppColors.primaryColor.withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد طلبات قيد الانتظار',
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
            itemCount: _pendingOrders.length,
            itemBuilder: (context, index) {
              final order = _pendingOrders[index];
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
                        color: Colors.orange.withOpacity(0.15),
                      ),
                      child: const Icon(
                        Icons.hourglass_top_rounded,
                        color: Colors.orange,
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
                              color: Colors.orange,
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
              );
            },
          );
  }
}
