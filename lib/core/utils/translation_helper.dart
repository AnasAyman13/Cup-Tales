import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

class TranslationHelper {
  /// Translates product names from English to Arabic with specific mappings.
  static String translateProductName(BuildContext context, String name, String? nameAr) {
    if (nameAr != null && nameAr.isNotEmpty) return nameAr;

    final upper = name.toUpperCase().trim();
    
    // Specific Mappings
    if (upper == 'ICED CAPPUCCINO') return 'آيس كابتشينو';
    if (upper == 'CARAMEL') return 'كراميل';
    if (upper == 'MINT LEMON') return 'ليمون نعناع';
    if (upper == 'MANGO') return 'مانجو فريش';
    
    // Generic contains mappings
    if (upper.contains('ORANGE')) return 'برتقال فريش';
    if (upper.contains('STRAWBERRY')) return 'فراولة فريش';
    if (upper.contains('COFFEE')) return 'قهوة';
    if (upper.contains('TEA')) return 'شاي';

    return name;
  }

  /// Translates order statuses to Arabic.
  static String translateStatus(BuildContext context, String status) {
    final s = status.toLowerCase().trim();
    
    if (s == 'preparing') return 'جاري التحضير';
    if (s == 'paid') return 'تم الدفع';
    if (s == 'completed') return 'تم الاستلام';
    
    // Fallbacks for other statuses
    if (s == 'pending') return context.tr('PENDING', 'قيد الانتظار');
    if (s == 'ready') return context.tr('READY', 'جاهز للاستلام');
    if (s == 'delivered') return context.tr('DELIVERED', 'تم التسليم');
    if (s == 'cancelled') return context.tr('CANCELLED', 'ملغي');
    
    return status.toUpperCase();
  }
}
