import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/api_service.dart';

enum SubscriptionPlan { free, weekly, monthly, yearly, lifetime }

/// Google Play Product IDs - Update these to match your Play Console products
class ProductIds {
  static const String weekly = 'ssw_pro_weekly';
  static const String monthly = 'ssw_pro_monthly';
  static const String yearly = 'ssw_pro_yearly';
  static const String lifetime = 'ssw_pro_lifetime';

  static const Set<String> allIds = {weekly, monthly, yearly, lifetime};

  static SubscriptionPlan planFromId(String productId) {
    switch (productId) {
      case weekly:
        return SubscriptionPlan.weekly;
      case monthly:
        return SubscriptionPlan.monthly;
      case yearly:
        return SubscriptionPlan.yearly;
      case lifetime:
        return SubscriptionPlan.lifetime;
      default:
        return SubscriptionPlan.free;
    }
  }

  static String idFromPlan(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.weekly:
        return weekly;
      case SubscriptionPlan.monthly:
        return monthly;
      case SubscriptionPlan.yearly:
        return yearly;
      case SubscriptionPlan.lifetime:
        return lifetime;
      case SubscriptionPlan.free:
        return '';
    }
  }
}

class SubscriptionProvider extends ChangeNotifier {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final ApiService _apiService = ApiService();

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _purchasePending = false;
  bool _loading = true;
  String? _errorMessage;

  SubscriptionPlan _currentPlan = SubscriptionPlan.free;
  bool _isSubscribed = false;
  DateTime? _expiryDate;
  late Box _box;

  // Getters
  List<ProductDetails> get products => _products;
  bool get isAvailable => _isAvailable;
  bool get purchasePending => _purchasePending;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  SubscriptionPlan get currentPlan => _currentPlan;
  bool get isSubscribed => _isSubscribed;
  bool get isPro => _isSubscribed && _currentPlan != SubscriptionPlan.free;
  DateTime? get expiryDate => _expiryDate;

  SubscriptionProvider() {
    _initBox();
  }

  Future<void> _initBox() async {
    _box = Hive.box('settings');
    _loadSubscription();
    await _initializeStore();
  }

  /// Initialize the in-app purchase store
  Future<void> _initializeStore() async {
    _loading = true;
    notifyListeners();

    // Check if store is available
    _isAvailable = await _inAppPurchase.isAvailable();

    if (!_isAvailable) {
      _loading = false;
      _errorMessage = 'Store not available';
      notifyListeners();
      return;
    }

    // Listen to purchase updates
    _subscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (error) {
        debugPrint('Purchase stream error: $error');
        _errorMessage = 'Purchase error occurred';
        notifyListeners();
      },
    );

    // Load available products
    await _loadProducts();

