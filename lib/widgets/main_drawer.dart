import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildSectionTitle('إحصائيات القراءة (دقائق)'),
                const _ReadingStatsChart(),
                const Divider(),
                _buildSectionTitle('الإعدادات'),
                _buildSettingsSection(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              size: 48,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'رفيق المسلم',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'الإصدار 1.0.0',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            ListTile(
              leading: const Icon(Icons.language, color: AppColors.primary),
              title: const Text('اللغة'),
              trailing: DropdownButton<String>(
                value: provider.appLanguage,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'ar', child: Text('العربية')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                ],
                onChanged: (val) {
                  if (val != null) provider.setAppLanguage(val);
                },
              ),
            ),
            SwitchListTile(
              secondary: const Icon(
                Icons.notifications_active,
                color: AppColors.primary,
              ),
              title: const Text('الإشعارات'),
              activeColor: AppColors.primaryDark,
              value: provider.notificationsEnabled,
              onChanged: (val) {
                provider.toggleNotifications();
              },
            ),
          ],
        );
      },
    );
  }
}

class _ReadingStatsChart extends StatelessWidget {
  const _ReadingStatsChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final today = DateTime.now();
        final days = List.generate(7, (index) {
          final date = today.subtract(Duration(days: 6 - index));
          final dateStr = date.toIso8601String().split('T')[0];
          final minutes = provider.dailyReadingMinutes[dateStr] ?? 0;
          return _DayStat(date: date, minutes: minutes);
        });

        int maxMinutes = days
            .map((e) => e.minutes)
            .fold(0, (a, b) => a > b ? a : b);
        if (maxMinutes == 0) maxMinutes = 1; // prevent division by zero

        return Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((day) {
                final heightRatio = day.minutes / maxMinutes;
                final dayName = _getArabicDay(day.date.weekday);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${day.minutes}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 24,
                        height: 80 * heightRatio + 4, // minimum height 4
                        decoration: BoxDecoration(
                          color: day.minutes > 0
                              ? AppColors.primary
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dayName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  String _getArabicDay(int weekday) {
    switch (weekday) {
      case DateTime.saturday:
        return 'سبت';
      case DateTime.sunday:
        return 'أحد';
      case DateTime.monday:
        return 'إثنين';
      case DateTime.tuesday:
        return 'ثلاثاء';
      case DateTime.wednesday:
        return 'أربعاء';
      case DateTime.thursday:
        return 'خميس';
      case DateTime.friday:
        return 'جمعة';
      default:
        return '';
    }
  }
}

class _DayStat {
  final DateTime date;
  final int minutes;

  _DayStat({required this.date, required this.minutes});
}
