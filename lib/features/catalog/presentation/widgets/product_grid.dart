import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../pos/providers/catalog_provider.dart';
import 'product_card.dart';

/// Touch-optimized product grid matching the 3-column square tile layout in Image 2.
class ProductGrid extends ConsumerWidget {
  const ProductGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(filteredProductsProvider);

    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 54,
                color: Color(0xFF666666),
              ),
              const SizedBox(height: 16),
              const Text(
                'No products in this category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap "+ ADD ITEM" in the top bar to add items to this category.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.posLimeGreen,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  ref.read(searchQueryProvider.notifier).state = '';
                  ref.read(selectedCategoryIdProvider.notifier).state = 'cat_all';
                },
                icon: const Icon(Icons.refresh),
                label: const Text('View All Categories'),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // High-contrast 3-column grid matching Image 2
        int crossAxisCount = 3;
        if (constraints.maxWidth < 450) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(4),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.15,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return ProductCard(product: products[index]);
          },
        );
      },
    );
  }
}
