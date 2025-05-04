import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_solar/widgets/bottom_nav_bar.dart';

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

  Future<void> _showEditNameDialog({
    required String currentFirstName,
    required String currentLastName,
  }) async {
    final TextEditingController controller = TextEditingController(text: (currentFirstName + (currentLastName.isNotEmpty ? ' $currentLastName' : '')));
    final formKey = GlobalKey<FormState>();
    final focusNode = FocusNode();
    await showDialog(
      context: context,
      builder: (context) {
        Future.delayed(Duration(milliseconds: 100), () {
          focusNode.requestFocus();
        });
        return AlertDialog(
          title: const Text('Edit Name'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Cannot be empty' : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final String input = controller.text.trim();
                  String firstName = '';
                  String lastName = '';
                  final parts = input.split(RegExp(r'\s+'));
                  if (parts.length > 1) {
                    firstName = parts[0];
                    lastName = parts.sublist(1).join(' ');
                  } else {
                    firstName = input;
                    lastName = '';
                  }
                  try {
                    final User? user = _auth.currentUser;
                    if (user != null) {
                      await _firestore.collection('users').doc(user.uid).update({
                        'firstName': firstName,
                        'lastName': lastName,
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                      Navigator.pop(context);
                      _loadUserData();
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating name: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditDialog({
    required String field,
    required String currentValue,
    required String label,
  }) async {
    final TextEditingController controller = TextEditingController(text: currentValue);
    final formKey = GlobalKey<FormState>();
    final focusNode = FocusNode();
    await showDialog(
      context: context,
      builder: (context) {
        Future.delayed(Duration(milliseconds: 100), () {
          focusNode.requestFocus();
        });
        return AlertDialog(
          title: Text('Edit $label'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(labelText: label),
              textCapitalization: TextCapitalization.sentences,
              keyboardType: label == 'Phone' ? TextInputType.phone : TextInputType.text,
              validator: (value) => value == null || value.isEmpty ? 'Cannot be empty' : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final User? user = _auth.currentUser;
                    if (user != null) {
                      await _firestore.collection('users').doc(user.uid).update({
                        field: controller.text,
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                      Navigator.pop(context);
                      _loadUserData();
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating $label: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoading && _userData == null) {
      // Redirect to login if not loading and user data is missing
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00A99D))),
      );
    }
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
          : _buildProfileView(),
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  Widget _buildProfileView() {
    final String firstName = _userData?['firstName'] ?? 'N/A';
    final String lastName = _userData?['lastName'] ?? '';
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
                      '${firstName[0]}${lastName.isNotEmpty ? lastName[0] : ''}',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00A99D),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  Container(
                    margin: const EdgeInsets.only(left: 40),
                    child: Text(
                    lastName.isNotEmpty ? '$firstName $lastName' : firstName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20, color: Color(0xFF00A99D)),
                    tooltip: 'Edit Name',
                    onPressed: () async {
                    await _showEditNameDialog(
                      currentFirstName: firstName,
                      currentLastName: lastName,
                    );
                    },
                  ),
                  ],
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
            _buildInfoRow(Icons.badge, 'User type', userType),
            _buildInfoRow(Icons.calendar_today, 'Member since', _formatTimestamp(createdAt)),
            _buildInfoRow(Icons.update, 'Last updated', _formatTimestamp(updatedAt)),
          ]),
          const SizedBox(height: 24),
          _buildSectionTitle('Contact Information'),
          const SizedBox(height: 16),
          _buildInfoCard([
            _buildInfoRow(Icons.location_on, 'Address', address, editable: true, field: 'address'),
            _buildInfoRow(Icons.location_city, 'City', city, editable: true, field: 'city'),
            _buildInfoRow(Icons.phone, 'Phone', phone, editable: true, field: 'phone'),
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

  Widget _buildInfoRow(IconData icon, String label, String value, {bool editable = false, String? field}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(top: 8),
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
          if (editable && field != null)
          IconButton(
            icon: const Icon(Icons.edit, size: 18, color: Color(0xFF00A99D)),
            tooltip: 'Edit $label',
            onPressed: () {
              _showEditDialog(
                field: field,
                currentValue: value,
                label: label,
              );
            },
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
