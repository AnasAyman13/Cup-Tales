import 'package:equatable/equatable.dart';

import 'order_item_entity.dart';

class OrderEntity extends Equatable {
  final String id;
  final String userId;
  final List<OrderItemEntity> items;
  final double totalAmount;
  final String status;
  final String branchName;
  final String? promoCode;
  final double discountAmount;
  final DateTime createdAt;

  const OrderEntity({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    this.branchName = '',
    this.promoCode,
    this.discountAmount = 0.0,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        items,
        totalAmount,
        status,
        branchName,
        promoCode,
        discountAmount,
        createdAt,
      ];
}
