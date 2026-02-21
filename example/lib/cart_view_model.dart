import 'package:flutter/foundation.dart';
import 'package:solid/solid.dart';

@immutable
class CartItem {
  final String id;
  final String name;
  final double price;
  final int quantity;

  const CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  CartItem copyWith({int? quantity}) => CartItem(
    id: id,
    name: name,
    price: price,
    quantity: quantity ?? this.quantity,
  );

  double get total => price * quantity;
}

const catalogue = [
  CartItem(id: 'p1', name: 'Flutter T-Shirt', price: 29.99),
  CartItem(id: 'p2', name: 'Dart Hoodie', price: 49.99),
  CartItem(id: 'p3', name: 'Solid Sticker Pack', price: 4.99),
  CartItem(id: 'p4', name: 'Dev Mug ☕', price: 14.99),
];

@immutable
class CartState {
  final List<CartItem> items;
  final bool isCheckingOut;
  final String? checkoutRef;
  final String? error;

  const CartState({
    this.items = const [],
    this.isCheckingOut = false,
    this.checkoutRef,
    this.error,
  });

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);
  double get subtotal => items.fold(0.0, (sum, i) => sum + i.total);

  CartState copyWith({
    List<CartItem>? items,
    bool? isCheckingOut,
    String? checkoutRef,
    String? error,
    bool clearRef = false,
    bool clearError = false,
  }) {
    return CartState(
      items: items ?? this.items,
      isCheckingOut: isCheckingOut ?? this.isCheckingOut,
      checkoutRef: clearRef ? null : (checkoutRef ?? this.checkoutRef),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CartViewModel extends Solid<CartState> {
  CartViewModel() : super(const CartState());

  void addItem(CartItem item) {
    final idx = state.items.indexWhere((i) => i.id == item.id);
    final updated = idx >= 0
        ? [
            ...state.items.sublist(0, idx),
            state.items[idx].copyWith(quantity: state.items[idx].quantity + 1),
            ...state.items.sublist(idx + 1),
          ]
        : [...state.items, item];
    push(state.copyWith(items: updated, clearRef: true, clearError: true));
  }

  void removeItem(String id) {
    push(
      state.copyWith(
        items: state.items.where((i) => i.id != id).toList(),
        clearRef: true,
      ),
    );
  }

  void updateQuantity(String id, int qty) {
    if (qty <= 0) {
      removeItem(id);
      return;
    }
    push(
      state.copyWith(
        items: state.items
            .map((i) => i.id == id ? i.copyWith(quantity: qty) : i)
            .toList(),
      ),
    );
  }

  void clearCart() => push(const CartState());

  Future<void> checkout() async {
    if (state.items.isEmpty) {
      push(state.copyWith(error: 'Cart is empty'));
      return;
    }
    push(state.copyWith(isCheckingOut: true, clearError: true));
    await Future<void>.delayed(const Duration(seconds: 2));
    final ref = 'ORD-${DateTime.now().millisecondsSinceEpoch % 10000}';
    push(CartState(checkoutRef: ref)); // clear cart, set ref
  }
}
