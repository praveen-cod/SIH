import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/user_model.dart';
import 'package:clay_containers/clay_containers.dart';

/// Role selector widget for switching between Patient / Doctor / Admin
class RoleSelector extends StatelessWidget {
 final UserRole selectedRole;
 final ValueChanged<UserRole> onRoleChanged;

 const RoleSelector({
  super.key,
  required this.selectedRole,
  required this.onRoleChanged,
 });

 @override
 Widget build(BuildContext context) {
  return ClayContainer(
   depth: 10,
   spread: 2,
   borderRadius: 16,
   color: AppColors.background,
   child: Padding(
    padding: const EdgeInsets.all(5),
    child: Row(
     children: UserRole.values.map((role) {
      final isSelected = role == selectedRole;
      return Expanded(
       child: GestureDetector(
        onTap: () => onRoleChanged(role),
        child: AnimatedContainer(
         duration: const Duration(milliseconds: 250),
         curve: Curves.easeInOut,
         padding: const EdgeInsets.symmetric(vertical: 12),
         decoration: BoxDecoration(
          gradient: isSelected
            ? const LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
             )
            : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
            ? [
              BoxShadow(
               color: AppColors.primary.withValues(alpha: 0.35),
               blurRadius: 12,
               offset: const Offset(0, 4),
              ),
             ]
            : null,
         ),
         child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
           Icon(
            role.icon,
            size: isSelected ? 24 : 20,
            color: isSelected ? Colors.white : AppColors.textSecondary,
           ),
           const SizedBox(height: 4),
           Text(
            role.displayName,
            style: AppTextStyles.labelMedium.copyWith(
             color: isSelected
               ? Colors.white
               : AppColors.textMuted,
             fontWeight: isSelected
               ? FontWeight.w600
               : FontWeight.w400,
             fontSize: 12,
            ),
           ),
          ],
         ),
        ).animate(target: isSelected ? 1 : 0),
       ),
      );
     }).toList(),
    ),
   ),
  );
 }
}
