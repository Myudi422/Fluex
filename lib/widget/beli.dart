import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shimmer/shimmer.dart';
import 'package:flue/color.dart';

class SubscriptionPage extends StatefulWidget {
  final String telegramId;

  SubscriptionPage({required this.telegramId});

  @override
  _SubscriptionPageState createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  bool _isPremium = false;
  bool _isLoading = true;
  String _expiredDate = '';
  String _log = '';
  final InAppPurchase _iap = InAppPurchase.instance;
  List<ProductDetails> _products = [];
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      // handle error here.
    });
  }

  Future<void> initPlatformState() async {
    final bool available = await _iap.isAvailable();
    if (available) {
      final ProductDetailsResponse response = await _iap.queryProductDetails(
        {
          'flue_10k_premium',
          'flue_30k_premium',
          'flue_50k_premium',
          'flue_100k_premium'
        }.toSet(),
      );
      if (response.notFoundIDs.isNotEmpty) {
        // Handle the error.
      }
      setState(() {
        _products = response.productDetails;
      });
    }
    checkPremiumStatus();
  }

  void checkPremiumStatus() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://ccgnimex.my.id/v2/android/cek_beli.php?telegram_id=${widget.telegramId}'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _isPremium = data['premium'] ?? false;
          _expiredDate = data['expired'] ?? '';
          _isLoading = false;
        });
      } else {
        print('Error: ${response.reasonPhrase}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Exception: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _subscribe(String productId, int duration) async {
    if (_isProcessing) return;
    _isProcessing = true;

    _log += '\nTombol langganan diklik';

    try {
      final ProductDetails product =
          _products.firstWhere((product) => product.id == productId);
      final PurchaseParam purchaseParam =
          PurchaseParam(productDetails: product);

      _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      _log += '\nError: $e';
      _isProcessing = false;
    }
  }

  Future<void> _handleSubscriptionButton(String productId, int duration) async {
    _subscribe(productId, duration);
  }

  Future<bool> updateUserSubscription(String telegramId, int duration) async {
    try {
      final url =
          'https://ccgnimex.my.id/v2/android/beli.php?telegram_id=$telegramId&duration=$duration';
      final response = await http.get(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        if (purchaseDetails.productID.startsWith('flue_')) {
          bool updateSuccess = await updateUserSubscription(widget.telegramId,
              _getDurationFromProductId(purchaseDetails.productID));
          if (updateSuccess) {
            _log += '\nStatus langganan pengguna berhasil diperbarui';
            checkPremiumStatus();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Langganan Berhasil, Silahkan refresh/restart aplikasi - Flue'),
                duration: Duration(seconds: 5),
              ),
            );
            if (purchaseDetails.pendingCompletePurchase) {
              await InAppPurchase.instance.completePurchase(purchaseDetails);
            }
          } else {
            _log += '\nGagal memperbarui status langganan pengguna';
          }
        }
        _isProcessing = false;
      } else if (purchaseDetails.status == PurchaseStatus.error ||
          purchaseDetails.status == PurchaseStatus.canceled) {
        _isProcessing = false;
      }
    });
  }

  int _getDurationFromProductId(String productId) {
    switch (productId) {
      case 'flue_10k_premium':
        return 30;
      case 'flue_30k_premium':
        return 90;
      case 'flue_50k_premium':
        return 180;
      case 'flue_100k_premium':
        return 365;
      default:
        return 30;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final paddingBottom = mediaQuery.padding.bottom;

    return Scaffold(
      backgroundColor: ColorManager.currentBackgroundColor,
      appBar: AppBar(
        title: Text('Langganan Saya',
            style: TextStyle(color: ColorManager.currentHomeColor)),
        backgroundColor: ColorManager.currentBackgroundColor,
        iconTheme: IconThemeData(color: ColorManager.currentHomeColor),
      ),
      body: _isLoading
          ? _buildLoadingWidget()
          : SingleChildScrollView(
              padding:
                  EdgeInsets.fromLTRB(20.0, 20.0, 20.0, paddingBottom + 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _isPremium
                        ? 'Anda sudah premium'
                        : 'Jadilah Anggota Premium',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ColorManager.currentHomeColor,
                    ),
                  ),
                  SizedBox(height: 20),
                  if (_isPremium)
                    Text(
                      'Tanggal Expired: $_expiredDate',
                      style: TextStyle(
                          fontSize: 18, color: ColorManager.currentHomeColor),
                    ),
                  SizedBox(height: 20),
                  if (!_isPremium)
                    Column(
                      children: [
                        Text(
                          'Langganan sekarang untuk menikmati berbagai fitur premium! Hanya Mulai Dari Rp 10.000/bulan, Cukup 1 kali pembelian, jika sudah expired, akan dikembalikan ke status free',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16,
                              color: ColorManager.currentHomeColor),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keuntungan Langganan Premium :',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ColorManager.currentHomeColor,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text('• Bebas Iklan',
                          style:
                              TextStyle(color: ColorManager.currentHomeColor)),
                      Text('• Badge Premium',
                          style:
                              TextStyle(color: ColorManager.currentHomeColor)),
                      Text('• Komentar Lebih Dari 1x per Episode',
                          style:
                              TextStyle(color: ColorManager.currentHomeColor)),
                      Text('• Dan Masih Banyak Lagi',
                          style:
                              TextStyle(color: ColorManager.currentHomeColor)),
                      SizedBox(height: 5),
                      Text(
                        'Jika Order Gagal, Silahkan Lapor admin, Mohon untuk tidak curang. akun akan kami banned.',
                        style: TextStyle(color: ColorManager.currentHomeColor),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                  SizedBox(height: 20),
                  _buildSubscriptionOptions(),
                ],
              ),
            ),
    );
  }

  Widget _buildSubscriptionOptions() {
    return Column(
      children: [
        _buildSubscriptionOption(
            'flue_10k_premium', 'Rp 10.000,00', '+ 1 Bulan', 30),
        _buildSubscriptionOption(
            'flue_30k_premium', 'Rp 30.000,00', '+ 3 Bulan', 90),
        _buildSubscriptionOption(
            'flue_50k_premium', 'Rp 55.000,00', '+ 6 Bulan', 180),
        _buildSubscriptionOption(
            'flue_100k_premium', 'Rp 99.000,00', '+ 12 Bulan', 365),
      ],
    );
  }

  Widget _buildSubscriptionOption(
      String productId, String price, String duration, int durationInDays) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: ElevatedButton(
        onPressed: () => _handleSubscriptionButton(productId, durationInDays),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              price,
              style: TextStyle(fontSize: 18),
            ),
            Text(
              duration,
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              height: 30.0,
              color: Colors.white,
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 200.0,
              color: Colors.white,
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 50.0,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
