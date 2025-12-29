import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/currency_model.dart';
import 'login_screen.dart';
import 'watchlist_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  List<Currency> _currencies = [];
  Map<int, bool> _isFavorite = {};
  bool _isLoading = true;
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final username = await _authService.getUsername();
      final prices = await _apiService.getPrices();

      // چک کردن وضعیت favorite هر ارز
      final favoriteStatus = <int, bool>{};
      for (var currency in prices) {
        favoriteStatus[currency.id] = await _apiService.isInWatchlist(currency.id);
      }

      setState(() {
        _username = username ?? 'کاربر';
        _currencies = prices;
        _isFavorite = favoriteStatus;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('خطا در دریافت قیمتها: $e');
    }
  }

  Future<void> _toggleFavorite(Currency currency) async {
    try {
      if (_isFavorite[currency.id] == true) {
        await _apiService.removeFromWatchlist(currency.id);
        setState(() {
          _isFavorite[currency.id] = false;
        });
        _showSnackBar('${currency.name} از علاقه‌مندی‌ها حذف شد');
      } else {
        await _apiService.addToWatchlist(currency.id);
        setState(() {
          _isFavorite[currency.id] = true;
        });
        _showSnackBar('${currency.name} به علاقه‌مندی‌ها اضافه شد');
      }
    } catch (e) {
      _showSnackBar('خطا: ${e.toString()}');
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('قیمت طلا و ارز'),
          backgroundColor: Colors.amber,
          actions: [
            IconButton(
              icon: Icon(Icons.favorite),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => WatchlistScreen())),
            ),
            IconButton(icon: Icon(Icons.refresh), onPressed: _loadData),
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(child: Text('خروج'), value: 'logout'),
              ],
              onSelected: (value) => value == 'logout' ? _logout() : null,
            ),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      color: Colors.amber[100],
                      child: Text('خوش آمدید $_username',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: _currencies.isEmpty
                          ? Center(child: Text('هیچ داده‌ای یافت نشد'))
                          : ListView.builder(
                              itemCount: _currencies.length,
                              padding: EdgeInsets.all(8),
                              itemBuilder: (context, index) {
                                final currency = _currencies[index];
                                final isPositive = currency.change24h >= 0;
                                final isFav = _isFavorite[currency.id] ?? false;

                                return Card(
                                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.all(16),
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.amber,
                                      child: Icon(Icons.currency_exchange, color: Colors.white),
                                    ),
                                    title: Text(currency.name,
                                        style: TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(currency.code),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // دکمه قلب
                                        IconButton(
                                          icon: Icon(
                                            isFav ? Icons.favorite : Icons.favorite_border,
                                            color: Colors.red,
                                            size: 28,
                                          ),
                                          onPressed: () => _toggleFavorite(currency),
                                        ),
                                        // قیمت و تغییرات
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text('${_formatPrice(currency.price)} ریال',
                                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                            SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                                                  color: isPositive ? Colors.green : Colors.red,
                                                  size: 16,
                                                ),
                                                Text('${currency.change24h.toStringAsFixed(2)}%',
                                                    style: TextStyle(
                                                      color: isPositive ? Colors.green : Colors.red,
                                                      fontWeight: FontWeight.bold,
                                                    )),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},'
    );
  }
}
