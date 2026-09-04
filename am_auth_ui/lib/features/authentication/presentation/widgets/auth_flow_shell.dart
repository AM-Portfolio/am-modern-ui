import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:am_design_system/core/config/brand_config.dart';
import 'package:am_design_system/core/theme/app_component_sizes.dart';
import 'package:am_design_system/core/theme/app_spacing.dart';
import 'package:am_design_system/core/theme/app_text_styles.dart';
import 'package:am_design_system/core/theme/color_extensions.dart';
import 'package:am_design_system/core/theme/cubit/theme_cubit.dart';
import 'package:am_design_system/shared/widgets/buttons/am_back_button.dart';

import 'auth_page_background.dart';
import 'glass_card_widget.dart';
import 'theme_toggle_widget.dart';

/// Login-parity auth chrome: wide glass with branding | form on desktop.
class AuthFlowShell extends StatelessWidget {
  const AuthFlowShell({
    super.key,
    required this.form,
    required this.brandingTitle,
    required this.brandingSubtitle,
    this.showBack = false,
    this.onBack,
  });

  final Widget form;
  final String brandingTitle;
  final String brandingSubtitle;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 600;
                final brand = context.brand;

                return Stack(
                  children: [
                    const AuthPageBackground(),
                    Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(
                          isCompact ? AppSpacing.md : AppSpacing.lg,
                        ),
                        child: GlassCardWidget(
                          isCompact: isCompact,
                          maxWidth: isCompact
                              ? double.infinity
                              : AppComponentSizes.formMaxWidth,
                          enableMotion: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (showBack) ...[
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: AmBackButton(
                                    label: 'Back',
                                    compact: isCompact,
                                    onPressed: onBack ??
                                        () => Navigator.of(context).maybePop(),
                                  ),
                                ),
                                SizedBox(
                                  height: isCompact
                                      ? AppSpacing.sm + 4
                                      : AppSpacing.md,
                                ),
                              ],
                              if (isCompact)
                                form
                              else
                                IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: _BrandingPanel(
                                          title: brandingTitle,
                                          subtitle: brandingSubtitle,
                                          logo: brand.logo,
                                          appIcon: brand.appIcon,
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm + 4,
                                        ),
                                        color: context.colors.divider
                                            .withValues(alpha: 0.5),
                                      ),
                                      Expanded(flex: 5, child: form),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: AppSpacing.md,
                      right: AppSpacing.md,
                      child: ThemeToggleWidget(
                        iconSize: isCompact ? 20 : 24,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _BrandingPanel extends StatelessWidget {
  const _BrandingPanel({
    required this.title,
    required this.subtitle,
    this.logo,
    required this.appIcon,
  });

  final String title;
  final String subtitle;
  final Widget? logo;
  final IconData appIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 4,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (logo != null) ...[
            logo!,
            const SizedBox(height: AppSpacing.md),
          ] else ...[
            Icon(
              appIcon,
              size: 36,
              color: context.colors.actionPrimaryBg,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            title,
            style: context.text.heroTitle().copyWith(
                  color: context.colors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          Text(
            subtitle,
            style: context.text.body().copyWith(
                  color: context.colors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
