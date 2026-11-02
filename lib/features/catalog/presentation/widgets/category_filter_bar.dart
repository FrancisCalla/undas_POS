import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../pos/providers/catalog_provider.dart';
import 'add_edit_product_dialog.dart';

/// Top horizontal category bar matching the high-contrast lime green tabs in Image 2.
class CategoryFilterBar extends ConsumerWidget {
  const CategoryFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final selectedCatId = ref.watch(selectedCategoryIdProvider);

    return Container(
      height: 48,
      color: Colors.black,
      child: Row(
        children: [
          // Category tabs
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 2),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category.id == selectedCatId;

                return InkWell(
                  onTap: () {
                    ref.read(selectedCategoryIdProvider.notifier).state = category.id;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF161616) : AppColors.posLimeGreen,
                      border: isSelected
                          ? const Border(
                              top: BorderSide(color: AppColors.posLimeGreen, width: 3.5),
                              left: BorderSide(color: Color(0xFF444444)),
                              right: BorderSide(color: Color(0xFF444444)),
                            )
                          : const Border(
                              right: BorderSide(color: Color(0xFF557722), width: 1),
                            ),
                    ),
                    child: Text(
                      category.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: isSelected ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 2),

          // "+ ADD ITEM" Tab (Directly in the top bar like Image 2's MANAGER tab)
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => const AddEditProductDialog(),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              color: AppColors.posOlive,
              child: const Row(
                children: [
                  Icon(Icons.add, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    '+ ADD ITEM',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
