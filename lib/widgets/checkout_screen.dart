import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_solar/widgets/snackbar_utils.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalAmount;

  const CheckoutScreen({
    Key? key,
    required this.cartItems,
    required this.totalAmount,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String _address = '';
  String _city = '';
  String _paymentMethod = 'Credit Card';
  String _cardNumber = '****2398';

  @override
  void initState() {
    super.initState();
    _loadUserAddress();
  }

  Future<void> _loadUserAddress() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final userData = await _firestore.collection('users').doc(user.uid).get();
        if (userData.exists) {
          setState(() {
            _address = userData['address'] ?? '';
            _city = userData['city'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Error loading user address: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _placeOrder() async {
    if (_address.isEmpty || _city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar('Please add a delivery address'),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        // Create order in Firestore
        final orderRef = await _firestore.collection('orders').add({
          'userId': user.uid,
          'items': widget.cartItems.map((item) => {
            'productId': item['productId'],
            'title': item['title'],
            'price': item['price'],
            'quantity': item['quantity'],
            'total': item['total'],
          }).toList(),
          'totalAmount': widget.totalAmount,
          'address': _address,
          'city': _city,
          'paymentMethod': _paymentMethod,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Clear user's cart
        final batch = _firestore.batch();
        for (var item in widget.cartItems) {
          final cartItemRef = _firestore
              .collection('users')
              .doc(user.uid)
              .collection('cart')
              .doc(item['id']);
          batch.delete(cartItemRef);
        }
        await batch.commit();

        // Show success dialog with OK button
        await showDialog(
          context: context,
          barrierDismissible: false, // Prevents dismissing by tapping outside
          builder: (context) => AlertDialog(
            title: const Text(
              'Success',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00A99D),
              ),
            ),
            content: const Text(
              'Order placed successfully!',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                  // Navigate to home and clear back stack
                  Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                },
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF00A99D),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error placing order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar('Error placing order: $e'),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddressModal() {
    final TextEditingController addressController = TextEditingController(text: _address);
    final TextEditingController cityController = TextEditingController(text: _city);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Delivery Address',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _address = addressController.text;
                      _city = cityController.text;
                    });

                    // Save address to user profile
                    final User? user = _auth.currentUser;
                    if (user != null) {
                      _firestore.collection('users').doc(user.uid).update({
                        'address': _address,
                        'city': _city,
                      });
                    }

                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A99D),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Save Address'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showPaymentMethodModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Image.asset(
                  'assets/visa.png',
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
                title: const Text('Visa Card'),
                subtitle: const Text('****2398'),
                trailing: Radio<String>(
                  value: 'Visa Card',
                  groupValue: _paymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _paymentMethod = value!;
                      _cardNumber = '****2398';
                    });
                    Navigator.pop(context);
                  },
                  activeColor: const Color(0xFF00A99D),
                ),
              ),
              ListTile(
                leading: Image.asset(
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
                title: const Text('MasterCard'),
                subtitle: const Text('****4567'),
                trailing: Radio<String>(
                  value: 'MasterCard',
                  groupValue: _paymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _paymentMethod = value!;
                      _cardNumber = '****4567';
                    });
                    Navigator.pop(context);
                  },
                  activeColor: const Color(0xFF00A99D),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.money, size: 40, color: Colors.green),
                title: const Text('Cash on Delivery'),
                trailing: Radio<String>(
                  value: 'Cash on Delivery',
                  groupValue: _paymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _paymentMethod = value!;
                      _cardNumber = '';
                    });
                    Navigator.pop(context);
                  },
                  activeColor: const Color(0xFF00A99D),
                ),
              ),
            ],
          ),
        );
      },
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
          'Checkout',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A99D)))
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Delivery Address Section
              const Text(
                'Delivery Address',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _showAddressModal,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFF00A99D),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _address.isEmpty
                            ? const Text(
                          'Add delivery address',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        )
                            : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _address,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _city,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Payment Method Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: _showPaymentMethodModal,
                    child: const Text(
                      'Change',
                      style: TextStyle(
                        color: Color(0xFF00A99D),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      _paymentMethod == 'Visa Card'
                          ? 'assets/visa.png'
                          : _paymentMethod == 'MasterCard'
                          ? 'assets/mastercard.png'
                          : 'assets/cod.png',
                      width: 40,
                      height: 30,
                      errorBuilder: (context, error, stackTrace) {
                        return _paymentMethod == 'Cash on Delivery'
                            ? const Icon(Icons.money, size: 30, color: Colors.green)
                            : Container(
                          width: 40,
                          height: 30,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.credit_card, size: 20),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _paymentMethod,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_cardNumber.isNotEmpty)
                            Text(
                              _cardNumber,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${widget.totalAmount.toStringAsFixed(0)} RS',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Order Summary Section (List of items)
              const Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: widget.cartItems.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Quantity: ${item['quantity']}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${(item['price'] * item['quantity']).toStringAsFixed(0)} Rs',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00A99D),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Total Service Fee
              const Text(
                'Total Service Fee',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '${widget.totalAmount.toStringAsFixed(0)} RS',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00A99D),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Confirm & Proceed Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A99D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Confirm & Proceed',
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