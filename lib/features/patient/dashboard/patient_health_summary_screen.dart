import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../repositories/patient_repository.dart';
import '../widgets/health_summary_card.dart';

class PatientHealthSummaryScreen extends ConsumerWidget {
  const PatientHealthSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientRepo = ref.watch(patientRepositoryProvider);
    final healthSummary = patientRepo.getHealthSummary();
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/patient-dashboard');
            }
          },
        ),
        title: const Text('Health Summary', style: TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overall Health Status', style: AppTextStyles.headingSmall),
            const SizedBox(height: 16),
            HealthSummaryCard(data: healthSummary),
            const SizedBox(height: 24),
            
            Text('Recent Vitals', style: AppTextStyles.headingSmall),
            const SizedBox(height: 16),
            _buildSimpleCard([
              {'metric': 'Blood Pressure', 'value': '120/80', 'unit': 'mmHg'},
              {'metric': 'Heart Rate', 'value': '72', 'unit': 'bpm'},
              {'metric': 'Temperature', 'value': '98.6', 'unit': '°F'},
            ]),
            const SizedBox(height: 24),
            
            Text('Latest Lab Results', style: AppTextStyles.headingSmall),
            const SizedBox(height: 16),
            _buildSimpleCard([
              {'metric': 'Hemoglobin A1c', 'value': '5.4', 'unit': '%'},
              {'metric': 'Cholesterol (Total)', 'value': '185', 'unit': 'mg/dL'},
              {'metric': 'Vitamin D', 'value': '35', 'unit': 'ng/mL'},
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleCard(List<Map<String, String>> items) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item['metric']!, style: AppTextStyles.bodyMedium),
                Text('${item['value']} ${item['unit']}', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
