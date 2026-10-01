import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/theme_provider.dart';
import 'package:go_router/go_router.dart';

/// Navigation item data
class NavItem {
 final String title;
 final IconData icon;
 final IconData activeIcon;
 final String? route;

 const NavItem({
  required this.title,
  required this.icon,
  required this.activeIcon,
  this.route,
 });
}

/// App drawer for patient navigation
class PatientDrawer extends StatelessWidget {
 final String userName;
 final String userId;
 final VoidCallback onLogout;

 const PatientDrawer({
  super.key,
  required this.userName,
  required this.userId,
  required this.onLogout,
 });

 static const List<NavItem> _items = [
  NavItem(
   title: 'Dashboard',
   icon: Icons.dashboard_outlined,
   activeIcon: Icons.dashboard_rounded,
   route: AppRoutes.patientDashboard,
  ),
  NavItem(
   title: 'Book Appointment',
   icon: Icons.calendar_today_outlined,
   activeIcon: Icons.calendar_today_rounded,
   route: AppRoutes.bookDoctor,
  ),
  NavItem(
   title: 'My Appointments',
   icon: Icons.event_note_outlined,
   activeIcon: Icons.event_note_rounded,
   route: AppRoutes.patientAppointments,
  ),
  NavItem(
   title: 'AI Consultation',
   icon: Icons.smart_toy_outlined,
   activeIcon: Icons.smart_toy_rounded,
   route: AppRoutes.consultationConsent,
  ),
  NavItem(
   title: 'Medical History',
   icon: Icons.history_outlined,
   activeIcon: Icons.history_rounded,
   route: AppRoutes.patientProfile,
  ),
  NavItem(
   title: 'Prescriptions & Docs',
   icon: Icons.medication_outlined,
   activeIcon: Icons.medication_rounded,
   route: AppRoutes.patientDocuments,
  ),
  NavItem(
   title: 'Profile', 
   icon: Icons.person_outline_rounded, 
   activeIcon: Icons.person_rounded, 
   route: AppRoutes.patientProfile,
  ),
  NavItem(
   title: 'Health Summary',
   icon: Icons.favorite_border_rounded,
   activeIcon: Icons.favorite_rounded,
   route: AppRoutes.healthSummary,
  ),
  NavItem(
   title: 'Recent Activity',
   icon: Icons.list_alt_outlined,
   activeIcon: Icons.list_alt_rounded,
   route: AppRoutes.recentActivity,
  ),
  NavItem(
   title: 'Settings', icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, route: AppRoutes.settings,
  ),
 ];

 @override
 Widget build(BuildContext context) {
  return _AppDrawer(
   userName: userName,
   userSubtitle: userId,
   userRole: 'Patient',
   accentColor: AppColors.patientPrimary,
   items: _items,
   currentRoute: AppRoutes.patientDashboard,
   onLogout: onLogout,
  );
 }
}

/// App drawer for doctor navigation
class DoctorDrawer extends StatelessWidget {
 final String userName;
 final String specialty;
 final VoidCallback onLogout;

 const DoctorDrawer({
  super.key,
  required this.userName,
  required this.specialty,
  required this.onLogout,
 });

 static const List<NavItem> _items = [
  NavItem(
   title: 'Dashboard',
   icon: Icons.dashboard_outlined,
   activeIcon: Icons.dashboard_rounded,
   route: AppRoutes.doctorDashboard,
  ),
  NavItem(
   title: 'Appointments',
   icon: Icons.calendar_today_outlined,
   activeIcon: Icons.calendar_today_rounded,
   route: AppRoutes.doctorAppointments,
  ),
  NavItem(
   title: 'Patients',
   icon: Icons.group_outlined,
   activeIcon: Icons.group_rounded,
   route: AppRoutes.doctorPatients,
  ),
  NavItem(
   title: 'Emergencies',
   icon: Icons.emergency_outlined,
   activeIcon: Icons.emergency_rounded,
   route: AppRoutes.emergencyEscalation,
  ),
  NavItem(
   title: 'Availability',
   icon: Icons.access_time_outlined,
   activeIcon: Icons.access_time_rounded,
   route: AppRoutes.doctorAvailability,
  ),

  NavItem(
   title: 'Profile', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, route: AppRoutes.profile,
  ),
  NavItem(
   title: 'Recent Activity',
   icon: Icons.list_alt_outlined,
   activeIcon: Icons.list_alt_rounded,
   route: AppRoutes.recentActivity,
  ),
  NavItem(
   title: 'Settings', icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, route: AppRoutes.settings,
  ),
 ];

 @override
 Widget build(BuildContext context) {
  return _AppDrawer(
   userName: userName,
   userSubtitle: specialty,
   userRole: 'Doctor',
   accentColor: AppColors.primary,
   items: _items,
   currentRoute: AppRoutes.doctorDashboard,
   onLogout: onLogout,
  );
 }
}

/// App drawer for admin navigation
class AdminDrawer extends StatelessWidget {
 final VoidCallback onLogout;

 const AdminDrawer({super.key, required this.onLogout});

