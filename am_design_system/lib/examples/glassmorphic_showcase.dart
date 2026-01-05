import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../widgets/display/glass_card.dart';
import '../widgets/buttons/glossy_button.dart';
import '../widgets/layouts/secondary_sidebar.dart';

/// Showcase of all glassmorphic UI components
class GlassmorphicShowcase extends StatelessWidget {
  const GlassmorphicShowcase({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Row(
        children: [
          // Secondary Sidebar Example
          SecondarySidebar(
            title: 'Menu',
            items: [
              SecondarySidebarItem(
                title: 'Dashboard',
                icon: Icons.dashboard,
                onTap: () {},
                accentColor: AppColors.primary,
              ),
              SecondarySidebarItem(
                title: 'Portfolio',
                icon: Icons.pie_chart,
                onTap: () {},
                accentColor: AppColors.accentBlue,
              ),
              SecondarySidebarItem(
                title: 'Analytics',
                icon: Icons.bar_chart,
                onTap: () {},
                accentColor: AppColors.accent,
              ),
              SecondarySidebarItem(
                title: 'Settings',
                icon: Icons.settings,
                onTap: () {},
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '5',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Text(
                    'Glassmorphic UI Components',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Metric Cards Grid (like reference image)
                  const Text(
                    'Metric Cards',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.8,
                    children: [
                      MetricCard(
                        label: 'Symbols Processed',
                        value: '1',
                        icon: Icons.trending_up,
                        accentColor: AppColors.info,
                      ),
                      MetricCard(
                        label: 'Payload Size',
                        value: '242.0 KB',
                        icon: Icons.storage,
                        accentColor: AppColors.accent,
                      ),
                      MetricCard(
                        label: 'Success',
                        value: '1',
                        icon: Icons.check_circle,
                        accentColor: AppColors.success,
                      ),
                      MetricCard(
                        label: 'Failed',
                        value: '0',
                        icon: Icons.error,
                        accentColor: AppColors.error,
                      ),
                      MetricCard(
                        label: 'Total Revenue',
                        value: '₹2.4M',
                        icon: Icons.account_balance_wallet,
                        accentColor: AppColors.accentBlue,
                      ),
                      MetricCard(
                        label: 'Active Users',
                        value: '1,234',
                        icon: Icons.people,
                        accentColor: AppColors.accentPink,
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // Glass Cards
                  const Text(
                    'Glass Cards',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Glass Card Example',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Icon(
                                    Icons.info_outline,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'This is a glassmorphic card with frosted glass effect, subtle borders, and beautiful shadows.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GradientCard(
                          gradientColors: const [
                            Color(0xFF6C5DD3),
                            Color(0xFF00D2D3),
                          ],
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gradient Card',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Vibrant gradient backgrounds with smooth color transitions.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // Buttons
                  const Text(
                    'Glossy Buttons',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      GlossyButton(
                        text: 'Primary Button',
                        onPressed: () {},
                        icon: Icons.star,
                      ),
                      GlossyButton(
                        text: 'Secondary',
                        onPressed: () {},
                        gradientColors: const [
                          Color(0xFFFF9F43),
                          Color(0xFFFF6B6B),
                        ],
                      ),
                      GlossyButton(
                        text: 'Success',
                        onPressed: () {},
                        icon: Icons.check,
                        gradientColors: const [
                          Color(0xFF00B894),
                          Color(0xFF00D2D3),
                        ],
                      ),
                      GlassButton(
                        text: 'Glass Button',
                        onPressed: () {},
                        icon: Icons.layers,
                      ),
                      GlossyButton(
                        text: 'Loading...',
                        onPressed: () {},
                        isLoading: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
