import 'package:flutter/material.dart';
import '../api_service.dart';
import '../auth.dart';

class CategoryEditScreen extends StatefulWidget {
  final Map<String, dynamic> category;
  const CategoryEditScreen({super.key, required this.category});

  @override
  State<CategoryEditScreen> createState() => _CategoryEditScreenState();
}

class _CategoryEditScreenState extends State<CategoryEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameCtl;
  String selectedType = "income";
  bool loading = false;

  @override
  void initState() {
    super.initState();
    nameCtl = TextEditingController(
      text: widget.category["name"] ?? widget.category["Name"] ?? "",
    );
    selectedType =
        (widget.category["type"] ?? widget.category["Type"] ?? "income").toString();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      final token = await AuthStore.getToken();
      final payload = {"name": nameCtl.text.trim(), "type": selectedType};
      final id = widget.category["id"] ?? widget.category["ID"] ?? widget.category["Id"];
      await ApiService().updateCategory(
        token!,
        id,
        payload,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal update: $e")));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    nameCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Kategori"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtl,
                        decoration: InputDecoration(
                          labelText: "Nama Kategori",
                          prefixIcon: const Icon(Icons.label),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        textInputAction: TextInputAction.done,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return "Nama kategori tidak boleh kosong";
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: "Tipe",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedType,
                                  items: const [
                                    DropdownMenuItem(value: "income", child: Text("Income")),
                                    DropdownMenuItem(value: "expense", child: Text("Expense")),
                                  ],
                                  onChanged: loading ? null : (v) => setState(() => selectedType = v ?? "income"),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                            label: Text(loading ? "Menyimpan..." : "Simpan"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: loading ? null : _save,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: loading ? null : () => Navigator.pop(context, false),
                            child: const Text("Batal"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
