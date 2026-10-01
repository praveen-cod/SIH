import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/admin_dashboard_models.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/admin_repository.dart';
import '../../../shared/widgets/app_navigation.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/reusable_dashboard_components.dart';
import '../widgets/admin_stats_grid.dart';
import '../widgets/admin_activity_feed.dart';
import '../widgets/ai_performance_card.dart';
import '../widgets/emergency_alerts_card.dart';
import '../widgets/ai_voice_assistant_card.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
 const AdminDashboardScreen({super.key});

 @override
 ConsumerState<AdminDashboardScreen> createState() =>
   _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
 final _scaffoldKey = GlobalKey<ScaffoldState>();

 String _dateFilter = 'Today';
 String _timeframe = 'Weekly';
 bool _isLoading = false;
 String? _errorMessage;

 AdminDashboardStats? _stats;
 List<PipelineStage>? _pipeline;
 AIPerformance? _aiPerformance;
 List<ConsultationReason>? _reasons;
 List<EmergencyAlert>? _emergencyAlerts;
 List<ActivityItem>? _activities;
 List<PlatformOverviewPoint>? _overviewPoints;

 @override
 void initState() {
  super.initState();
  _loadDashboardData();
 }

 Future<void> _loadDashboardData() async {
  setState(() {
   _isLoading = true;
   _errorMessage = null;
  });

  try {
   final repo = ref.read(adminRepositoryProvider);
   final statsFuture = repo.getDashboardStats(dateFilter: _dateFilter);
   final pipelineFuture = repo.getAppointmentPipeline();
   final aiFuture = repo.getAIPerformance();
   final reasonsFuture = repo.getTopConsultationReasons();
   final alertsFuture = repo.getEmergencyAlerts();
   final activityFuture = repo.getLiveActivity();
   final overviewFuture = repo.getPlatformOverview(timeframe: _timeframe);

   final results = await Future.wait([
    statsFuture,
    pipelineFuture,
    aiFuture,
    reasonsFuture,
    alertsFuture,
    activityFuture,
    overviewFuture,
   ]);

   if (mounted) {
    setState(() {
     _stats = results[0] as AdminDashboardStats;
     _pipeline = results[1] as List<PipelineStage>;
     _aiPerformance = results[2] as AIPerformance;
     _reasons = results[3] as List<ConsultationReason>;
     _emergencyAlerts = results[4] as List<EmergencyAlert>;
     _activities = results[5] as List<ActivityItem>;
     _overviewPoints = results[6] as List<PlatformOverviewPoint>;
     _isLoading = false;
    });
   }
  } catch (e) {
   if (mounted) {
    setState(() {
     _errorMessage = 'Failed to connect to Healthcare Operations Service.';
     _isLoading = false;
    });
   }
  }
 }

 void _showDateFilterSelector() {
  final options = ['Today', 'Yesterday', 'Last 7 Days', 'Last 30 Days', 'Custom Range'];
  showModalBottomSheet(
   context: context,
   backgroundColor: AppColors.backgroundSecondary,
   shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
   ),
   builder: (context) {
    return SafeArea(
     child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
       mainAxisSize: MainAxisSize.min,
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
        Padding(
         padding: const EdgeInsets.symmetric(horizontal: 12),
         child: Text(
          'Select Reporting Period',
          style: AppTextStyles.headingSmall,
         ),
        ),
        const SizedBox(height: 12),
        ...options.map((opt) {
         final isSelected = opt == _dateFilter;
         return ListTile(
          title: Text(
           opt,
           style: AppTextStyles.bodyMedium.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
           ),
          ),
          trailing: isSelected
            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
            : null,
          shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(10),
          ),
          onTap: () {
           Navigator.pop(context);
           setState(() => _dateFilter = opt);
           _loadDashboardData();
          },
         );
        }),
       ],
      ),
     ),
    );
   },
  );
 }

 void _showEmergencyTriageModal(EmergencyAlert alert) {
  showModalBottomSheet(
   context: context,
   backgroundColor: AppColors.backgroundSecondary,
   isScrollControlled: true,
   shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
   ),
   builder: (context) {
    return _EmergencyDetailSheet(alert: alert);
   },
  );
 }

 @override
 Widget build(BuildContext context) {
  final greeting = _getGreeting();

  return Scaffold(
   key: _scaffoldKey,
   backgroundColor: AppColors.background,
   drawer: AdminDrawer(
    onLogout: () async {
     final router = GoRouter.of(context);
     await ref.read(authProvider.notifier).logout();
     router.go(AppRoutes.login);
    },
   ),
   body: SafeArea(
    child: Stack(
     children: [
      _AdminBackground(),
      Center(
       child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: RefreshIndicator(
         onRefresh: _loadDashboardData,
         color: AppColors.primary,
         backgroundColor: AppColors.surface,
         child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
            const SizedBox(height: 16),
            // 1. Header
            DashboardHeader(
             scaffoldKey: _scaffoldKey,
             notificationCount: _emergencyAlerts?.length ?? 3,
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 20),

            // Greeting + System Online Status
            Row(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
              Expanded(
               child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                 Text(
                  '$greeting, Admin ',
                  style: AppTextStyles.headingLarge,
                 ),
                 const SizedBox(height: 4),
                 Text(
                  "Here's your healthcare system overview.",
                  style: AppTextStyles.bodyMedium,
                 ),
                ],
               ),
              ),
              // System Status Indicator
              Container(
               padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
               ),
               decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                 color: AppColors.success.withValues(alpha: 0.35),
                 width: 0.5,
                ),
               ),
               child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                 const PulseDot(color: AppColors.success, size: 7),
                 const SizedBox(width: 6),
                 Text(
                  'System Online',
                  style: AppTextStyles.labelSmall.copyWith(
                   color: AppColors.success,
                   fontWeight: FontWeight.w600,
                  ),
                 ),
                ],
               ),
              ),
             ],
            )
              .animate()
              .fadeIn(delay: 150.ms, duration: 500.ms)
              .slideX(begin: -0.05, end: 0),
            const SizedBox(height: 20),

            // 2. Date Filter near top
            Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
              _SectionLabel(label: 'Platform Analytics', color: AppColors.primary),
              GestureDetector(
               onTap: _showDateFilterSelector,
               child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                 color: AppColors.surface,
                 borderRadius: BorderRadius.circular(10),
                 border: Border.all(color: AppColors.border),
                ),
                child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                  const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                   '$_dateFilter ▼',
                   style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                   ),
                  ),
                 ],
                ),
               ),
              ),
             ],
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            const SizedBox(height: 14),

            // Error / Loading / Content
            if (_errorMessage != null)
             ErrorStateWidget(
              message: _errorMessage!,
              onRetry: _loadDashboardData,
             )
            else if (_isLoading && _stats == null)
             _buildSkeletons()
            else if (_stats != null) ...[
             // 3. Overview Statistics Grid (6 Cards)
             AdminStatsGrid(stats: _stats!)
               .animate()
               .fadeIn(delay: 250.ms, duration: 500.ms),
             const SizedBox(height: 24),

             // 4. Quick Actions
             _SectionLabel(label: 'Quick Actions', color: AppColors.secondary),
             const SizedBox(height: 12),
             Row(
              children: [
               Expanded(
                child: QuickActionCard(
                 title: 'Patients',
                 icon: Icons.people_outline_rounded,
                 color: AppColors.primary,
                 onTap: () => context.push(AppRoutes.adminPatients),
                ),
               ),
               const SizedBox(width: 8),
               Expanded(
                child: QuickActionCard(
                 title: 'Doctors',
                 icon: Icons.medical_services_outlined,
                 color: AppColors.doctorPrimary,
                 onTap: () => context.push(AppRoutes.adminDoctors),
                ),
               ),
               const SizedBox(width: 8),
               Expanded(
                child: QuickActionCard(
                 title: 'Appointments',
                 icon: Icons.calendar_month_outlined,
                 color: AppColors.secondary,
                 onTap: () => context.push(AppRoutes.adminAppointments),
                ),
               ),
               const SizedBox(width: 8),
               Expanded(
                child: QuickActionCard(
                 title: 'Emergencies',
                 icon: Icons.emergency_share_outlined,
                 color: AppColors.error,
                 onTap: () => context.push(AppRoutes.emergencyEscalation),
                ),
               ),
              ],
             ).animate().fadeIn(delay: 300.ms, duration: 450.ms),
             const SizedBox(height: 28),

             // 5. Emergency Alerts (Dedicated Section)
             if (_emergencyAlerts != null && _emergencyAlerts!.isNotEmpty) ...[
              EmergencyAlertsCard(
               alerts: _emergencyAlerts!,
               onViewAlert: _showEmergencyTriageModal,
              )
                .animate()
                .fadeIn(delay: 350.ms, duration: 400.ms)
                .shake(delay: 600.ms, duration: 500.ms),
              const SizedBox(height: 28),
             ],

             // 6. Platform Overview Chart
             if (_overviewPoints != null) ...[
              GlassCard(
               padding: const EdgeInsets.all(18),
               child: PlatformOverviewChart(
                data: _overviewPoints!,
                activeTimeframe: _timeframe,
                onTimeframeChanged: (tf) {
                 setState(() => _timeframe = tf);
                 _loadDashboardData();
                },
               ),
              ).animate().fadeIn(delay: 400.ms, duration: 450.ms),
              const SizedBox(height: 28),
             ],

             // 7. Appointment Pipeline (Funnel stages with % conversions)
             _SectionLabel(label: 'Appointment Pipeline', color: AppColors.primary),
             const SizedBox(height: 12),
             if (_pipeline != null)
              GlassCard(
               padding: const EdgeInsets.all(18),
               child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                 Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                   Expanded(
                    child: Text(
                     'Intake → Appointment Conversion',
                     style: AppTextStyles.labelLarge,
                    ),
                   ),
                   const SizedBox(width: 8),
                   Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                     color: AppColors.primary.withValues(alpha: 0.12),
                     borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                     'Real-Time Funnel',
                     style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                     ),
                    ),
                   ),
                  ],
                 ),
                 const SizedBox(height: 16),
                 AppointmentPipelineWidget(stages: _pipeline!),
                ],
               ),
              ).animate().fadeIn(delay: 450.ms, duration: 500.ms),
             const SizedBox(height: 28),

             // 8. AI Voice Assistant Status
             _SectionLabel(label: 'AI Voice Assistant Status', color: AppColors.accent),
             const SizedBox(height: 12),
             const AIVoiceAssistantCard()
               .animate()
               .fadeIn(delay: 500.ms, duration: 450.ms),
             const SizedBox(height: 28),

             // 9. AI Performance
             _SectionLabel(label: 'AI Performance Metrics', color: AppColors.secondary),
             const SizedBox(height: 12),
             if (_aiPerformance != null)
              AIPerformanceCard(data: _aiPerformance!)
                .animate()
                .fadeIn(delay: 550.ms, duration: 450.ms),
             const SizedBox(height: 28),

             // 10. Top Consultation Reasons
             _SectionLabel(label: 'Top Consultation Reasons', color: AppColors.doctorPrimary),
             const SizedBox(height: 12),
             if (_reasons != null)
              GlassCard(
               padding: const EdgeInsets.all(18),
               child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                 Text(
                  'Clinical Category Distribution',
                  style: AppTextStyles.labelLarge,
                 ),
                 const SizedBox(height: 4),
                 Text(
                  'Aggregated from AI voice intake & direct appointments',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                 ),
                 const SizedBox(height: 18),
                 HorizontalBarChart(items: _reasons!),
                ],
               ),
              ).animate().fadeIn(delay: 600.ms, duration: 450.ms),
             const SizedBox(height: 28),

             // 11. Live Activity
             Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
               _SectionLabel(label: 'Live Activity Stream', color: AppColors.primary),
               GestureDetector(
                onTap: () => context.push(AppRoutes.recentActivity),
                child: Text(
                 'View Full Log',
                 style: AppTextStyles.link.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                 ),
                ),
               ),
              ],
             ).animate().fadeIn(delay: 650.ms, duration: 400.ms),
             const SizedBox(height: 12),
             if (_activities != null)
              AdminActivityFeed(activities: _activities!)
                .animate()
                .fadeIn(delay: 700.ms, duration: 450.ms),
             const SizedBox(height: 36),
            ],
           ],
          ),
         ),
        ),
       ),
      ),
     ],
    ),
   ),
  );
 }

 Widget _buildSkeletons() {
  return Column(
   children: [
    Row(
     children: const [
      Expanded(child: SkeletonCard(height: 110)),
      SizedBox(width: 12),
      Expanded(child: SkeletonCard(height: 110)),
     ],
    ),
    const SizedBox(height: 12),
    Row(
     children: const [
      Expanded(child: SkeletonCard(height: 110)),
      SizedBox(width: 12),
      Expanded(child: SkeletonCard(height: 110)),
     ],
    ),
    const SizedBox(height: 20),
    const SkeletonCard(height: 200),
    const SizedBox(height: 20),
    const SkeletonCard(height: 180),
   ],
  );
 }

 String _getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  return 'Good Evening';
 }
}

