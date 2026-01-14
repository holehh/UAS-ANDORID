// lib/screens/transactions_screen.dart
import 'package:finance_app/screens/transactions_detail_screen.dart';
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../auth.dart';
import 'transactions_create_screen.dart';
import 'transactions_edit_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<dynamic> items = [];
  bool loading = true;
  String query = "";

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final token = await AuthStore.getToken();
    if (token == null) return;
    try {
      final data = await ApiService().getTransactions(token);
      setState(() {
        items = List.from(data ?? []);
        loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
      }
    }
  }

  Future<void> _deleteItem(int id) async {
    final token = await AuthStore.getToken();
    if (token == null) return;
    try {
      await ApiService().deleteTransaction(token, id);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal hapus: $e")));
    }
  }

  Color _colorForType(String type) {
    switch (type.toLowerCase()) {
      case "income":
        return Colors.green;
      case "expense":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  List<dynamic> get _filteredItems {
    if (query.trim().isEmpty) return items;
    final q = query.toLowerCase();
    return items.where((t) {
      final note = (t["note"] ?? t["description"] ?? "").toString().toLowerCase();
      final cat = (t["category_name"] ?? "").toString().toLowerCase();
      return note.contains(q) || cat.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Transaksi"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Cari transaksi...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => query = v),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TransactionCreateScreen()),
          );
          if (result == true) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text("Tambah"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _filteredItems.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Center(child: Text("Belum ada transaksi", style: TextStyle(color: Colors.grey[600]))),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      itemCount: _filteredItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final t = _filteredItems[i];
                        final id = t["id"] ?? t["ID"] ?? t["Id"];
                        final type = (t["category_type"] ?? t["type"] ?? "").toString();
                        final amount = (t["amount"] ?? t["Amount"] ?? 0).toString();
                        final categoryName = (t["category_name"] ?? t["category"] ?? "").toString();
                        final date = (t["date"] ?? t["created_at"] ?? "").toString();
                        final color = _colorForType(type);
                        return Dismissible(
                          key: ValueKey(id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) async {
                            final res = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("Hapus Transaksi"),
                                content: const Text("Yakin ingin menghapus transaksi ini?"),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
                                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Hapus")),
                                ],
                              ),
                            );
                            return res == true;
                          },
                          onDismissed: (_) {
                            if (id != null) _deleteItem(id as int);
                          },
                          background: Container(
                            padding: const EdgeInsets.only(right: 20),
                            alignment: Alignment.centerRight,
                            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 1,
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => TransactionDetailScreen(transaction: t)),
                                );
                              },
                              leading: CircleAvatar(
                                radius: 26,
                                backgroundColor: color.withOpacity(0.12),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(type.toLowerCase() == "income" ? Icons.arrow_downward : Icons.arrow_upward,
                                        size: 18, color: color),
                                    const SizedBox(height: 2),
                                    Text(
                                      amount.replaceAll(".0", ""),
                                      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              title: Text(t["note"] ?? t["description"] ?? "-", style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text("$date • $categoryName", style: const TextStyle(fontSize: 12)),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) async {
                                  final token = await AuthStore.getToken();
                                  if (value == "edit") {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => TransactionEditScreen(transaction: t)),
                                    );
                                    _load();
                                  } else if (value == "delete") {
                                    if (id != null) _deleteItem(id as int);
                                  } else if (value == "share") {
                                    // placeholder for share or other actions
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: "edit", child: Text("Edit")),
                                  PopupMenuItem(value: "delete", child: Text("Hapus")),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
