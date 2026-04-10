import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/order_item_entity.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/language_cubit.dart';
import '../../../../core/utils/translation_helper.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/orders_cubit.dart';
import '../cubit/orders_state.dart';
import '../../../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../../../core/widgets/antigravity_loader.dart';

// ─── Brand constants shared across all widgets in this file ──────────────────
const _kPrimary = Color(0xFF2D3194);
const _kBg = Color(0xFFF3F4F8);

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _OrdersView();
  }
}

class _OrdersView extends StatefulWidget {
  const _OrdersView();

  @override
  State<_OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<_OrdersView> {
  bool _showActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OrdersCubit>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageCubit>();
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                ),
              )
            : null,
        title: Text(
          context.loc.navOrders,
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, state) => _buildBody(state),
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────

  Widget _buildBody(OrdersState state) {
    if (state is OrdersLoading || state is OrdersInitial) {
      return const Center(
        child: AntigravityLoaderCore(size: 80),
      );
    }

    if (state is OrdersError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 52, color: Colors.red.shade300),
              const SizedBox(height: 12),
              Text(state.message,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => context.read<OrdersCubit>().loadOrders(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                label: Text(context.loc.retry,
                    style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (state is OrdersLoaded) {
      // Task 2: Combine both active and history into a single list
      final displayed = [...state.activeOrders, ...state.historyOrders];

      if (displayed.isEmpty) {
        return _EmptyState(
          icon: Icons.receipt_long_rounded,
          label: context.tr('No orders yet', 'لا توجد طلبات بعد'),
        );
      }

      return RefreshIndicator(
        color: _kPrimary,
        onRefresh: () => context.read<OrdersCubit>().loadOrders(),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: displayed.length,
          itemBuilder: (context, index) =>
              _OrderCard(order: displayed[index]),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

// Removes the _Tab completely because it's no longer used

// ─── Order Card (Receipt-style) ───────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final OrderEntity order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageCubit>();
    if (order.items.isEmpty) return const SizedBox.shrink();

    final shortId = order.id.length > 8 ? order.id.substring(0, 8) : order.id;
    final isAr = context.loc.isAr;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Order ID + Status ──────────────────────────────────────
          _buildHeader(context, shortId, isAr),

          // ── Meta: Date + Branch ────────────────────────────────────────────
          _buildMeta(context, isAr),

          // ── Dashed separator ──────────────────────────────────────────────
          _DashedDivider(),

          // ── Item list ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                for (final item in order.items) ...[
                  _ItemRow(item: item, isAr: isAr),
                  if (item != order.items.last)
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                ],
              ],
            ),
          ),

          // ── Dashed separator ──────────────────────────────────────────────
          _DashedDivider(),

          // ── Footer: Total ─────────────────────────────────────────────────
          _buildFooter(context),

          // ── Reorder Button ────────────────────────────────────────────────
          _buildReorderButton(context),
        ],
      ),
    );
  }

  // ── Sub-builders ──────────────────────────────────────────────────────────

  Widget _buildReorderButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            final cartCubit = context.read<CartCubit>();

            // Call the batch method (fire-and-forget) to prevent UI flicker
            cartCubit.replaceCartWithItems(order.items);

            // Navigate instantaneously for a completely snappy feel
            Navigator.pushNamed(context, '/checkout');
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: _kPrimary,
            side: const BorderSide(color: _kPrimary, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          icon: const Icon(Icons.replay_rounded, size: 18),
          label: Text(
            context.tr('Reorder', 'اطلب مرة أخرى'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String shortId, bool isAr) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Order ID badge
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded,
                  size: 16, color: _kPrimary),
              const SizedBox(width: 6),
              Text(
                '#$shortId',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          // Status chip
          _StatusChip(status: order.status),
        ],
      ),
    );
  }

  Widget _buildMeta(BuildContext context, bool isAr) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          const Icon(Icons.storefront_rounded, size: 13, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            _getBranchName(context, order.branchName),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.calendar_today_rounded,
              size: 12, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            _formattedDate(order.createdAt),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final hasDiscount =
        order.discountAmount > 0 || order.promoCode != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          if (hasDiscount) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('Discount', 'الخصم'),
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                Text(
                  '- ${order.discountAmount.toStringAsFixed(2)} ${context.loc.egp}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('Order Total', 'إجمالي الطلب'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${order.totalAmount.toStringAsFixed(2)} ${context.loc.egp}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: _kPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formattedDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  static const Map<String, String> _branchArMap = {
    'rehab': 'فرع الرحاب',
    'mahalla1': 'فرع المحلة 1 - طريق طنطا',
    'mahalla2': 'فرع المحلة 2 - ش رضا حافظ',
  };
  static const Map<String, String> _branchEnMap = {
    'rehab': 'Rehab Branch',
    'mahalla1': 'Mahalla Branch 1 (Tanta Road)',
    'mahalla2': 'Mahalla Branch 2 (Reda Hafez St)',
  };

  String _getBranchName(BuildContext context, String branchId) {
    // Task 5: Force Arabic branch names globally, regardless of locale.
    if (branchId.isEmpty) {
      return 'فرع كب تيلز';
    }
    return _branchArMap[branchId] ?? branchId;
  }
}

