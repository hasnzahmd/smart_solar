import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final BuildContext context;

  const CustomBottomNavigationBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.context,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Get screen dimensions
        final double screenWidth = MediaQuery.of(context).size.width;
        final double screenHeight = MediaQuery.of(context).size.height;
        final double maxWidth = constraints.maxWidth;

        // Calculate responsive dimensions
        final double iconSize = (maxWidth * 0.06).clamp(20.0, 32.0); // 6% of screen width, clamped
        final double fontSize = (maxWidth * 0.03).clamp(10.0, 14.0); // 3% of screen width, clamped
        final double floatingNavSize = (maxWidth * 0.15).clamp(50.0, 80.0); // 15% of screen width, clamped
        final double horizontalSpacing = (maxWidth * 0.02).clamp(4.0, 16.0); // 2% of screen width, clamped
        final double navHeight = (screenHeight * 0.1).clamp(60.0, 80.0); // 10% of screen height, clamped

        return Container(
          height: navHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildNavItem(Icons.home_outlined, 'Home', 0, iconSize, fontSize),
              _buildNavItem(Icons.calendar_today_outlined, 'Booking', 1, iconSize, fontSize),
              _buildFloatingNavItem(floatingNavSize),
              _buildNavItem(Icons.shopping_cart_outlined, 'Cart', 3, iconSize, fontSize),
              _buildNavItem(Icons.person_outline, 'Profile', 4, iconSize, fontSize),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, double iconSize, double fontSize) {
    final isSelected = selectedIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => onItemTapped(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF00A99D) : Colors.grey,
              size: iconSize,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                color: isSelected ? const Color(0xFF00A99D) : Colors.grey,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingNavItem(double size) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/service');
        },
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          child: Image.asset(
            'assets/floatingnavitem.png',
            width: size * 1.6,
            height: size * 1.6,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}