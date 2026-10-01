import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/appointment_model.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/patient_repository.dart';
import '../../../repositories/consultation_repository.dart';
import '../../../services/appointment_service.dart' hide apiClientProvider;
import '../../../shared/widgets/app_navigation.dart';
import '../../../shared/widgets/glass_card.dart';
import '../widgets/patient_appointment_card.dart';
import '../widgets/health_summary_card.dart';
import '../widgets/ai_assistant_card.dart';
import '../../../core/network/api_client.dart';

class PatientDashboardScreen extends ConsumerStatefulWidget {
 const PatientDashboardScreen({super.key});

 @override
 ConsumerState<PatientDashboardScreen> createState() =>
   _PatientDashboardScreenState();
}

class _PatientDashboardScreenState
  extends ConsumerState<PatientDashboardScreen> {
 final _scaffoldKey = GlobalKey<ScaffoldState>();
 DateTime? _lastBackPressTime;
 List<ClinicalAppointmentModel>? _liveAppointments;
 bool _isLoadingAppointments = true;
 List<Map<String, dynamic>>? _actualActivity;

 @override
 void initState() {
  super.initState();
  _loadLiveAppointments();
  _loadRecentActivity();
 }

 Future<void> _loadRecentActivity() async {
  try {
   final apiClient = ref.read(apiClientProvider);
   final response = await apiClient.get('/api/patients/me/activity?skip=0&limit=3', requireAuth: true);
   if (mounted) {
    setState(() {
     _actualActivity = (response as List<dynamic>).map((e) {
      final date = DateTime.tryParse(e['created_at'] ?? '');
      final timeStr = date != null ? '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}' : '';
      return {
       'title': e['action'] ?? 'Unknown',
       'subtitle': e['details'] ?? 'No details',
       'time': timeStr,
       'icon': Icons.local_activity,
      };
     }).toList();
    });
   }
  } catch (_) {}
 }

 Future<void> _loadLiveAppointments() async {
  try {
   final appts = await ref
     .read(appointmentServiceProvider)
     .getPatientAppointments()
     .timeout(
      const Duration(seconds: 5),
      onTimeout: () => <ClinicalAppointmentModel>[],
     );
   if (mounted) {
    setState(() {
     _liveAppointments = appts;
     _isLoadingAppointments = false;
    });
   }
  } catch (_) {
   if (mounted) {
    setState(() {
     _isLoadingAppointments = false;
    });
   }
  }
 }

 @override
 Widget build(BuildContext context) {
  final user = ref.watch(currentUserProvider);
  final patientRepo = ref.watch(patientRepositoryProvider);
  final appointments = patientRepo.getUpcomingAppointments();
  final activity = patientRepo.getRecentActivity();
  final healthSummary = patientRepo.getHealthSummary();
  final activityToDisplay = _actualActivity ?? activity;

  final List<AppointmentModel> displayAppointments;
  if (_liveAppointments != null && _liveAppointments!.isNotEmpty) {
   displayAppointments = _liveAppointments!.map((a) => a.toAppointmentModel()).toList();
  } else {
   displayAppointments = appointments;
  }

  final firstName = user?.name.split(' ').first ?? 'Patient';
  final greeting = _getGreeting();

  return PopScope(
   canPop: false,
   onPopInvokedWithResult: (didPop, result) {
    if (didPop) return;
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
     _scaffoldKey.currentState?.closeDrawer();
     return;
    }
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
      now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
     _lastBackPressTime = now;
     ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
       content: Text('Press back again to exit'),
       duration: Duration(seconds: 2),
       backgroundColor: AppColors.surface,
      ),
     );
     return;
    }
    SystemNavigator.pop();
   },
   child: Scaffold(
    key: _scaffoldKey,
    backgroundColor: AppColors.background,
    drawer: PatientDrawer(
     userName: user?.name ?? 'Patient',
     userId: user?.patientId ?? 'HC-XXXXXXXX',
     onLogout: () async {
      ref.read(consultationProvider.notifier).reset();
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.go(AppRoutes.login);
     },
    ),
   body: SafeArea(
    child: Stack(
     children: [
      // Background blobs
      _DashboardBackground(),
      RefreshIndicator(
       color: AppColors.primary,
       backgroundColor: AppColors.surface,
       onRefresh: _loadLiveAppointments,
       child: Center(
        child: ConstrainedBox(
         constraints: const BoxConstraints(maxWidth: 880),
         child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
          const SizedBox(height: 16),
          // Header
          DashboardHeader(scaffoldKey: _scaffoldKey)
            .animate()
            .fadeIn(duration: 400.ms),
          const SizedBox(height: 24),
          // Greeting
          Row(
           children: [
            Expanded(
             child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
               Text(
                '$greeting, $firstName ',
                style: AppTextStyles.headingLarge,
               ),
               const SizedBox(height: 4),
               Text(
                'How can we help you today?',
                style: AppTextStyles.bodyMedium,
               ),
              ],
             ),
            ),
            // AI Online indicator
            Container(
             padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
             ),
             decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
               color: AppColors.success.withValues(alpha: 0.3),
               width: 0.5,
              ),
             ),
             child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
               _PulseDot(color: AppColors.success),
               const SizedBox(width: 6),
               Text(
                'AI Online',
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
          const SizedBox(height: 24),
          // AI Assistant Card
          AIAssistantCard(
           onStartConsultation: () =>
             context.push(AppRoutes.consultationConsent),
          )
            .animate()
            .fadeIn(delay: 250.ms, duration: 500.ms)
            .slideY(begin: 0.05, end: 0),
          const SizedBox(height: 24),
          // Quick Stats
          _QuickStatsRow(appointmentCount: displayAppointments.length)
            .animate()
            .fadeIn(delay: 350.ms, duration: 500.ms),
          const SizedBox(height: 24),
          // Upcoming Appointments
          _SectionHeader(
           title: 'Upcoming Appointments',
           actionLabel: 'View All',
           onAction: () => context.push(AppRoutes.patientAppointments),
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          const SizedBox(height: 14),
          if (_isLoadingAppointments && displayAppointments.isEmpty)
           const Center(
            child: Padding(
             padding: EdgeInsets.all(16.0),
             child: CircularProgressIndicator(color: AppColors.primary),
            ),
           )
          else if (displayAppointments.isEmpty)
           _EmptyAppointments(
            onBookDoctor: () => context.push(AppRoutes.bookDoctor),
           )
          else
           ...displayAppointments.asMap().entries.map(
              (entry) => PatientAppointmentCard(
               appointment: entry.value,
              )
                .animate()
                .fadeIn(
                 delay: Duration(
                   milliseconds: 450 + entry.key * 80),
                 duration: 400.ms,
                )
                .slideX(begin: 0.05, end: 0),
             ),
          const SizedBox(height: 24),
          // Health Summary
          _SectionHeader(
           title: 'Health Summary',
           actionLabel: 'Full Report',
           onAction: () => context.push(AppRoutes.healthSummary),
          ).animate().fadeIn(delay: 550.ms, duration: 400.ms),
          const SizedBox(height: 14),
          HealthSummaryCard(data: healthSummary)
            .animate()
            .fadeIn(delay: 600.ms, duration: 400.ms),
          const SizedBox(height: 24),
          // Recent Activity
          _SectionHeader(
           title: 'Recent Activity',
           actionLabel: 'See All',
           onAction: () => context.push(AppRoutes.recentActivity),
          ).animate().fadeIn(delay: 650.ms, duration: 400.ms),
          const SizedBox(height: 14),
          ...activityToDisplay.asMap().entries.map(
             (entry) => _ActivityItem(
              data: entry.value,
             )
               .animate()
               .fadeIn(
                delay: Duration(
                  milliseconds: 700 + entry.key * 60),
                duration: 400.ms,
               ),
            ),
          const SizedBox(height: 32),
         ],
        ),
       ),
      ),
     ),
    ),
   ],
  ),
 ),
   bottomNavigationBar: _PatientBottomNav(
    currentIndex: 0,
    onTap: (i) {
     if (i == 2) context.push(AppRoutes.consultationConsent);
     if (i == 1) context.push(AppRoutes.patientAppointments);
     if (i == 3) {
      context.push(AppRoutes.patientProfile);
     }
    },
   ),
  ),
 );
}

 String _getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  return 'Good Evening';
 }
}

