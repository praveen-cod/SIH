import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Modal bottom sheet for choosing preferred consultation language
class LanguageSelectorSheet extends ConsumerStatefulWidget {
 final bool isMandatory;
 final Function(AppLanguage selected)? onSelected;

 const LanguageSelectorSheet({
  super.key,
  this.isMandatory = false,
  this.onSelected,
 });

 static Future<AppLanguage?> show(
  BuildContext context, {
  bool isMandatory = false,
  Function(AppLanguage selected)? onSelected,
 }) {
  return showModalBottomSheet<AppLanguage>(
   context: context,
   isScrollControlled: true,
   isDismissible: !isMandatory,
   enableDrag: !isMandatory,
   backgroundColor: Colors.transparent,
   builder: (context) => LanguageSelectorSheet(
    isMandatory: isMandatory,
    onSelected: onSelected,
   ),
  );
 }

 @override
 ConsumerState<LanguageSelectorSheet> createState() => _LanguageSelectorSheetState();
}

class _LanguageSelectorSheetState extends ConsumerState<LanguageSelectorSheet> {
 late AppLanguage _selected;

 @override
 void initState() {
  super.initState();
  _selected = ref.read(languageProvider).currentLanguage;
 }

 void _confirmSelection() {
  ref.read(languageProvider.notifier).selectLanguage(_selected);
  widget.onSelected?.call(_selected);
  Navigator.of(context).pop(_selected);
 }

 @override
 Widget build(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final screenWidth = mediaQuery.size.width;
  final maxSheetWidth = screenWidth > 640 ? 560.0 : screenWidth;
  final bottomPadding = mediaQuery.viewInsets.bottom + mediaQuery.padding.bottom;

  return Center(
   child: ConstrainedBox(
    constraints: BoxConstraints(
     maxWidth: maxSheetWidth,
     maxHeight: mediaQuery.size.height * 0.85,
    ),
    child: Container(
     decoration: BoxDecoration(
      color: AppColors.backgroundSecondary,
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      border: Border(
       top: BorderSide(color: AppColors.border, width: 1.5),
      ),
      boxShadow: [
       BoxShadow(
        color: Colors.black54,
        blurRadius: 30,
        offset: Offset(0, -10),
       ),
      ],
     ),
     child: SafeArea(
      top: false,
      child: Column(
       mainAxisSize: MainAxisSize.min,
       children: [
        // Drag Handle
        const SizedBox(height: 12),
        Container(
         width: 44,
         height: 4.5,
         decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(3),
         ),
        ),
        const SizedBox(height: 16),

        // Header
        Padding(
         padding: const EdgeInsets.symmetric(horizontal: 24),
         child: Row(
          children: [
           Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
             color: AppColors.primary.withValues(alpha: 0.15),
             shape: BoxShape.circle,
             border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
             ),
            ),
            child: const Icon(
             Icons.translate_rounded,
             color: AppColors.primary,
             size: 22,
            ),
           ),
           const SizedBox(width: 14),
           Expanded(
            child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
              Text(
               'Choose Your Language',
               style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: 18,
               ),
              ),
              const SizedBox(height: 2),
              Text(
               'AI assistant will speak and respond in your language',
               style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
               ),
              ),
             ],
            ),
           ),
           if (!widget.isMandatory)
            IconButton(
             onPressed: () => Navigator.of(context).pop(),
             icon: const Icon(
              Icons.close_rounded,
              color: AppColors.textMuted,
              size: 20,
             ),
            ),
          ],
         ),
        ),
        const SizedBox(height: 16),
        const Divider(color: AppColors.border, height: 1),

        // Languages Grid List
        Flexible(
         child: ListView.separated(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          itemCount: AppLanguage.all.length,
          separatorBuilder: (_, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
           final lang = AppLanguage.all[index];
           final isSelected = _selected.code == lang.code;

           return Material(
            color: Colors.transparent,
            child: InkWell(
             onTap: () {
              setState(() {
               _selected = lang;
              });
             },
             borderRadius: BorderRadius.circular(16),
             child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
               horizontal: 16,
               vertical: 14,
              ),
              decoration: BoxDecoration(
               color: isSelected
                 ? AppColors.primary.withValues(alpha: 0.12)
                 : AppColors.surface,
               borderRadius: BorderRadius.circular(16),
               border: Border.all(
                color: isSelected
                  ? AppColors.primary
                  : AppColors.border,
                width: isSelected ? 1.8 : 1,
               ),
               boxShadow: isSelected
                 ? [
                   BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                   ),
                  ]
                 : null,
              ),
              child: Row(
               children: [
                // Radio checkmark icon
                Container(
                 width: 24,
                 height: 24,
                 decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                    ? AppColors.primary
                    : Colors.transparent,
                  border: Border.all(
                   color: isSelected
                     ? AppColors.primary
                     : AppColors.textMuted,
                   width: 2,
                  ),
                 ),
                 child: isSelected
                   ? const Icon(
                     Icons.check_rounded,
                     color: Colors.white,
                     size: 16,
                    )
                   : null,
                ),
                const SizedBox(width: 14),

                // Native Name & English Name
                Expanded(
                 child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                   Row(
                    children: [
                     Text(
                      lang.name,
                      style: TextStyle(
                       fontSize: 16,
                       fontWeight: isSelected
                         ? FontWeight.w700
                         : FontWeight.w600,
                       color: isSelected
                         ? AppColors.textPrimary
                         : AppColors.textPrimary,
                      ),
                     ),
                     const SizedBox(width: 8),
                     Text(
                      '(${lang.englishName})',
                      style: TextStyle(
                       fontSize: 12.5,
                       color: isSelected
                         ? AppColors.primaryLight
                         : AppColors.textMuted,
                      ),
                     ),
                    ],
                   ),
                   const SizedBox(height: 3),
                   Text(
                    lang.samplePhrase,
                    style: TextStyle(
                     fontSize: 11.5,
                     color: AppColors.textMuted,
                     fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                   ),
                  ],
                 ),
                ),

                // Code Badge
                Container(
                 padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                 ),
                 decoration: BoxDecoration(
                  color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.25)
                    : AppColors.textPrimary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                   color: isSelected
                     ? AppColors.primary.withValues(alpha: 0.5)
                     : Colors.transparent,
                   width: 0.8,
                  ),
                 ),
                 child: Text(
                  lang.code.toUpperCase(),
                  style: TextStyle(
                   fontSize: 11,
                   fontWeight: FontWeight.w700,
                   color: isSelected
                     ? AppColors.primaryLight
                     : AppColors.textMuted,
                  ),
                 ),
                ),
               ],
              ),
             ),
            ),
           );
          },
         ),
        ),

        // Confirm Selection Button
        Padding(
         padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPadding > 0 ? bottomPadding : 20),
         child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
           borderRadius: BorderRadius.circular(14),
           gradient: const LinearGradient(
            colors: AppColors.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
           ),
           boxShadow: [
            BoxShadow(
             color: AppColors.primary.withValues(alpha: 0.4),
             blurRadius: 14,
             offset: const Offset(0, 4),
            ),
           ],
          ),
          child: ElevatedButton.icon(
           onPressed: _confirmSelection,
           icon: const Icon(Icons.check_circle_rounded, size: 20),
           label: Text(
            'Confirm & Continue in ${_selected.name} (${_selected.englishName})',
            style: const TextStyle(
             fontSize: 14.5,
             fontWeight: FontWeight.w700,
             color: Colors.white,
            ),
           ),
           style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(14),
            ),
           ),
          ),
         ),
        ),
       ],
      ),
     ),
    ),
   ),
  );
 }
}
