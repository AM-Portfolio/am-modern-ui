import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:am_design_system/core/theme/color_extensions.dart';
import 'package:am_design_system/core/theme/cubit/theme_cubit.dart';

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

                return Stack(
                  children: [
                    const AuthPageBackground(),
                    Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(isCompact ? 16 : 24),
                        child: GlassCardWidget(
                          isCompact: isCompact,
                          maxWidth: isCompact ? double.infinity : 1080,
                          enableMotion: false,
                          child: isCompact
                              ? form
                              : IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: _BrandingPanel(
                                          title: brandingTitle,
                                          subtitle: brandingSubtitle,
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        color: context.colors.divider
                                            .withValues(alpha: 0.5),
                                      ),
                                      Expanded(flex: 5, child: form),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: ThemeToggleWidget(
                        iconSize: isCompact ? 20 : 24,
                      ),
                    ),
                    if (showBack)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: context.colors.textPrimary,
                          ),
                          onPressed: onBack ??
                              () => Navigator.of(context).maybePop(),
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
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
