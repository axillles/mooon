import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/food.dart';

class FoodMenuScreen extends StatefulWidget {
  final String? seatRow;
  final int? seatNumber;
  final int? screeningId;

  const FoodMenuScreen({
    super.key,
    this.seatRow,
    this.seatNumber,
    this.screeningId,
  });

  @override
  State<FoodMenuScreen> createState() => _FoodMenuScreenState();
}

class _FoodMenuScreenState extends State<FoodMenuScreen> {
  late Future<Map<String, List<FoodItem>>> _menuFuture;
  FoodOrder? _order;
  List<Map<String, dynamic>> _items = []; // Изменен тип
  final ScrollController _listController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {};
  String? _activeCategory;

  @override
  void initState() {
    super.initState();
    _menuFuture = SupabaseService.getFoodMenu();
    _ensureDraftOrder();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  Future<void> _ensureDraftOrder() async {
    if (widget.screeningId != null &&
        widget.seatRow != null &&
        widget.seatNumber != null) {
      final order = await SupabaseService.getOrCreateDraftFoodOrder(
        screeningId: widget.screeningId!,
        seatRow: widget.seatRow!,
        seatNumber: widget.seatNumber!,
      );
      if (!mounted) return;
      final items = await SupabaseService.getOrderItems(order.id);
      if (!mounted) return;
      setState(() {
        _order = order;
        _items = items;
      });
    }
  }

  void _openDetails(FoodItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _FoodDetailsSheet(
            item: item,
            onAdd: (double finalPrice) async {
              if (_order == null) return;
              await SupabaseService.addFoodToOrder(
                orderId: _order!.id,
                foodId: item.id,
                quantity: 1,
                unitPriceOverride: finalPrice,
              );
              final items = await SupabaseService.getOrderItems(_order!.id);
              if (!mounted) return;
              setState(() => _items = items);
            },
          ),
    );
  }

