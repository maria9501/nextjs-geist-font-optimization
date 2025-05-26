import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/booking_service.dart';
import '../services/professional_service.dart';
import '../utils/theme.dart';
import '../utils/responsive_builder.dart';

class ProfessionalDashboardScreen extends ConsumerStatefulWidget {
  const ProfessionalDashboardScreen({super.key});

  @override
  ConsumerState<ProfessionalDashboardScreen> createState() =>
      _ProfessionalDashboardScreenState();
}

class _ProfessionalDashboardScreenState
    extends ConsumerState<ProfessionalDashboardScreen>
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

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 40,
                  // TODO: Add professional photo
                ),
                SizedBox(height: AppTheme.spacing_md),
                Text(
                  'Име на майстор',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                Text(
                  'Онлайн',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Табло'),
            selected: true,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('График'),
            onTap: () {
              Navigator.pop(context);
              _tabController.animateTo(1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Отзиви'),
            onTap: () {
              Navigator.pop(context);
              _tabController.animateTo(2);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Моят профил'),
            onTap: () {
              Navigator.pop(context);
              _tabController.animateTo(3);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Настройки'),
            onTap: () {
              // TODO: Navigate to settings
            },
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
    );
  }

  Widget _buildRequestsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final bookingsAsync =
            ref.watch(professionalBookingsProvider('TODO: Get professional ID'));

        return bookingsAsync.when(
          data: (bookings) {
            final pendingBookings =
                bookings.where((b) => b.status == BookingStatus.pending).toList();

            if (pendingBookings.isEmpty) {
              return const Center(
                child: Text('Нямате чакащи заявки'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacing_md),
              itemCount: pendingBookings.length,
              itemBuilder: (context, index) {
                final booking = pendingBookings[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacing_md),
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
                        const SizedBox(height: AppTheme.spacing_sm),
                        Text(
                          'Дата: ${booking.dateTime.day}.${booking.dateTime.month}.${booking.dateTime.year}',
                        ),
                        Text(
                          'Час: ${booking.dateTime.hour}:${booking.dateTime.minute.toString().padLeft(2, '0')}',
                        ),
                        const SizedBox(height: AppTheme.spacing_sm),
                        Text('Адрес: ${booking.address}'),
                        if (booking.notes != null) ...[
                          const SizedBox(height: AppTheme.spacing_sm),
                          Text('Бележки: ${booking.notes}'),
                        ],
                        const SizedBox(height: AppTheme.spacing_md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () async {
                                await ref
                                    .read(bookingServiceProvider)
                                    .updateBookingStatus(
                                      booking.id,
                                      BookingStatus.cancelled,
                                    );
                              },
                              child: const Text('Откажи'),
                            ),
                            const SizedBox(width: AppTheme.spacing_md),
                            ElevatedButton(
                              onPressed: () async {
                                await ref
                                    .read(bookingServiceProvider)
                                    .updateBookingStatus(
                                      booking.id,
                                      BookingStatus.accepted,
                                    );
                              },
                              child: const Text('Приеми'),
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
          error: (error, stack) => Center(child: Text('Error: $error')),
        );
      },
    );
  }

  Widget _buildScheduleTab() {
    return Consumer(
      builder: (context, ref, child) {
        final bookingsAsync =
            ref.watch(professionalBookingsProvider('TODO: Get professional ID'));

        return bookingsAsync.when(
          data: (bookings) {
            final acceptedBookings = bookings
                .where((b) => b.status == BookingStatus.accepted)
                .toList();

            if (acceptedBookings.isEmpty) {
              return const Center(
                child: Text('Нямате приети заявки'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacing_md),
              itemCount: acceptedBookings.length,
              itemBuilder: (context, index) {
                final booking = acceptedBookings[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacing_md),
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
                        const SizedBox(height: AppTheme.spacing_sm),
                        Text(
                          'Дата: ${booking.dateTime.day}.${booking.dateTime.month}.${booking.dateTime.year}',
                        ),
                        Text(
                          'Час: ${booking.dateTime.hour}:${booking.dateTime.minute.toString().padLeft(2, '0')}',
                        ),
                        const SizedBox(height: AppTheme.spacing_sm),
                        Text('Адрес: ${booking.address}'),
                        if (booking.notes != null) ...[
                          const SizedBox(height: AppTheme.spacing_sm),
                          Text('Бележки: ${booking.notes}'),
                        ],
                        const SizedBox(height: AppTheme.spacing_md),
                        ElevatedButton(
                          onPressed: () async {
                            await ref.read(bookingServiceProvider).updateBookingStatus(
                                  booking.id,
                                  BookingStatus.completed,
                                );
                          },
                          child: const Text('Маркирай като завършена'),
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

  Widget _buildReviewsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final reviewsAsync =
            ref.watch(professionalReviewsProvider('TODO: Get professional ID'));

        return reviewsAsync.when(
          data: (reviews) {
            if (reviews.isEmpty) {
              return const Center(
                child: Text('Все още нямате отзиви'),
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        );
      },
    );
  }

  Widget _buildProfileTab() {
    return Consumer(
      builder: (context, ref, child) {
        final professionalAsync =
            ref.watch(professionalProvider('TODO: Get professional ID'));

        return professionalAsync.when(
          data: (professional) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacing_md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacing_md),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: professional.photoUrl != null
                              ? NetworkImage(professional.photoUrl!)
                              : null,
                          child: professional.photoUrl == null
                              ? Text(
                                  professional.name[0],
                                  style: const TextStyle(fontSize: 32),
                                )
                              : null,
                        ),
                        const SizedBox(height: AppTheme.spacing_md),
                        Text(
                          professional.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing_xs),
                        Text(professional.email),
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
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppTheme.spacing_md),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              // TODO: Implement edit services
                            },
                            child: const Text('Редактирай услуги'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing_md),
                Card(
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
                        if (professional.galleryUrls.isEmpty)
                          const Center(
                            child: Text('Нямате качени снимки'),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: AppTheme.spacing_sm,
                              mainAxisSpacing: AppTheme.spacing_sm,
                            ),
                            itemCount: professional.galleryUrls.length,
                            itemBuilder: (context, index) {
                              return Image.network(
                                professional.galleryUrls[index],
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        const SizedBox(height: AppTheme.spacing_md),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              // TODO: Implement edit gallery
                            },
                            child: const Text('Управление на галерия'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Табло'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Заявки'),
            Tab(text: 'График'),
            Tab(text: 'Отзиви'),
            Tab(text: 'Профил'),
          ],
        ),
      ),
      drawer: _buildDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestsTab(),
          _buildScheduleTab(),
          _buildReviewsTab(),
          _buildProfileTab(),
        ],
      ),
    );
  }
}
