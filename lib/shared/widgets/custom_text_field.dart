import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clay_containers/clay_containers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Custom text field with validation and styling
class CustomTextField extends StatefulWidget {
 final String label;
 final String? hint;
 final TextEditingController? controller;
 final bool isPassword;
 final TextInputType keyboardType;
 final String? Function(String?)? validator;
 final IconData? prefixIcon;
 final Widget? suffix;
 final int? maxLines;
 final bool enabled;
 final void Function(String)? onChanged;
 final List<TextInputFormatter>? inputFormatters;
 final TextInputAction? textInputAction;
 final FocusNode? focusNode;
 final VoidCallback? onEditingComplete;

 const CustomTextField({
  super.key,
  required this.label,
  this.hint,
  this.controller,
  this.isPassword = false,
  this.keyboardType = TextInputType.text,
  this.validator,
  this.prefixIcon,
  this.suffix,
  this.maxLines = 1,
  this.enabled = true,
  this.onChanged,
  this.inputFormatters,
  this.textInputAction,
  this.focusNode,
  this.onEditingComplete,
 });

 @override
 State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
 bool _obscureText = true;
 bool _isFocused = false;
 String? _errorText;
 late FocusNode _focusNode;

 @override
 void initState() {
  super.initState();
  _focusNode = widget.focusNode ?? FocusNode();
  _focusNode.addListener(() {
   setState(() {
    _isFocused = _focusNode.hasFocus;
   });
  });
 }

 @override
 void dispose() {
  if (widget.focusNode == null) {
   _focusNode.dispose();
  }
  super.dispose();
 }

 @override
 Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final baseColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
  final hasError = _errorText != null;

  return Column(
   crossAxisAlignment: CrossAxisAlignment.start,
   children: [
    Text(
     widget.label,
     style: AppTextStyles.labelMedium.copyWith(
      color: _isFocused
        ? AppColors.primary
        : hasError
          ? AppColors.error
          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
      fontWeight: FontWeight.w500,
     ),
    ),
    const SizedBox(height: 8),
    ClayContainer(
     color: baseColor,
     borderRadius: 12,
     depth: 20,
     spread: 2,
     emboss: true,
     child: TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      obscureText: widget.isPassword && _obscureText,
      keyboardType: widget.keyboardType,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      enabled: widget.enabled,
      inputFormatters: widget.inputFormatters,
      textInputAction: widget.textInputAction,
      onEditingComplete: widget.onEditingComplete,
      style: AppTextStyles.bodyLarge.copyWith(
       color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
      decoration: InputDecoration(
       hintText: widget.hint,
       hintStyle: AppTextStyles.bodyMedium.copyWith(
        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
       ),
       filled: false,
       contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
       ),
       prefixIcon: widget.prefixIcon != null
         ? Icon(
           widget.prefixIcon,
           color: _isFocused
             ? AppColors.primary
             : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
           size: 20,
          )
         : null,
       suffixIcon: widget.isPassword
         ? GestureDetector(
           onTap: () {
            setState(() {
             _obscureText = !_obscureText;
            });
           },
           child: Icon(
            _obscureText
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            size: 20,
           ),
          )
         : widget.suffix,
       border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
       ),
       enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: hasError ? const BorderSide(color: AppColors.error) : BorderSide.none,
       ),
       focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: hasError ? const BorderSide(color: AppColors.error, width: 1.5) : const BorderSide(color: AppColors.primary, width: 1.5),
       ),
       errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
       ),
       focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
       ),
      ),
      validator: (value) {
       final error = widget.validator?.call(value);
       WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
         setState(() {
          _errorText = error;
         });
        }
       });
       return null; // We show custom error below
      },
      onChanged: widget.onChanged,
     ),
    ),
    if (hasError) ...[
     const SizedBox(height: 6),
     Row(
      children: [
       const Icon(
        Icons.info_outline_rounded,
        size: 13,
        color: AppColors.error,
       ),
       const SizedBox(width: 5),
       Expanded(
        child: Text(
         _errorText!,
         style: AppTextStyles.caption.copyWith(
          color: AppColors.error,
         ),
        ),
       ),
      ],
     ),
    ],
   ],
  );
 }
}

/// Password strength indicator
class PasswordStrengthIndicator extends StatelessWidget {
 final String password;

 const PasswordStrengthIndicator({super.key, required this.password});

 @override
 Widget build(BuildContext context) {
  final strength = _getStrength(password);
  final info = _strengthInfo(strength);

  if (password.isEmpty) return const SizedBox.shrink();

  return Column(
   crossAxisAlignment: CrossAxisAlignment.start,
   children: [
    const SizedBox(height: 8),
    Row(
     children: List.generate(4, (index) {
      return Expanded(
       child: Container(
        margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
        height: 3,
        decoration: BoxDecoration(
         color: index < strength ? info.color : AppColors.border,
         borderRadius: BorderRadius.circular(2),
        ),
       ),
      );
     }),
    ),
    const SizedBox(height: 6),
    Text(
     info.label,
     style: AppTextStyles.caption.copyWith(color: info.color),
    ),
   ],
  );
 }

 int _getStrength(String password) {
  if (password.isEmpty) return 0;
  int strength = 0;
  if (password.length >= 8) strength++;
  if (password.contains(RegExp(r'[A-Z]'))) strength++;
  if (password.contains(RegExp(r'[0-9]'))) strength++;
  if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
  return strength;
 }

 ({String label, Color color}) _strengthInfo(int strength) {
  switch (strength) {
   case 1:
    return (label: 'Weak', color: AppColors.error);
   case 2:
    return (label: 'Fair', color: AppColors.warning);
   case 3:
    return (label: 'Good', color: AppColors.primary);
   case 4:
    return (label: 'Strong', color: AppColors.success);
   default:
    return (label: '', color: AppColors.border);
  }
 }
}
