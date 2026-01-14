import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "http://10.0.2.2:3000";

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": name, "email": email, "password": password}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body);
    }
    throw Exception("Register gagal: ${res.body}");
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Login gagal: ${res.body}");
  }

  Future<Map<String, dynamic>> getSummary(String token) async {
    final res = await http.get(
      Uri.parse("$baseUrl/reports/summary"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Gagal ambil summary: ${res.body}");
  }

  Future<List<dynamic>> getTransactions(String token) async {
    final res = await http.get(
      Uri.parse("$baseUrl/transactions"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Gagal ambil transaksi: ${res.body}");
  }

  Future<Map<String, dynamic>> createTransaction(
    String token,
    Map<String, dynamic> payload,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/transactions"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(payload),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body);
    }
    throw Exception("Gagal buat transaksi: ${res.body}");
  }

  Future<void> updateTransaction(
    String token,
    int id,
    Map<String, dynamic> payload,
  ) async {
    final res = await http.put(
      Uri.parse("$baseUrl/transactions/$id"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(payload),
    );
    if (res.statusCode != 200) {
      throw Exception("Gagal update transaksi: ${res.body}");
    }
  }

  Future<void> deleteTransaction(String token, int id) async {
    final res = await http.delete(
      Uri.parse("$baseUrl/transactions/$id"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode != 200) {
      throw Exception("Gagal hapus transaksi: ${res.body}");
    }
  }

  Future<List<dynamic>> getExpenseByCategory(String token) async {
    final res = await http.get(
      Uri.parse("$baseUrl/reports/expense-by-category"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Gagal ambil expense by category: ${res.body}");
  }

  Future<List<dynamic>> getCategories(String token) async {
    final res = await http.get(
      Uri.parse("$baseUrl/categories"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Gagal ngambil kategori: ${res.body}");
  }

  Future<Map<String, dynamic>> createCategory(
    String token,
    Map<String, dynamic> payload,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/categories"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(payload),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body);
    }
    throw Exception("Gagal buat kategori: ${res.body}");
  }

  Future<void> updateCategory(
    String token,
    int id,
    Map<String, dynamic> payload,
  ) async {
    final res = await http.put(
      Uri.parse("$baseUrl/categories/$id"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(payload),
    );
    if (res.statusCode != 200) {
      throw Exception("Gagal update kategori: ${res.body}");
    }
  }

  Future<void> deleteCategory(String token, int id) async {
    final res = await http.delete(
      Uri.parse("$baseUrl/categories/$id"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode != 200) {
      throw Exception("Gagal hapus kategori: ${res.body}");
    }
  }

  Future<List<dynamic>> getBudgets(String token) async {
    final res = await http.get(
      Uri.parse("$baseUrl/budgets"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Gagal ambil budget: ${res.body}");
  }

  Future<void> createBudget(String token, Map<String, dynamic> payload) async {
    final res = await http.post(
      Uri.parse("$baseUrl/budgets"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(payload),
    );
    if (res.statusCode != 201) {
      throw Exception("Gagal tambah budget: ${res.body}");
    }
  }

  Future<List<dynamic>> getBudgetStatus(String token) async {
    final res = await http.get(
      Uri.parse("$baseUrl/budgets/status"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Gagal ambil status budget: ${res.body}");
  }

  Future<List<dynamic>> getBudgetChart(String token) async {
    final res = await http.get(
      Uri.parse("$baseUrl/budgets/chart"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load budget chart: ${res.body}");
    }
  }

  Future<void> updateBudget(
    String token,
    int id,
    Map<String, dynamic> payload,
  ) async {
    final res = await http.put(
      Uri.parse("$baseUrl/budgets/$id"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(payload),
    );
    if (res.statusCode != 200) {
      throw Exception("Failed to update budget: ${res.body}");
    }
  }

  Future<void> deleteBudget(String token, int id) async {
    final res = await http.delete(
      Uri.parse("$baseUrl/budgets/$id"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode != 200) {
      throw Exception("Failed to delete budget: ${res.body}");
    }
  }

  Future<Map<String, dynamic>> getBudgetDetail(String token, int id) async {
    final res = await http.get(
      Uri.parse("$baseUrl/budgets/$id/detail"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load budget detail: ${res.body}");
    }
  }

  Future<Map<String, dynamic>> getBudgetSummary(String token) async {
    final res = await http.get(
      Uri.parse("$baseUrl/budgets/summary"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load budget summary: ${res.body}");
    }
  }

  Future<List<dynamic>> getBudgetBarData(String token) async {
    final res = await http.get(
      Uri.parse("$baseUrl/budgets/bar"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load budget bar data: ${res.body}");
    }
  }

  Future<List<dynamic>> getNotifications(String token) async {
    final res = await http.get(
      Uri.parse("$baseUrl/notifications"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    } else {
      throw Exception("Gagal ambil notifikasi: ${res.body}");
    }
  }

  Future<Map<String, dynamic>> getNotificationDetail(
    String token,
    int id,
  ) async {
    final res = await http.get(
      Uri.parse("$baseUrl/notifications/$id"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Gagal ambil detail notifikasi: ${res.body}");
    }
  }

  Future<void> deleteNotification(String token, int id) async {
    final res = await http.delete(
      Uri.parse("$baseUrl/notifications/$id"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode != 200) {
      throw Exception("Gagal hapus notifikasi: ${res.body}");
    }
  }

Future<List<dynamic>> getMonthlyReport(String token) async {
  final res = await http.get(
    Uri.parse("$baseUrl/reports/monthly"),
    headers: {"Authorization": "Bearer $token"},
  );
  if (res.statusCode == 200) return jsonDecode(res.body);
  throw Exception("Gagal ambil laporan bulanan: ${res.body}");
}

Future<Map<String, dynamic>> getProfile(String token) async {
    final res = await http.get(
      Uri.parse("$baseUrl/profile"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Gagal ambil profil: ${res.body}");
    }
  }

  Future<Map<String, dynamic>> updateProfile(
      String token, Map<String, dynamic> payload) async {
    final res = await http.put(
      Uri.parse("$baseUrl/profile"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(payload),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Gagal update profil: ${res.body}");
    }
  }


Future<String> uploadPhoto(String token, File file) async {
  final req = http.MultipartRequest("POST", Uri.parse("$baseUrl/profile/photo"));
  req.headers["Authorization"] = "Bearer $token";
  req.files.add(await http.MultipartFile.fromPath("photo", file.path));

  final res = await req.send();
  if (res.statusCode == 200) {
    final body = await res.stream.bytesToString();
    final data = jsonDecode(body);
    // backend return {"PhotoURL": "/uploads/filename.png"}
    return data["PhotoURL"];
  } else {
    throw Exception("Gagal upload foto: ${res.statusCode}");
  }
}}
