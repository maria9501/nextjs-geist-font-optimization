import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../services/professional_service.dart';
import '../services/booking_service.dart';
import '../utils/theme.dart';
import '../utils/responsive_builder.dart';

class ProfessionalProfileScreen extends ConsumerWidget {
  final String professionalId;

  const ProfessionalProfileScreen({
    super.key,
    required this.professionalId,
  });

  Widget _buildInfoSection(Professional professional) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing_md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: professional.photoUrl != null
                      ? NetworkImage(professional.photoUrl!)
                      : null,
                  child: professional.photoUrl == null
                      ? Text(professional.name[0],
                          style: const TextStyle(fontSize: 24))
                      : null,
                ),
                const SizedBox(width: AppTheme.spacing_md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        professional.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing_sm),
                      Text(
                        professional.categories.join(' • '),
                        style: const TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing_sm),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '${professional.rating} (${professional.reviewCount} отзива)',
                            style: const TextStyle(fontSize: 16),
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
              children: [
                const Icon(Icons.location_on, size: 20),
                const SizedBox(width: 4),
                Text(professional.city),
                const Spacer(),
                if (professional.isVerified)
                  const Padding(
                    padding: EdgeInsets.only(right: AppTheme.spacing_sm),
                    child: Chip(
                      label: Text('Верифициран'),
                      avatar: Icon(Icons.verified, size: 16),
                    ),
                  ),
                if (professional.isCertified)
                  const Padding(
                    padding: EdgeInsets.only(right: AppTheme.spacing_sm),
                    child: Chip(
                      label: Text('Сертифициран'),
                      avatar: Icon(Icons.workspace_premium, size: 16),
                    ),
                  ),
                if (professional.isResponsive)
                  const Chip(
                    label: Text('Отзивчив'),
                    avatar: Icon(Icons.speed, size: 16),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing_md),
            const Text(
              'Последна активност:',
              style: TextStyle(color: AppTheme.textLight),
            ),
            Text('Онлайн преди ${_getLastActiveTime(professional.lastActive)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection(Professional professional) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing_md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Представяне',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacing_md),
            Text(professional.description),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection(Professional professional) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing_md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Услуги и цени',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacing_md),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: professional.services.length,
              itemBuilder: (context, index) {
                final service = professional.services[index];
                return ListTile(
                  title: Text(service.name),
                  subtitle: service.description != null
                      ? Text(service.description!)
                      : null,
                  trailing: Text(
                    '${service.price} лв.${service.priceType == 'per_hour' ? '/час' : ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGallerySection(Professional professional) {
    if (professional.galleryUrls.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing_md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Галерия',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacing_md),
            CarouselSlider(
              options: CarouselOptions(
                height: 200,
                viewportFraction: 0.8,
                enlargeCenterPage: true,
              ),
              items: professional.galleryUrls.map((url) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTheme.radius_md),
                        image: DecorationImage(
                          image: NetworkImage(url),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection(String professionalId) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing_md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Отзиви',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacing_md),
            Consumer(
              builder: (context, ref, child) {
                final reviews = ref.watch(professionalReviewsProvider(professionalId));
                return reviews.when(
                  data: (reviews) => ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      return ListTile(
                        title: Row(
                          children: [
                            Text(review.clientName),
                            const Spacer(),
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < review.rating ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppTheme.spacing_sm),
                            Text(review.comment),
                            const SizedBox(height: AppTheme.spacing_xs),
                            Text(
                              _formatDate(review.createdAt),
                              style: const TextStyle(
                                color: AppTheme.textLight,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Error: $error')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilitySection(String professionalId) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing_md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Наличност и резервация',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacing_md),
            Consumer(
              builder: (context, ref, child) {
                final availability = ref.watch(
                  professionalAvailabilityProvider(
                    (professionalId: professionalId, date: DateTime.now()),
                  ),
                );

                return availability.when(
                  data: (slots) => Column(
                    children: [
                      // Calendar or time slots widget here
                      const SizedBox(height: AppTheme.spacing_md),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Implement message functionality
                              },
                              icon: const Icon(Icons.message),
                              label: const Text('Изпрати съобщение'),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacing_md),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // TODO: Navigate to booking screen
                              },
                              icon: const Icon(Icons.calendar_today),
                              label: const Text('Резервирай услуга'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Error: $error')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getLastActiveTime(DateTime lastActive) {
    final now = DateTime.now();
    final difference = now.difference(lastActive);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} минути';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} часа';
    } else {
      return '${difference.inDays} дни';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профил на майстор'),
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final professionalAsync = ref.watch(professionalProvider(professionalId));

          return professionalAsync.when(
            data: (professional) => ResponsiveBuilder(
              mobile: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacing_md),
                child: Column(
                  children: [
                    _buildInfoSection(professional),
                    const SizedBox(height: AppTheme.spacing_md),
                    _buildDescriptionSection(professional),
                    const SizedBox(height: AppTheme.spacing_md),
                    _buildServicesSection(professional),
                    const SizedBox(height: AppTheme.spacing_md),
                    _buildGallerySection(professional),
                    const SizedBox(height: AppTheme.spacing_md),
                    _buildReviewsSection(professionalId),
                    const SizedBox(height: AppTheme.spacing_md),
                    _buildAvailabilitySection(professionalId),
                  ],
                ),
              ),
              tablet: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.spacing_md),
                      child: Column(
                        children: [
                          _buildInfoSection(professional),
                          const SizedBox(height: AppTheme.spacing_md),
                          _buildDescriptionSection(professional),
                          const SizedBox(height: AppTheme.spacing_md),
                          _buildServicesSection(professional),
                          const SizedBox(height: AppTheme.spacing_md),
                          _buildGallerySection(professional),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.spacing_md),
                      child: Column(
                        children: [
                          _buildReviewsSection(professionalId),
                          const SizedBox(height: AppTheme.spacing_md),
                          _buildAvailabilitySection(professionalId),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              desktop: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.spacing_md),
                      child: Column(
                        children: [
                          _buildInfoSection(professional),
                          const SizedBox(height: AppTheme.spacing_md),
                          _buildDescriptionSection(professional),
                          const SizedBox(height: AppTheme.spacing_md),
                          _buildServicesSection(professional),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.spacing_md),
                      child: Column(
                        children: [
                          _buildGallerySection(professional),
                          const SizedBox(height: AppTheme.spacing_md),
                          _buildReviewsSection(professionalId),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.spacing_md),
                      child: _buildAvailabilitySection(professionalId),
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          );
        },
      ),
    );
  }
}
