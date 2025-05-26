import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/booking_service.dart';
import '../services/professional_service.dart';
import '../utils/theme.dart';
import '../utils/responsive_builder.dart';

class ClientDashboardScreen extends ConsumerStatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  ConsumerState<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends ConsumerState<ClientDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildBookingsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final bookingsAsync = ref.watch(clientBookingsProvider('TODO: Get user ID'));

        return bookingsAsync.when(
          data: (bookings) {
            if (bookings.isEmpty) {
              return const Center(
                child: Text('Все още нямате резервации'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacing_md),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacing_md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    booking.serviceType,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spacing_xs),
                                  Text(
                                    'Дата: ${booking.dateTime.day}.${booking.dateTime.month}.${booking.dateTime.year}',
                                  ),
                                  Text(
                                    'Час: ${booking.dateTime.hour}:${booking.dateTime.minute.toString().padLeft(2, '0')}',
                                  ),
                                ],
                              ),
                            ),
                            _buildStatusChip(booking.status),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacing_md),
                        Text('Адрес: ${booking.address}'),
                        if (booking.notes != null) ...[
                          const SizedBox(height: AppTheme.spacing_sm),
                          Text('Бележки: ${booking.notes}'),
                        ],
                        const SizedBox(height: AppTheme.spacing_md),
                        if (booking.status == BookingStatus.completed)
                          OutlinedButton(
                            onPressed: () {
                              // TODO: Show review dialog
                            },
                            child: const Text('Остави отзив'),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        );
      },
    );
  }

  Widget _buildFavoritesTab() {
    return Consumer(
      builder: (context, ref, child) {
        // TODO: Implement favorites provider
        final professionals = <Professional>[];

        if (professionals.isEmpty) {
          return const Center(
            child: Text('Все още нямате любими майстори'),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(AppTheme.spacing_md),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: AppTheme.spacing_md,
            mainAxisSpacing: AppTheme.spacing_md,
          ),
          itemCount: professionals.length,
          itemBuilder: (context, index) {
            final professional = professionals[index];
            return Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: professional.photoUrl != null
                        ? Image.network(
                            professional.photoUrl!,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.person,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacing_md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          professional.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing_xs),
                        Text(professional.categories.join(', ')),
                        const SizedBox(height: AppTheme.spacing_xs),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text('${professional.rating}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReviewsTab() {
    return Consumer(
      builder: (context, ref, child) {
        // TODO: Implement user reviews provider
        final reviews = <Review>[];

        if (reviews.isEmpty) {
          return const Center(
            child: Text('Все още нямате оставени отзиви'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spacing_md),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing_md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review.clientName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileTab() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing_md),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing_md),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    // TODO: Add user photo
                  ),
                  const SizedBox(height: AppTheme.spacing_md),
                  const Text(
                    'Име на потребител',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing_xs),
                  const Text('email@example.com'),
                  const SizedBox(height: AppTheme.spacing_md),
                  OutlinedButton(
                    onPressed: () {
                      // TODO: Implement edit profile
                    },
                    child: const Text('Редактирай профил'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing_md),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Известия'),
                  trailing: Switch(
                    value: true, // TODO: Get from settings
                    onChanged: (value) {
                      // TODO: Update settings
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Език'),
                  trailing: DropdownButton<String>(
                    value: 'bg',
                    items: const [
                      DropdownMenuItem(
                        value: 'bg',
                        child: Text('Български'),
                      ),
                      DropdownMenuItem(
                        value: 'en',
                        child: Text('English'),
                      ),
                    ],
                    onChanged: (value) {
                      // TODO: Update language
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Изход'),
                  onTap: () {
                    // TODO: Implement logout
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BookingStatus status) {
    Color color;
    String text;

    switch (status) {
      case BookingStatus.pending:
        color = Colors.orange;
        text = 'Чакащ';
        break;
      case BookingStatus.accepted:
        color = Colors.blue;
        text = 'Приет';
        break;
      case BookingStatus.completed:
        color = Colors.green;
        text = 'Завършен';
        break;
      case BookingStatus.cancelled:
        color = Colors.red;
        text = 'Отказан';
        break;
    }

    return Chip(
      label: Text(text),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Моят профил'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Резервации'),
            Tab(text: 'Любими'),
            Tab(text: 'Отзиви'),
            Tab(text: 'Профил'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingsTab(),
          _buildFavoritesTab(),
          _buildReviewsTab(),
          _buildProfileTab(),
        ],
      ),
    );
  }
}
