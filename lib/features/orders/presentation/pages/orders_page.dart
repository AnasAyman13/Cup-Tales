import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/order_entity.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/language_cubit.dart';
import '../cubit/orders_cubit.dart';
import '../cubit/orders_state.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OrdersCubit()..loadOrders(),
      child: const _OrdersView(),
    );
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
  Widget build(BuildContext context) {
    context.watch<LanguageCubit>();
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home', // Using '/home' or AppRouter.home
                  (route) => false,
                ),
              )
            : null,
        title: Text(
          context.loc.navOrders,
          style:
              const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, state) {
          return Column(
            children: [
              _buildTabs(),
              const SizedBox(height: 10),
              Expanded(child: _buildBody(state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          _Tab(
            label: context.tr('Active', 'الحالية'),
            selected: _showActive,
            onTap: () => setState(() => _showActive = true),
          ),
          _Tab(
            label: context.tr('History', 'السجل'),
            selected: !_showActive,
            onTap: () => setState(() => _showActive = false),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(OrdersState state) {
    if (state is OrdersLoading || state is OrdersInitial) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2D3194)),
      );
    }

    if (state is OrdersError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(state.message,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<OrdersCubit>().loadOrders(),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D3194)),
              child: Text(context.loc.retry,
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (state is OrdersLoaded) {
      final displayed = _showActive ? state.activeOrders : state.historyOrders;

      if (displayed.isEmpty) {
        return _EmptyState(
          icon: _showActive
              ? Icons.hourglass_empty_outlined
              : Icons.receipt_long_outlined,
          label: _showActive
              ? context.tr(
                  'No active orders right now', 'لا توجد طلبات حالية الآن')
              : context.tr('No order history yet', 'لا يوجد سجل طلبات بعد'),
        );
      }

      return RefreshIndicator(
        color: const Color(0xFF2D3194),
        onRefresh: () => context.read<OrdersCubit>().loadOrders(),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          itemCount: displayed.length,
          itemBuilder: (context, index) => _OrderCard(order: displayed[index]),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

// ─── Reusable Tab ────────────────────────────────────────────────────────────

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF2D3194) : Colors.grey;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? const Color(0xFF2D3194) : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Order Card ──────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final OrderEntity order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageCubit>();
    final isActive = order.status == 'preparing';
    final shortId = order.id.length > 6 ? order.id.substring(0, 6) : order.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          Row(
            children: [
              // Icon
              SizedBox(
                height: 70,
                child: order.productImage.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          order.productImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.local_cafe,
                              color: Color(0xFF2D3194)),
                        ),
                      )
                    : const Icon(Icons.local_cafe, color: Color(0xFF2D3194)),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Status chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF2D3194).withOpacity(0.12)
                                : Colors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _translateStatus(context, order.status),
                            style: TextStyle(
                              color: isActive
                                  ? const Color(0xFF2D3194)
                                  : Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Text(
                          '#$shortId',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr(order.productName,
                          order.productNameAr ?? order.productName),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isActive
                          ? context.tr('Estimated: 8-12 mins',
                              'الوقت المتوقع: ٨-١٢ دقيقة')
                          : _formattedDate(order.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('Total Price', 'السعر الإجمالي'),
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(
                    '${order.price.toStringAsFixed(2)} ${context.loc.egp}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formattedDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _translateStatus(BuildContext context, String status) {
    if (status == 'preparing') return context.tr('PREPARING', 'قيد التحضير');
    if (status == 'completed') return context.tr('COMPLETED', 'مكتمل');
    if (status == 'cancelled') return context.tr('CANCELLED', 'ملغي');
    return status.toUpperCase();
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

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
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
