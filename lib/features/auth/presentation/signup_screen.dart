import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../repositories/auth_repository.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/app_logo.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emergencyCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String _selectedGender = 'Male';
  int _selectedAge = 25;
  bool _termsAccepted = false;
  bool _showSuccess = false;
  String _generatedId = '';

  final List<String> _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _emergencyCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept Terms & Conditions to continue.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).signUp(
          name: _nameCtrl.text,
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
          phone: _phoneCtrl.text,
          emergencyContact: _emergencyCtrl.text,
          age: _selectedAge,
          gender: _selectedGender,
        );

    if (success && mounted) {
      final user = ref.read(currentUserProvider);
      setState(() {
        _showSuccess = true;
        _generatedId = user?.patientId ?? 'HC-XXXXXXXX';
      });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        context.go(AppRoutes.patientDashboard);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

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

    if (_showSuccess) {
      return _SuccessScreen(patientId: _generatedId);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            _BackgroundBlobs(),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      const SizedBox(height: 20),
                      // Back button + Logo
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                color: AppColors.textPrimary,
                                size: 20,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Center(child: AppLogo(compact: true)),
                          ),
                          const SizedBox(width: 40),
                        ],
                      )
                          .animate()
                          .fadeIn(duration: 400.ms),
                      const SizedBox(height: 28),
                      // Title
                      Text(
                        'Create Account',
                        style: AppTextStyles.displaySmall,
                      ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                      const SizedBox(height: 6),
                      Text(
                        'Join HealthCall AI as a patient',
                        style: AppTextStyles.bodyMedium,
                      ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                      const SizedBox(height: 28),
                      // Form fields
                      _FormSection(
                        title: 'Personal Information',
                        children: [
                          CustomTextField(
                            label: 'Full Name *',
                            hint: 'John Doe',
                            controller: _nameCtrl,
                            prefixIcon: Icons.person_outline_rounded,
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Full name is required';
                              }
                              if (v.trim().length < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          // Age and Gender row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Age *',
                                      style: AppTextStyles.labelMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      height: 54,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceLight,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.cake_outlined,
                                            size: 18,
                                            color: AppColors.textMuted,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: DropdownButton<int>(
                                              value: _selectedAge,
                                              dropdownColor:
                                                  AppColors.surface,
                                              underline: const SizedBox(),
                                              isExpanded: true,
                                              style:
                                                  AppTextStyles.bodyLarge
                                                      .copyWith(
                                                color:
                                                    AppColors.textPrimary,
                                              ),
                                              items: List.generate(
                                                100,
                                                (i) => DropdownMenuItem(
                                                  value: i + 1,
                                                  child: Text('${i + 1}'),
                                                ),
                                              ),
                                              onChanged: (v) => setState(
                                                () => _selectedAge = v!,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Gender *',
                                      style: AppTextStyles.labelMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      height: 54,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceLight,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      child: DropdownButton<String>(
                                        value: _selectedGender,
                                        dropdownColor: AppColors.surface,
                                        underline: const SizedBox(),
                                        isExpanded: true,
                                        style: AppTextStyles.bodyLarge
                                            .copyWith(
                                          color: AppColors.textPrimary,
                                          fontSize: 13,
                                        ),
                                        items: _genders
                                            .map(
                                              (g) => DropdownMenuItem(
                                                value: g,
                                                child: Text(g),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (v) => setState(
                                          () => _selectedGender = v!,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                      const SizedBox(height: 16),
                      _FormSection(
                        title: 'Contact Information',
                        children: [
                          CustomTextField(
                            label: 'Phone Number *',
                            hint: '+1 555 0100',
                            controller: _phoneCtrl,
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9+\-\s()]'),
                              ),
                            ],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Phone number is required';
                              }
                              if (v.replaceAll(RegExp(r'\D'), '').length < 10) {
                                return 'Enter a valid phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            label: 'Emergency Contact Number *',
                            hint: '+1 555 0199',
                            controller: _emergencyCtrl,
                            prefixIcon: Icons.emergency_outlined,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9+\-\s()]'),
                              ),
                            ],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Emergency contact is required';
                              }
                              if (v.replaceAll(RegExp(r'\D'), '').length < 10) {
                                return 'Enter a valid phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            label: 'Email Address *',
                            hint: 'john.doe@email.com',
                            controller: _emailCtrl,
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                  .hasMatch(v)) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                        ],
                      ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                      const SizedBox(height: 16),
                      _FormSection(
                        title: 'Security',
                        children: [
                          CustomTextField(
                            label: 'Password *',
                            hint: '••••••••',
                            controller: _passwordCtrl,
                            isPassword: true,
                            prefixIcon: Icons.lock_outline_rounded,
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Password is required';
                              }
                              if (v.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),
                          PasswordStrengthIndicator(
                            password: _passwordCtrl.text,
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            label: 'Confirm Password *',
                            hint: '••••••••',
                            controller: _confirmCtrl,
                            isPassword: true,
                            prefixIcon: Icons.lock_outline_rounded,
                            textInputAction: TextInputAction.done,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (v != _passwordCtrl.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ],
                      ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
                      const SizedBox(height: 20),
                      // Terms and conditions
                      GestureDetector(
                        onTap: () => setState(
                          () => _termsAccepted = !_termsAccepted,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: _termsAccepted
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: _termsAccepted
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: 1.5,
                                ),
                              ),
                              child: _termsAccepted
                                  ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: AppTextStyles.bodySmall,
                                  children: [
                                    const TextSpan(
                                      text: 'I agree to the ',
                                    ),
                                    TextSpan(
                                      text: 'Terms & Conditions',
                                      style: AppTextStyles.link.copyWith(
                                        fontSize: 12,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: ' and ',
                                    ),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: AppTextStyles.link.copyWith(
                                        fontSize: 12,
                                      ),
                                    ),
                                    const TextSpan(
                                      text:
                                          ' of HealthCall AI. I consent to the collection and processing of my health information.',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 550.ms, duration: 400.ms),
                      const SizedBox(height: 28),
                      GradientButton(
                        label: 'Create Account',
                        onPressed: authState.isLoading ? null : _handleSignUp,
                        isLoading: authState.isLoading,
                        icon: Icons.person_add_outlined,
                        width: double.infinity,
                      ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: AppTextStyles.bodySmall,
                          ),
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Text(
                              'Login',
                              style: AppTextStyles.link.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 650.ms, duration: 400.ms),
                      const SizedBox(height: 40),
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

class _FormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _FormSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headingSmall),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _SuccessScreen extends StatelessWidget {
  final String patientId;

  const _SuccessScreen({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.success, Color(0xFF16A34A)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 52,
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0, 0),
                    end: const Offset(1, 1),
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(),
              const SizedBox(height: 32),
              Text(
                'Account Created!',
                style: AppTextStyles.displaySmall,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
              const SizedBox(height: 12),
              Text(
                'Welcome to HealthCall AI',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Your Patient ID',
                      style: AppTextStyles.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      patientId,
                      style: AppTextStyles.statMedium.copyWith(
                        color: AppColors.primary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Save this ID for future reference',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                strokeWidth: 2,
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 12),
              Text(
                'Redirecting to your dashboard...',
                style: AppTextStyles.bodySmall,
              ).animate().fadeIn(delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackgroundBlobs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -40,
          right: -40,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withOpacity(0.06),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -60,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.05),
            ),
          ),
        ),
      ],
    );
  }
}