class _SectionLabel extends StatelessWidget {
 final String label;
 final Color color;

 const _SectionLabel({required this.label, required this.color});

 @override
 Widget build(BuildContext context) {
  return Row(
   mainAxisSize: MainAxisSize.min,
   children: [
    Container(
     width: 3.5,
     height: 16,
     decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
     ),
    ),
    const SizedBox(width: 10),
    Flexible(
     child: Text(
      label,
      style: AppTextStyles.headingSmall.copyWith(fontSize: 16),
      overflow: TextOverflow.ellipsis,
     ),
    ),
   ],
  );
 }
}

/// Full-detail bottom sheet for an emergency alert with dispatch doctor functionality
class _EmergencyDetailSheet extends ConsumerStatefulWidget {
 final EmergencyAlert alert;
 const _EmergencyDetailSheet({required this.alert});

 @override
 ConsumerState<_EmergencyDetailSheet> createState() => _EmergencyDetailSheetState();
}

class _EmergencyDetailSheetState extends ConsumerState<_EmergencyDetailSheet> {
 List<Map<String, dynamic>> _doctors = [];
 String? _selectedDoctorId;
 bool _loading = true;
 bool _dispatching = false;

 @override
 void initState() {
  super.initState();
  _loadDoctors();
 }

 Future<void> _loadDoctors() async {
  try {
   final repo = ref.read(adminRepositoryProvider);
   final doctors = await repo.getDoctors();
   if (mounted) {
    setState(() {
     _doctors = doctors
         .map((d) => {'id': d.doctorId, 'name': d.name, 'specialty': d.specialization})
         .toList();
     _loading = false;
    });
   }
  } catch (_) {
   if (mounted) setState(() => _loading = false);
  }
 }

