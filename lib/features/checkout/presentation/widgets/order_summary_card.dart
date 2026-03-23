import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/translation_helper.dart';

class OrderSummaryCard extends StatelessWidget {
  final List<dynamic> items;
  final double subtotal;
  final double total;
  final double promoDiscount;
  final String? appliedPromo;

  const OrderSummaryCard({
    super.key,
    required this.items,
    required this.subtotal,
    required this.total,
    this.promoDiscount = 0.0,
    this.appliedPromo,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasPromo = promoDiscount > 0 && appliedPromo != null;
    final double finalTotal = total - promoDiscount;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.03),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Text(
              context.tr('Order Summary', 'ملخص الطلب'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          // ── Body ────────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Detailed Item List
                ...items.map((item) {
                  final String name = item.productName ?? '';
                  final String? nameAr = item.productNameAr;
                  final int qty = item.quantity ?? 1;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${qty}x ${TranslationHelper.translateProductName(context, name, nameAr)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '${((item.price ?? 0.0) * qty).toStringAsFixed(2)} ${context.loc.egp}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Divider(height: 1),
                ),

                _buildSummaryRow(
                  context.tr('Subtotal', 'المجموع الفرعي'),
                  '${subtotal.toStringAsFixed(2)} ${context.loc.egp}',
                  isBold: false,
                ),
                // Promo discount row — shown only when a code is applied
                if (hasPromo) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_offer_rounded,
                              size: 15, color: Colors.green),
                          const SizedBox(width: 6),
                          Text(
                            'خصم ($appliedPromo)',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '- ${promoDiscount.toStringAsFixed(2)} ${context.loc.egp}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Divider(height: 1),
                ),
                _buildSummaryRow(
                  context.loc.total,
                  '${finalTotal.toStringAsFixed(2)} ${context.loc.egp}',
                  isBold: true,
                  color: hasPromo ? Colors.green : AppColors.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value,
      {bool isBold = false, Color? color, double size = 15}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: size,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color ?? Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: size,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w800,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}


