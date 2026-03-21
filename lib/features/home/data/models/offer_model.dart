import '../../domain/entities/offer_entity.dart';

class OfferModel extends OfferEntity {
  const OfferModel({
    required super.id,
    required super.imageUrl,
    super.link,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id']?.toString() ?? '',
      imageUrl: json['image_url'] as String? ?? json['image'] as String? ?? '',
      link: json['link'] as String?,
    );
  }
}
