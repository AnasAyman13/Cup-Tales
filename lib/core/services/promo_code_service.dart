import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Result Types ─────────────────────────────────────────────────────────────

abstract class PromoResult {
  const PromoResult();
}

class PromoValid extends PromoResult {
  final double discountAmount; // absolute EGP value to subtract
  final String code;           // the validated code string
  const PromoValid({required this.discountAmount, required this.code});
}

class PromoInvalid extends PromoResult {
  final String arabicReason;
  const PromoInvalid(this.arabicReason);
}

// ─── Service ──────────────────────────────────────────────────────────────────

class PromoCodeService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Validates a promo code against the Supabase [promo_codes] table.
  /// [subtotal] is the cart total BEFORE any discount — used to compute
  /// percentage-based discounts.
  Future<PromoResult> validate(String code, double subtotal) async {
    try {
      final trimmedCode = code.trim();
      print('DEBUG: Querying code: $trimmedCode');

      // Case-insensitive lookup
      final data = await _client
          .from('promo_codes')
          .select()
          .ilike('code', trimmedCode)
          .maybeSingle();

      print('DEBUG: Supabase response: $data');

      if (data == null) {
        print('DEBUG: Request returned null. Check RLS SELECT policy.');
        return const PromoInvalid('الكود غير صحيح');
      }

      // ── Check is_active ───────────────────────────────────────────────────
      final bool isActive = data['is_active'] as bool? ?? false;
      if (!isActive) {
        debugPrint('[PromoCodeService] is_active is false');
        return const PromoInvalid('هذا الكود غير مفعّل');
      }

      // ── Check expiry_date ─────────────────────────────────────────────────
      final String? expiryRaw = data['expiry_date'] as String?;
      if (expiryRaw != null) {
        final expiry = DateTime.tryParse(expiryRaw);
        if (expiry != null && DateTime.now().toUtc().isAfter(expiry.toUtc())) {
          debugPrint('[PromoCodeService] Code expired. Now(UTC)=${DateTime.now().toUtc()} vs Expiry(UTC)=${expiry.toUtc()}');
          return const PromoInvalid('الكود منتهي الصلاحية');
        }
      }

      // ── Check usage_limit ─────────────────────────────────────────────────
      final int usedCount = (data['used_count'] as num? ?? 0).toInt();
      final int usageLimit = (data['usage_limit'] as num? ?? 0).toInt();
      if (usageLimit > 0 && usedCount >= usageLimit) {
        return const PromoInvalid('تم الوصول للحد الأقصى لاستخدام هذا الكود');
      }

      // ── Parse discount ────────────────────────────────────────────────────
      // Supports: "80%" → percentage, "50" or 50 → fixed EGP amount
      final dynamic rawDiscount = data['discount'];
      double discountAmount = 0.0;

      if (rawDiscount is String) {
        final trimmed = rawDiscount.trim();
        if (trimmed.endsWith('%')) {
          final percent = double.tryParse(trimmed.replaceAll('%', '')) ?? 0.0;
          discountAmount = subtotal * (percent / 100);
        } else {
          discountAmount = double.tryParse(trimmed) ?? 0.0;
        }
      } else if (rawDiscount is num) {
        discountAmount = rawDiscount.toDouble();
      }

      if (discountAmount <= 0) {
        return const PromoInvalid('الكود لا يتضمن خصماً صالحاً');
      }

      // Cap discount so total never goes negative
      discountAmount = discountAmount.clamp(0.0, subtotal);

      return PromoValid(
        discountAmount: discountAmount,
        code: (data['code'] as String? ?? code).trim(),
      );
    } catch (e) {
      return const PromoInvalid('حدث خطأ أثناء التحقق من الكود');
    }
  }

  /// Increments [used_count] by 1 for the given [code].
  /// Called after a successful payment — failures are silently swallowed
  /// so they never block order confirmation.
  Future<void> incrementUsage(String code) async {
    try {
      // Fetch current count first, then update
      final data = await _client
          .from('promo_codes')
          .select('id, used_count')
          .ilike('code', code.trim())
          .maybeSingle();

      if (data == null) return;

      final int currentCount = (data['used_count'] as num? ?? 0).toInt();
      await _client
          .from('promo_codes')
          .update({'used_count': currentCount + 1})
          .eq('id', data['id'] as Object);
    } catch (_) {
      // Non-critical — don't rethrow
    }
  }
}
