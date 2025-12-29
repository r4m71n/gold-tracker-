import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';
import '../models/currency_model.dart';

class WatchlistScreen extends StatefulWidget {
  @override
  _WatchlistScreenState createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final ApiService _apiService = ApiService();
  List<Currency> _watchlist = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWatchlist();
  }

  Future<void> _loadWatchlist() async {
    setState(() => _isLoading = true);
    try {
      final watchlist = await _apiService.getWatchlist();
      setState(() {
        _watchlist = watchlist;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('خطا: ${e.toString()}');
    }
  }

  Future<void> _removeFromWatchlist(Currency currency) async {
    try {
      await _apiService.removeFromWatchlist(currency.id);
      setState(() {
        _watchlist.removeWhere((c) => c.id == currency.id);
      });
      _showSnackBar('${currency.name} از لیست حذف شد');
    } catch (e) {
      _showSnackBar('خطا: ${e.toString()}');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orange),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('علاقه‌مندی‌های من'),
          backgroundColor: Colors.amber,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _loadWatchlist,
            ),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadWatchlist,
                child: _watchlist.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'لیست علاقه‌مندی‌های شما خالی است',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'از صفحه اصلی ارز مورد نظر را انتخاب کنید',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _watchlist.length,
                        padding: EdgeInsets.all(8),
                        itemBuilder: (context, index) {
                          final currency = _watchlist[index];
                          final isPositive = currency.change24h >= 0;

                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: Colors.red[400],
                                child: Icon(Icons.favorite, color: Colors.white),
                              ),
                              title: Text(
                                currency.name,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(currency.code),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // دکمه حذف
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, color: Colors.red, size: 28),
                                    onPressed: () => _removeFromWatchlist(currency),
                                  ),
                                  SizedBox(width: 8),
                                  // قیمت و تغییرات
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${_formatPrice(currency.price)} ریال',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                                            color: isPositive ? Colors.green : Colors.red,
                                            size: 16,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            '${currency.change24h.toStringAsFixed(2)}%',
                                            style: TextStyle(
                                              color: isPositive ? Colors.green : Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
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
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
