import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:clay_containers/clay_containers.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/localization/language_provider.dart';
import '../../../models/user_model.dart';
import '../../../repositories/auth_repository.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/language_selector_sheet.dart';
import '../widgets/role_selector.dart';

class LoginScreen extends ConsumerStatefulWidget {
 const LoginScreen({super.key});

 @override
 ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
 final _formKey = GlobalKey<FormState>();
 final _emailCtrl = TextEditingController();
 final _passwordCtrl = TextEditingController();

 UserRole _selectedRole = UserRole.patient;

 @override
 void initState() {
  super.initState();
  _fillCredentialsForRole(_selectedRole);
 }

 void _fillCredentialsForRole(UserRole role) {
  _emailCtrl.text = '${role.name}@demo.com';
  _passwordCtrl.text = 'Demo@1234';
 }

 @override
 void dispose() {
  _emailCtrl.dispose();
  _passwordCtrl.dispose();
  super.dispose();
 }

 String get _emailHint {
  switch (_selectedRole) {
   case UserRole.patient:
    return 'patient@demo.com';
   case UserRole.doctor:
    return 'doctor@demo.com';
   case UserRole.admin:
    return 'admin@demo.com';
  }
 }

 Future<void> _handleLogin() async {
  if (!_formKey.currentState!.validate()) return;

  final router = GoRouter.of(context);
  final targetRole = _selectedRole;

  final success = await ref.read(authProvider.notifier).login(
     email: _emailCtrl.text,
     password: _passwordCtrl.text,
     role: targetRole,
    );

  if (success && mounted) {
   switch (targetRole) {
    case UserRole.patient:
     // Check if language preference is already selected, otherwise prompt
     final langState = ref.read(languageProvider);
     if (!langState.hasChosenPreference) {
      await LanguageSelectorSheet.show(
       context,
       isMandatory: false,
      );
     }
     if (mounted) {
      router.go(AppRoutes.patientDashboard);
     }
     break;
    case UserRole.doctor:
     router.go(AppRoutes.doctorDashboard);
     break;
    case UserRole.admin:
     router.go(AppRoutes.adminDashboard);
     break;
   }
  }
 }

 Future<void> _handleQuickLogin() async {
  _fillCredentialsForRole(_selectedRole);
  await _handleLogin();
 }

 @override
 Widget build(BuildContext context) {
  final authState = ref.watch(authProvider);

  // Show snackbar on error
  ref.listen(authProvider, (prev, next) {
   if (next.errorMessage != null && prev?.errorMessage != next.errorMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(
      content: Text(next.errorMessage!),
      backgroundColor: AppColors.error,
     ),
    );
    ref.read(authProvider.notifier).clearError();
   }
  });