  int get _totalQuantity =>
      _items.fold(0, (sum, it) => sum + (it['item'] as FoodOrderItem).quantity);
  double get _totalAmount => _items.fold(
    0.0,
    (sum, it) =>
        sum +
        (it['item'] as FoodOrderItem).quantity *
            (it['item'] as FoodOrderItem).unitPrice,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121218),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121218),
        elevation: 0,
        title: const Text('Меню в зал'),
        actions: [
          if (_order != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  _totalAmount.toStringAsFixed(2) + ' BYN',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            ),
        ],
      ),
      body: FutureBuilder<Map<String, List<FoodItem>>>(
        future: _menuFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data ?? {};
          if (data.isEmpty) {
            return const Center(
              child: Text(
                'Меню пока недоступно',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final List<String> categories = data.keys.toList();
          print('FoodMenuScreen: получены категории: $categories');
          _activeCategory ??= categories.first;
          for (final c in categories) {
            _sectionKeys.putIfAbsent(c, () => GlobalKey());
          }

          return ListView(
            controller: _listController,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            children: [
              // Горизонтальное меню категорий
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final c = categories[index];
                    final bool selected = c == _activeCategory;
                    return GestureDetector(
                      onTap: () async {
                        setState(() => _activeCategory = c);
                        final key = _sectionKeys[c];
                        if (key?.currentContext != null) {
                          await Scrollable.ensureVisible(
                            key!.currentContext!,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            alignment: 0.05,
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              selected
                                  ? const Color(0xFF5B5BFF)
                                  : const Color(0xFF1A1A22),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color:
                                selected
                                    ? const Color(0xFF5B5BFF)
                                    : Colors.white24,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            c,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (context, _) => const SizedBox(width: 8),
                  itemCount: categories.length,
                ),
              ),
              const SizedBox(height: 12),

              for (final entry in data.entries) ...[
                Container(
                  key: _sectionKeys[entry.key],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 12,
                          bottom: 8,
                          left: 4,
                          right: 4,
                        ),
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.72,
                            ),
                        itemCount: entry.value.length,
                        itemBuilder: (context, i) {
                          final item = entry.value[i];
                          final cartItems = _items.where(
                            (it) =>
                                (it['item'] as FoodOrderItem).foodId == item.id,
                          );
                          final cartItem =
                              cartItems.isEmpty ? null : cartItems.first;
                          return _FoodCard(
                            item: item,
                            onOpen: () => _openDetails(item),
                            quantityInCart:
                                cartItem != null
                                    ? (cartItem['item'] as FoodOrderItem)
                                        .quantity
                                    : null,
                            onIncreaseQuantity:
                                cartItem != null
                                    ? () => _openDetails(item)
                                    : null,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar:
          (_order != null && _totalQuantity > 0)
              ? SafeArea(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A22),
                    border: Border(
                      top: BorderSide(color: Colors.white12, width: 1),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openCart,
                          icon: const Icon(
                            Icons.shopping_cart_outlined,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Корзина (' +
                                _totalQuantity.toString() +
                                ') — ' +
                                _totalAmount.toStringAsFixed(2) +
                                ' BYN',
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B5BFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : null,
    );
  }

  void _openCart() async {
    if (_order == null) return;

    String? defaultSeatRow = widget.seatRow;
    int? defaultSeatNumber = widget.seatNumber;
    if (defaultSeatRow == null || defaultSeatNumber == null) {
      defaultSeatRow = _order!.seatRow;
      defaultSeatNumber = _order!.seatNumber;
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F0F14),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.88,
          maxChildSize: 0.95,
          minChildSize: 0.7,
          builder: (context, controller) {
            return _CartBottomSheet(
              items: _items,
              totalAmount: _totalAmount,
              defaultSeatRow: defaultSeatRow,
              defaultSeatNumber: defaultSeatNumber,
              onQuantityChange: _changeQty,
              onRemoveItem: _removeItem,
              onUpdateSeatInfo: (row, number) async {
                if (_order != null) {
                  await SupabaseService.updateFoodOrderSeat(
                    orderId: _order!.id,
                    seatRow: row,
                    seatNumber: number,
                  );
                }
              },
              onDismiss: () => Navigator.of(context).pop(),
            );
          },
        );
      },
    );
    if (_order != null) {
      final items = await SupabaseService.getOrderItems(_order!.id);
      if (!mounted) return;
      setState(() {
        _items = items;
      });
    }
  }

  Future<void> _changeQty(FoodOrderItem it, int newQty) async {
    if (_order == null) return;
    await SupabaseService.setFoodItemQuantity(
      orderId: _order!.id,
      foodId: it.foodId,
      quantity: newQty,
    );
    final items = await SupabaseService.getOrderItems(_order!.id);
    if (!mounted) return;
    setState(() => _items = items);
  }

  Future<void> _removeItem(FoodOrderItem it) async {
    if (_order == null) return;
    await SupabaseService.removeFoodFromOrder(
      orderId: _order!.id,
      foodId: it.foodId,
    );
    final items = await SupabaseService.getOrderItems(_order!.id);
    if (!mounted) return;
    setState(() => _items = items);
  }
}

class _FoodCard extends StatelessWidget {
  final FoodItem item;
  final VoidCallback onOpen;
  final int? quantityInCart;
  final VoidCallback? onIncreaseQuantity;

  const _FoodCard({
    required this.item,
    required this.onOpen,
    this.quantityInCart,
    this.onIncreaseQuantity,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF18181C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFF111115),
                  child:
                      item.imageUrl != null && item.imageUrl!.isNotEmpty
                          ? Image.network(item.imageUrl!, fit: BoxFit.cover)
                          : const Icon(
                            Icons.local_cafe,
                            color: Colors.white24,
                            size: 48,
                          ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: const [
                  Expanded(child: SizedBox()),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white38,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodDetailsSheet extends StatefulWidget {
  final FoodItem item;
  final void Function(double finalPrice) onAdd;
  const _FoodDetailsSheet({required this.item, required this.onAdd});

  @override
  State<_FoodDetailsSheet> createState() => _FoodDetailsSheetState();
}

class _FoodDetailsSheetState extends State<_FoodDetailsSheet> {
  late String _selectedSize;

  @override
  void initState() {
    super.initState();
    final sizes = widget.item.availableSizes;
    _selectedSize = sizes.isNotEmpty ? sizes[(sizes.length - 1) ~/ 2] : 'M';
  }

  double get _price {
    return widget.item.getPriceForSize(_selectedSize);
  }

  String? get _volume {
    return widget.item.getVolumeForSize(_selectedSize);
  }

  @override
  Widget build(BuildContext context) {
    final sizes = widget.item.availableSizes;
    if (sizes.isEmpty) return const SizedBox.shrink();

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F14),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header with close
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
          ),

          // Image
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                color: const Color(0xFF121218),
                child:
                    widget.item.imageUrl != null &&
                            widget.item.imageUrl!.isNotEmpty
                        ? Image.network(
                          widget.item.imageUrl!,
                          fit: BoxFit.cover,
                        )
                        : const Icon(
                          Icons.local_cafe,
                          color: Colors.white24,
                          size: 72,
                        ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          Text(
            widget.item.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'customize as you like it',
            style: TextStyle(color: Colors.white38),
          ),

          const SizedBox(height: 16),
          // SegmentedButton размеров + кнопка добавления справа
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: [
                      for (final s in sizes)
                        ButtonSegment<String>(value: s, label: Text(s)),
                    ],
                    selected: {_selectedSize},
                    onSelectionChanged: (newSel) {
                      if (newSel.isNotEmpty) {
                        setState(() => _selectedSize = newSel.first);
                      }
                    },
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.resolveWith<Color?>((states) {
                            if (states.contains(MaterialState.selected)) {
                              return const Color(0xFF5B5BFF);
                            }
                            return const Color(0xFF1A1A22);
                          }),
                      foregroundColor:
                          MaterialStateProperty.resolveWith<Color?>((states) {
                            return Colors.white;
                          }),
                      side: MaterialStateProperty.resolveWith<BorderSide?>((
                        states,
                      ) {
                        if (states.contains(MaterialState.selected)) {
                          return const BorderSide(color: Color(0xFF5B5BFF));
                        }
                        return const BorderSide(color: Colors.white24);
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 40, // Такая же высота как у SegmentedButton
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onAdd(_price);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B5BFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, color: Colors.white, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          _price.toStringAsFixed(2) + ' BYN',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final FoodOrderItem item;
  final String itemName;
  final String? imageUrl;
  final VoidCallback onInc;
  final VoidCallback onDec;
  final VoidCallback onDelete;

  const _CartItemTile({
    required this.item,
    required this.itemName,
    this.imageUrl,
    required this.onInc,
    required this.onDec,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF18181C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 44,
              height: 44,
              color: const Color(0xFF111115),
              child:
                  (imageUrl != null && imageUrl!.isNotEmpty)
                      ? Image.network(imageUrl!, fit: BoxFit.cover)
                      : const Icon(
                        Icons.local_cafe,
                        color: Colors.white24,
                        size: 22,
                      ),
            ),
          ),
          const SizedBox(width: 12),
          // Name + Price column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        itemName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Quantity stepper
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F1F28),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: onDec,
                            iconSize: 20,
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            icon: const Icon(
                              Icons.remove,
                              color: Colors.white70,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              item.quantity.toString(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          IconButton(
                            onPressed: onInc,
                            iconSize: 20,
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            icon: const Icon(Icons.add, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.unitPrice.toStringAsFixed(2) + ' BYN',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final String? defaultSeatRow;
  final int? defaultSeatNumber;
  final Function(FoodOrderItem, int) onQuantityChange;
  final Function(FoodOrderItem) onRemoveItem;
  final Function(String, int) onUpdateSeatInfo;
  final VoidCallback onDismiss;

  const _CartBottomSheet({
    required this.items,
    required this.totalAmount,
    required this.defaultSeatRow,
    required this.defaultSeatNumber,
    required this.onQuantityChange,
    required this.onRemoveItem,
    required this.onUpdateSeatInfo,
    required this.onDismiss,
  });

  @override
  State<_CartBottomSheet> createState() => _CartBottomSheetState();
}

class _CartBottomSheetState extends State<_CartBottomSheet> {
  late TextEditingController _rowController;
  late TextEditingController _numberController;
  List<Map<String, dynamic>> _items; // Локальная копия для обновления UI
  String _paymentMethod = 'Apple Pay';

  _CartBottomSheetState() : _items = [];

  @override
  void initState() {
    super.initState();
    _rowController = TextEditingController(text: widget.defaultSeatRow ?? '');
    _numberController = TextEditingController(
      text: widget.defaultSeatNumber?.toString() ?? '',
    );
    _items = List.from(widget.items); // Копируем начальные данные
  }

  @override
  void dispose() {
    _rowController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  // Метод для обновления количества товара
  void _updateItemQuantity(FoodOrderItem item, int newQuantity) async {
    await widget.onQuantityChange(item, newQuantity);
    // Обновляем локальное состояние
    setState(() {
      final index = _items.indexWhere(
        (it) => (it['item'] as FoodOrderItem).id == item.id,
      );
      if (index != -1) {
        _items[index] = {
          ..._items[index],
          'item': FoodOrderItem(
            id: item.id,
            orderId: item.orderId,
            foodId: item.foodId,
            quantity: newQuantity,
            unitPrice: item.unitPrice,
          ),
        };
      }
    });
  }

  // Метод для удаления товара
  void _removeItem(FoodOrderItem item) async {
    await widget.onRemoveItem(item);
    // Обновляем локальное состояние
    setState(() {
      _items.removeWhere((it) => (it['item'] as FoodOrderItem).id == item.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _items.fold(
      0.0,
      (sum, it) =>
          sum +
          (it['item'] as FoodOrderItem).quantity *
              (it['item'] as FoodOrderItem).unitPrice,
    );

    void _maybeCloseIfEmpty() {
      if (_items.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).maybePop();
        });
      }
    }

    _maybeCloseIfEmpty();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: red trash clears all, close right
          Row(
            children: [
              IconButton(
                onPressed: () async {
                  await SupabaseService.clearFoodOrder(
                    (widget.items.first['item'] as FoodOrderItem).orderId,
                  );
                  setState(() => _items.clear());
                  _maybeCloseIfEmpty();
                },
                icon: const Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.redAccent,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: widget.onDismiss,
                icon: const Icon(Icons.close, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final it = _items[i];
                return Dismissible(
                  key: ValueKey(
                    (it['item'] as FoodOrderItem).id.toString() +
                        '_' +
                        i.toString(),
                  ),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                  ),
                  onDismissed: (_) {
                    _removeItem(it['item'] as FoodOrderItem);
                    _maybeCloseIfEmpty();
                  },
                  child: _CartListRow(
                    name: it['name'] as String,
                    imageUrl: it['imageUrl'] as String?,
                    sizeLabel: _extractMaxSizeLabel(it['sizePrices']),
                    price:
                        _extractMaxSizePrice(it['sizePrices']) ??
                        (it['item'] as FoodOrderItem).unitPrice,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Поля ряд/место под списком
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _rowController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Ряд',
                    labelStyle: TextStyle(color: Colors.white54),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF5B5BFF)),
                    ),
                  ),
                  onChanged: (value) {
                    final number = int.tryParse(_numberController.text);
                    if (value.isNotEmpty && number != null) {
                      widget.onUpdateSeatInfo(value, number);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _numberController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Место',
                    labelStyle: TextStyle(color: Colors.white54),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF5B5BFF)),
                    ),
                  ),
                  onChanged: (value) {
                    final number = int.tryParse(value);
                    if (_rowController.text.isNotEmpty && number != null) {
                      widget.onUpdateSeatInfo(_rowController.text, number);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Payment bar
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final method = await showModalBottomSheet<String>(
                      context: context,
                      backgroundColor: const Color(0xFF1F1F28),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      builder: (ctx) {
                        return SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(
                                  Icons.apple,
                                  color: Colors.white,
                                ),
                                title: const Text(
                                  'Apple Pay',
                                  style: TextStyle(color: Colors.white),
                                ),
                                onTap: () => Navigator.of(ctx).pop('Apple Pay'),
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.credit_card,
                                  color: Colors.white,
                                ),
                                title: const Text(
                                  'Add card',
                                  style: TextStyle(color: Colors.white),
                                ),
                                onTap: () => Navigator.of(ctx).pop('Card'),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                    if (method != null) {
                      setState(() => _paymentMethod = method);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1F28),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _paymentMethod == 'Apple Pay'
                              ? Icons.apple
                              : Icons.credit_card,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _paymentMethod == 'Apple Pay'
                                ? 'Apple Pay'
                                : 'Add card',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.expand_more, color: Colors.white70),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Total', style: TextStyle(color: Colors.white70)),
                  Text(
                    totalAmount.toStringAsFixed(2) + ' BYN',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Оплата: ' + _paymentMethod)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4453FF),
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text(
                'Pay',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartListRow extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final String? sizeLabel;
  final double price;

  const _CartListRow({
    required this.name,
    required this.imageUrl,
    required this.sizeLabel,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF18181C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          // Image taking full item height
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(12),
            ),
            child: Container(
              width: 64,
              height: 64,
              color: const Color(0xFF111115),
              child:
                  (imageUrl != null && imageUrl!.isNotEmpty)
                      ? Image.network(imageUrl!, fit: BoxFit.cover)
                      : const Icon(Icons.local_cafe, color: Colors.white24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (sizeLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sizeLabel!,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 6),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              price.toStringAsFixed(2) + ' BYN',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String? _extractMaxSizeLabel(dynamic sizePrices) {
  if (sizePrices is Map<String, dynamic> && sizePrices.isNotEmpty) {
    final keys = sizePrices.keys.toList()..sort();
    final last = keys.last;
    final map = sizePrices[last];
    if (map is Map<String, dynamic>) {
      return last +
          (map['volume'] != null ? ' • ' + map['volume'].toString() : '');
    }
    return last;
  }
  return null;
}

double? _extractMaxSizePrice(dynamic sizePrices) {
  if (sizePrices is Map<String, dynamic> && sizePrices.isNotEmpty) {
    final keys = sizePrices.keys.toList()..sort();
    final last = keys.last;
    final map = sizePrices[last];
    if (map is Map<String, dynamic> && map['price'] != null) {
      return (map['price'] as num).toDouble();
    }
  }
  return null;
}
