class Product {
  final int id;
  final String title;
  final String description;
  final double price;
  final String thumbnail;
  final int stock;
  final String sku;
  final double rating; // Added rating
  final String shippingInformation; // Added shipping
  final String returnPolicy; // Added return policy
  final int reviewCount; // Added review count (derived or direct)

  final List<Review> reviews; // Updated to List<Review>
  final List<String> images; // Added images list
  final String brand; // Added brand
  final String category; // Added category

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.thumbnail,
    required this.stock,
    this.sku = '',
    this.rating = 0.0,
    this.shippingInformation = 'Ships in 1-2 business days',
    this.returnPolicy = '30 days return policy',
    this.reviewCount = 0,
    this.reviews = const [],
    this.images = const [],
    this.brand = '',
    this.category = '',
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    var list = json['reviews'] as List? ?? [];
    List<Review> reviewsList = list.map((i) => Review.fromJson(i)).toList();

    var imagesList =
        (json['images'] as List?)?.map((e) => e as String).toList() ?? [];

    return Product(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'No Title',
      description: json['description'] as String? ?? 'No Description',
      price: (json['price'] as num? ?? 0).toDouble(),
      thumbnail: json['thumbnail'] as String? ?? '',
      stock: json['stock'] as int? ?? 0,
      sku: json['sku'] as String? ?? '',
      rating: (json['rating'] as num? ?? 0).toDouble(),
      shippingInformation:
          json['shippingInformation'] as String? ??
          'Ships in 1-2 business days',
      returnPolicy: json['returnPolicy'] as String? ?? '30 days return policy',
      reviewCount: reviewsList.length,
      reviews: reviewsList,
      images: imagesList,
      brand: json['brand'] as String? ?? '',
      category: json['category'] as String? ?? '',
    );
  }
  Product copyWith({
    int? id,
    String? title,
    String? description,
    double? price,
    String? thumbnail,
    int? stock,
    String? sku,
    double? rating,
    String? shippingInformation,
    String? returnPolicy,
    int? reviewCount,
    List<Review>? reviews,
    List<String>? images,
    String? brand,
    String? category,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      thumbnail: thumbnail ?? this.thumbnail,
      stock: stock ?? this.stock,
      sku: sku ?? this.sku,
      rating: rating ?? this.rating,
      shippingInformation: shippingInformation ?? this.shippingInformation,
      returnPolicy: returnPolicy ?? this.returnPolicy,
      reviewCount: reviewCount ?? this.reviewCount,
      reviews: reviews ?? this.reviews,
      images: images ?? this.images,
      brand: brand ?? this.brand,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'thumbnail': thumbnail,
      'stock': stock,
      'sku': sku,
      'rating': rating,
      'shippingInformation': shippingInformation,
      'returnPolicy': returnPolicy,
      'reviewCount': reviewCount,
      'reviews': reviews.map((x) => x.toJson()).toList(),
      'images': images,
      'brand': brand,
      'category': category,
    };
  }
}

class Review {
  final int rating;
  final String comment;
  final String date;
  final String reviewerName;
  final String reviewerEmail;

  Review({
    required this.rating,
    required this.comment,
    required this.date,
    required this.reviewerName,
    required this.reviewerEmail,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String? ?? '',
      date: json['date'] as String? ?? '',
      reviewerName: json['reviewerName'] as String? ?? 'Anonymous',
      reviewerEmail: json['reviewerEmail'] as String? ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'comment': comment,
      'date': date,
      'reviewerName': reviewerName,
      'reviewerEmail': reviewerEmail,
    };
  }
}
