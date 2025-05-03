import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_solar/snackbar_utils.dart';
 // Import the utils

class BookingScreen extends StatefulWidget {
  final String serviceType;

  const BookingScreen({
    Key? key,
    required this.serviceType,
  }) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String _selectedCategory = 'Small Residential';
  List<Map<String, dynamic>> _selectedPackages = [];
  bool _includeFurniture = false;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 0);
  double _calculatedFee = 0.0;
  String _selectedWatt = '';
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  final User? _currentUser = FirebaseAuth.instance.currentUser;

  final List<String> _wattOptions = [
    '3 KW',
    '4 KW',
    '5 KW',
    '6 KW',
    '7 KW',
    '8 KW',
    '9 KW',
    '10 KW',
    '10 KW+'
  ];

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Small Residential',
      'image': 'assets/home.png',
    },
    {
      'name': 'Commercial',
      'image': 'assets/commercial.png',
    },
    {
      'name': 'Industrial',
      'image': 'assets/industrial.png',
    },
  ];

  final List<Map<String, dynamic>> _packages = [
    {
      'name': 'Maintenance Package',
      'description': 'Regular upkeep for optimal performance',
      'price': 5000.0,
      'services': [
        'System health check every 6 months',
        'Panel cleaning twice a year',
        'Battery performance assessment',
        'Minor repairs and adjustments'
      ],
      'color': const Color(0xFF00A99D),
    },
    {
      'name': 'Cleaning Package',
      'description': 'Keep your system clean and spotless',
      'price': 3000.0,
      'services': [
        'Deep cleaning of solar panels',
        'Removal of dust, dirt, and debris',
        'Inspection for physical damage',
        'Cleaning report with recommendations'
      ],
      'color': const Color(0xFF4CAF50),
    },
    {
      'name': 'Error Solution Package',
      'description': 'Fix issues quickly and efficiently',
      'price': 7000.0,
      'services': [
        'Troubleshooting system errors',
        'Inverter and battery diagnostics',
        'Wiring and connection checks',
        'On-site repair service'
      ],
      'color': const Color(0xFFFF9800),
    },
    {
      'name': 'Installation Package',
      'description': 'Professional setup for your system',
      'price': 15000.0,
      'services': [
        'Complete system installation',
        'Panel mounting and wiring',
        'Inverter and battery setup',
        'Initial system testing and calibration'
      ],
      'color': const Color(0xFF3F51B5),
    },
  ];

  @override
  void dispose() {
    _companyController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _showPackageDetails(BuildContext context, Map<String, dynamic> package) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            package['name'],
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Price: Rs. ${NumberFormat('#,###').format(package['price'])}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF00A99D),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Services Included:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...package['services'].map<Widget>((service) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(fontSize: 16),
                      ),
                      Expanded(
                        child: Text(
                          service,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Close',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF00A99D),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Booking Successful!",
            style: TextStyle(
              color: Color(0xFF00A99D),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            "Your booking has been submitted successfully. You will receive a confirmation soon.",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text(
                "OK",
                style: TextStyle(
                  color: Color(0xFF00A99D),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
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
        title: Text(
          widget.serviceType,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _categories.map((category) {
                  final bool isSelected = _selectedCategory == category['name'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category['name'];
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFE0F7F3)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(color: const Color(0xFF00A99D), width: 2)
                                : null,
                          ),
                          child: Center(
                            child: Image.asset(
                              category['image'],
                              width: 40,
                              height: 40,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category['name'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              const Text(
                'Packages',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _packages.length,
                  itemBuilder: (context, index) {
                    final package = _packages[index];
                    final bool isSelected = _selectedPackages.contains(package);

                    LinearGradient getGradientForPackage() {
                      switch(package['name']) {
                        case 'Maintenance Package':
                          return const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF76D0C6),
                              Color(0xFF03A290),
                            ],
                            stops: [0.0561, 0.7327],
                            transform: GradientRotation(100.7 * 3.14159 / 180),
                          );
                        case 'Cleaning Package':
                          return const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF7CC47F),
                              Color(0xFF2E9735),
                            ],
                            stops: [0.0561, 0.7327],
                            transform: GradientRotation(100.7 * 3.14159 / 180),
                          );
                        case 'Error Solution Package':
                          return const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFFBB6D),
                              Color(0xFFE67E00),
                            ],
                            stops: [0.0561, 0.7327],
                            transform: GradientRotation(100.7 * 3.14159 / 180),
                          );
                        case 'Installation Package':
                          return const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF8F96E8),
                              Color(0xFF303F9F),
                            ],
                            stops: [0.0561, 0.7327],
                            transform: GradientRotation(100.7 * 3.14159 / 180),
                          );
                        default:
                          return const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF76D0C6),
                              Color(0xFF03A290),
                            ],
                            stops: [0.0561, 0.7327],
                            transform: GradientRotation(100.7 * 3.14159 / 180),
                          );
                      }
                    }

                    Color getButtonColor() {
                      switch(package['name']) {
                        case 'Maintenance Package':
                          return const Color(0xFFE0F7F5);
                        case 'Cleaning Package':
                          return const Color(0xFFE0F7E0);
                        case 'Error Solution Package':
                          return const Color(0xFFFFF3E0);
                        case 'Installation Package':
                          return const Color(0xFFE8EAF6);
                        default:
                          return const Color(0xFFE0F7F5);
                      }
                    }
                    
                    Color getTextColor() {
                      switch(package['name']) {
                        case 'Maintenance Package':
                          return const Color(0xFF00A99D);
                        case 'Cleaning Package':
                          return const Color(0xFF2E9735);
                        case 'Error Solution Package':
                          return const Color(0xFFE67E00);
                        case 'Installation Package':
                          return const Color(0xFF303F9F);
                        default:
                          return const Color(0xFF00A99D);
                      }
                    }

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedPackages.remove(package);
                          } else {
                            _selectedPackages.add(package);
                          }
                          _calculatedFee = _selectedPackages.fold(
                            0.0,
                                (sum, pkg) => sum + pkg['price'],
                          );
                        });
                      },
                      child: Container(
                        width: 240,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          gradient: getGradientForPackage(),
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: package['color'], width: 2)
                              : Border.all(color: Colors.grey.shade200),
                        ),
                        child: Stack(
                          children: [
                            if (isSelected)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    color: package['color'],
                                    size: 16,
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: package['color'].withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      package['name'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    package['description'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        'Rs. ${NumberFormat('#,###').format(package['price'])}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        '/package',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: ElevatedButton(
                                onPressed: () {
                                  _showPackageDetails(context, package);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: getButtonColor(),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                ),
                                child: Text(
                                  'View Details',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: getTextColor(),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How Many Watt?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text(
                          'Select number of KW',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        value: _selectedWatt.isNotEmpty ? _selectedWatt : null,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        iconSize: 24,
                        elevation: 16,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedWatt = newValue!;
                          });
                        },
                        items: _wattOptions
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter Company and Model',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _companyController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Enter Company and Model',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter Service Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _locationController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Enter your complete address',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Radio(
                    value: true,
                    groupValue: _includeFurniture,
                    onChanged: (value) {
                      setState(() {
                        _includeFurniture = value as bool;
                      });
                    },
                    activeColor: const Color(0xFF00A99D),
                  ),
                  const Text(
                    'Include Furniture',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              GestureDetector(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.grey,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('MMMM dd, yyyy').format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              GestureDetector(
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (picked != null && picked != _selectedTime) {
                    setState(() {
                      _selectedTime = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Colors.grey,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedTime.format(context),
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Calculated Fee',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'PKR',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          NumberFormat('#,###').format(_calculatedFee),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00A99D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_selectedPackages.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        buildCustomSnackBar('Please select at least one package'),
                      );
                      return;
                    }

                    if (_selectedWatt.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        buildCustomSnackBar('Please select the watt value'),
                      );
                      return;
                    }

                    if (_companyController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        buildCustomSnackBar('Please enter the company and model'),
                      );
                      return;
                    }

                    if (_locationController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        buildCustomSnackBar('Please enter your service location'),
                      );
                      return;
                    }

                    try {
                      if (_currentUser == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          buildCustomSnackBar('You must be logged in to make a booking'),
                        );
                        return;
                      }

                      await FirebaseFirestore.instance.collection('bookings').add({
                        'userId': _currentUser.uid,
                        'userEmail': _currentUser.email,
                        'packageNames': _selectedPackages.map((pkg) => pkg['name']).toList(),
                        'packagePrices': _selectedPackages.map((pkg) => pkg['price']).toList(),
                        'totalPrice': _calculatedFee,
                        'watt': _selectedWatt,
                        'companyAndModel': _companyController.text,
                        'location': _locationController.text,
                        'includeFurniture': _includeFurniture,
                        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
                        'time': _selectedTime.format(context),
                        'calculatedFee': _calculatedFee,
                        'category': _selectedCategory,
                        'status': 'pending',
                        'serviceType': widget.serviceType,
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                      _showSuccessDialog();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        buildCustomSnackBar('Error submitting booking: $e'),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A99D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Proceed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}