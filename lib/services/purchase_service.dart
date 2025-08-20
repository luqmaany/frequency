import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'storage_service.dart';

class PurchaseService {
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Map premium category IDs to Play Console product IDs
  static const Map<String, String> skuByCategoryId = {
    'anime': 'convey_category_anime',
    'tv': 'convey_category_tv',
  };

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
    final response = await _inAppPurchase
        .queryProductDetails(skuByCategoryId.values.toSet());
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
    for (final entry in skuByCategoryId.entries) {
      if (entry.value == sku) return entry.key;
    }
    return null;
  }
}