 static const List<NavItem> _items = [
  NavItem(
   title: 'Dashboard',
   icon: Icons.dashboard_outlined,
   activeIcon: Icons.dashboard_rounded,
   route: AppRoutes.adminDashboard,
  ),
  NavItem(
   title: 'Patients',
   icon: Icons.group_outlined,
   activeIcon: Icons.group_rounded,
   route: AppRoutes.adminPatients,
  ),
  NavItem(
   title: 'Doctors',
   icon: Icons.local_hospital_outlined,
   activeIcon: Icons.local_hospital_rounded,
   route: AppRoutes.adminDoctors,
  ),
  NavItem(
   title: 'Appointments',
   icon: Icons.calendar_month_outlined,
   activeIcon: Icons.calendar_month_rounded,
   route: AppRoutes.adminAppointments,
  ),
  NavItem(
   title: 'AI Analytics',
   icon: Icons.analytics_outlined,
   activeIcon: Icons.analytics_rounded,
  ),

  NavItem(
   title: 'Emergency Alerts',
   icon: Icons.emergency_outlined,
   activeIcon: Icons.emergency_rounded,
   route: AppRoutes.emergencyEscalation,
  ),
  NavItem(
   title: 'Recent Activity',
   icon: Icons.list_alt_outlined,
   activeIcon: Icons.list_alt_rounded,
   route: AppRoutes.recentActivity,
  ),
  NavItem(
   title: 'Settings', icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, route: AppRoutes.settings,
  ),
 ];

 @override
 Widget build(BuildContext context) {
  return _AppDrawer(
   userName: 'HealthCall AI',
   userSubtitle: 'Admin Portal',
   userRole: 'Administrator',
   accentColor: AppColors.primary,
   items: _items,
   currentRoute: AppRoutes.adminDashboard,
   onLogout: onLogout,
  );
 }
}

/// Internal shared drawer implementation with subtle glow on active item
class _AppDrawer extends StatelessWidget {
 final String userName;
 final String userSubtitle;
 final String userRole;
 final Color accentColor;
 final List<NavItem> items;
 final String currentRoute;
 final VoidCallback onLogout;

 const _AppDrawer({
  required this.userName,
  required this.userSubtitle,
  required this.userRole,
  required this.accentColor,
  required this.items,
  required this.currentRoute,
  required this.onLogout,
 });

 @override
 Widget build(BuildContext context) {
  return Drawer(
   backgroundColor: AppColors.backgroundSecondary,
   width: MediaQuery.of(context).size.width * 0.80,
   child: SafeArea(
    child: Column(
     children: [
      // Header
      Container(
       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
       decoration: BoxDecoration(
        gradient: LinearGradient(
         colors: [
          accentColor.withValues(alpha: 0.18),
          const Color(0xFF8B5CF6).withValues(alpha: 0.08),
          Colors.transparent,
         ],
         begin: Alignment.topCenter,
         end: Alignment.bottomCenter,
        ),
       ),
       child: Column(
        children: [
         Row(
          children: [
           Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
             gradient: const LinearGradient(
              colors: [Color(0xFF2D8EFF), Color(0xFF8B5CF6)],
             ),
             shape: BoxShape.circle,
             boxShadow: [
              BoxShadow(
               color: const Color(0xFF2D8EFF).withValues(alpha: 0.35),
               blurRadius: 12,
               offset: const Offset(0, 3),
              ),
             ],
            ),
            child: const Center(
             child: Icon(
              Icons.health_and_safety_rounded,
              color: Colors.white,
              size: 24,
             ),
            ),
           ),
           const SizedBox(width: 14),
           Expanded(
            child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
              Text(
               userName,
               style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
               ),
               overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
               userSubtitle,
               style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
               ),
               overflow: TextOverflow.ellipsis,
              ),
             ],
            ),
           ),
          ],
         ),
         const SizedBox(height: 14),
         Align(
          alignment: Alignment.centerLeft,
          child: Container(
           padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 4,
           ),
           decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
             color: accentColor.withValues(alpha: 0.3),
             width: 0.5,
            ),
           ),
           child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
             Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
               color: accentColor,
               shape: BoxShape.circle,
              ),
             ),
             const SizedBox(width: 6),
             Text(
              userRole,
              style: AppTextStyles.labelSmall.copyWith(
               color: accentColor,
               fontWeight: FontWeight.w600,
              ),
             ),
            ],
           ),
          ),
         ),
        ],
       ),
      ),
      const Divider(height: 1, color: AppColors.border),
      const SizedBox(height: 8),
      // Nav items
      Expanded(
       child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: items.length,
        itemBuilder: (context, index) {
         final item = items[index];
         final isActive = item.route == currentRoute;

         return Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
           color: isActive
             ? accentColor.withValues(alpha: 0.15)
             : Colors.transparent,
           borderRadius: BorderRadius.circular(12),
           border: isActive
             ? Border.all(
               color: accentColor.withValues(alpha: 0.4),
               width: 1,
              )
             : null,
           boxShadow: isActive
             ? [
               BoxShadow(
                color: accentColor.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 2),
               ),
              ]
             : null,
          ),
          child: Material(
           type: MaterialType.transparency,
           child: ListTile(
            leading: Icon(
            isActive ? item.activeIcon : item.icon,
            color: isActive ? accentColor : AppColors.textMuted,
            size: 22,
           ),
           title: Text(
            item.title,
            style: AppTextStyles.bodyMedium.copyWith(
             color: isActive
               ? AppColors.textPrimary
               : AppColors.textSecondary,
             fontWeight:
               isActive ? FontWeight.w600 : FontWeight.w400,
            ),
           ),
           dense: true,
           shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
           ),
           contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 0,
           ),
           onTap: () {
            final router = GoRouter.of(context);
            Navigator.of(context).pop();
            if (item.route != null) {
             if (item.route != currentRoute) {
              if (item.route == AppRoutes.settings || 
                  item.route == AppRoutes.profile || 
                  item.route == AppRoutes.patientProfile || 
                  item.route == AppRoutes.patientDocuments ||
                  item.route == AppRoutes.emergencyEscalation) {
               router.push(item.route!);
              } else {
               router.go(item.route!);
              }
             }
            } else {
             router.push(
              '${AppRoutes.comingSoon}?title=${Uri.encodeComponent(item.title)}',
             );
            }
           },
          ),
         ),
        );
       },
       ),
      ),
      const Divider(height: 1, color: AppColors.border),
      // Switch Role / Account
      Padding(
       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
       child: Material(
        type: MaterialType.transparency,
        child: ListTile(
         leading: const Icon(
         Icons.switch_account_rounded,
         color: AppColors.primaryLight,
         size: 22,
        ),
        title: Text(
         'Switch Role / Account',
         style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
         ),
        ),
        dense: true,
        shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        onTap: () {
         Navigator.of(context).pop();
         onLogout();
        },
       ),
      ),
     ),
      // Logout
      Padding(
       padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
       child: Material(
        type: MaterialType.transparency,
        child: ListTile(
         leading: const Icon(
         Icons.logout_rounded,
         color: AppColors.error,
         size: 22,
        ),
        title: Text(
         'Logout',
         style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.error,
          fontWeight: FontWeight.w600,
         ),
        ),
        dense: true,
        shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        onTap: () {
         Navigator.of(context).pop();
         onLogout();
        },
       ),
      ),
     ),
    ],
    ),
   ),
  );
 }
}

