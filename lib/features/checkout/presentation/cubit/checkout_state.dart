import 'package:equatable/equatable.dart';
import '../../../../core/models/branch.dart';

abstract class CheckoutState extends Equatable {
  const CheckoutState();

  @override
  List<Object?> get props => [];
}

class CheckoutInitial extends CheckoutState {
  final String selectedMethod;
  final Branch? selectedBranch;
  final List<Branch> branches;

  const CheckoutInitial({
    this.selectedMethod = 'Cashier',
    this.selectedBranch,
    this.branches = const [],
  });

  @override
  List<Object?> get props => [selectedMethod, selectedBranch, branches];
}

class CheckoutProcessing extends CheckoutState {}

class CheckoutSuccess extends CheckoutState {}

class CheckoutPaymentRedirect extends CheckoutState {
  final String url;

  const CheckoutPaymentRedirect(this.url);

  @override
  List<Object> get props => [url];
}

class CheckoutError extends CheckoutState {
  final String message;

  const CheckoutError(this.message);

  @override
  List<Object> get props => [message];
}
