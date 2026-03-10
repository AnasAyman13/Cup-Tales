import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

class BranchesPage extends StatelessWidget {
  const BranchesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          context.tr('Our Branches', 'فروعنا'),
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          BranchCard(
            nameEn: 'Rehab Branch',
            nameAr: 'فرع الرحاب',
            areaEn: 'New Cairo',
            areaAr: 'القاهرة الجديدة',
            url:
                'https://www.google.com/maps/search/?api=1&query=30.0756875,31.5028125',
          ),
          const SizedBox(height: 16),
          BranchCard(
            nameEn: 'Mahalla Branch 1',
            nameAr: 'فرع المحلة 1',
            areaEn: 'El Mahalla El Kubra',
            areaAr: 'المحلة الكبرى',
            url:
                'https://www.google.com/maps/search/?api=1&query=30.9277151,31.130399',
          ),
          const SizedBox(height: 16),
          BranchCard(
            nameEn: 'Mahalla Branch 2',
            nameAr: 'فرع المحلة 2',
            areaEn: 'El Mahalla El Kubra',
            areaAr: 'المحلة الكبرى',
            url:
                'https://www.google.com/maps/search/?api=1&query=30.9779318,31.1816941',
          ),
        ],
      ),
    );
  }
}

class BranchCard extends StatelessWidget {
  final String nameEn;
  final String nameAr;
  final String areaEn;
  final String areaAr;
  final String url;

  const BranchCard({
    super.key,
    required this.nameEn,
    required this.nameAr,
    required this.areaEn,
    required this.areaAr,
    required this.url,
  });

  Future<void> _openMap(BuildContext context) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          _showError(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context);
      }
    }
  }

  void _showError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr('Unable to open maps', 'تعذر فتح الخرائط'),
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Locale currentLocale = Localizations.localeOf(context);
    final isEn = currentLocale.languageCode == 'en';

    final branchName = isEn ? nameEn : nameAr;
    final branchArea = isEn ? areaEn : areaAr;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => _openMap(context),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            branchName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  branchArea,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openMap(context),
                    icon: const Icon(Icons.map_outlined, size: 20),
                    label: Text(
                      context.tr('Open in Maps', 'افتح في الخرائط'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
