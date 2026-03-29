import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utls/constants.dart';
import '../../services/order_service.dart';
import '../../models/order_model.dart';

// ═══════════════════════════════════════════════════════════════════════════
// شاشة تفاصيل الطلب
// ═══════════════════════════════════════════════════════════════════════════

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? _orderData;
  bool _isLoading = true;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() => _isLoading = true);

    final data = await OrderService.getOrderDetails(widget.orderId);

    if (mounted) {
      setState(() {
        _orderData = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'إلغاء الطلب',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          'هل أنت متأكد من إلغاء الطلب #${widget.orderId}؟',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('لا', style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'نعم، إلغاء',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCancelling = true);

    final result = await OrderService.cancelOrder(widget.orderId);

    setState(() => _isCancelling = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ?? '',
            style: GoogleFonts.cairo(),
            textAlign: TextAlign.center,
          ),
          backgroundColor:
              result['success'] == true ? Colors.green : Colors.red,
        ),
      );

      if (result['success'] == true) {
        _loadOrderDetails(); // إعادة تحميل التفاصيل
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'طلب #${widget.orderId}',
          style: GoogleFonts.cairo(
            color: AppColors.primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primaryColor),
            onPressed: _loadOrderDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            )
          : _orderData == null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'تعذر تحميل تفاصيل الطلب',
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadOrderDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: Text(
              'إعادة المحاولة',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final order = _orderData!['order'] as Map<String, dynamic>;
    final items = _orderData!['items'] as List;
    final statusHistory = _orderData!['status_history'] as List;

    final status = OrderStatusExtension.fromString(order['status'] ?? 'pending');
    final customer = order['customers'] as Map<String, dynamic>?;
    final dateFormat = DateFormat('yyyy/MM/dd - hh:mm a');
    final createdAt = DateTime.parse(order['created_at']);

    return RefreshIndicator(
      onRefresh: _loadOrderDetails,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── حالة الطلب ───
            _buildStatusCard(status, createdAt, dateFormat),

            const SizedBox(height: 16),

            // ─── شريط التقدم ───
            if (status.isActive) ...[
              _buildProgressBar(status),
              const SizedBox(height: 16),
            ],

            // ─── عناصر الطلب ───
            _buildItemsCard(items),

            const SizedBox(height: 16),

            // ─── معلومات التوصيل ───
            _buildDeliveryInfoCard(order, customer),

            const SizedBox(height: 16),

            // ─── ملخص الأسعار ───
            _buildPriceCard(order),

            // ─── ملاحظات ───
            if (order['note'] != null && (order['note'] as String).isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildNoteCard(order['note']),
            ],

            // ─── سجل الحالات ───
            if (statusHistory.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildStatusHistoryCard(statusHistory),
            ],

            // ─── زر إلغاء الطلب ───
            if (status == OrderStatus.pending) ...[
              const SizedBox(height: 20),
              _buildCancelButton(),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ─── بطاقة حالة الطلب ──────────────────────────────────────────────

  Widget _buildStatusCard(
      OrderStatus status, DateTime createdAt, DateFormat dateFormat) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: status.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(status.icon, color: status.color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.label,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: status.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateFormat.format(createdAt),
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: status.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '#${widget.orderId}',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: status.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── شريط التقدم ──────────────────────────────────────────────────

  Widget _buildProgressBar(OrderStatus status) {
    final steps = [
      {'label': 'قيد الانتظار', 'status': OrderStatus.pending},
      {'label': 'مؤكد', 'status': OrderStatus.confirmed},
      {'label': 'قيد التحضير', 'status': OrderStatus.preparing},
      {'label': 'تم الشحن', 'status': OrderStatus.shipped},
      {'label': 'تم التوصيل', 'status': OrderStatus.delivered},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تتبع الطلب',
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final stepStatus = step['status'] as OrderStatus;
            final isCompleted = status.index >= stepStatus.index;
            final isCurrent = status == stepStatus;
            final isLast = index == steps.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الخط والنقطة
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? status.color
                            : Colors.grey[300],
                        border: isCurrent
                            ? Border.all(
                                color: status.color.withOpacity(0.3),
                                width: 3,
                              )
                            : null,
                      ),
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 30,
                        color: isCompleted
                            ? status.color.withOpacity(0.5)
                            : Colors.grey[300],
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // النص
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    step['label'] as String,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isCompleted
                          ? AppColors.primaryColor
                          : Colors.grey[400],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ─── بطاقة العناصر ────────────────────────────────────────────────

  Widget _buildItemsCard(List items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              children: [
                Icon(Icons.shopping_bag_outlined,
                    color: AppColors.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'المنتجات (${items.length})',
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...items.map((item) {
            final title =
                item['title_snapshot'] ?? item['items']?['title'] ?? 'منتج';
            final quantity = item['quantity'] as int;
            final unitPrice = (item['unit_price'] as num).toDouble();
            final lineTotal = (item['line_total'] as num).toDouble();

            // الصورة
            String? imagePath;
            final itemData = item['items'];
            if (itemData != null) {
              final images = itemData['item_images'] as List?;
              if (images != null && images.isNotEmpty) {
                imagePath = images.firstWhere(
                  (img) => img['is_primary'] == true,
                  orElse: () => images.first,
                )['image_path'];
              }
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  // الصورة
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: imagePath != null && imagePath.isNotEmpty
                          ? (imagePath.startsWith('http')
                              ? CachedNetworkImage(
                                  imageUrl: imagePath,
                                  fit: BoxFit.cover,
                                  errorWidget: (c, u, e) => _imagePlaceholder(),
                                )
                              : _imagePlaceholder())
                          : _imagePlaceholder(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // التفاصيل
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${unitPrice.toStringAsFixed(0)} د.ع × $quantity',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${lineTotal.toStringAsFixed(0)} د.ع',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Icon(Icons.image, size: 24, color: Colors.grey[400]),
    );
  }

  // ─── بطاقة معلومات التوصيل ─────────────────────────────────────────

  Widget _buildDeliveryInfoCard(
      Map<String, dynamic> order, Map<String, dynamic>? customer) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping_outlined,
                  color: AppColors.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'معلومات التوصيل',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          const Divider(),
          if (customer != null) ...[
            _buildInfoRow(Icons.person_outline, 'الاسم', customer['name'] ?? ''),
            _buildInfoRow(Icons.phone_outlined, 'الهاتف', customer['phone'] ?? ''),
            if (customer['city'] != null)
              _buildInfoRow(Icons.location_city_outlined, 'المنطقة', customer['city']),
            if (customer['address'] != null)
              _buildInfoRow(Icons.home_outlined, 'العنوان', customer['address']),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── بطاقة الأسعار ────────────────────────────────────────────────

  Widget _buildPriceCard(Map<String, dynamic> order) {
    final subtotal = (order['subtotal'] as num).toDouble();
    final deliveryFee = (order['delivery_fee'] as num).toDouble();
    final total = (order['total'] as num).toDouble();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPriceRow('المنتجات', '${subtotal.toStringAsFixed(0)} د.ع'),
          const SizedBox(height: 6),
          _buildPriceRow(
            'التوصيل',
            deliveryFee == 0
                ? 'مجاني'
                : '${deliveryFee.toStringAsFixed(0)} د.ع',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),
          _buildPriceRow(
            'الإجمالي',
            '${total.toStringAsFixed(0)} د.ع',
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isBold ? AppColors.primaryColor : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: isBold ? 17 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? AppColors.primaryColor : Colors.black87,
          ),
        ),
      ],
    );
  }

  // ─── بطاقة الملاحظات ──────────────────────────────────────────────

  Widget _buildNoteCard(String note) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.note_outlined, color: Colors.amber[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ملاحظات',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[800],
                  ),
                ),
                Text(
                  note,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: Colors.amber[900],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── سجل الحالات ──────────────────────────────────────────────────

  Widget _buildStatusHistoryCard(List statusHistory) {
    final timeFormat = DateFormat('hh:mm a');
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: AppColors.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'سجل الحالات',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          const Divider(),
          ...statusHistory.reversed.map((entry) {
            final entryStatus =
                OrderStatusExtension.fromString(entry['status'] ?? 'pending');
            final entryDate = DateTime.parse(entry['created_at']);
            final notes = entry['notes'] as String?;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: entryStatus.color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entryStatus.label,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: entryStatus.color,
                          ),
                        ),
                        if (notes != null && notes.isNotEmpty)
                          Text(
                            notes,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        dateFormat.format(entryDate),
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                      Text(
                        timeFormat.format(entryDate),
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── زر إلغاء الطلب ──────────────────────────────────────────────

  Widget _buildCancelButton() {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: _isCancelling ? null : _cancelOrder,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isCancelling
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.red,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'إلغاء الطلب',
                    style: GoogleFonts.cairo(
                      color: Colors.red,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
