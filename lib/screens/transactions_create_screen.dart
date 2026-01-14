import 'package:flutter/material.dart';
import '../api_service.dart';
import '../auth.dart';

class TransactionCreateScreen extends StatefulWidget {
  const TransactionCreateScreen({super.key});
  @override
  State<TransactionCreateScreen> createState() => _TransactionCreateScreenState();
}

class _TransactionCreateScreenState extends State<TransactionCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final amountCtl = TextEditingController();
  final noteCtl = TextEditingController();
  DateTime selected = DateTime.now();
  bool loading = false;

  String selectedType = "income"; // default
  List<dynamic> allCategories = [];
  List<dynamic> filteredCategories = [];
  dynamic selectedCategory;

  @override
  void initState() {
    super.initState();
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
        allCategories = List.from(data ?? []);
      });
      _filterCategories();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
    }
  }

  void _filterCategories() {
    final filtered = allCategories.where((c) {
      final type = (c["type"] ?? c["Type"] ?? "").toString().toLowerCase();
      return type == selectedType.toLowerCase();
    }).toList();
    setState(() {
      filteredCategories = filtered;
      selectedCategory = filtered.isNotEmpty ? filtered[0] : null;
    });
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
      if (token == null) return;
      final raw = amountCtl.text.replaceAll(',', '').trim();
      final amount = double.tryParse(raw) ?? 0.0;
      final payload = {
        "amount": amount,
        "date": selected.toIso8601String(),
        "note": noteCtl.text.trim(),
        "category_id": selectedCategory?["id"] ?? selectedCategory?["ID"],
        "type": selectedType,
      };
      await ApiService().createTransaction(token, payload);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget _typeSelector() {
    return Row(
      children: [
        ChoiceChip(
          label: const Text("Income"),
          selected: selectedType == "income",
          onSelected: (v) {
            if (!v) return;
            setState(() => selectedType = "income");
            _filterCategories();
          },
          selectedColor: Colors.green.shade100,
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text("Expense"),
          selected: selectedType == "expense",
          onSelected: (v) {
            if (!v) return;
            setState(() => selectedType = "expense");
            _filterCategories();
          },
          selectedColor: Colors.red.shade100,
        ),
      ],
    );
  }

  Widget _categoryChips() {
    if (filteredCategories.isEmpty) {
      return TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.info_outline),
        label: const Text("Belum ada kategori untuk tipe ini"),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filteredCategories.map((c) {
          final name = (c["name"] ?? c["Name"] ?? "").toString();
          final id = c["id"] ?? c["ID"];
          final selected = selectedCategory != null && (selectedCategory["id"] ?? selectedCategory["ID"]) == id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(name),
              selected: selected,
              onSelected: (_) => setState(() => selectedCategory = c),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Transaksi"),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih tipe, kategori, dan isi jumlah.")));
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: loading ? null : _save,
        icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
        label: const Text("Simpan"),
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
                        labelText: "Catatan (opsional)",
                        prefixIcon: const Icon(Icons.note),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Align(alignment: Alignment.centerLeft, child: _typeSelector()),
                    const SizedBox(height: 12),
                    Align(alignment: Alignment.centerLeft, child: Text("Kategori", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700]))),
                    const SizedBox(height: 8),
                    _categoryChips(),
                    const SizedBox(height: 16),
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
                          icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check),
                          label: const Text("Simpan"),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (filteredCategories.isEmpty)
                      TextButton(
                        onPressed: () {},
                        child: const Text("Kelola kategori"),
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