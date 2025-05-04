import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_solar/widgets/checkout_screen.dart';

import 'package:smart_solar/widgets/snackbar_utils.dart';


import '../widgets/bottom_nav_bar.dart'; // Import the utils

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _cartItems = [];
  double _totalAmount = 0;
  int _selectedIndex = 3; // Cart tab selected
  final TextEditingController _couponController = TextEditingController();
  double _discount = 0.0; // To store the applied discount

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _loadCartItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final cartSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .get();

        final List<Map<String, dynamic>> items = [];
        double total = 0;

        for (var doc in cartSnapshot.docs) {
          final item = doc.data();

          // Get product details
          final productId = item['productId'];
          final productSnapshot = await _firestore.collection('products').doc(productId).get();
          final productData = productSnapshot.data();

          if (productData != null) {
            // Parse the price safely
            double price = 0;
            final rawPrice = productData['price'];
            if (rawPrice is num) {
              price = rawPrice.toDouble();
            } else if (rawPrice is String) {
              // Handle string formats like "Rs 5000" or "5000"
              final cleanedPrice = rawPrice.replaceAll(RegExp(r'[^0-9.]'), '');
              price = double.tryParse(cleanedPrice) ?? 0;
            }

            final quantity = item['quantity'] ?? 1;
            final itemTotal = price * quantity;
            total += itemTotal;

            items.add({
              'id': doc.id,
              'productId': productId,
              'title': productData['title'] ?? 'Unknown Product',
              'price': price, // Store the parsed numeric price
              'image': productData['image'] ?? 'assets/solarsystem.png',
              'quantity': quantity,
              'total': itemTotal,
            });
          }
        }

        setState(() {
          _cartItems = items;
          _totalAmount = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading cart items: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateQuantity(String itemId, int newQuantity) async {
    if (newQuantity < 1) return;

    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .doc(itemId)
            .update({'quantity': newQuantity});

        await _loadCartItems();
      }
    } catch (e) {
      print('Error updating quantity: $e');
    }
  }

  Future<void> _removeItem(String itemId) async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .doc(itemId)
            .delete();

        await _loadCartItems();
      }
    } catch (e) {
      print('Error removing item: $e');
    }
  }

  void _proceedToCheckout() {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar('Your cart is empty'),
      );
      return;
    }

    // Pass the discounted total to CheckoutScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          cartItems: _cartItems,
          totalAmount: _totalAmount - _discount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A99D),
        elevation: 0,
        title: const Text(
          'Cart',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        context: context,
        onItemTapped: (index) {
          if (index != _selectedIndex) {
            if (index == 0) { // Home
              Navigator.pushReplacementNamed(context, '/home');
            } else if (index == 1) { // Booking
              Navigator.pushReplacementNamed(context, '/booking-history');
            } else if (index == 2) { // Floating button (Booking)
              Navigator.pushNamed(context, '/service');
            } else if (index == 4) { // Profile
              Navigator.pushReplacementNamed(context, '/profile');
            }
          }
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A99D)))
          : Column(
        children: [
          // Your Bag title
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            alignment: Alignment.centerLeft,
            child: const Text(
              'Your Bag',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00A99D),
              ),
            ),
          ),

          // Cart items list
          Expanded(
            child: _cartItems.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                return _buildCartItem(item);
              },
            ),
          ),

          // Payment method
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/mastercard.png',
                    width: 40,
                    height: 30,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 40,
                        height: 30,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.credit_card, size: 20),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Credit or Debit Card / COD',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Total and checkout button
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(_totalAmount - _discount).toStringAsFixed(0)} Rs',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00A99D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _proceedToCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A99D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Checkout',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    final backgroundColor = _cartItems.indexOf(item) % 2 == 0
        ? const Color(0xFFE8F5F4) // Light green for even items
        : const Color(0xFFEBF1FB); // Light blue for odd items

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Product image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              item['image'],
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),

          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(item['price'] * item['quantity']).toStringAsFixed(0)} Rs',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF00A99D),
                  ),
                ),
              ],
            ),
          ),

          // Quantity controls
          Row(
            children: [
              InkWell(
                onTap: () => _updateQuantity(item['id'], item['quantity'] + 1),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                  child: const Icon(Icons.add, size: 16),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${item['quantity']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  if (item['quantity'] > 1) {
                    _updateQuantity(item['id'], item['quantity'] - 1);
                  }
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                  child: const Icon(Icons.remove, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _removeItem(item['id']),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Icon(Icons.delete_outline, size: 16, color: Colors.red.shade300),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}