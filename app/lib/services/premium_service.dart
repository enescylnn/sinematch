import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../config/app_config.dart';
import '../core/network/api_client.dart';

class PremiumService {
  PremiumService(this._api);
  final ApiClient _api;
  final InAppPurchase _iap = InAppPurchase.instance;

  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  Future<List<ProductDetails>> loadProducts() async {
    if (AppConfig.demoMode) return const [];
    final available = await _iap.isAvailable();
    if (!available) return const [];
    final response = await _iap.queryProductDetails(AppConfig.premiumProductIds);
    return response.productDetails;
  }

  Future<bool> buy(ProductDetails product) {
    final purchaseParam = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> syncPurchase(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
    if (AppConfig.demoMode) return;
    await _api.post('/premium/receipt', body: {
      'product_id': purchase.productID,
      'purchase_id': purchase.purchaseID,
      'status': purchase.status.name,
      'verification_data': purchase.verificationData.serverVerificationData,
      'source': purchase.verificationData.source,
    });
  }

  Future<Map<String, dynamic>> status() async {
    if (AppConfig.demoMode) return {'is_premium': false};
    return await _api.get('/premium/status') as Map<String, dynamic>;
  }
}
