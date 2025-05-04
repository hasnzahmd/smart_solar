import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add product to cart
  Future<void> addToCart(String productId, {int quantity = 1}) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Check if product already exists in cart
      final cartQuery = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .where('productId', isEqualTo: productId)
          .get();

      if (cartQuery.docs.isNotEmpty) {
        // Update quantity if product already in cart
        final existingItem = cartQuery.docs.first;
        final currentQuantity = existingItem.data()['quantity'] ?? 0;
        await existingItem.reference.update({
          'quantity': currentQuantity + quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Add new product to cart
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .add({
          'productId': productId,
          'quantity': quantity,
          'addedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error adding to cart: $e');
      rethrow;
    }
  }

  // Get cart count
  Stream<int> getCartCount() {
    final User? user = _auth.currentUser;
    if (user == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Clear cart
  Future<void> clearCart() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final cartItems = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .get();

      final batch = _firestore.batch();
      for (var doc in cartItems.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error clearing cart: $e');
      rethrow;
    }
  }
}