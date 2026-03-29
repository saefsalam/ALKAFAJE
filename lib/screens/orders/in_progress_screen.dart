import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utls/constants.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import 'order_detail_screen.dart';

class InProgressScreen extends StatefulWidget {
  const InProgressScreen({super.key});

  @override
  State<InProgressScreen> createState() => _InProgressScreenState();
}

class _InProgressScreenState extends State<InProgressScreen> {
  // ═══════════════════════════════════════════════════════════════════════════
  // المتغيرات
  // ═══════════════════════════════════════════════════════════════════════════

  List<Order> _inProgressOrders = [];
  bool _isLoading = true;

  // ═══════════════════════════════════════════════════════════════════════════
  // تحميل البيانات
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final orders = await OrderService.getMyOrdersByStatus(['confirmed', 'preparing', 'shipped']);

      if (!mounted) return;
      setState(() {
        _inProgressOrders = orders;
        _isLoading = false;
      });
    } catch (e) {
      print('خطأ في تحميل الطلبات الجارية: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // الواجهة
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      );
    }

    final inProgressOrders = _inProgressOrders;

    return inProgressOrders.isEmpty
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
        : RefreshIndicator(
          onRefresh: _loadOrders,
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 90),
            itemCount: inProgressOrders.length,
            itemBuilder: (context, index) {
              final order = inProgressOrders[index];
              final dateFormat = DateFormat('yyyy/MM/dd');
              return GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailScreen(orderId: order.id),
                    ),
                  );
                  _loadOrders();
                },
                child: Container(
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
                            color: order.status.color.withOpacity(0.15),
                          ),
                          child: Icon(
                            order.status.icon,
                            color: order.status.color,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'طلب #${order.id}',
                                style: GoogleFonts.cairo(
                                  color: AppColors.primaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                order.status.label,
                                style: GoogleFonts.cairo(
                                  color: order.status.color,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (order.customerName != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  order.customerName!,
                                  style: GoogleFonts.cairo(
                                    color: AppColors.primaryColor.withOpacity(
                                      0.6,
                                    ),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              dateFormat.format(order.createdAt),
                              style: GoogleFonts.cairo(
                                color: AppColors.primaryColor.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${order.total.toStringAsFixed(0)} د.ع',
                              style: GoogleFonts.cairo(
                                color: order.status.color,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: order.status.progress,
                        minHeight: 8,
                        backgroundColor: AppColors.primaryColor.withOpacity(
                          0.1,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          order.status.color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${(order.status.progress * 100).toInt()}%',
                        style: GoogleFonts.cairo(
                          color: order.status.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              );
            },
          ),
        );
  }
}
