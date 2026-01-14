import 'package:flutter/material.dart';
import '../api_service.dart';
import '../auth.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> _notifications = [];
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final token = await AuthStore.getToken();
      if (token == null) {
        if (!mounted) return;
        setState(() => _notifications = []);
        return;
      }
      _token = token;
      final data = await ApiService().getNotifications(token);
      if (!mounted) return;
      setState(() => _notifications = data);
    } catch (e) {
      if (!mounted) return;
      _showSnack("Gagal ambil notifikasi: $e");
    }
  }

  Future<void> _deleteNotification(int id, int index) async {
    if (_token == null) {
      _showSnack("Token tidak tersedia");
      return;
    }
    try {
      await ApiService().deleteNotification(_token!, id);
      if (!mounted) return;
      setState(() => _notifications.removeAt(index));
      _showSnack("Notifikasi dihapus");
    } catch (e) {
      _showSnack("Gagal hapus notifikasi: $e");
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifikasi")),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _notifications.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text("Belum ada notifikasi"),
                    ),
                  )
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final n = _notifications[index] as Map<String, dynamic>;
                  final created = n["created_at"] != null
                      ? (DateTime.tryParse(n["created_at"].toString())
                              ?.toLocal()
                              .toString()
                              .split('.')
                              .first ??
                          n["created_at"].toString())
                      : '';
                  final id = int.tryParse('${n["id"]}') ?? 0;

                  return Card(
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  elevation: 2,
  child: ListTile(
    isThreeLine: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    leading: const CircleAvatar(
      backgroundColor: Colors.indigo,
      child: Icon(Icons.notifications, color: Colors.white, size: 20),
    ),
    title: Text(n["title"] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Text(
          n["message"] ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(created, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    ),
    trailing: IconButton(
      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
      tooltip: 'Hapus',
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Konfirmasi'),
            content: const Text('Hapus notifikasi ini?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Hapus')),
            ],
          ),
        );
        if (confirm == true) {
          await _deleteNotification(id, index);
        }
      },
    ),
    onTap: () async {
      if (_token == null) {
        _showSnack("Token tidak tersedia");
        return;
      }
      try {
        final detail = await ApiService().getNotificationDetail(_token!, id);
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(detail["title"] ?? ''),
            content: Text(detail["message"] ?? ''),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup")),
            ],
          ),
        );
      } catch (e) {
        _showSnack("Gagal ambil detail: $e");
      }
    },
  ),
);
                },
              ),
      ),
    );
  }
}