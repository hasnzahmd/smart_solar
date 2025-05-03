import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_solar/cart_service.dart';
import 'package:smart_solar/snackbar_utils.dart'; // Already imported

class ProductDetailScreen extends StatefulWidget {
  final String docId;
  final String title;
  final String price;
  final String image;

  const ProductDetailScreen({
    Key? key,
    required this.docId,
    required this.title,
    required this.price,
    required this.image,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CartService _cartService = CartService();
  bool _isLoading = true;
  Map<String, dynamic>? _productData;
  int _quantity = 1;
  bool _addingToCart = false;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final productDoc = await _firestore.collection('products').doc(widget.docId).get();
      if (productDoc.exists) {
        setState(() {
          _productData = productDoc.data();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading product details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addToCart() async {
    setState(() {
      _addingToCart = true;
    });

    try {
      await _cartService.addToCart(widget.docId, quantity: _quantity);
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar(
          '${widget.title} added to cart',
          actionLabel: 'VIEW CART',
          actionOnPressed: () {
            Navigator.pushNamed(context, '/cart');
          },
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar('Error adding to cart: $e'),
      );
    } finally {
      setState(() {
        _addingToCart = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A99D)))
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              Center(
                child: Image.asset(
                  widget.image,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),

              // Product title and price
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.price,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00A99D),
                ),
              ),
              const SizedBox(height: 16),

              // Product description
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _productData?['description'] ?? 'No description available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 24),

              // Quantity selector
              Row(
                children: [
                  const Text(
                    'Quantity:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () {
                      if (_quantity > 1) {
                        setState(() {
                          _quantity--;
                        });
                      }
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Icon(Icons.remove, size: 18),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '$_quantity',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _quantity++;
                      });
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Icon(Icons.add, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Add to cart button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _addingToCart ? null : _addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A99D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _addingToCart
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Add to Cart',
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
      ),
    );
  }
}