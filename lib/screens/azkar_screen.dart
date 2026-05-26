import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
// import '../models/models.dart';
import '../utils/constants.dart';

class AzkarScreen extends StatefulWidget {
  final String category;

  const AzkarScreen({Key? key, required this.category}) : super(key: key);

  @override
  _AzkarScreenState createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen> {
  // Map to store the current count for each Zekr index
  Map<int, int> _counts = {};

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final azkarList = provider.azkarByCategory[widget.category] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: azkarList.length,
        itemBuilder: (context, index) {
          final zekr = azkarList[index];
          final currentCount = _counts[index] ?? 0;
          final targetCount = zekr.count;
          final isCompleted = currentCount >= targetCount;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: AppStyles.defaultBorderRadius,
            ),
            elevation: isCompleted ? 1 : 4,
            color: isCompleted ? Colors.grey.shade200 : Colors.white,
            child: InkWell(
              borderRadius: AppStyles.defaultBorderRadius,
              onTap: isCompleted
                  ? null
                  : () {
                      setState(() {
                        _counts[index] = currentCount + 1;
                      });
                    },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      zekr.zekr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppStyles.titleSize,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? AppColors.textLight : AppColors.text,
                        height: 2.0,
                      ),
                    ),
                    if (zekr.description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        zekr.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: AppStyles.bodySize,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (targetCount > 1)
                          Expanded(
                            child: Stack(
                              alignment: Alignment.centerRight,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: targetCount > 0
                                        ? currentCount / targetCount
                                        : 1.0,
                                    minHeight: 10,
                                    backgroundColor: AppColors.background,
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                        AppColors.primary),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          const Spacer(),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.grey.shade400
                                : AppColors.primaryDark,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$currentCount / $targetCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
        },
      ),
    );
  }
}
