import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/product_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';

class ProductDetailsPage extends StatefulWidget {
  final ProductEntity product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  String? _selectedSize;
  int _quantity = 1;
  bool? _isIceCreamCategory;

  final Map<String, double> _availableSizes = {};

  @override
  void initState() {
    super.initState();
    // Dynamically detect which sizes have prices mapped in Supabase
    if (widget.product.priceS != null)
      _availableSizes['S'] = widget.product.priceS!;
    if (widget.product.priceM != null)
      _availableSizes['M'] = widget.product.priceM!;
    if (widget.product.priceL != null)
      _availableSizes['L'] = widget.product.priceL!;

    // Auto-select the first available size (Defaults to M if exists)
    if (_availableSizes.containsKey('M')) {
      _selectedSize = 'M';
    } else if (_availableSizes.isNotEmpty) {
      _selectedSize = _availableSizes.keys.first;
    }
    _checkCategory();
  }

  Future<void> _checkCategory() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('categories')
          .select('name, name_ar')
          .eq('id', widget.product.categoryId)
          .single();
      final String name = response['name']?.toString().toLowerCase() ?? '';
      final String nameAr = response['name_ar']?.toString().toLowerCase() ?? '';
      if (mounted) {
        setState(() {
          _isIceCreamCategory = name.contains('sundae') ||
              name.contains('ice cream') ||
              nameAr.contains('صنداي') ||
              nameAr.contains('ايس كريم') ||
              nameAr.contains('آيس كريم');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isIceCreamCategory = false;
        });
      }
    }
  }

  bool get _isSundae {
    if (_isIceCreamCategory != null) return _isIceCreamCategory!;
    final n = widget.product.name.toLowerCase();
    final nAr = widget.product.nameAr?.toLowerCase() ?? '';
    return n.contains('sundae') ||
        nAr.contains('صنداي') ||
        nAr.contains('آيس كريم');
  }

  double get _totalPrice {
    if (_selectedSize == null) return 0.0;
    return (_availableSizes[_selectedSize] ?? 0.0) * _quantity;
  }

  String _getFallbackDescription(BuildContext context) {
    if (widget.product.description.isNotEmpty) {
      return widget.product.description;
    }

    final name = widget.product.name;
    final nameAr = widget.product.nameAr ?? name;

    if (_isSundae) {
      return context.tr(
        'Treat yourself to $name. Our premium ice cream is crafted for the ultimate creamy and rich experience. Choose between a crispy biscuit cone or a classic sundae cup to satisfy your sweet cravings!',
        'دلل نفسك مع $nameAr. آيس كريم فاخر ومحضر بعناية ليمنحك تجربة غنية ولذيذة. اختر بين بسكويت مقرمش أو كوب صنداي كلاسيكي واستمتع بأحلى الأوقات!',
      );
    } else {
      return context.tr(
        'Enjoy the perfect and refreshing taste of $name. Crafted with the finest ingredients to bring you a unique flavor that brightens your day.',
        'استمتع بالمذاق الرائع والمنعش لـ $nameAr. محضر بأجود المكونات ليقدم لك نكهة فريدة ومميزة تضيء يومك.',
      );
    }
  }

  Widget _buildIceCreamSelector() {
    return Row(
      children: _availableSizes.entries.map((entry) {
        final sizeCode = entry.key; // 'S' or 'M'
        final isSelected = _selectedSize == sizeCode;

        String title = '';
        if (sizeCode == 'S') {
          title = context.tr('Biscuit', 'بسكويت');
        } else if (sizeCode == 'M') {
          title = context.tr('Sundae Cup', 'كوب صنداي');
        } else {
          title = sizeCode;
        }

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedSize = sizeCode),
            child: Container(
              margin: EdgeInsets.only(
                  right: sizeCode != _availableSizes.keys.last ? 12.0 : 0),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  Icon(
                    sizeCode == 'S'
                        ? Icons.cookie_outlined
                        : Icons.icecream_outlined,
                    color: isSelected ? Colors.white : AppColors.primary,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${entry.value} ${context.loc.egp}',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isSelected ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = context.tr(
      widget.product.name,
      widget.product.nameAr ?? widget.product.name,
    );
    final description = _getFallbackDescription(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero Image ──
            Container(
              height: MediaQuery.of(context).size.height * 0.45,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                child: Transform.scale(
                  scale: 1.15,
                  alignment: const Alignment(0, -0.3),
                  child: Image.network(
                    widget.product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image,
                        size: 80,
                        color: Colors.grey),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title & Price Header ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${_totalPrice.toStringAsFixed(2)} ${context.loc.egp}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Description ──
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Size Selector ──
                  if (_availableSizes.isNotEmpty) ...[
                    Text(
                      _isSundae
                          ? context.tr('Serving Option', 'طريقة التقديم')
                          : context.loc.size,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isSundae)
                      _buildIceCreamSelector()
                    else
                      Row(
                        children: _availableSizes.entries.map((entry) {
                          final sizeCode = entry.key;
                          final isSelected = _selectedSize == sizeCode;

                          String displaySize = sizeCode;
                          if (sizeCode == 'S') displaySize = context.loc.small;
                          if (sizeCode == 'M') displaySize = context.loc.medium;
                          if (sizeCode == 'L') displaySize = context.loc.large;

                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: ChoiceChip(
                              label: Text(
                                displaySize,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: AppColors.primary,
                              backgroundColor: Colors.white,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedSize = sizeCode);
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                  const SizedBox(height: 32),

                  // ── Quantity & Add To Cart ──
                  Row(
                    children: [
                      // Quantity Control
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove,
                                  color: AppColors.textPrimary),
                              onPressed: () => setState(() {
                                if (_quantity > 1) _quantity--;
                              }),
                            ),
                            Text(
                              '$_quantity',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add,
                                  color: AppColors.textPrimary),
                              onPressed: () => setState(() => _quantity++),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Add To Cart Button
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          onPressed: _selectedSize == null
                              ? null
                              : () {
                                  context.read<CartCubit>().addToCart(
                                        productId: widget.product.id,
                                        productName: widget.product.name,
                                        price: _availableSizes[_selectedSize] ??
                                            0.0,
                                        image: widget.product.imageUrl,
                                        quantity: _quantity,
                                      );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(context.loc.addedToCart),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  Navigator.pop(context);
                                },
                          child: Text(
                            context.loc.addToCart,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