    _loading = false;
    notifyListeners();
  }

  /// Load products from the store
  Future<void> _loadProducts() async {
    try {
      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(ProductIds.allIds);

      if (response.error != null) {
        debugPrint('Error loading products: ${response.error}');
        _errorMessage = 'Failed to load products';
      }

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found: ${response.notFoundIDs}');
        _errorMessage =
            'Products not found in Store: ${response.notFoundIDs.join(', ')}. Check Play Console.';
      }

      _products = response.productDetails;

      // Sort products by price
      _products.sort((a, b) => a.rawPrice.compareTo(b.rawPrice));

      debugPrint('Loaded ${_products.length} products');
    } catch (e) {
      debugPrint('Error querying products: $e');
      _errorMessage = 'Failed to load products';
    }
  }

  /// Handle purchase updates from the store
  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      debugPrint(
          'Purchase update: ${purchaseDetails.status} for ${purchaseDetails.productID}');

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          _purchasePending = true;
          notifyListeners();
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _handleSuccessfulPurchase(purchaseDetails);
          break;

        case PurchaseStatus.error:
          _purchasePending = false;
          _errorMessage = purchaseDetails.error?.message ?? 'Purchase failed';
          notifyListeners();
          break;

        case PurchaseStatus.canceled:
          _purchasePending = false;
          notifyListeners();
          break;
      }

      // Complete the purchase if required
      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  /// Handle a successful purchase
  Future<void> _handleSuccessfulPurchase(
      PurchaseDetails purchaseDetails) async {
    _purchasePending = false;

    final plan = ProductIds.planFromId(purchaseDetails.productID);

    // Verify with backend
    try {
      await _apiService.verifySubscription(
        purchaseToken: purchaseDetails.verificationData.serverVerificationData,
        plan: plan.name,
        productId: purchaseDetails.productID,
      );
    } catch (e) {
      debugPrint('Backend verification failed: $e');
      // Continue anyway - local verification
    }

    // Update local state
    _currentPlan = plan;
    _isSubscribed = true;

    // Set expiry date based on plan
    switch (plan) {
      case SubscriptionPlan.weekly:
        _expiryDate = DateTime.now().add(const Duration(days: 7));
        break;
      case SubscriptionPlan.monthly:
        _expiryDate = DateTime.now().add(const Duration(days: 30));
        break;
      case SubscriptionPlan.yearly:
        _expiryDate = DateTime.now().add(const Duration(days: 365));
        break;
      case SubscriptionPlan.lifetime:
        _expiryDate = DateTime(2100, 1, 1);
        break;
      case SubscriptionPlan.free:
        break;
    }

    await _saveSubscription();
    notifyListeners();
  }

  void _loadSubscription() {
    final planIndex = _box.get('subscriptionPlan', defaultValue: 0) as int;
    _currentPlan = SubscriptionPlan.values[planIndex];
    _isSubscribed = _box.get('isSubscribed', defaultValue: false) as bool;
    final expiryString = _box.get('expiryDate') as String?;
    if (expiryString != null) {
      _expiryDate = DateTime.parse(expiryString);
      // Check if subscription has expired
      if (_expiryDate!.isBefore(DateTime.now()) &&
          _currentPlan != SubscriptionPlan.lifetime) {
        _isSubscribed = false;
        _currentPlan = SubscriptionPlan.free;
        _saveSubscription();
      }
    }
    notifyListeners();
  }

  Future<void> _saveSubscription() async {
    await _box.put('subscriptionPlan', _currentPlan.index);
    await _box.put('isSubscribed', _isSubscribed);
    if (_expiryDate != null) {
      await _box.put('expiryDate', _expiryDate!.toIso8601String());
    }
  }

  /// Purchase a subscription
  Future<bool> subscribe(SubscriptionPlan plan) async {
    if (plan == SubscriptionPlan.free) {
      await cancelSubscription();
      return true;
    }

    // Find the product
    final productId = ProductIds.idFromPlan(plan);
    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('Product not found: $productId'),
    );

    // Create purchase param
    final purchaseParam = PurchaseParam(productDetails: product);

    // Determine if subscription or non-consumable
    if (plan == SubscriptionPlan.lifetime) {
      // Lifetime is a non-consumable purchase
      return await _inAppPurchase.buyNonConsumable(
          purchaseParam: purchaseParam);
    } else {
      // Weekly, Monthly, Yearly are subscriptions
      return await _inAppPurchase.buyNonConsumable(
          purchaseParam: purchaseParam);
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    _purchasePending = true;
    notifyListeners();

    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      debugPrint('Restore purchases error: $e');
      _errorMessage = 'Failed to restore purchases';
    }

    _purchasePending = false;
    notifyListeners();
  }

  /// Cancel subscription (local only - actual cancellation is via Play Store)
  Future<void> cancelSubscription() async {
    _currentPlan = SubscriptionPlan.free;
    _isSubscribed = false;
    _expiryDate = null;
    await _saveSubscription();
    notifyListeners();
  }

  /// Get product details by plan
  ProductDetails? getProductForPlan(SubscriptionPlan plan) {
    final productId = ProductIds.idFromPlan(plan);
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// Get price string for a plan from store
  String getPriceForPlan(SubscriptionPlan plan) {
    final product = getProductForPlan(plan);
    if (product != null) {
      return product.price;
    }
    // Fallback to static prices
    return planDetails[plan]?['price'] ?? '\$0';
  }

  // Subscription plan details (fallback when store not available)
  static const Map<SubscriptionPlan, Map<String, dynamic>> planDetails = {
    SubscriptionPlan.free: {
      'name': 'Free',
      'price': '\$0',
      'period': '',
      'features': ['Limited wallpapers', 'Ads enabled', 'Basic quality'],
      'savings': '',
    },
    SubscriptionPlan.weekly: {
      'name': 'Weekly',
      'price': '\INR 5.00',
      'period': '/week',
      'features': [
        'All wallpapers',
        'No ads',
        'HD quality',
        'New content first'
      ],
      'savings': '',
    },
    SubscriptionPlan.monthly: {
      'name': 'Monthly',
      'price': '\INR 29.99',
      'period': '/month',
      'features': [
        'All wallpapers',
        'No ads',
        'HD quality',
        'New content first',
        'Priority support'
      ],
      'savings': 'Save 37%',
    },
    SubscriptionPlan.yearly: {
      'name': 'Yearly',
      'price': '\INR 59.89',
      'period': '/year',
      'features': [
        'All wallpapers',
        'No ads',
        '4K quality',
        'New content first',
        'Priority support',
        'Exclusive packs'
      ],
      'savings': 'Save 50%',
      'popular': true,
    },
    SubscriptionPlan.lifetime: {
      'name': 'Lifetime',
      'price': '\INR 299.99',
      'period': 'one-time',
      'features': [
        'All wallpapers forever',
        'No ads ever',
        '4K quality',
        'All future updates',
        'Priority support',
        'All exclusive packs'
      ],
      'savings': 'Best Value',
    },
  };

  String getPlanName(SubscriptionPlan plan) {
    return planDetails[plan]!['name'] as String;
  }

  String getPlanPrice(SubscriptionPlan plan) {
    return planDetails[plan]!['price'] as String;
  }

  List<String> getPlanFeatures(SubscriptionPlan plan) {
    return planDetails[plan]!['features'] as List<String>;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
