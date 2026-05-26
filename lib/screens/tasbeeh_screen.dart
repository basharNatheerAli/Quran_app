import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';

class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({Key? key}) : super(key: key);

  @override
  _TasbeehScreenState createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> {
  final List<Map<String, dynamic>> predefinedTasbeehs = [
    {'text': 'سُبْحَانَ اللَّهِ', 'target': 33},
    {'text': 'الْحَمْدُ لِلَّهِ', 'target': 33},
    {'text': 'اللَّهُ أَكْبَرُ', 'target': 33},
    {'text': 'لَا إِلَهَ إِلَّا اللَّهُ', 'target': 100},
    {'text': 'أَسْتَغْفِرُ اللَّهَ', 'target': 100},
    {'text': 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ', 'target': 10},
    {'text': 'اللهم صل وسلم على نبينا محمد', 'target': 10},
  ];

  int selectedTasbeehIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize provider with the first tasbeeh target on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      if (provider.tasbeehTarget != predefinedTasbeehs[0]['target']) {
        provider.setTasbeehTarget(predefinedTasbeehs[0]['target'] as int);
      }
    });
  }

  void _onTasbeehSelected(int index, AppProvider provider) {
    setState(() {
      selectedTasbeehIndex = index;
    });
    provider.setTasbeehTarget(predefinedTasbeehs[index]['target'] as int);
    provider.resetCurrentTasbeeh();
  }

  void _showTargetDialog(BuildContext context, AppProvider provider) {
    int newTarget = provider.tasbeehTarget;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تغيير الهدف'),
          content: TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'أدخل الهدف الجديد',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              newTarget = int.tryParse(value) ?? provider.tasbeehTarget;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                if (newTarget > 0) {
                  setState(() {
                    predefinedTasbeehs[selectedTasbeehIndex]['target'] =
                        newTarget;
                  });
                  provider.setTasbeehTarget(newTarget);
                }
                Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المسبحة')),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Horizontal list of predefined tasbeehs
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(predefinedTasbeehs.length, (index) {
                      final isSelected = selectedTasbeehIndex == index;
                      final tasbeeh = predefinedTasbeehs[index];
                      return GestureDetector(
                        onTap: () => _onTasbeehSelected(index, provider),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryDark
                                : AppColors.background,
                            border: Border.all(
                              color: AppColors.primaryDark,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${tasbeeh['text']} (${tasbeeh['target']})",
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.primaryDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }),
                  ).animate().fadeIn().slideY(),

                  const SizedBox(height: 32),

                  // Current Tasbeeh Name
                  Text(
                    predefinedTasbeehs[selectedTasbeehIndex]['text'] as String,
                    style: const TextStyle(
                      fontSize: AppStyles.titleSize,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ).animate().fadeIn(),

                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: () => _showTargetDialog(context, provider),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'الهدف: ${provider.tasbeehTarget}',
                            style: const TextStyle(
                              fontSize: AppStyles.subtitleSize,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.edit,
                            size: 20,
                            color: AppColors.primaryDark,
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(),

                  const SizedBox(height: 40),

                  // Counter Button
                  GestureDetector(
                    onTap: () => provider.incrementTasbeeh(),
                    child:
                        Container(
                              width: 250,
                              height: 250,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primaryDark,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryDark.withOpacity(
                                      0.4,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '${provider.currentTasbeehCount}',
                                  style: const TextStyle(
                                    fontSize: 64,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                            .animate(
                              key: ValueKey(provider.currentTasbeehCount),
                            )
                            .scale(
                              begin: const Offset(0.95, 0.95),
                              end: const Offset(1, 1),
                              duration: 100.ms,
                              curve: Curves.easeOut,
                            ),
                  ),
                  const SizedBox(height: 40),

                  // Progress Bar & Cycle Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${provider.currentTasbeehCount} / ${provider.tasbeehTarget}',
                              style: const TextStyle(
                                fontSize: AppStyles.subtitleSize,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: provider.tasbeehTarget > 0
                                ? provider.currentTasbeehCount /
                                      provider.tasbeehTarget
                                : 0,
                            minHeight: 12,
                            backgroundColor: AppColors.primary.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn().slideY(begin: 0.5),
                  ),

                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'الإجمالي',
                            style: TextStyle(
                              fontSize: AppStyles.subtitleSize,
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${provider.totalTasbeehCount}',
                            style: const TextStyle(
                              fontSize: AppStyles.titleSize,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 40),
                      Column(
                        children: [
                          Text(
                            'إعادة تعيين',
                            style: TextStyle(
                              fontSize: AppStyles.subtitleSize,
                              color: AppColors.textLight,
                            ),
                          ),
                          IconButton(
                            onPressed: () => provider.resetTotalTasbeeh(),
                            icon: const Icon(
                              Icons.refresh,
                              size: 32,
                              color: AppColors.textLight,
                            ),
                            tooltip: 'تصفير الإجمالي',
                          ),
                        ],
                      ),
                    ],
                  ).animate().fadeIn().slideY(begin: 0.5),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