// ─── Status Chip ─────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    final Color bg;
    final Color fg;

    switch (s) {
      case 'preparing':
      case 'paid':
        bg = _kPrimary.withValues(alpha: 0.10);
        fg = _kPrimary;
        break;
      case 'completed':
      case 'delivered':
        bg = Colors.green.withValues(alpha: 0.12);
        fg = Colors.green.shade700;
        break;
      case 'pending':
        bg = Colors.amber.withValues(alpha: 0.14);
        fg = Colors.amber.shade900;
        break;
      case 'ready':
        bg = Colors.teal.withValues(alpha: 0.12);
        fg = Colors.teal.shade700;
        break;
      case 'cancelled':
        bg = Colors.red.withValues(alpha: 0.12);
        fg = Colors.red.shade700;
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.12);
        fg = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        TranslationHelper.translateStatus(context, status),
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Item Row (Receipt line) ──────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  final OrderItemEntity item;
  final bool isAr;

  const _ItemRow({required this.item, required this.isAr});

  String _sizeLabel(String? size) {
    if (size == null || size.trim().isEmpty) return isAr ? 'وسط' : 'M';
    switch (size.toUpperCase()) {
      case 'S':
        return isAr ? 'صغير' : 'S';
      case 'M':
        return isAr ? 'وسط' : 'M';
      case 'L':
        return isAr ? 'كبير' : 'L';
      case 'XL':
        return isAr ? 'XL' : 'XL';
      default:
        return size;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = item.displayName(isAr);
    final sizeLabel = _sizeLabel(item.selectedSize);
    final options = item.selectedOptions;
    final optionStr = options.isNotEmpty
        ? ' · ${options.map((o) => TranslationHelper.translateOption(context, o)).join(', ')}'
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Thumbnail ────────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 48,
              height: 48,
              child: item.hasImage
                  ? Transform.scale(
                      scale: 1.3, // Task 1: Zoom in to crop out text
                      child: Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _PlaceholderIcon(),
                      ),
                    )
                  : _PlaceholderIcon(),
            ),
          ),
          const SizedBox(width: 12),

          // ── Name + size + options ────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quantity badge + name on same line
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Qty pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.quantity}×',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _kPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        '$name ($sizeLabel)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                if (optionStr.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    optionStr,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 4),

                // Unit price × qty = line total
                Row(
                  children: [
                    Text(
                      '${item.unitPrice.toStringAsFixed(2)} ${context.loc.egp}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                    if (item.quantity > 1) ...[
                      Text(
                        '  ×${item.quantity}  =  ',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade400),
                      ),
                      Text(
                        '${item.totalPrice.toStringAsFixed(2)} ${context.loc.egp}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper: image placeholder
class _PlaceholderIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0F0F5),
      child: const Icon(Icons.local_cafe_rounded,
          color: _kPrimary, size: 22),
    );
  }
}

// ─── Dashed Divider ───────────────────────────────────────────────────────────

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const dashWidth = 6.0;
          const dashGap = 4.0;
          final count =
              (constraints.maxWidth / (dashWidth + dashGap)).floor();
          return Row(
            children: List.generate(count, (_) {
              return Padding(
                padding: const EdgeInsets.only(right: dashGap),
                child: SizedBox(
                  width: dashWidth,
                  height: 1,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(color: Color(0xFFDDDDDD)),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;

  const _EmptyState({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageCubit>();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 52, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 20),
          Text(
            label,
            style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 15,
                fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
