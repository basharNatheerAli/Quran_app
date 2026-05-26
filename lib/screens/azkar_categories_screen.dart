import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import 'azkar_screen.dart';

class AzkarCategoriesScreen extends StatelessWidget {
  const AzkarCategoriesScreen({Key? key}) : super(key: key);

  IconData _getIconForCategory(String category) {
    if (category.contains('صباح')) return Icons.wb_sunny;
    if (category.contains('مساء')) return Icons.nights_stay;
    if (category.contains('نوم') || category.contains('استيقاظ'))
      return Icons.bedtime;
    if (category.contains('صلاة') ||
        category.contains('مسجد') ||
        category.contains('أذان'))
      return Icons.mosque;
    if (category.contains('وضوء')) return Icons.water_drop;
    if (category.contains('طعام') || category.contains('أكل'))
      return Icons.restaurant;
    if (category.contains('سفر') || category.contains('ركوب'))
      return Icons.directions_car;
    if (category.contains('قرآن') || category.contains('ختم'))
      return Icons.menu_book;
    if (category.contains('مرض') || category.contains('عطاس'))
      return Icons.medical_services;
    if (category.contains('ثوب') || category.contains('لبس'))
      return Icons.checkroom;
    if (category.contains('خلاء')) return Icons.wc;
    if (category.contains('مطر') || category.contains('ريح'))
      return Icons.cloud;
    if (category.contains('هم') ||
        category.contains('حزن') ||
        category.contains('كرب'))
      return Icons.sentiment_dissatisfied;
    if (category.contains('دين')) return Icons.attach_money;
    if (category.contains('مجلس')) return Icons.people_alt;
    if (category.contains('أهل') ||
        category.contains('زواج') ||
        category.contains('مولود'))
      return Icons.family_restroom;
    if (category.contains('ميت') ||
        category.contains('قبر') ||
        category.contains('جنازة'))
      return Icons.nights_stay;
    if (category.contains('غضب')) return Icons.mood_bad;
    if (category.contains('خروج') ||
        category.contains('دخول') ||
        category.contains('منزل'))
      return Icons.home;
    if (category.contains('أذان')) return Icons.campaign;
    if (category.contains('رقية') || category.contains('تعويذ'))
      return Icons.shield;
    if (category.contains('صيام') || category.contains('فطر'))
      return Icons.fastfood;
    if (category.contains('حج') ||
        category.contains('عمرة') ||
        category.contains('طواف') ||
        category.contains('مروة') ||
        category.contains('صفا'))
      return Icons.mosque;
    if (category.contains('استخارة')) return Icons.compare_arrows;

    return Icons.volunteer_activism;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الأذكار')),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final categories = provider.azkarByCategory.keys.toList();

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AzkarScreen(category: category),
                        ),
                      );
                    },
                    borderRadius: AppStyles.defaultBorderRadius,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppStyles.defaultBorderRadius,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getIconForCategory(category),
                              color: AppColors.primaryDark,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            category,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: AppStyles.bodySize,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(
                    duration: 400.ms,
                    delay: Duration(milliseconds: 2 * index),
                  )
                  .scale();
            },
          );
        },
      ),
    );
  }
}