class _QuickStatsRow extends StatelessWidget {
 final int appointmentCount;

 const _QuickStatsRow({required this.appointmentCount});

 @override
 Widget build(BuildContext context) {
  return Row(
   children: [
    Expanded(
     child: StatCard(
      label: 'Upcoming',
      value: '$appointmentCount',
      icon: Icons.calendar_today_rounded,
      accentColor: AppColors.primary,
      change: '+1',
     ),
    ),
    const SizedBox(width: 8),
    Expanded(
     child: StatCard(
      label: 'Prescriptions',
      value: '3',
      icon: Icons.medication_rounded,
      accentColor: AppColors.secondary,
     ),
    ),
    const SizedBox(width: 8),
    Expanded(
     child: StatCard(
      label: 'AI Sessions',
      value: '12',
      icon: Icons.smart_toy_rounded,
      accentColor: AppColors.accent,
      change: '+3',
     ),
    ),
   ],
  );
 }
}

class _SectionHeader extends StatelessWidget {
 final String title;
 final String actionLabel;
 final VoidCallback onAction;

 const _SectionHeader({
  required this.title,
  required this.actionLabel,
  required this.onAction,
 });

 @override
 Widget build(BuildContext context) {
  return Row(
   mainAxisAlignment: MainAxisAlignment.spaceBetween,
   children: [
    Text(title, style: AppTextStyles.headingSmall),
    GestureDetector(
     onTap: onAction,
     child: Text(actionLabel, style: AppTextStyles.link),
    ),
   ],
  );
 }
}

