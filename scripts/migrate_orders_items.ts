/**
 * =============================================================================
 * Cup Tales — Orders Items Migration Script
 * =============================================================================
 *
 * PURPOSE:
 * Normalizes the messy historical data inside the `orders.items` JSONB column.
 * Maps every possible legacy key variation to the new canonical schema.
 *
 * NEW CANONICAL ITEM SCHEMA:
 * {
 * product_id      : string        // fallback: ""
 * product_name_en : string        // from product_name / name
 * product_name_ar : string | null // from product_name_ar, fallback null
 * unit_price      : number        // from price, or total_amount / quantity
 * quantity        : number        // fallback: 1
 * total_price     : number        // from total_amount, or unit_price * quantity
 * image_url       : string | null // from image / product_image / imageUrl
 * selected_size   : string | null // from selected_size / size
 * selected_options: any[]         // from selected_options / options, fallback []
 * }
 *
 * USAGE:
 * 1. npm install          (inside /scripts)
 * 2. Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in your environment
 * OR replace the placeholders directly below.
 * 3. npx ts-node migrate_orders_items.ts
 * =============================================================================
 */

import { createClient, SupabaseClient } from '@supabase/supabase-js';

// ─── Configuration ────────────────────────────────────────────────────────────

// 🔴 تم تعديل الرابط والمفتاح بنجاح 🔴
const SUPABASE_URL: string =
  process.env.SUPABASE_URL ?? 'https://xidugzdzigyezserlhlj.supabase.co';

const SUPABASE_SERVICE_ROLE_KEY: string =
  process.env.SUPABASE_SERVICE_ROLE_KEY ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhpZHVnemR6aWd5ZXpzZXJsaGxqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MjcyMzU1OSwiZXhwIjoyMDg4Mjk5NTU5fQ.WAOqIgeiWqHluUt8lJIS7vpRvelsdtN9RG7FyMAl7OY';

// Set to true for a dry-run (logs changes without writing to DB)
const DRY_RUN: boolean = process.env.DRY_RUN === 'true' ? true : false;

// ─── Types ────────────────────────────────────────────────────────────────────

/** The strict, unified item shape we want every item to conform to. */
interface NormalizedItem {
  product_id: string;
  product_name_en: string;
  product_name_ar: string | null;
  unit_price: number;
  quantity: number;
  total_price: number;
  image_url: string | null;
  selected_size: string | null;
  selected_options: any[];
}

/** A raw legacy item — we use `any` because the old data has no fixed shape. */
type LegacyItem = Record<string, any>;

