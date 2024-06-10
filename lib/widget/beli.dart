import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shimmer/shimmer.dart';

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
      final ProductDetailsResponse response = await _iap.queryProductDetails({'niflex_10k_premium'});
      if (response.notFoundIDs.isNotEmpty) {
        // Handle the error.
      }
      _products = response.productDetails;
    }
    checkPremiumStatus();
  }

  void checkPremiumStatus() async {
    try {
      final response = await http.get(
        Uri.parse('https://ccgnimex.my.id/v2/android/cek_beli.php?telegram_id=${widget.telegramId}'),
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

  void _subscribe() async {
    _log += '\nTombol langganan diklik';

    try {
      final ProductDetails product = _products.firstWhere((product) => product.id == 'niflex_10k_premium');
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    
      // Melakukan pembelian
      _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      _log += '\nError: $e';
    }
  }

void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
  purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.status == PurchaseStatus.purchased) {
      if (purchaseDetails.productID == 'niflex_10k_premium') {
        bool updateSuccess = await updateUserSubscription(widget.telegramId);
        if (updateSuccess) {
          _log += '\nStatus langganan pengguna berhasil diperbarui';
          // Menyegarkan status premium setelah pembaruan langganan berhasil
          checkPremiumStatus();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Langganan Berhasil, Silahkan refresh/restart aplikasi - Flue'),
              duration: Duration(seconds: 5),
            ),
          );
          // Konfirmasi pembelian
          if (purchaseDetails.pendingCompletePurchase) {
            await InAppPurchase.instance.completePurchase(purchaseDetails);
          }
        } else {
          _log += '\nGagal memperbarui status langganan pengguna';
          // Menangani kasus di mana pembaruan langganan pengguna gagal
        }
      }
    }
  });
}



  Future<void> _handleSubscriptionButton() async {
    if (_isPremium) {
      // Jika pengguna sudah premium, tidak perlu melakukan apa pun
      _subscribe();
    } else {
      // Jika pengguna belum premium, atau hendak memperpanjang langganan
      _subscribe();
    }
  }

  Future<bool> updateUserSubscription(String telegramId) async {
    try {
      final url = 'https://ccgnimex.my.id/v2/android/beli.php?telegram_id=$telegramId';
      final response = await http.get(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Langganan Saya'),
      ),
      body: _isLoading
          ? _buildLoadingWidget() // Show shimmer loading if isLoading is true
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _isPremium ? 'Anda sudah premium' : 'Jadilah Anggota Premium',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  if (_isPremium) // Show expired date only if user is premium
                    Text(
                      'Tanggal Expired: $_expiredDate', // Show expired date
                      style: TextStyle(fontSize: 18),
                    ),
                  SizedBox(height: 20),
                  if (!_isPremium)
                    Column(
                      children: [
                        Text(
                          'Langganan sekarang untuk menikmati berbagai fitur premium! Hanya Rp 10.000/bulan, Cukup 1 kali pembelian, jika sudah expired, akan dikembalikan ke status free',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keuntungan Langganan Premium : (Untuk Sekarang)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text('• Bebas Iklan 100%'),
                      Text('• Badge Diamond (Premium) di chatroom'),
                      Text('• Membantu admin agar aplikasi update terus.'),
                      SizedBox(height: 10),
                      Text(
                        '*akun disarankan login 1 perangkat, jika lebih otomatis diblok.',
                        style: TextStyle(fontSize: 9),
                      ),
                      SizedBox(height: 7),
                      Text(
                        '*Jika sudah order premium, tapi error, chat admin di chatroom atau di media sosial kami!',
                        style: TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _handleSubscriptionButton,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    ),
                    child: Text(
                      _isPremium ? 'Perpanjang Langganan (Rp 10.000/bulan)' : 'Langganan (Rp 10.000/bulan)',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // Function to build shimmer loading widget
  Widget _buildLoadingWidget() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 32,
              width: double.infinity,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Column(
              children: [
                Container(
                  height: 16,
                  width: double.infinity,
                  color: Colors.white,
                ),
                SizedBox(height: 20),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 18,
                  width: 250,
                  color: Colors.white,
                ),
                SizedBox(height: 10),
                Container(
                  height: 18,
                  width: 200,
                  color: Colors.white,
                ),
                Container(
                  height: 18,
                  width: 180,
                  color: Colors.white,
                ),
                Container(
                  height: 18,
                  width: 220,
                  color: Colors.white,
                ),
                Container(
                  height: 18,
                  width: 250,
                  color: Colors.white,
                ),
              ],
            ),
            SizedBox(height: 10),
            Container(
              height: 48,
              width: double.infinity,
              color: Colors.white,
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}