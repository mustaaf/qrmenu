import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:qrmenu/config/theme.dart';
import 'package:qrmenu/viewmodels/category_viewmodel.dart';
import 'package:qrmenu/viewmodels/social_media_viewmodel.dart'; // Add this import
import 'package:qrmenu/models/category_model.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  final String restaurantId;

  const HomeScreen({
    super.key,
    required this.restaurantId,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load data when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final categoryViewModel =
        Provider.of<CategoryViewModel>(context, listen: false);
    final socialMediaViewModel =
        Provider.of<SocialMediaViewModel>(context, listen: false);

    // Load categories and social media info with restaurant ID
    categoryViewModel.loadCategories(widget.restaurantId);
    socialMediaViewModel.loadSocialMediaInfo(widget.restaurantId);
  }

  // Launch URL helper method
  void _launchUrl(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;

    // Add http:// prefix if missing
    if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
      urlString = 'https://$urlString';
    }

    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // Show error if URL can't be launched
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $urlString')),
        );
      }
    }
  }

  // Launch phone number
  void _launchPhone(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) return;

    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not call $phoneNumber')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Consumer<SocialMediaViewModel>(
            builder: (context, viewModel, child) {
          final logo = viewModel.socialMedia.logo;

          if (logo != null && logo.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.network(
                logo,
                errorBuilder: (_, __, ___) => const Icon(Icons.restaurant_menu),
              ),
            );
          }

          return const Icon(Icons.restaurant_menu);
        }),
        scrolledUnderElevation: 0,
        title: Consumer<SocialMediaViewModel>(
            builder: (context, viewModel, child) {
          return Text(
              viewModel.socialMedia.restaurantname ?? 'QR Restaurant Menu');
        }),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<CategoryViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (viewModel.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${viewModel.error}'),
                        ElevatedButton(
                          onPressed: () =>
                              viewModel.loadCategories(widget.restaurantId),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (viewModel.categories.isEmpty) {
                  return const Center(
                    child: Text('No menu categories available'),
                  );
                }

                return LayoutBuilder(builder: (context, constraints) {
                  // Responsive grid layout
                  final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;

                  return GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      childAspectRatio: 1.8, // 1:1.5 aspect ratio
                    ),
                    itemCount: viewModel.categories.length,
                    itemBuilder: (context, index) {
                      final category = viewModel.categories[index];
                      return _buildCategoryCard(context, category);
                    },
                  );
                });
              },
            ),
          ),

          // Thin gray separator
          const Divider(
            height: 1,
            thickness: 0.5,
            color: Colors.grey,
          ),

          // Social Media Icons Footer
          Consumer<SocialMediaViewModel>(builder: (context, viewModel, child) {
            final socialMedia = viewModel.socialMedia;

            // Don't show footer if no social links available
            if (socialMedia.facebook == null &&
                socialMedia.twitter == null &&
                socialMedia.instagram == null &&
                socialMedia.phoneNumber == null) {
              return const SizedBox.shrink();
            }

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Only show icons for available links
                  if (socialMedia.facebook != null)
                    _buildSocialIcon(Icons.facebook, () {
                      _launchUrl(socialMedia.facebook);
                    }),

                  if (socialMedia.facebook != null &&
                      (socialMedia.twitter != null ||
                          socialMedia.instagram != null ||
                          socialMedia.phoneNumber != null))
                    const SizedBox(width: 20),

                  if (socialMedia.twitter != null)
                    _buildSocialIcon(Icons.workspace_premium, () {
                      _launchUrl(socialMedia.twitter);
                    }),

                  if (socialMedia.twitter != null &&
                      (socialMedia.instagram != null ||
                          socialMedia.phoneNumber != null))
                    const SizedBox(width: 20),

                  if (socialMedia.instagram != null)
                    _buildSocialIcon(Icons.photo_camera, () {
                      _launchUrl(socialMedia.instagram);
                    }),

                  if (socialMedia.instagram != null &&
                      socialMedia.phoneNumber != null)
                    const SizedBox(width: 20),

                  if (socialMedia.phoneNumber != null)
                    _buildSocialIcon(Icons.phone, () {
                      _launchPhone(socialMedia.phoneNumber);
                    }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Category category) {
    return Card(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          category.imageUrl != null
              ? Image.network(
                  category.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[800],
                  ),
                )
              : Container(
                  color: Colors.grey[800],
                ),

          // Semi-transparent overlay for better text readability
          Container(
            color: Colors.black.withOpacity(0.6),
          ),

          // Content overlay
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    category.name.toUpperCase(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 40,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Text(category.description ?? '',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                SizedBox(
                  width: 120, // Increase width to accommodate longer text
                  child: ElevatedButton(
                    onPressed: () => context.go(
                        '/restaurant/${widget.restaurantId}/category/${category.id}'),
                    style: AppTheme.detailsButtonStyle,
                    child: FittedBox(
                      // Add FittedBox to ensure text fits
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Detayları Gör',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              )),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Theme.of(context).iconTheme.color,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20), // Smaller circle
      child: Container(
        padding: const EdgeInsets.all(6), // Smaller padding
        decoration: AppTheme.socialIconDecoration,
        child: Icon(
          icon,
          color: Colors.white,
          size: 16, // Smaller icon size
        ),
      ),
    );
  }
}
