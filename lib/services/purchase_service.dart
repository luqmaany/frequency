import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'storage_service.dart';
import '../data/category_registry.dart';

class PurchaseService {
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Deprecated: hardcoded map. Prefer reading SKU from Category.sku.
  static const Map<String, String> skuByCategoryId = {};

  static Future<void> init() async {
    final available = await _inAppPurchase.isAvailable();
    if (!available) return;
    _subscription ??=
        _inAppPurchase.purchaseStream.listen(_onPurchaseUpdates, onDone: () {
      _subscription?.cancel();
      _subscription = null;
    });
  }

  static Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  static Future<List<ProductDetails>> loadProducts() async {
    // Collect SKUs from dynamic categories
    final List<String> skus = CategoryRegistry.getAllCategories()
        .where((c) => c.sku != null && c.sku!.isNotEmpty)
        .map((c) => c.sku!)
        .toSet()
        .toList();
    if (skus.isEmpty) return const <ProductDetails>[];
    final response = await _inAppPurchase.queryProductDetails(skus.toSet());
    return response.productDetails;
  }

  static Future<void> buyCategory(
      {required String categoryId, required ProductDetails product}) async {
    final param = PurchaseParam(productDetails: product);
    await _inAppPurchase.buyNonConsumable(purchaseParam: param);
  }

  static Future<void> restorePurchases() async {
    await _inAppPurchase.restorePurchases();
  }

  static Future<void> _onPurchaseUpdates(
      List<PurchaseDetails> purchases) async {
    final unlocked = await StorageService.getUnlockedCategoryIds();
    for (final p in purchases) {
      final categoryId = _categoryIdForSku(p.productID);
      if (categoryId == null) {
        if (p.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(p);
        }
        continue;
      }

      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (!unlocked.contains(categoryId)) {
            unlocked.add(categoryId);
            await StorageService.saveUnlockedCategoryIds(unlocked);
          }
          if (p.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(p);
          }
          break;
        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
          if (p.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(p);
          }
          break;
        case PurchaseStatus.pending:
          break;
      }
    }
  }

  static String? _categoryIdForSku(String sku) {
    // Map back from SKU to category by checking Category.sku
    for (final c in CategoryRegistry.getAllCategories()) {
      if (c.sku != null && c.sku == sku) return c.id;
    }
    return null;
  }
}