  return Scaffold(
   backgroundColor: AppColors.background,
   body: GestureDetector(
    onTap: () => FocusScope.of(context).unfocus(),
    child: Stack(
     children: [
      // Background gradient blobs
      _BackgroundGradient(),
      SafeArea(
       child: Center(
        child: ConstrainedBox(
         constraints: const BoxConstraints(maxWidth: 480),
         child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
           key: _formKey,
           child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
           const SizedBox(height: 24),
           // Top Language Selector Pill
           Align(
            alignment: Alignment.centerRight,
            child: Consumer(
             builder: (context, ref, _) {
              final currentLang = ref.watch(languageProvider).currentLanguage;
              return Material(
               color: Colors.transparent,
               child: InkWell(
                onTap: () => LanguageSelectorSheet.show(context),
                borderRadius: BorderRadius.circular(20),
                child: ClayContainer(
                 depth: 10,
                 spread: 2,
                 borderRadius: 20,
                 color: AppColors.background,
                 child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                    const Icon(
                     Icons.language_rounded,
                     size: 16,
                     color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                     '${currentLang.name} (${currentLang.code.toUpperCase()})',
                     style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                     ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                     Icons.keyboard_arrow_down_rounded,
                     size: 16,
                     color: AppColors.textMuted,
                    ),
                   ],
                  ),
                 ),
                ),
               ),
              );
             },
            ),
           ),
           const SizedBox(height: 20),
           // Logo
           const AppLogo(size: 64, showTagline: true)
             .animate()
             .fadeIn(duration: 700.ms)
             .slideY(begin: -0.2, end: 0),
           const SizedBox(height: 32),
           // Role Selector
           RoleSelector(
            selectedRole: _selectedRole,
            onRoleChanged: (role) {
             setState(() {
              _selectedRole = role;
              _fillCredentialsForRole(role);
             });
             ref.read(authProvider.notifier).clearError();
            },
           )
             .animate()
             .fadeIn(delay: 200.ms, duration: 500.ms),
           const SizedBox(height: 28),
           // Login Form Card
           _LoginFormCard(
            role: _selectedRole,
            emailCtrl: _emailCtrl,
            passwordCtrl: _passwordCtrl,
            emailHint: _emailHint,
            isLoading: authState.isLoading,
            onLogin: _handleLogin,
            onSignUp: _selectedRole == UserRole.patient
              ? () => context.push(AppRoutes.signup)
              : null,
            onForgotPassword: () => context.go(
             '${AppRoutes.comingSoon}?title=Forgot+Password',
            ),
            formKey: _formKey,
           )
             .animate()
             .fadeIn(delay: 350.ms, duration: 500.ms)
             .slideY(begin: 0.1, end: 0),
           const SizedBox(height: 24),
           // Instant AI Consultation (Patient only)
           if (_selectedRole == UserRole.patient) ...[
            Row(
             children: [
              const Expanded(child: Divider()),
              Padding(
               padding:
                 const EdgeInsets.symmetric(horizontal: 12),
               child: Text(
                'or',
                style: AppTextStyles.bodySmall.copyWith(
                 color: AppColors.textMuted,
                ),
               ),
              ),
              const Expanded(child: Divider()),
             ],
            ),
            const SizedBox(height: 20),
            AIActionButton(
             onPressed: () => context.push(AppRoutes.instantAI),
            )
              .animate()
              .fadeIn(delay: 500.ms, duration: 500.ms),
            const SizedBox(height: 8),
            Text(
             'No account required · Instant access',
             style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
             ),
             textAlign: TextAlign.center,
            ),
           ],
             // Demo credentials hint with quick fill and 1-tap login
             const SizedBox(height: 32),
             _DemoCredentialsHint(
              role: _selectedRole,
              isLoading: authState.isLoading,
              onFill: () {
               setState(() => _fillCredentialsForRole(_selectedRole));
               ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                 content: Text('Demo credentials loaded for ${_selectedRole.displayName}'),
                 backgroundColor: AppColors.primary,
                 duration: const Duration(seconds: 1),
                ),
               );
              },
              onQuickLogin: _handleQuickLogin,
             )
               .animate()
               .fadeIn(delay: 600.ms, duration: 500.ms),
             const SizedBox(height: 32),
            ],
           ),
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
}

class _LoginFormCard extends StatelessWidget {
 final UserRole role;
 final TextEditingController emailCtrl;
 final TextEditingController passwordCtrl;
 final String emailHint;
 final bool isLoading;
 final VoidCallback onLogin;
 final VoidCallback? onSignUp;
 final VoidCallback onForgotPassword;
 final GlobalKey<FormState> formKey;

 const _LoginFormCard({
  required this.role,
  required this.emailCtrl,
  required this.passwordCtrl,
  required this.emailHint,
  required this.isLoading,
  required this.onLogin,
  required this.onSignUp,
  required this.onForgotPassword,
  required this.formKey,
 });

 @override
 Widget build(BuildContext context) {
  return ClayContainer(
   depth: 20,
   spread: 4,
   borderRadius: 24,
   color: AppColors.background,
   child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
     crossAxisAlignment: CrossAxisAlignment.stretch,
     children: [
      Text(
       '${role.displayName} Login',
       style: AppTextStyles.headingMedium,
      ),
      const SizedBox(height: 4),
      Text(
       _subtitleForRole(role),
       style: AppTextStyles.bodySmall,
      ),
      const SizedBox(height: 24),
      CustomTextField(
       label: role == UserRole.patient ? 'Email or Patient ID' : 'Email',
       hint: emailHint,
       controller: emailCtrl,
       prefixIcon: Icons.email_outlined,
       keyboardType: TextInputType.emailAddress,
       textInputAction: TextInputAction.next,
       validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Email is required';
        return null;
       },
      ),
      const SizedBox(height: 16),
      CustomTextField(
       label: 'Password',
       hint: '••••••••',
       controller: passwordCtrl,
       isPassword: true,
       prefixIcon: Icons.lock_outline_rounded,
       textInputAction: TextInputAction.done,
       validator: (v) {
        if (v == null || v.isEmpty) return 'Password is required';
        return null;
       },
      ),
      const SizedBox(height: 12),
      Align(
       alignment: Alignment.centerRight,
       child: GestureDetector(
        onTap: onForgotPassword,
        child: Text(
         'Forgot Password?',
         style: AppTextStyles.link,
        ),
       ),
      ),
      const SizedBox(height: 24),
      GradientButton(
       label: 'Login',
       onPressed: isLoading ? null : onLogin,
       isLoading: isLoading,
       width: double.infinity,
      ),
      if (onSignUp != null) ...[
       const SizedBox(height: 20),
       Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
         Text(
          "Don't have an account? ",
          style: AppTextStyles.bodySmall,
         ),
         GestureDetector(
          onTap: onSignUp,
          child: Text(
           'Sign Up',
           style: AppTextStyles.link.copyWith(
            fontWeight: FontWeight.w600,
           ),
          ),
         ),
        ],
       ),
      ],
     ],
    ),
   ),
  );
 }

 String _subtitleForRole(UserRole role) {
  switch (role) {
   case UserRole.patient:
    return 'Access your health records & appointments';
   case UserRole.doctor:
    return 'Access your practice dashboard';
   case UserRole.admin:
    return 'Access the system administration panel';
  }
 }
}

