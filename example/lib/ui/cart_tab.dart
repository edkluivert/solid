import 'package:flutter/material.dart';
import 'package:solid_x/solid_x.dart';

import '../cart_view_model.dart';

class CartTab extends StatelessWidget {
  const CartTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SolidProvider<CartViewModel>(
      create: CartViewModel.new,
      // SolidListener — side effects on state change (snackbars, navigation)
      child: SolidListener<CartViewModel, CartState>(
        listener: (context, state) {
          if (state.checkoutRef != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text('✅ Order placed! Ref: ${state.checkoutRef}'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                ),
              );
          }
          if (state.error != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.error!),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
          }
        },
        // SolidBuilder — rebuilds UI on every push()
        child: SolidBuilder<CartViewModel, CartState>(
          builder: (context, state) {
            final vm = context.solid<CartViewModel>();
            return Scaffold(
              appBar: AppBar(
                title: const Text('Cart'),
                centerTitle: true,
                actions: [
                  if (state.itemCount > 0)
                    Badge.count(
                      count: state.itemCount,
                      child: const Icon(Icons.shopping_cart_outlined),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined),
                    tooltip: 'Clear cart',
                    onPressed: vm.clearCart,
                  ),
                ],
              ),
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Text(
                      'Tap a product to add it to the cart',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  _ProductGrid(vm: vm),
                  const Divider(height: 1),
                  Expanded(
                    child: _CartList(state: state, vm: vm),
                  ),
                  _CheckoutBar(state: state, vm: vm),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final CartViewModel vm;
  const _ProductGrid({required this.vm});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: catalogue.length,
      itemBuilder: (_, i) {
        final p = catalogue[i];
        return Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => vm.addItem(p),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '\$${p.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.add_circle_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CartList extends StatelessWidget {
  final CartState state;
  final CartViewModel vm;
  const _CartList({required this.state, required this.vm});

  @override
  Widget build(BuildContext context) {
    if (state.items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 56),
            SizedBox(height: 12),
            Text('Your cart is empty'),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: state.items.length,
      itemBuilder: (_, i) {
        final item = state.items[i];
        return ListTile(
          title: Text(item.name),
          subtitle: Text('\$${item.price.toStringAsFixed(2)} each'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                onPressed: () => vm.updateQuantity(item.id, item.quantity - 1),
              ),
              Text(
                '${item.quantity}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                onPressed: () => vm.updateQuantity(item.id, item.quantity + 1),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => vm.removeItem(item.id),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  final CartState state;
  final CartViewModel vm;
  const _CheckoutBar({required this.state, required this.vm});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Subtotal', style: Theme.of(context).textTheme.labelSmall),
                Text(
                  '\$${state.subtotal.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                onPressed: state.isCheckingOut ? null : vm.checkout,
                child: state.isCheckingOut
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Checkout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