/** Minimal representation of an orders row. */
interface OrderRow {
  id: string | number;
  items: LegacyItem[] | null;
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

/** Safely reads the first defined, non-null value from a list of keys on obj. */
function pick<T>(obj: LegacyItem, keys: string[], defaultValue: T): T {
  for (const key of keys) {
    const val = obj[key];
    if (val !== undefined && val !== null) return val as T;
  }
  return defaultValue;
}

/** Coerces a value to a finite number; returns fallback if it cannot. */
function toNumber(val: any, fallback: number): number {
  const n = Number(val);
  return isFinite(n) ? n : fallback;
}

/** Coerces a value to a trimmed string; returns fallback if falsy/empty. */
function toStr(val: any, fallback: string): string {
  if (val === null || val === undefined) return fallback;
  const s = String(val).trim();
  return s.length > 0 ? s : fallback;
}

// ─── Core Normalizer ─────────────────────────────────────────────────────────

/**
 * Accepts a single raw legacy item and returns a NormalizedItem.
 * All mapping / fallback logic lives here.
 */
function normalizeItem(raw: LegacyItem, orderIndex: string): NormalizedItem {
  // ── product_id ──────────────────────────────────────────────────────────────
  const product_id = toStr(
    pick(raw, ['product_id', 'productId', 'id'], ''),
    ''
  );

  // ── product_name_en ─────────────────────────────────────────────────────────
  const product_name_en = toStr(
    pick(raw, ['product_name_en', 'product_name', 'name', 'title', 'productName'], ''),
    'Unknown Product'
  );

  // ── product_name_ar ─────────────────────────────────────────────────────────
  const rawAr = pick<string | null>(
    raw,
    ['product_name_ar', 'productNameAr', 'name_ar', 'nameAr'],
    null
  );
  const product_name_ar = rawAr ? toStr(rawAr, null as any) || null : null;

  // ── quantity ─────────────────────────────────────────────────────────────────
  const quantity = Math.max(
    1,
    toNumber(pick(raw, ['quantity', 'qty', 'count', 'amount'], 1), 1)
  );

  // ── unit_price ───────────────────────────────────────────────────────────────
  // Priority: explicit price → total_amount / quantity → subtotal / quantity → 0
  let unit_price: number;

  const rawPrice = pick<any>(raw, ['price', 'unit_price', 'unitPrice', 'item_price'], null);
  if (rawPrice !== null && isFinite(Number(rawPrice))) {
    unit_price = toNumber(rawPrice, 0);
  } else {
    // Try to back-calculate from total_amount
    const rawTotal = pick<any>(raw, ['total_amount', 'total', 'subtotal', 'totalAmount'], null);
    if (rawTotal !== null && isFinite(Number(rawTotal))) {
      unit_price = toNumber(rawTotal, 0) / quantity;
    } else {
      unit_price = 0;
    }
  }

  // ── total_price ──────────────────────────────────────────────────────────────
  // Priority: explicit total_amount / total → unit_price * quantity
  const rawTotalAmount = pick<any>(
    raw,
    ['total_amount', 'total', 'subtotal', 'totalAmount', 'total_price'],
    null
  );
  const total_price =
    rawTotalAmount !== null && isFinite(Number(rawTotalAmount))
      ? toNumber(rawTotalAmount, unit_price * quantity)
      : parseFloat((unit_price * quantity).toFixed(2));

  // ── image_url ─────────────────────────────────────────────────────────────────
  const rawImage = pick<string | null>(
    raw,
    ['image_url', 'image', 'product_image', 'productImage', 'imageUrl', 'img'],
    null
  );
  const image_url = rawImage ? toStr(rawImage, null as any) || null : null;

  // ── selected_size ─────────────────────────────────────────────────────────────
  const rawSize = pick<string | null>(
    raw,
    ['selected_size', 'size', 'selectedSize', 'variant'],
    null
  );
  const selected_size = rawSize ? toStr(rawSize, null as any) || null : null;

  // ── selected_options ──────────────────────────────────────────────────────────
  const rawOptions = pick<any>(
    raw,
    ['selected_options', 'options', 'selectedOptions', 'addons', 'extras', 'toppings'],
    []
  );
  const selected_options = Array.isArray(rawOptions) ? rawOptions : [];

  return {
    product_id,
    product_name_en,
    product_name_ar,
    unit_price: parseFloat(unit_price.toFixed(2)),
    quantity,
    total_price: parseFloat(total_price.toFixed(2)),
    image_url,
    selected_size,
    selected_options,
  };
}

// ─── Migration Runner ─────────────────────────────────────────────────────────

async function migrate(): Promise<void> {
  console.log('='.repeat(62));
  console.log('  Cup Tales — Orders Items Migration Script');
  console.log('='.repeat(62));
  console.log(`  Mode   : ${DRY_RUN ? '🟡 DRY RUN (no DB writes)' : '🟢 LIVE (writing to DB)'}`);
  console.log(`  Target : ${SUPABASE_URL}`);
  console.log('='.repeat(62));

  if (
    SUPABASE_URL.includes('YOUR_PROJECT_REF') ||
    SUPABASE_SERVICE_ROLE_KEY.includes('YOUR_SERVICE_ROLE_KEY')
  ) {
    console.error(
      '\n❌  ERROR: Please set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY before running.\n'
    );
    process.exit(1);
  }

  const supabase: SupabaseClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  // ── 1. Fetch all orders ────────────────────────────────────────────────────
  console.log('\n📥  Fetching all orders from the database…');

  const { data: orders, error: fetchError } = await supabase
    .from('orders')
    .select('id, items');

  if (fetchError) {
    console.error('❌  Failed to fetch orders:', fetchError.message);
    process.exit(1);
  }

  if (!orders || orders.length === 0) {
    console.log('ℹ️   No orders found. Nothing to migrate.');
    return;
  }

  console.log(`✅  Fetched ${orders.length} order(s).\n`);

  // ── 2. Statistics ──────────────────────────────────────────────────────────
  let totalOrders = 0;
  let ordersWithChanges = 0;
  let totalItemsProcessed = 0;
  let totalErrors = 0;

  // ── 3. Iterate & normalize ─────────────────────────────────────────────────
  for (const order of orders as OrderRow[]) {
    totalOrders++;
    const orderId = order.id;

    if (!order.items || !Array.isArray(order.items) || order.items.length === 0) {
      console.log(`⚠️   Order [${orderId}]: items is null/empty — skipping.`);
      continue;
    }

    console.log(`\n🔄  Order [${orderId}]: Processing ${order.items.length} item(s)…`);

    let normalizedItems: NormalizedItem[];

    try {
      normalizedItems = order.items.map((raw: LegacyItem, index: number) => {
        const orderRef = `${orderId}[${index}]`;
        const normalized = normalizeItem(raw, orderRef);

        // Log what changed for auditing
        const changes: string[] = [];
        if (raw.price === undefined && raw.total_amount !== undefined)
          changes.push('unit_price back-calculated from total_amount');
        if (raw.total_amount === undefined && raw.price !== undefined)
          changes.push('total_price calculated from price×qty');
        if (raw.product_image !== undefined && raw.image_url === undefined)
          changes.push('image → image_url');
        if (raw.product_name !== undefined && raw.product_name_en === undefined)
          changes.push('product_name → product_name_en');
        if (!raw.selected_options)
          changes.push('selected_options defaulted to []');

        if (changes.length > 0) {
          console.log(`    ✏️   Item ${index}: [${normalized.product_name_en}] — ${changes.join(', ')}`);
        } else {
          console.log(`    ✅  Item ${index}: [${normalized.product_name_en}] — already clean.`);
        }

        totalItemsProcessed++;
        return normalized;
      });
    } catch (itemError: any) {
      console.error(`❌  Order [${orderId}]: Failed to normalize items — ${itemError.message}`);
      totalErrors++;
      continue;
    }

    // ── 4. Update the row ────────────────────────────────────────────────────
    if (DRY_RUN) {
      console.log(`    🟡  DRY RUN — would update order [${orderId}] with ${normalizedItems.length} item(s).`);
      ordersWithChanges++;
      continue;
    }

    const { error: updateError } = await supabase
      .from('orders')
      .update({ items: normalizedItems })
      .eq('id', orderId);

    if (updateError) {
      console.error(`❌  Order [${orderId}]: Update failed — ${updateError.message}`);
      totalErrors++;
    } else {
      console.log(`    💾  Order [${orderId}]: Updated successfully.`);
      ordersWithChanges++;
    }
  }

  // ── 5. Summary ────────────────────────────────────────────────────────────
  console.log('\n' + '='.repeat(62));
  console.log('  Migration Complete — Summary');
  console.log('='.repeat(62));
  console.log(`  Total orders processed : ${totalOrders}`);
  console.log(`  Orders updated         : ${ordersWithChanges}`);
  console.log(`  Total items normalized : ${totalItemsProcessed}`);
  console.log(`  Errors                 : ${totalErrors}`);
  if (DRY_RUN) {
    console.log('\n  🟡  This was a DRY RUN. Re-run with DRY_RUN=false to apply changes.');
  } else {
    console.log('\n  ✅  All changes have been written to the database.');
  }
  console.log('='.repeat(62) + '\n');
}

// ─── Entry Point ──────────────────────────────────────────────────────────────
migrate().catch((err) => {
  console.error('\n💥  Unexpected fatal error:', err);
  process.exit(1);
});