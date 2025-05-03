import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:smart_solar/bottom_nav_bar.dart';
import 'package:smart_solar/booking_screen.dart';
import 'package:smart_solar/snackbar_utils.dart';
 // Import the utils

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({Key? key}) : super(key: key);

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  int _selectedIndex = 1; // Set to 1 for Booking tab

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Bookings & Orders',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00A99D),
          indicatorWeight: 3,
          labelColor: const Color(0xFF00A99D),
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: 'Bookings'),
            Tab(text: 'Orders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingsList('pending'),
          _buildOrdersList(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  Widget _buildBookingsList(String status) {
    final User? user = _auth.currentUser;

    if (user == null) {
      return const Center(
        child: Text('You must be logged in to view bookings'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: status)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00A99D)));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No bookings',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        final bookings = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index].data() as Map<String, dynamic>;
            final bookingId = bookings[index].id;

            return _buildBookingCard(booking, bookingId, 'booking');
          },
        );
      },
    );
  }

  Widget _buildOrdersList() {
    final User? user = _auth.currentUser;

    if (user == null) {
      return const Center(
        child: Text('You must be logged in to view orders'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .where('status', isNotEqualTo: 'cancelled')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00A99D)));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No orders',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        final orders = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index].data() as Map<String, dynamic>;
            final orderId = orders[index].id;

            return _buildBookingCard(order, orderId, 'order');
          },
        );
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> data, String id, String type) {
    final String title = type == 'booking'
        ? (data['serviceType'] ?? 'Unknown Service')
        : 'Order #${id.substring(0, 8)}';

    final String date = type == 'booking'
        ? (data['date'] ?? 'N/A')
        : data['createdAt'] != null
        ? _formatTimestamp(data['createdAt'])
        : 'N/A';

    final String time = type == 'booking' ? (data['time'] ?? 'N/A') : 'N/A';

    final List<dynamic> items = type == 'booking'
        ? (data['packageNames'] ?? [])
        : (data['items'] ?? []);
    final String mainItem = type == 'booking'
        ? (items.isNotEmpty ? items[0].toString() : 'Item')
        : (items.isNotEmpty ? items[0]['title']?.toString() ?? 'Item' : 'Item');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    type == 'booking' ? 'Complete on ${_formatDate(date)}' : 'Ordered on $date',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (type == 'booking') ...[
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      time,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.cleaning_services_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  type == 'booking' ? 'One-Time Cleaning Service' : 'Product Purchase',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.handyman_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    Text(
                      mainItem,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00A99D),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildActionButton(
                  'View Details',
                  const Color(0xFF00A99D),
                      () => _showOrderStatusModal(context, data, id, type),
                ),
                if (type == 'booking') ...[
                  const SizedBox(width: 8),
                  _buildActionButton(
                    'Cancel',
                    Colors.red.shade50,
                        () => _showCancelConfirmation(context, id, 'booking'),
                    textColor: Colors.red,
                  ),
                ] else ...[
                  const SizedBox(width: 8),
                  _buildActionButton(
                    'Cancel Order',
                    Colors.red.shade50,
                        () => _showCancelConfirmation(context, id, 'order'),
                    textColor: Colors.red,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onPressed, {Color textColor = Colors.white}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: textColor,
        ),
      ),
    );
  }

  void _showOrderStatusModal(BuildContext context, Map<String, dynamic> data, String id, String type) {
    print('Booking/Order Data: $data'); // Debug print to inspect the data

    final String title = type == 'booking'
        ? (data['serviceType'] ?? 'Unknown Service')
        : 'Order #${id.substring(0, 8)}';

    final List<dynamic> items = type == 'booking'
        ? (data['packageNames'] ?? [])
        : (data['items'] ?? []);
    final String mainItem = type == 'booking'
        ? (items.isNotEmpty ? items[0].toString() : 'Item')
        : (items.isNotEmpty ? items[0]['title']?.toString() ?? 'Item' : 'Item');

    final double totalPrice = type == 'booking'
        ? (data['totalPrice'] is num ? (data['totalPrice'] as num).toDouble() : 0.0)
        : (data['totalAmount'] is num ? (data['totalAmount'] as num).toDouble() : 0.0);

    final String date = type == 'booking'
        ? (data['date'] ?? 'N/A')
        : data['createdAt'] != null
        ? _formatTimestamp(data['createdAt'])
        : 'N/A';

    final String time = type == 'booking' ? (data['time'] ?? 'N/A') : 'N/A';

    String locationName = 'N/A';
    String locationAddress = '';

    if (type == 'booking') {
      if (data['location'] != null) {
        locationName = 'Location';
        locationAddress = data['location'].toString(); // Treat location as a string
      } else if (data['locationName'] != null) {
        locationName = data['locationName'].toString();
        locationAddress = data['locationAddress']?.toString() ?? 'N/A';
      } else if (data['address'] != null) {
        locationName = 'Location';
        locationAddress = data['address'].toString();
      } else if (data['userAddress'] != null) {
        locationName = 'Location';
        locationAddress = data['userAddress'].toString();
      } else if (data['bookingLocation'] != null) {
        locationName = 'Location';
        locationAddress = data['bookingLocation'].toString();
      }
    } else {
      locationName = 'Delivery Address';
      locationAddress = '${data['address'] ?? ''}, ${data['city'] ?? ''}';
    }

    _firestore.collection('users').doc(data['userId']).get().then((userData) {
      if (!userData.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          buildCustomSnackBar('User data not found'),
        );
        return;
      }

      final Map<String, dynamic> user = userData.data() as Map<String, dynamic>? ?? {};
      final String firstName = user['firstName']?.toString() ?? '';
      final String lastName = user['lastName']?.toString() ?? '';
      final String userName = '$firstName $lastName'.trim();

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        type == 'booking' ? 'Booking Details' : 'Order Details',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    type == 'booking' ? '$mainItem Installation' : mainItem,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        userName.isEmpty ? 'User' : userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (type == 'booking')
                        Expanded(
                          child: _buildDetailCard(
                            Icons.access_time,
                            'Time',
                            _formatDuration(time),
                          ),
                        ),
                      if (type == 'booking') const SizedBox(width: 16),
                      Expanded(
                        child: _buildDetailCard(
                          Icons.location_on,
                          type == 'booking' ? 'Location' : 'Address',
                          locationName,
                          subtitle: locationAddress,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailCard(
                          Icons.calendar_today,
                          type == 'booking' ? 'Date' : 'Order Date',
                          date,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDetailCard(
                          Icons.attach_money,
                          'Price',
                          '${NumberFormat('#,###').format(totalPrice)} RS Total',
                        ),
                      ),
                    ],
                  ),
                  if (type == 'order' && items.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] ?? 'Item',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
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
                            '${(item['price'] * item['quantity']).toStringAsFixed(0)} RS',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00A99D),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        buildCustomSnackBar('Error loading user data: $error'),
      );
    });
  }

  Widget _buildDetailCard(IconData icon, String title, String value, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00A99D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context, String id, String type) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cancel ${type == 'booking' ? 'Booking' : 'Order'}'),
          content: Text('Are you sure you want to cancel this ${type == 'booking' ? 'booking' : 'order'}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'No',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                final collection = type == 'booking' ? 'bookings' : 'orders';
                _firestore.collection(collection).doc(id).update({
                  'status': 'cancelled',
                  'cancelledAt': FieldValue.serverTimestamp(),
                }).then((_) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    buildCustomSnackBar('${type == 'booking' ? 'Booking' : 'Order'} cancelled successfully'),
                  );
                }).catchError((error) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    buildCustomSnackBar('Error cancelling ${type}: $error'),
                  );
                });
              },
              child: const Text(
                'Yes',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return CustomBottomNavigationBar(
      selectedIndex: _selectedIndex,
      context: context,
      onItemTapped: (index) {
        setState(() {
          _selectedIndex = index;
        });

        if (index == 0) {
          Navigator.pushReplacementNamed(context, '/home');
        } else if (index == 1) {
          Navigator.pushReplacementNamed(context, '/booking-history');
        } else if (index == 3) {
          Navigator.pushReplacementNamed(context, '/cart');
        } else if (index == 4) {
          if (ModalRoute.of(context)?.settings.name != '/profile') {
            Navigator.pushReplacementNamed(context, '/profile');
          }
        }
      },
    );
  }

  String _formatDate(String dateStr) {
    try {
      final DateTime date = DateFormat('yyyy-MM-dd').parse(dateStr);
      return DateFormat('d MMM').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    try {
      final DateTime date = timestamp.toDate();
      return DateFormat('d MMM yyyy').format(date);
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatDuration(String timeStr) {
    if (timeStr.contains('-')) {
      try {
        final parts = timeStr.split('-');
        final startTime = parts[0].trim();
        final endTime = parts[1].trim();
        return '2 hr 30 min';
      } catch (e) {
        return timeStr;
      }
    }
    return timeStr;
  }
}