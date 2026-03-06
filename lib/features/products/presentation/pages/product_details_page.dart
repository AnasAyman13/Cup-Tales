import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/product_entity.dart';
import '../../../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../../../features/cart/domain/entities/cart_item_entity.dart';

class ProductDetailsPage extends StatefulWidget {
  final ProductEntity product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  String _selectedSize = 'M';
  int _quantity = 1;

  double get _totalPrice {
    double sizeMultiplier = 1.0;
    if (_selectedSize == 'S') sizeMultiplier = 0.8;
    if (_selectedSize == 'L') sizeMultiplier = 1.2;
    return (widget.product.basePrice * sizeMultiplier) * _quantity;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Placeholder
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.brown[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(child: Icon(Icons.coffee, size: 100, color: Colors.brown)),
            ),
            const SizedBox(height: 20),
            Text(widget.product.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(widget.product.description, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 20),
            
            // Size Selector
            const Text('Select Size:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['S', 'M', 'L'].map((size) {
                return ChoiceChip(
                  label: Text(size),
                  selected: _selectedSize == size,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedSize = size);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
            // Quantity Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => setState(() {
                    if (_quantity > 1) _quantity--;
                  }),
                ),
                Text('$_quantity', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => _quantity++),
                ),
              ],
            ),
            
            const Spacer(),
            
            // Add to Cart Button
            ElevatedButton(
              onPressed: () {
                final item = CartItemEntity(
                  product: widget.product,
                  quantity: _quantity,
                  size: _selectedSize,
                );
                context.read<CartCubit>().addToCart(item);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added $_quantity ${widget.product.name} to cart!')),
                );
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Add to Cart', style: TextStyle(fontSize: 18)),
                    Text('\$${_totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
