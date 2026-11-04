import 'package:flutter/material.dart';

void main() => runApp(const DrugCartApp());

class DrugCartApp extends StatelessWidget {
  const DrugCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drug Cart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      home: const OrderPage(),
    );
  }
}

class MenuItem {
  final String name;
  final double price; // in GHS
  final IconData icon;
  const MenuItem(this.name, this.price, this.icon);
}

const menu = [
  MenuItem('Paracetamol 500mg', 5.00, Icons.medication_liquid),
  MenuItem('Amoxicillin 250mg', 15.00, Icons.medication),
  MenuItem('Ibuprofen 400mg', 8.50, Icons.medication_outlined),
  MenuItem('Vitamin C Tablets', 12.00, Icons.local_pharmacy),
  MenuItem('Cough Syrup 100ml', 20.00, Icons.local_drink),
];

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  // THE STATE: quantity ordered for each menu index
  final Map<int, int> _qty = {};

  // Challenge 3: search filter
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    debugPrint('OrderPage: initState() -- runs ONCE');
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    debugPrint('OrderPage: dispose() -- cleaning up');
    _searchController.dispose();
    super.dispose();
  }

  double get _total {
    var sum = 0.0;
    _qty.forEach((i, q) => sum += menu[i].price * q);
    return sum;
  }

  // Challenge 1: badge count
  int get _itemCount {
    var count = 0;
    _qty.forEach((i, q) => count += q);
    return count;
  }

  void _change(int index, int delta) {
    setState(() {
      final next = (_qty[index] ?? 0) + delta;
      if (next <= 0) {
        _qty.remove(index); // never below zero
      } else {
        _qty[index] = next;
      }
    });
  }

  Future<void> _clearOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear order?'),
        content: const Text('All quantities will reset to zero.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _qty.clear());
      // Challenge 2: SnackBar feedback
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Order cleared')));
    }
  }

  List<int> get _filteredIndexes {
    if (_searchQuery.isEmpty) {
      return List.generate(menu.length, (i) => i);
    }
    final query = _searchQuery.toLowerCase();
    final indexes = <int>[];
    for (var i = 0; i < menu.length; i++) {
      if (menu[i].name.toLowerCase().contains(query)) {
        indexes.add(i);
      }
    }
    return indexes;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('OrderPage: build() -- drawing UI');
    final indexes = _filteredIndexes;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Drug Cart '),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Badge(
              label: Text('$_itemCount'),
              isLabelVisible: _itemCount > 0,
              child: const Icon(Icons.shopping_cart),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear order',
            onPressed: _qty.isEmpty ? null : _clearOrder,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search drugs',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          // Dashboard now stretches to fit the full width of the screen.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: double.infinity,
              child: OrderDashboard(itemCount: _itemCount, total: _total),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: indexes.isEmpty
                ? const Center(child: Text('No matching drugs'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: indexes.length,
                    itemBuilder: (context, listIndex) {
                      final i = indexes[listIndex];
                      final item = menu[i];
                      final q = _qty[i] ?? 0;
                      return Padding(
                        // 8-pixel vertical gap between each rounded tile
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          elevation: 1,
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade50,
                              child: Icon(item.icon, color: Colors.blue),
                            ),
                            title: Text(item.name),
                            subtitle: Text(
                              'GHS ${item.price.toStringAsFixed(2)}',
                            ),
                            trailing: QuantityStepper(
                              quantity: q,
                              onIncrement: () => _change(i, 1),
                              onDecrement: () => _change(i, -1),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// The dashboard showing order item count and running total.
// Now stretched to fit the full width of the screen instead of floating
// as a small centered card.
class OrderDashboard extends StatelessWidget {
  final int itemCount;
  final double total;

  const OrderDashboard({
    super.key,
    required this.itemCount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$itemCount item${itemCount == 1 ? '' : 's'} in order',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'GHS ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Challenge 4: extracted quantity stepper.
// This is a StatelessWidget because it holds no state of its own: the
// quantity it shows comes in from the parent via the `quantity` field,
// and both buttons just call the onIncrement/onDecrement callbacks back
// up to _OrderPageState, which is the only place _qty (the real state)
// lives. Since this widget never mutates anything itself, it never
// needs setState() and can safely stay stateless.

class QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: quantity == 0 ? null : onDecrement,
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: onIncrement,
        ),
      ],
    );
  }
}

// testing pull request for the first and this is comment is want I am using for the noticeable 
// change to make the pr testing 