class _DemoCredentialsHint extends StatelessWidget {
 final UserRole role;
 final bool isLoading;
 final VoidCallback onFill;
 final VoidCallback onQuickLogin;

 const _DemoCredentialsHint({
  required this.role,
  required this.isLoading,
  required this.onFill,
  required this.onQuickLogin,
 });

 @override
 Widget build(BuildContext context) {
  final email = '${role.name}@demo.com';
  const password = 'Demo@1234';

  Color roleColor;
  switch (role) {
   case UserRole.patient:
    roleColor = AppColors.patientPrimary;
    break;
   case UserRole.doctor:
    roleColor = AppColors.doctorPrimary;
    break;
   case UserRole.admin:
    roleColor = AppColors.primary;
    break;
  }

  return Container(
   padding: const EdgeInsets.all(16),
   decoration: BoxDecoration(
    color: roleColor.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
     color: roleColor.withValues(alpha: 0.25),
    ),
   ),
   child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
     Row(
      children: [
       Icon(Icons.bolt_rounded, size: 18, color: roleColor),
       const SizedBox(width: 6),
       Expanded(
        child: Text(
         'Demo Credentials (${role.displayName})',
         style: AppTextStyles.labelMedium.copyWith(
          color: roleColor,
          fontWeight: FontWeight.w700,
         ),
         overflow: TextOverflow.ellipsis,
        ),
       ),
       const SizedBox(width: 6),
       GestureDetector(
        onTap: onFill,
        child: Container(
         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
         decoration: BoxDecoration(
          color: roleColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: roleColor.withValues(alpha: 0.3)),
         ),
         child: Text(
          'Auto-fill',
          style: TextStyle(
           fontSize: 11,
           fontWeight: FontWeight.w600,
           color: roleColor,
          ),
         ),
        ),
       ),
      ],
     ),
     const SizedBox(height: 10),
     Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
       color: AppColors.surface,
       borderRadius: BorderRadius.circular(8),
       border: Border.all(color: AppColors.border),
      ),
      child: Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
        Row(
         children: [
          Text('Email: ', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
          Text(
           email,
           style: AppTextStyles.caption.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
           ),
          ),
         ],
        ),
        const SizedBox(height: 3),
        Row(
         children: [
          Text('Password: ', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
          Text(
           password,
           style: AppTextStyles.caption.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
           ),
          ),
         ],
        ),
       ],
      ),
     ),
     const SizedBox(height: 12),
     ElevatedButton.icon(
      onPressed: isLoading ? null : onQuickLogin,
      style: ElevatedButton.styleFrom(
       backgroundColor: roleColor,
       foregroundColor: Colors.white,
       padding: const EdgeInsets.symmetric(vertical: 10),
       shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
       ),
       elevation: 0,
      ),
      icon: isLoading
        ? const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
           strokeWidth: 2,
           color: Colors.white,
          ),
         )
        : const Icon(Icons.login_rounded, size: 16),
      label: Text(
       'Quick Login as ${role.displayName}',
       style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
     ),
    ],
   ),
  );
 }
}

class _BackgroundGradient extends StatelessWidget {
 @override
 Widget build(BuildContext context) {
  return Stack(
   children: [
    // Top-left blue blob
    Positioned(
     top: -60,
     left: -60,
     child: Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
       shape: BoxShape.circle,
       color: AppColors.primary.withValues(alpha: 0.07),
      ),
     ),
    ),
    // Bottom-right purple blob
    Positioned(
     bottom: -80,
     right: -80,
     child: Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
       shape: BoxShape.circle,
       color: AppColors.secondary.withValues(alpha: 0.06),
      ),
     ),
    ),
   ],
  );
 }
}
