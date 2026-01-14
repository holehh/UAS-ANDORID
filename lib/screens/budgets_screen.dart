import 'package:flutter/material.dart';
import '../api_service.dart';
import '../auth.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  List<dynamic> budgets = [];
  List<dynamic> categories = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
    _loadCategories();
  }

  Future<void> _loadBudgets() async {
    final token = await AuthStore.getToken();
    if (token == null) return;
    try {
      final data = await ApiService().getBudgets(token);
      setState(() {
        budgets = data;
        loading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal load budget: $e")));
    }
  }

  Future<void> _loadCategories() async {
    final token = await AuthStore.getToken();
    if (token == null) return;
    try {
      final data = await ApiService().getCategories(token);
      setState(() {
        categories = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal load kategori: $e")));
    }
  }

  Future<void> _showBudgetDetail(int id) async {
    final token = await AuthStore.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Token tidak tersedia")));
      return;
    }
    try {
      final detail = await ApiService().getBudgetDetail(token, id);
      final bud = detail["budget"] ?? {};
      final transactions = List.from(detail["transactions"] ?? []);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          builder: (_, controller) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  bud["CategoryName"] ?? "Budget Detail",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatCard("Limit", "${bud["LimitAmount"] ?? '-'}", Colors.indigo),
                    const SizedBox(width: 8),
                    _buildStatCard("Terpakai", "${detail["total_expense"] ?? 0}", Colors.redAccent),
                    const SizedBox(width: 8),
                    _buildStatCard("Status", "${detail["status"] ?? '-'}", Colors.green),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Periode: ${bud["StartDate"]?.toString().split("T")[0] ?? "-"} - ${bud["EndDate"]?.toString().split("T")[0] ?? "-"}",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                const Text("Transaksi", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: transactions.isEmpty
                      ? const Center(child: Text("Belum ada transaksi"))
                      : ListView.separated(
                          controller: controller,
                          itemCount: transactions.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final t = transactions[i];
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                backgroundColor: t["Amount"] != null && (t["Amount"] as num) > 0 ? Colors.green : Colors.red,
                                child: Text(
                                  (t["Amount"] ?? 0).toString().replaceAll(".0", ""),
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                              title: Text(t["Description"] ?? t["Note"] ?? "Transaksi"),
                              subtitle: Text(t["Date"]?.toString().split("T")[0] ?? ""),
                              trailing: Text("${t["Amount"] ?? 0}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteBudget(int id) async {
    final token = await AuthStore.getToken();
    if (token == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Konfirmasi Hapus"),
        content: const Text("Yakin ingin menghapus budget ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Hapus")),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService().deleteBudget(token, id);
      _loadBudgets();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal hapus budget: $e")));
    }
  }

  Future<void> _editBudget(Map<String, dynamic> budget) async {
    final limitCtl = TextEditingController(
      text: budget["limit_amount"]?.toString() ?? "",
    );
    DateTime? startDate = budget["start_date"] != null ? DateTime.tryParse(budget["start_date"]) : null;
    DateTime? endDate = budget["end_date"] != null ? DateTime.tryParse(budget["end_date"]) : null;
    int? selectedCategory = budget["category_id"];

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Budget"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: limitCtl,
                decoration: const InputDecoration(labelText: "Limit Amount"),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: Text(
                  "Start Date: ${startDate?.toIso8601String().split("T")[0] ?? "-"}",
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => startDate = picked);
                  }
                },
              ),
              ListTile(
                title: Text(
                  "End Date: ${endDate?.toIso8601String().split("T")[0] ?? "-"}",
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: endDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => endDate = picked);
                  }
                },
              ),
              DropdownButtonFormField<int>(
                initialValue: selectedCategory,
                items: [
                  const DropdownMenuItem(
                    value: 0,
                    child: Text("Total (Tanpa Kategori)"),
                  ),
                  ...categories.map((c) {
                    return DropdownMenuItem(
                      value: c["ID"],
                      child: Text(c["Name"] ?? "Kategori"),
                    );
                  }),
                ],
                onChanged: (v) => selectedCategory = v,
                decoration: const InputDecoration(labelText: "Kategori"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Simpan"),
          ),
        ],
      ),
    );

    if (result == true) {
      final token = await AuthStore.getToken();
      try {
        await ApiService().updateBudget(token!, budget["ID"], {
          "limit_amount": double.tryParse(limitCtl.text),
          "start_date": startDate?.toIso8601String().split("T")[0],
          "end_date": endDate?.toIso8601String().split("T")[0],
          "category_id": selectedCategory ?? 0,
        });
        _loadBudgets();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal update budget: $e")));
      }
    }
  }

  Future<void> _addBudget() async {
    final limitCtl = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;
    int? selectedCategory = 0;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Tambah Budget"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: limitCtl,
                decoration: const InputDecoration(labelText: "Limit Amount"),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: Text(
                  "Start Date: ${startDate?.toIso8601String().split("T")[0] ?? "-"}",
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => startDate = picked);
                  }
                },
              ),
              ListTile(
                title: Text(
                  "End Date: ${endDate?.toIso8601String().split("T")[0] ?? "-"}",
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => endDate = picked);
                  }
                },
              ),
              DropdownButtonFormField<int>(
                initialValue: selectedCategory,
                items: [
                  const DropdownMenuItem(
                    value: 0,
                    child: Text("Total (Tanpa Kategori)"),
                  ),
                  ...categories.map((c) {
                    return DropdownMenuItem(
                      value: c["ID"],
                      child: Text(c["Name"] ?? "Kategori"),
                    );
                  }),
                ],
                onChanged: (v) => selectedCategory = v,
                decoration: const InputDecoration(labelText: "Kategori"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              if (limitCtl.text.trim().isEmpty || startDate == null || endDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Semua field wajib diisi")));
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );

    if (result == true) {
      final token = await AuthStore.getToken();
      try {
        await ApiService().createBudget(token!, {
          "category_id": selectedCategory ?? 0,
          "limit_amount": double.tryParse(limitCtl.text.trim()) ?? 0,
          "start_date": startDate?.toIso8601String().split("T")[0],
          "end_date": endDate?.toIso8601String().split("T")[0],
        });
        _loadBudgets();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal tambah budget: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Budgets"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadBudgets(),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addBudget,
        icon: const Icon(Icons.add),
        label: const Text("Tambah"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : budgets.isEmpty
              ? const Center(child: Text("Belum ada budget"))
              : RefreshIndicator(
                  onRefresh: _loadBudgets,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: budgets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final b = budgets[i];
                      final categoryName = categories.firstWhere(
                        (c) => c["ID"] == b["CategoryID"],
                        orElse: () => {"Name": "Total"},
                      )["Name"];
                      final limit = (b["LimitAmount"] ?? 0) is num ? (b["LimitAmount"] as num).toDouble() : double.tryParse('${b["LimitAmount"]}') ?? 0.0;
                      final spent = (b["TotalExpense"] ?? b["TotalExpenseAmount"] ?? b["TotalSpent"] ?? b["total_expense"] ?? 0);
                      final spentVal = (spent is num) ? spent.toDouble() : double.tryParse('$spent') ?? 0.0;
                      final percent = limit > 0 ? (spentVal / limit).clamp(0.0, 1.0) : 0.0;

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          onTap: () {
                            final id = (b["ID"] is int) ? b["ID"] as int : int.tryParse('${b["ID"]}') ?? 0;
                            if (id != 0) _showBudgetDetail(id);
                          },
                          leading: CircleAvatar(
                            radius: 26,
                            backgroundColor: percent >= 1.0 ? Colors.redAccent : (percent > 0.7 ? Colors.orange : Colors.indigo),
                            child: Text(
                              categoryName != null && categoryName.toString().isNotEmpty ? (categoryName.toString()[0].toUpperCase()) : "B",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                          ),
                          title: Text(categoryName ?? "Total", style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              LinearProgressIndicator(value: percent, minHeight: 6, backgroundColor: Colors.grey[200]),
                              const SizedBox(height: 6),
                              Text(
                                "Terpakai: ${spentVal.toStringAsFixed(0)}  •  Limit: ${limit.toStringAsFixed(0)}",
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Periode: ${b["StartDate"]?.toString().split("T")[0] ?? '-'} → ${b["EndDate"]?.toString().split("T")[0] ?? '-'}",
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == "edit") {
                                _editBudget(b);
                              } else if (value == "delete") {
                                _deleteBudget(b["ID"]);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: "edit", child: Text("Edit")),
                              PopupMenuItem(value: "delete", child: Text("Hapus")),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
