import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BookingStatus {
  pending,
  accepted,
  completed,
  cancelled,
}

class Booking {
  final String id;
  final String clientId;
  final String professionalId;
  final String serviceType;
  final DateTime dateTime;
  final String address;
  final BookingStatus status;
  final double? price;
  final String? notes;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.clientId,
    required this.professionalId,
    required this.serviceType,
    required this.dateTime,
    required this.address,
    required this.status,
    this.price,
    this.notes,
    required this.createdAt,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      clientId: data['clientId'],
      professionalId: data['professionalId'],
      serviceType: data['serviceType'],
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      address: data['address'],
      status: BookingStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
      ),
      price: data['price']?.toDouble(),
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clientId': clientId,
      'professionalId': professionalId,
      'serviceType': serviceType,
      'dateTime': Timestamp.fromDate(dateTime),
      'address': address,
      'status': status.toString(),
      'price': price,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new booking
  Future<String> createBooking({
    required String clientId,
    required String professionalId,
    required String serviceType,
    required DateTime dateTime,
    required String address,
    double? price,
    String? notes,
  }) async {
    try {
      final booking = await _firestore.collection('bookings').add({
        'clientId': clientId,
        'professionalId': professionalId,
        'serviceType': serviceType,
        'dateTime': Timestamp.fromDate(dateTime),
        'address': address,
        'status': BookingStatus.pending.toString(),
        'price': price,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return booking.id;
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  // Get bookings for a client
  Stream<List<Booking>> getClientBookings(String clientId) {
    return _firestore
        .collection('bookings')
        .where('clientId', isEqualTo: clientId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
  }

  // Get bookings for a professional
  Stream<List<Booking>> getProfessionalBookings(String professionalId) {
    return _firestore
        .collection('bookings')
        .where('professionalId', isEqualTo: professionalId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList());
  }

  // Update booking status
  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status.toString(),
      });
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  // Cancel booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.cancelled.toString(),
      });
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  // Get professional's availability
  Future<List<DateTime>> getProfessionalAvailability(
    String professionalId,
    DateTime date,
  ) async {
    try {
      final bookings = await _firestore
          .collection('bookings')
          .where('professionalId', isEqualTo: professionalId)
          .where('dateTime',
              isGreaterThanOrEqualTo: DateTime(date.year, date.month, date.day))
          .where('dateTime',
              isLessThan: DateTime(date.year, date.month, date.day + 1))
          .get();

      final bookedTimes = bookings.docs
          .map((doc) => (doc.data()['dateTime'] as Timestamp).toDate())
          .toList();

      // Generate available time slots (assuming 1-hour slots from 8 AM to 8 PM)
      final availableSlots = <DateTime>[];
      final startTime = DateTime(date.year, date.month, date.day, 8);
      final endTime = DateTime(date.year, date.month, date.day, 20);

      for (var time = startTime;
          time.isBefore(endTime);
          time = time.add(const Duration(hours: 1))) {
        if (!bookedTimes.any((bookedTime) =>
            bookedTime.hour == time.hour &&
            bookedTime.day == time.day &&
            bookedTime.month == time.month &&
            bookedTime.year == time.year)) {
          availableSlots.add(time);
        }
      }

      return availableSlots;
    } catch (e) {
      throw Exception('Failed to get professional availability: $e');
    }
  }
}

// Providers
final bookingServiceProvider = Provider<BookingService>((ref) => BookingService());

final clientBookingsProvider =
    StreamProvider.family<List<Booking>, String>((ref, clientId) {
  return ref.watch(bookingServiceProvider).getClientBookings(clientId);
});

final professionalBookingsProvider =
    StreamProvider.family<List<Booking>, String>((ref, professionalId) {
  return ref
      .watch(bookingServiceProvider)
      .getProfessionalBookings(professionalId);
});

final professionalAvailabilityProvider = FutureProvider.family<List<DateTime>,
    ({String professionalId, DateTime date})>((ref, params) {
  return ref
      .watch(bookingServiceProvider)
      .getProfessionalAvailability(params.professionalId, params.date);
});
