import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  // Production tokens extracted from lib/core/config/supabase_config.dart
  const supabaseUrl = 'https://xidugzdzigyezserlhlj.supabase.co';
  const supabaseKey = 'sb_publishable_l7sZcgZzKYUHtRyvG2wCGA_AVGJ6N0R';

  final client = SupabaseClient(supabaseUrl, supabaseKey);

  print('Fetching categories...');
  final data = await client.from('categories').select();

  print(
      'Found \${data.length} categories. Checking for missing Arabic names...');

  for (var category in data) {
    final id = category['id'];
    final nameEn = category['name_en'] ?? category['name'] ?? '';
    final nameAr = category['name_ar'];

    if (nameAr == null || nameAr.toString().trim().isEmpty) {
      print('Category ID \$id (\$nameEn) is missing Arabic translation.');

      String translation = '';
      final lowerName = nameEn.toString().toLowerCase();

      if (lowerName.contains('iced')) {
        translation = 'المشروبات المثلجة';
      } else if (lowerName.contains('hot')) {
        translation = 'المشروبات الساخنة';
      } else if (lowerName.contains('fresh juice')) {
        translation = 'العصائر الطبيعية';
      } else if (lowerName.contains('smoothie')) {
        translation = 'سموثي';
      } else if (lowerName.contains('dessert') ||
          lowerName.contains('sweets')) {
        translation = 'الحلويات';
      } else if (lowerName.contains('bakery')) {
        translation = 'المخبوزات';
      } else if (lowerName.contains('frappe')) {
        translation = 'فرابيه';
      } else {
        translation = 'صنف جديد'; // Default fallback
      }

      print('  -\> Updating to: \$translation');

      try {
        await client
            .from('categories')
            .update({'name_ar': translation}).eq('id', id);
        print('  -\> Success.');
      } catch (e) {
        print('  -\> Failed: \$e');
      }
    } else {
      print(
          'Category ID \$id (\$nameEn) already has Arabic translation: \$nameAr');
    }
  }

  print('Patch complete.');
  exit(0);
}