 Future<void> _dispatchDoctor() async {
  if (_selectedDoctorId == null) {
   ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Please select a doctor first')),
   );
   return;
  }
  setState(() => _dispatching = true);
  try {
   final repo = ref.read(adminRepositoryProvider);
   await repo.dispatchDoctorToEmergency(
    emergencyId: widget.alert.id,
    doctorId: _selectedDoctorId!,
   );
   if (mounted) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(
      content: Text('Doctor dispatched to ${widget.alert.patientName ?? widget.alert.patientId}'),
      backgroundColor: AppColors.success,
     ),
    );
   }
  } catch (e) {
   if (mounted) {
    setState(() => _dispatching = false);
    ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(content: Text('Dispatch failed: $e'), backgroundColor: AppColors.error),
    );
   }
  }
 }

 @override
 Widget build(BuildContext context) {
  final alert = widget.alert;
  return DraggableScrollableSheet(
   initialChildSize: 0.85,
   maxChildSize: 0.95,
   minChildSize: 0.5,
   expand: false,
   builder: (context, scrollController) {
    return Container(
     decoration: const BoxDecoration(
      color: AppColors.backgroundSecondary,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
     ),
     child: SafeArea(
      top: false,
      child: SingleChildScrollView(
       controller: scrollController,
       padding: const EdgeInsets.all(24),
       child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         // Drag handle
         Center(
          child: Container(
           width: 40,
           height: 4,
           margin: const EdgeInsets.only(bottom: 20),
           decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
           ),
          ),
         ),
         // Header
         Row(
          children: [
           Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
             color: AppColors.error.withValues(alpha: 0.15),
             borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.emergency_rounded, color: AppColors.error, size: 26),
           ),
           const SizedBox(width: 14),
           Expanded(
            child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
              Text(
               alert.patientName ?? 'Unknown Patient',
               style: AppTextStyles.headingSmall,
              ),
              Text(
               'Patient ID: ${alert.patientId}',
               style: AppTextStyles.caption.copyWith(color: AppColors.errorLight),
              ),
             ],
            ),
           ),
           Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
             color: AppColors.error.withValues(alpha: 0.15),
             borderRadius: BorderRadius.circular(8),
             border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
            ),
            child: Text(
             alert.severityLevel.toUpperCase(),
             style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w700,
             ),
            ),
           ),
          ],
         ),
         const SizedBox(height: 20),
         // Time info
         Row(
          children: [
           const Icon(Icons.access_time_rounded, size: 15, color: AppColors.textMuted),
           const SizedBox(width: 6),
           Text('Reported: ', style: AppTextStyles.caption),
           Text(alert.requestedTimeAgo, style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          ],
         ),
         const SizedBox(height: 16),
         // Symptom summary
         Text('Symptom Summary', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textMuted)),
         const SizedBox(height: 6),
         Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
           color: AppColors.surface,
           borderRadius: BorderRadius.circular(12),
           border: Border.all(color: AppColors.border),
          ),
          child: Text(
           alert.symptomSummary,
           style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary, height: 1.5),
          ),
         ),
         if (alert.emergencyImageUrl != null) ...[
          const SizedBox(height: 20),
          Text('Emergency Image', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 8),
          ClipRRect(
           borderRadius: BorderRadius.circular(14),
           child: Image.network(
            alert.emergencyImageUrl!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
           ),
          ),
         ],
         // Location
         if (alert.latitude != null && alert.longitude != null) ...[
          const SizedBox(height: 20),
          Text('Patient Location', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(
           'Lat: ${alert.latitude}  |  Lng: ${alert.longitude}',
           style: AppTextStyles.caption.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          ClipRRect(
           borderRadius: BorderRadius.circular(14),
           child: SizedBox(
            height: 200,
            child: FlutterMap(
             options: MapOptions(
              initialCenter: LatLng(double.parse(alert.latitude!), double.parse(alert.longitude!)),
              initialZoom: 15.0,
             ),
             children: [
              TileLayer(
               urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
               userAgentPackageName: 'com.healthcallai.app',
              ),
              MarkerLayer(
               markers: [
                Marker(
                 point: LatLng(double.parse(alert.latitude!), double.parse(alert.longitude!)),
                 width: 36,
                 height: 36,
                 child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                ),
               ],
              ),
             ],
            ),
           ),
          ),
         ],
         const SizedBox(height: 24),
         // Dispatch Doctor section
         Text('Dispatch Doctor', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textMuted)),
         const SizedBox(height: 8),
         if (_loading)
          const Center(child: CircularProgressIndicator())
         else if (_doctors.isEmpty)
          Text('No doctors available', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted))
         else
          Container(
           decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
           ),
           child: DropdownButtonFormField<String>(
            initialValue: _selectedDoctorId,
            isExpanded: true,
            decoration: const InputDecoration(
             contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
             border: InputBorder.none,
             hintText: 'Select a doctor',
            ),
            dropdownColor: AppColors.backgroundSecondary,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
            items: _doctors.map((d) {
             return DropdownMenuItem<String>(
              value: d['id'].toString(),
              child: Text(
               '${d['name']} — ${d['specialty'] ?? 'General'}',
               overflow: TextOverflow.ellipsis,
              ),
             );
            }).toList(),
            onChanged: (val) => setState(() => _selectedDoctorId = val),
           ),
          ),
         const SizedBox(height: 24),
         // Buttons
         Row(
          children: [
           Expanded(
            child: OutlinedButton(
             onPressed: () => Navigator.pop(context),
             style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
             ),
             child: const Text('Dismiss'),
            ),
           ),
           const SizedBox(width: 12),
           Expanded(
            flex: 2,
            child: ElevatedButton.icon(
             onPressed: _dispatching ? null : _dispatchDoctor,
             icon: _dispatching
                 ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                 : const Icon(Icons.local_hospital_rounded, size: 18),
             label: Text(_dispatching ? 'Dispatching...' : 'Dispatch Doctor'),
             style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
             ),
            ),
           ),
          ],
         ),
         const SizedBox(height: 16),
        ],
       ),
      ),
     ),
    );
   },
  );
 }
}

class _AdminBackground extends StatelessWidget {
 @override
 Widget build(BuildContext context) {
  return Positioned.fill(
   child: Stack(
    children: [
     Positioned(
      top: -100,
      right: -60,
      child: Container(
       width: 260,
       height: 260,
       decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.04),
       ),
      ),
     ),
     Positioned(
      bottom: 250,
      left: -80,
      child: Container(
       width: 220,
       height: 220,
       decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF8B5CF6).withValues(alpha: 0.03),
       ),
      ),
     ),
    ],
   ),
  );
 }
}
