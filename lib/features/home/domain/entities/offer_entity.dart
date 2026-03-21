import 'package:equatable/equatable.dart';

class OfferEntity extends Equatable {
  final String id;
  final String imageUrl;
  final String? link;

  const OfferEntity({
    required this.id,
    required this.imageUrl,
    this.link,
  });

  @override
  List<Object?> get props => [id, imageUrl, link];
}