class _ActivityItem extends StatelessWidget {
 final Map<String, dynamic> data;

 const _ActivityItem({required this.data});

 @override
 Widget build(BuildContext context) {
  return GlassCard(
   padding: const EdgeInsets.all(14),
   margin: const EdgeInsets.only(bottom: 10),
   child: Row(
    children: [
     Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
       color: AppColors.background,
       shape: BoxShape.circle,
      ),
      child: Center(
       child: Icon(
        data['icon'] as IconData,
        size: 20,
        color: AppColors.primary,
       ),
      ),
     ),
     const SizedBox(width: 14),
     Expanded(
      child: Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
        Text(
         data['title'] as String,
         style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
         ),
        ),
        const SizedBox(height: 2),
        Text(
         data['subtitle'] as String,
         style: AppTextStyles.bodySmall,
        ),
       ],
      ),
     ),
     Text(
      data['time'] as String,
      style: AppTextStyles.caption,
     ),
    ],
   ),
  );
 }
}

class _EmptyAppointments extends StatelessWidget {
 final VoidCallback? onBookDoctor;

 const _EmptyAppointments({this.onBookDoctor});

 @override
 Widget build(BuildContext context) {
  return GlassCard(
   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
   child: Center(
    child: Column(
     children: [
      const Icon(
       Icons.calendar_today_outlined,
       color: AppColors.textMuted,
       size: 36,
      ),
      const SizedBox(height: 12),
      Text(
       'No upcoming appointments',
       style: AppTextStyles.bodyMedium,
      ),
      const SizedBox(height: 6),
      Text(
       'Consult with AI triage or book an accredited specialist directly',
       textAlign: TextAlign.center,
       style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
      ),
      if (onBookDoctor != null) ...[
       const SizedBox(height: 16),
       OutlinedButton.icon(
        onPressed: onBookDoctor,
        icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
        label: const Text('Book Doctor Appointment', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
         side: const BorderSide(color: AppColors.primary),
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
       ),
      ],
     ],
    ),
   ),
  );
 }
}

class _PatientBottomNav extends StatelessWidget {
 final int currentIndex;
 final ValueChanged<int> onTap;

 const _PatientBottomNav({
  required this.currentIndex,
  required this.onTap,
 });

 @override
 Widget build(BuildContext context) {
  return Container(
   decoration: const BoxDecoration(
    color: AppColors.backgroundSecondary,
    border: Border(top: BorderSide(color: AppColors.border)),
   ),
   child: SafeArea(
    child: Padding(
     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
     child: Row(
       children: [
        Expanded(
         child: _NavItem(
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard_rounded,
          label: 'Home',
          isActive: currentIndex == 0,
          onTap: () => onTap(0),
         ),
        ),
        Expanded(
         child: _NavItem(
          icon: Icons.calendar_today_outlined,
          activeIcon: Icons.calendar_today_rounded,
          label: 'Bookings',
          isActive: currentIndex == 1,
          onTap: () => onTap(1),
         ),
        ),
        Expanded(child: _AINavButton(onTap: () => onTap(2))),
        Expanded(
         child: _NavItem(
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          label: 'Profile',
          isActive: currentIndex == 3,
          onTap: () => onTap(3),
         ),
        ),
       ],
     ),
    ),
   ),
  );
 }
}

class _NavItem extends StatelessWidget {
 final IconData icon;
 final IconData activeIcon;
 final String label;
 final bool isActive;
 final VoidCallback onTap;