/// Dashboard header with hamburger, logo, notifications, and theme toggle
class DashboardHeader extends ConsumerWidget {
 final GlobalKey<ScaffoldState> scaffoldKey;
 final int notificationCount;
 final VoidCallback? onNotificationTap;

 const DashboardHeader({
  super.key,
  required this.scaffoldKey,
  this.notificationCount = 3,
  this.onNotificationTap,
 });

 @override
 Widget build(BuildContext context, WidgetRef ref) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return Row(
   children: [
    GestureDetector(
     onTap: () => scaffoldKey.currentState?.openDrawer(),
     child: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
       color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
       borderRadius: BorderRadius.circular(12),
       border: Border.all(color: AppColors.border),
      ),
      child: Icon(
       Icons.menu_rounded,
       color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
       size: 22,
      ),
     ),
    ),
    Expanded(
     child: Center(
      child: Row(
       mainAxisSize: MainAxisSize.min,
       children: [
        Container(
         width: 22,
         height: 22,
         decoration: BoxDecoration(
          gradient: const LinearGradient(
           colors: [Color(0xFF2D8EFF), Color(0xFF8B5CF6)],
          ),
          borderRadius: BorderRadius.circular(6),
         ),
         child: const Center(
          child: Icon(
           Icons.add_rounded,
           color: Colors.white,
           size: 16,
          ),
         ),
        ),
        const SizedBox(width: 8),
        Text(
         'HealthCall AI',
         style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          letterSpacing: -0.3,
         ),
        ),
       ],
      ),
     ),
    ),
    GestureDetector(
     onTap: () {
      ref.read(themeModeProvider.notifier).toggleTheme();
     },
     child: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
       color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
       borderRadius: BorderRadius.circular(12),
       border: Border.all(color: AppColors.border),
      ),
      child: Icon(
       isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
       color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
       size: 20,
      ),
     ),
    ),
    const SizedBox(width: 10),
    GestureDetector(
     onTap: onNotificationTap ??
       () {
        context.push('${AppRoutes.comingSoon}?title=Notifications');
       },
     child: Stack(
      children: [
       Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
         color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
         borderRadius: BorderRadius.circular(12),
         border: Border.all(color: AppColors.border),
        ),
        child: Icon(
         Icons.notifications_outlined,
         color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
         size: 22,
        ),
       ),
       if (notificationCount > 0)
        Positioned(
         top: 7,
         right: 7,
         child: Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
           color: AppColors.error,
           shape: BoxShape.circle,
          ),
          constraints: const BoxConstraints(
           minWidth: 10,
           minHeight: 10,
          ),
         ),
        ),
      ],
     ),
    ),
   ],
  );
 }
}
