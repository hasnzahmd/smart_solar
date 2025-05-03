import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_solar/bottom_nav_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  int _selectedIndex = 4; // Set to 4 for Profile tab

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          setState(() {
            _userData = userDoc.data() as Map<String, dynamic>;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: $e')),
      );
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('MMM d, yyyy').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A99D)))
          : _userData == null
          ? _buildNotLoggedInView()
          : _buildProfileView(),
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  Widget _buildNotLoggedInView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle_outlined,
            size: 100,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'Please log in to view your profile',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              // Navigate to login screen when implemented
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A99D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Login',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    final String firstName = _userData?['firstName'] ?? 'N/A';
    final String lastName = _userData?['lastName'] ?? 'N/A';
    final String email = _userData?['email'] ?? 'N/A';
    final String address = _userData?['address'] ?? 'N/A';
    final String city = _userData?['city'] ?? 'N/A';
    final String userType = _userData?['userType'] ?? 'User';
    final String phone = _userData?['phone'] ?? 'N/A';
    final Timestamp? createdAt = _userData?['createdAt'] as Timestamp?;
    final Timestamp? updatedAt = _userData?['updatedAt'] as Timestamp?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                    border: Border.all(
                      color: const Color(0xFF00A99D),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${firstName[0]}${lastName[0]}',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00A99D),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$firstName $lastName',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userType,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Account Information'),
          const SizedBox(height: 16),
          _buildInfoCard([
            _buildInfoRow(Icons.email, 'Email', email),
            _buildInfoRow(Icons.badge, 'User Type', userType),
            _buildInfoRow(Icons.calendar_today, 'Member Since', _formatTimestamp(createdAt)),
            _buildInfoRow(Icons.update, 'Last Updated', _formatTimestamp(updatedAt)),
          ]),
          const SizedBox(height: 24),
          _buildSectionTitle('Contact Information'),
          const SizedBox(height: 16),
          _buildInfoCard([
            _buildInfoRow(Icons.location_on, 'Address', address),
            _buildInfoRow(Icons.location_city, 'City', city),
            _buildInfoRow(Icons.phone, 'Phone', phone),
          ]),
          const SizedBox(height: 32),
          _buildActionButtons(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF00A99D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF00A99D),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [

        OutlinedButton(
          onPressed: () async {
            try {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false); // Clear login flag
              await _auth.signOut(); // Firebase sign out
              Navigator.pushReplacementNamed(context, '/login'); // Go to login screen
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error signing out: $e')),
              );
            }
          },

          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            minimumSize: const Size(double.infinity, 50),
            side: const BorderSide(color: Colors.red),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Logout',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
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

        // Handle navigation based on index
        if (index == 0) { // Home
          Navigator.pushReplacementNamed(context, '/home');
        } else if (index == 1) { // Booking
          Navigator.pushReplacementNamed(context, '/booking-history');
        } else if (index == 3) { // Cart
          Navigator.pushReplacementNamed(context, '/cart');
        } else if (index == 4) { // Profile - already on this screen
          if (ModalRoute.of(context)?.settings.name != '/profile') {
            Navigator.pushReplacementNamed(context, '/profile');
          }
        }
      },
    );
  }
}
