import 'package:flutter/material.dart';
import '../api_service.dart';
import '../auth.dart';
import 'transactions_edit_screen.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> transaction;
  const TransactionDetailScreen({super.key, required this.transaction});

  Future<void> _delete(BuildContext context) async {
    final token = await AuthStore.getToken();
    try {
      await ApiService().deleteTransaction(token!, transaction["id"]);
      if (!context.mounted) return;
      Navigator.pop(context, true); // kembali ke list dengan flag refresh
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = transaction["category_type"] ?? "";
    final categoryName = transaction["category_name"] ?? "";
    final amount = transaction["amount"] ?? 0;
    final note = transaction["note"] ?? "";
    final date = transaction["date"] ?? "";

    final color = type == "income" ? Colors.green : Colors.red;
    final icon = type == "income" ? Icons.arrow_downward : Icons.arrow_upward;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Transaksi"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TransactionEditScreen(transaction: transaction),
                ),
              );
              if (result == true && context.mounted) {
                Navigator.pop(context, true); // refresh list setelah edit
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Konfirmasi"),
                  content: const Text("Yakin ingin menghapus transaksi ini?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Hapus")),
                  ],
                ),
              );
              if (confirm == true) {
                _delete(context);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400), // ukuran proporsional
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 48, color: color),
                  const SizedBox(height: 12),
                  Text(
                    "Rp $amount",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _detailRow("Catatan", note),
                  _detailRow("Tanggal", date),
                  _detailRow("Kategori", categoryName),
                  _detailRow("Tipe", type.toUpperCase()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}