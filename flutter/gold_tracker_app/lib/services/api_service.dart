import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/currency_model.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = 'https://web-production-99bc.up.railway.app/api';
  final AuthService _authService = AuthService();

  Future<List<Currency>> getPrices() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/prices/'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => Currency.fromJson(item)).toList();
      } else {
        throw Exception('خطا در دریافت قیمتها');
      }
    } catch (e) {
      print('Error in getPrices: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register(String username, String password, String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password, 'email': email}),
      );
      if (response.statusCode == 201) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['error'] ?? 'خطا در ثبت نام');
      }
    } catch (e) {
      print('Error in register: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['error'] ?? 'خطا در ورود');
      }
    } catch (e) {
      print('Error in login: $e');
      rethrow;
    }
  }

  Future<List<Currency>> getWatchlist() async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('لطفا ابتدا وارد شوید');

      final response = await http.get(
        Uri.parse('$baseUrl/watchlist/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => Currency.fromJson(item)).toList();
      } else {
        throw Exception('خطا در دریافت لیست');
      }
    } catch (e) {
      print('Error in getWatchlist: $e');
      rethrow;
    }
  }

  Future<void> addToWatchlist(int currencyId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('لطفا ابتدا وارد شوید');

      final response = await http.post(
        Uri.parse('$baseUrl/watchlist/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'currency_id': currencyId}),
      );
      if (response.statusCode != 200) {
        throw Exception('خطا در افزودن');
      }
    } catch (e) {
      print('Error in addToWatchlist: $e');
      rethrow;
    }
  }

  Future<void> removeFromWatchlist(int currencyId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('لطفا ابتدا وارد شوید');

      final response = await http.delete(
        Uri.parse('$baseUrl/watchlist/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'currency_id': currencyId}),
      );
      if (response.statusCode != 200) {
        throw Exception('خطا در حذف');
      }
    } catch (e) {
      print('Error in removeFromWatchlist: $e');
      rethrow;
    }
  }

  // ========== متد جدید برای چک کردن وضعیت Favorite ==========
  Future<bool> isInWatchlist(int currencyId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/watchlist/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final watchlistIds = data.map((item) => item['id'] as int).toList();
        return watchlistIds.contains(currencyId);
      }
      return false;
    } catch (e) {
      print('Error checking watchlist: $e');
      return false;
    }
  }
}
