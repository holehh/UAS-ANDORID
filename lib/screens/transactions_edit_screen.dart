import 'package:flutter/material.dart';
import '../api_service.dart';
import '../auth.dart';

class TransactionEditScreen extends StatefulWidget {
  final Map<String, dynamic> transaction;
  const TransactionEditScreen({super.key, required this.transaction});

  @override
  State<TransactionEditScreen> createState() => _TransactionEditScreenState();
}

class _TransactionEditScreenState extends State<TransactionEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController amountCtl;
  late TextEditingController noteCtl;
  late DateTime selected;
  dynamic selectedCategory;
  List<dynamic> categories = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    amountCtl = TextEditingController(text: (widget.transaction["amount"] ?? widget.transaction["Amount"] ?? 0).toString());
    noteCtl = TextEditingController(text: widget.transaction["note"] ?? widget.transaction["description"] ?? "");
    selected = DateTime.tryParse(widget.transaction["date"] ?? widget.transaction["created_at"] ?? "") ?? DateTime.now();
    selectedCategory = {
      "id": widget.transaction["category_id"] ?? widget.transaction["CategoryID"] ?? widget.transaction["category"]?["id"],
      "name": widget.transaction["category_name"] ?? widget.transaction["CategoryName"] ?? widget.transaction["category"]?["name"],
      "type": widget.transaction["category_type"] ?? widget.transaction["CategoryType"] ?? widget.transaction["category"]?["type"],
    };
    _loadCategories();
  }

  @override
  void dispose() {
    amountCtl.dispose();
    noteCtl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final token = await AuthStore.getToken();
    if (token == null) return;
    try {
      final data = await ApiService().getCategories(token);
      setState(() {
        categories = List.from(data ?? []);
        // try to match existing category by id
        final cid = selectedCategory?["id"];
        if (cid != null) {
          final match = categories.firstWhere((c) => (c["id"] ?? c["ID"] ?? c["Id"]).toString() == cid.toString(), orElse: () => null);
          if (match != null) selectedCategory = match;
        }
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: selected,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => selected = d);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      final token = await AuthStore.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Token tidak tersedia")));
        setState(() => loading = false);
        return;
      }
      final raw = amountCtl.text.replaceAll(',', '').trim();
      final amount = double.tryParse(raw) ?? 0.0;
      final payload = {
        "amount": amount,
        "date": selected.toIso8601String(),
        "note": noteCtl.text.trim(),
        "category_id": selectedCategory == null ? null : (selectedCategory["id"] ?? selectedCategory["ID"]),
      };
      final id = widget.transaction["id"] ?? widget.transaction["ID"] ?? widget.transaction["Id"];
      await ApiService().updateTransaction(token, id, payload);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menyimpan: $e")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Transaksi"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: amountCtl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Jumlah",
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) {
                        final s = v?.replaceAll(',', '').trim() ?? '';
                        if (s.isEmpty) return "Jumlah harus diisi";
                        if (double.tryParse(s) == null) return "Masukkan angka valid";
                        if ((double.tryParse(s) ?? 0) <= 0) return "Jumlah harus lebih dari 0";
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: noteCtl,
                      decoration: InputDecoration(
                        labelText: "Catatan",
                        prefixIcon: const Icon(Icons.note),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<dynamic>(
                      initialValue: selectedCategory,
                      items: categories.map((c) {
                        final id = c["id"] ?? c["ID"] ?? c["Id"];
                        final name = c["name"] ?? c["Name"] ?? "-";
                        return DropdownMenuItem(value: c, child: Text(name.toString()));
                      }).toList(),
                      decoration: InputDecoration(
                        labelText: "Kategori",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.category),
                      ),
                      onChanged: (v) => setState(() => selectedCategory = v),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_today),
                            label: Text(selected.toIso8601String().substring(0, 10)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: loading ? null : _save,
                          icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                          label: Text(loading ? "Menyimpan..." : "Simpan"),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}