 const _NavItem({
  required this.icon,
  required this.activeIcon,
  required this.label,
  required this.isActive,
  required this.onTap,
 });

 @override
 Widget build(BuildContext context) {
  return GestureDetector(
   onTap: onTap,
    child: AnimatedContainer(
     duration: const Duration(milliseconds: 200),
     padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
     decoration: BoxDecoration(
      color: isActive ? AppColors.primary.withValues(alpha: 0.1) : null,
      borderRadius: BorderRadius.circular(12),
     ),
     child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
       Icon(
        isActive ? activeIcon : icon,
        color: isActive ? AppColors.primary : AppColors.textMuted,
        size: 22,
       ),
       const SizedBox(height: 4),
       FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
         label,
         style: AppTextStyles.labelSmall.copyWith(
          color: isActive ? AppColors.primary : AppColors.textMuted,
          fontWeight:
            isActive ? FontWeight.w600 : FontWeight.w400,
         ),
        ),
       ),
      ],
     ),
    ),
  );
 }
}

class _AINavButton extends StatefulWidget {
 final VoidCallback onTap;

 const _AINavButton({required this.onTap});

 @override
 State<_AINavButton> createState() => _AINavButtonState();
}

class _AINavButtonState extends State<_AINavButton>
  with SingleTickerProviderStateMixin {
 late AnimationController _controller;
 late Animation<double> _glow;

 @override
 void initState() {
  super.initState();
  _controller = AnimationController(
   vsync: this,
   duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);
  _glow =
    Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
 }

 @override
 void dispose() {
  _controller.dispose();
  super.dispose();
 }

 @override
 Widget build(BuildContext context) {
  return GestureDetector(
   onTap: widget.onTap,
   child: AnimatedBuilder(
    animation: _glow,
    builder: (context, _) => Container(
     width: 54,
     height: 54,
     decoration: BoxDecoration(
      gradient: const LinearGradient(
       colors: AppColors.primaryGradient,
       begin: Alignment.topLeft,
       end: Alignment.bottomRight,
      ),
      shape: BoxShape.circle,
      boxShadow: [
       BoxShadow(
        color:
          AppColors.primary.withValues(alpha: 0.5 * _glow.value),
        blurRadius: 16 * _glow.value,
        spreadRadius: 2,
       ),
      ],
     ),
     child: const Icon(
      Icons.auto_awesome,
      color: Colors.white,
      size: 24,
     ),
    ),
   ),
  );
 }
}

class _PulseDot extends StatefulWidget {
 final Color color;

 const _PulseDot({required this.color});

 @override
 State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
  with SingleTickerProviderStateMixin {
 late AnimationController _controller;

 @override
 void initState() {
  super.initState();
  _controller = AnimationController(
   vsync: this,
   duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);
 }

 @override
 void dispose() {
  _controller.dispose();
  super.dispose();
 }

 @override
 Widget build(BuildContext context) {
  return AnimatedBuilder(
   animation: _controller,
   builder: (_, _) => Container(
    width: 7,
    height: 7,
    decoration: BoxDecoration(
     color: widget.color.withValues(alpha: 0.6 + 0.4 * _controller.value),
     shape: BoxShape.circle,
     boxShadow: [
      BoxShadow(
       color: widget.color
         .withValues(alpha: 0.6 * _controller.value),
       blurRadius: 6,
       spreadRadius: 1,
      ),
     ],
    ),
   ),
  );
 }
}

class _DashboardBackground extends StatelessWidget {
 @override
 Widget build(BuildContext context) {
  return Positioned.fill(
   child: Stack(
    children: [
     Positioned(
      top: -100,
      right: -80,
      child: Container(
       width: 250,
       height: 250,
       decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.04),
       ),
      ),
     ),
     Positioned(
      bottom: 200,
      left: -60,
      child: Container(
       width: 180,
       height: 180,
       decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.secondary.withValues(alpha: 0.04),
       ),
      ),
     ),
    ],
   ),
  );
 }
}
