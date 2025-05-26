import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/professional_service.dart';
import '../utils/responsive_builder.dart';
import '../utils/theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing_md),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Търси услуга или майстор...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius_md),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return ref.watch(categoriesProvider).when(
          data: (categories) {
            return SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing_md,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: AppTheme.spacing_md),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(category.iconUrl),
                        ),
                        const SizedBox(height: AppTheme.spacing_sm),
                        Text(
                          category.name,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error: $error'),
          ),
        );
  }

  Widget _buildRecommendedProfessionals() {
    return ref.watch(recommendedProfessionalsProvider).when(
          data: (professionals) {
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppTheme.spacing_md),
              itemCount: professionals.length,
              itemBuilder: (context, index) {
                final professional = professionals[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppTheme.spacing_md),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacing_md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: professional.photoUrl != null
                                  ? NetworkImage(professional.photoUrl!)
                                  : null,
                              child: professional.photoUrl == null
                                  ? Text(professional.name[0])
                                  : null,
                            ),
                            const SizedBox(width: AppTheme.spacing_md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    professional.name,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: AppTheme.spacing_xs),
                                  Text(
                                    professional.categories.join(', '),
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: AppTheme.spacing_xs),
                                  Row(
                                    children: [
                                      const Icon(Icons.star,
                                          color: Colors.amber, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${professional.rating} (${professional.reviewCount})',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacing_md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              professional.city,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Row(
                              children: [
                                if (professional.isVerified)
                                  const Padding(
                                    padding:
                                        EdgeInsets.only(right: AppTheme.spacing_sm),
                                    child: Icon(Icons.verified,
                                        color: AppTheme.primaryBlue, size: 20),
                                  ),
                                if (professional.isCertified)
                                  const Padding(
                                    padding:
                                        EdgeInsets.only(right: AppTheme.spacing_sm),
                                    child: Icon(Icons.workspace_premium,
                                        color: AppTheme.primaryBlue, size: 20),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacing_md),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  // TODO: Navigate to professional profile
                                },
                                child: const Text('Виж профил'),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacing_md),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  // TODO: Navigate to booking screen
                                },
                                child: const Text('Резервирай'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error: $error'),
          ),
        );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          _buildCategories(),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacing_md),
            child: Text(
              'Препоръчани майстори',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          _buildRecommendedProfessionals(),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(),
                _buildCategories(),
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing_md),
                  child: Text(
                    'Препоръчани майстори',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                _buildRecommendedProfessionals(),
              ],
            ),
          ),
        ),
        const Expanded(
          flex: 3,
          child: Center(
            child: Text('Select a professional to view details'),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(),
                _buildCategories(),
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing_md),
                  child: Text(
                    'Препоръчани майстори',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                _buildRecommendedProfessionals(),
              ],
            ),
          ),
        ),
        const Expanded(
          flex: 2,
          child: Center(
            child: Text('Select a professional to view details'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.network(
              'https://via.placeholder.com/40',
              width: 40,
              height: 40,
            ),
            const SizedBox(width: AppTheme.spacing_md),
            const Text('Услуги по часове'),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              // TODO: Implement location selection
            },
            icon: const Icon(Icons.location_on),
            label: const Text('София ▼'),
          ),
        ],
      ),
      body: ResponsiveBuilder(
        mobile: _buildMobileLayout(),
        tablet: _buildTabletLayout(),
        desktop: _buildDesktopLayout(),
      ),
    );
  }
}
