import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ServiceCategory {
  final String id;
  final String name;
  final String iconUrl;

  ServiceCategory({
    required this.id,
    required this.name,
    required this.iconUrl,
  });

  factory ServiceCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceCategory(
      id: doc.id,
      name: data['name'],
      iconUrl: data['iconUrl'],
    );
  }
}

class Professional {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final String description;
  final List<String> categories;
  final List<Service> services;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final bool isCertified;
  final bool isResponsive;
  final String city;
  final DateTime lastActive;
  final List<String> galleryUrls;

  Professional({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    required this.description,
    required this.categories,
    required this.services,
    required this.rating,
    required this.reviewCount,
    required this.isVerified,
    required this.isCertified,
    required this.isResponsive,
    required this.city,
    required this.lastActive,
    required this.galleryUrls,
  });

  factory Professional.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Professional(
      id: doc.id,
      name: data['name'],
      email: data['email'],
      phone: data['phone'],
      photoUrl: data['photoUrl'],
      description: data['description'],
      categories: List<String>.from(data['categories']),
      services: (data['services'] as List)
          .map((service) => Service.fromMap(service))
          .toList(),
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      isVerified: data['isVerified'] ?? false,
      isCertified: data['isCertified'] ?? false,
      isResponsive: data['isResponsive'] ?? false,
      city: data['city'],
      lastActive: (data['lastActive'] as Timestamp).toDate(),
      galleryUrls: List<String>.from(data['galleryUrls'] ?? []),
    );
  }
}

class Service {
  final String name;
  final double price;
  final String? description;
  final String priceType; // 'per_hour' or 'fixed'

  Service({
    required this.name,
    required this.price,
    this.description,
    required this.priceType,
  });

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      name: map['name'],
      price: map['price'].toDouble(),
      description: map['description'],
      priceType: map['priceType'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'description': description,
      'priceType': priceType,
    };
  }
}

class Review {
  final String id;
  final String clientId;
  final String clientName;
  final String professionalId;
  final double rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.professionalId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      clientId: data['clientId'],
      clientName: data['clientName'],
      professionalId: data['professionalId'],
      rating: data['rating'].toDouble(),
      comment: data['comment'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

class ProfessionalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all service categories
  Stream<List<ServiceCategory>> getCategories() {
    return _firestore.collection('categories').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => ServiceCategory.fromFirestore(doc))
              .toList(),
        );
  }

  // Get recommended professionals
  Stream<List<Professional>> getRecommendedProfessionals() {
    return _firestore
        .collection('users')
        .where('userType', isEqualTo: 'UserType.professional')
        .orderBy('rating', descending: true)
        .limit(10)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Professional.fromFirestore(doc))
              .toList(),
        );
  }

  // Get professional by ID
  Future<Professional> getProfessionalById(String id) async {
    final doc = await _firestore.collection('users').doc(id).get();
    if (!doc.exists) {
      throw Exception('Professional not found');
    }
    return Professional.fromFirestore(doc);
  }

  // Get professionals by category
  Stream<List<Professional>> getProfessionalsByCategory(String categoryId) {
    return _firestore
        .collection('users')
        .where('userType', isEqualTo: 'UserType.professional')
        .where('categories', arrayContains: categoryId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Professional.fromFirestore(doc))
              .toList(),
        );
  }

  // Get reviews for a professional
  Stream<List<Review>> getProfessionalReviews(String professionalId) {
    return _firestore
        .collection('reviews')
        .where('professionalId', isEqualTo: professionalId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList(),
        );
  }

  // Add a review
  Future<void> addReview({
    required String clientId,
    required String clientName,
    required String professionalId,
    required double rating,
    required String comment,
  }) async {
    try {
      // Add the review
      await _firestore.collection('reviews').add({
        'clientId': clientId,
        'clientName': clientName,
        'professionalId': professionalId,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update professional's rating
      final reviews = await _firestore
          .collection('reviews')
          .where('professionalId', isEqualTo: professionalId)
          .get();

      final totalRating = reviews.docs.fold<double>(
          0, (sum, doc) => sum + doc.data()['rating'].toDouble());
      final averageRating = totalRating / reviews.docs.length;

      await _firestore.collection('users').doc(professionalId).update({
        'rating': averageRating,
        'reviewCount': reviews.docs.length,
      });
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }

  // Update professional's services
  Future<void> updateServices(String professionalId, List<Service> services) async {
    try {
      await _firestore.collection('users').doc(professionalId).update({
        'services': services.map((service) => service.toMap()).toList(),
      });
    } catch (e) {
      throw Exception('Failed to update services: $e');
    }
  }

  // Update professional's gallery
  Future<void> updateGallery(String professionalId, List<String> galleryUrls) async {
    try {
      await _firestore.collection('users').doc(professionalId).update({
        'galleryUrls': galleryUrls,
      });
    } catch (e) {
      throw Exception('Failed to update gallery: $e');
    }
  }

  // Search professionals
  Future<List<Professional>> searchProfessionals(String query) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'UserType.professional')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      return snapshot.docs.map((doc) => Professional.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to search professionals: $e');
    }
  }
}

// Providers
final professionalServiceProvider =
    Provider<ProfessionalService>((ref) => ProfessionalService());

final categoriesProvider = StreamProvider<List<ServiceCategory>>((ref) {
  return ref.watch(professionalServiceProvider).getCategories();
});

final recommendedProfessionalsProvider =
    StreamProvider<List<Professional>>((ref) {
  return ref.watch(professionalServiceProvider).getRecommendedProfessionals();
});

final professionalProvider =
    FutureProvider.family<Professional, String>((ref, id) {
  return ref.watch(professionalServiceProvider).getProfessionalById(id);
});

final professionalReviewsProvider =
    StreamProvider.family<List<Review>, String>((ref, professionalId) {
  return ref
      .watch(professionalServiceProvider)
      .getProfessionalReviews(professionalId);
});
