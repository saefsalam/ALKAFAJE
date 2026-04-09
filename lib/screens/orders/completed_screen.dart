import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utls/constants.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../widget/loading_animation.dart';
import 'order_detail_screen.dart';

class CompletedScreen extends StatefulWidget {
  const CompletedScreen({super.key});

  @override
  State<CompletedScreen> createState() => _CompletedScreenState();
}

class _CompletedScreenState extends State<CompletedScreen> {
  // ═══════════════════════════════════════════════════════════════════════════
  // المتغيرات
  // ═══════════════════════════════════════════════════════════════════════════

  List<Order> _completedOrders = [];
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
      final orders =
          await OrderService.getMyOrdersByStatus(['delivered', 'cancelled']);

      if (!mounted) return;
      setState(() {
        _completedOrders = orders;
        _isLoading = false;
      });
    } catch (e) {
      print('خطأ في تحميل الطلبات المكتملة: $e');
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
      return const Center(
        child: LoadingAnimation(size: 150),
      );
    }

    final completedOrders = _completedOrders;

    return completedOrders.isEmpty
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
        : RefreshIndicator(
            onRefresh: _loadOrders,
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 90),
              itemCount: completedOrders.length,
              itemBuilder: (context, index) {
                final order = completedOrders[index];
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
                    child: Row(
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
                              if (order.customerName != null)
                                Text(
                                  order.customerName!,
                                  style: GoogleFonts.cairo(
                                    color:
                                        AppColors.primaryColor.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
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
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: order.status.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                order.status.label,
                                style: GoogleFonts.cairo(
                                  color: order.status.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
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
