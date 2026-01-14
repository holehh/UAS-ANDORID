import 'package:finance_app/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'dart:async';
import '../api_service.dart';
import '../auth.dart';
import 'transactions_screen.dart';
import 'category_screen.dart';
import 'budgets_screen.dart';
import 'notification_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? summary;
  bool loading = true;
  List<dynamic> monthly = [];
  List<dynamic> budgets = []; // data budget untuk chart & status
  List<dynamic> recent = [];
  Timer? _refreshTimer;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _loadMonthly();
    _loadBudgets();
    _loadRecentTransactions();
    _checkNotifications();

    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await Future.wait([_loadSummary(), _loadMonthly(), _loadBudgets(), _loadRecentTransactions()]);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRecentTransactions() async {
    final token = await AuthStore.getToken();
    if (token == null) return;
    try {
      final data = await ApiService().getTransactions(token);
      if (!mounted) return;
      // keep only latest 5
      setState(() => recent = (data.take(5).toList()));
    } catch (e) {
      if (!mounted) return;
      // silently ignore
    }
  }

  String _formatCurrency(num n) {
    final s = n.toStringAsFixed(0);
    return s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  }

  Future<void> _loadSummary() async {
    final token = await AuthStore.getToken();
    if (token == null) {
      setState(() => loading = false);
      return;
    }
    try {
      final res = await ApiService().getSummary(token);
      setState(() {
        summary = res;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
      setState(() => loading = false);
    }
  }

  Future<void> _loadMonthly() async {
    final token = await AuthStore.getToken();
    if (token == null) return;
    try {
      final data = await ApiService().getMonthlyReport(token);
      setState(() {
        monthly = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
    }
  }

  Future<void> _loadBudgets() async {
    final token = await AuthStore.getToken();
    if (token == null) return;
    try {
      final data = await ApiService().getBudgetStatus(
        token,
      ); // ambil status budget
      setState(() {
        budgets = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
    }
  }

  Future<void> _logout() async {
    await AuthStore.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
  }

  Future<void> _checkNotifications() async {
    try {
      final token = await AuthStore.getToken();
      if (token == null) return;

      final data = await ApiService().getNotifications(token);

      if (data.isNotEmpty) {
        final latest = data.first as Map<String, dynamic>;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("🔔 ${latest["title"]}: ${latest["message"]}"),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        });
      }
    } catch (e) {
      debugPrint("Notif error: $e");
    }
  }

  void _showBudgetQuickDetail(Map<String, dynamic> b) {
    final category = b["category_name"] ?? b["CategoryName"] ?? "Total";
    final limit = (b["limit_amount"] ?? b["LimitAmount"] ?? 0).toString();
    final spent = (b["total_expense"] ?? b["TotalExpense"] ?? 0).toString();
    final status = b["status"] ?? "-";
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(category),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text("Limit"), trailing: Text(limit)),
            ListTile(title: const Text("Terpakai"), trailing: Text(spent)),
            ListTile(title: const Text("Status"), trailing: Text(status)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // buka halaman Budget
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BudgetScreen()),
              );
            },
            child: const Text("Lihat Detail"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final income = (summary?["total_income"] ?? 0).toDouble();
    final expense = (summary?["total_expense"] ?? 0).toDouble();
    final saldo = (summary?["saldo"] ?? 0).toDouble();

    final pages = [
      _dashboardContent(income, expense, saldo),
      const TransactionsScreen(),
      const CategoryScreen(),
      const BudgetScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Saku Ku"),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            ),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Transaksi"),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: "Kategori",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: "Budget",
          ),
                    BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profil", // item baru untuk profil
          ),

        ],
      ),
    );
  }

Widget _dashboardContent(double income, double expense, double saldo) {
  if (loading) {
    return const Center(child: CircularProgressIndicator());
  }

  return RefreshIndicator(
    onRefresh: () async {
      await Future.wait([
        _loadSummary(),
        _loadMonthly(),
        _loadBudgets(),
      ]);
    },
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ringkasan Income, Expense, Saldo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _summaryCard("Pemasukan", income, Colors.green,
                  subtitle: "Total pemasukan"),
              _summaryCard("Pengeluaran", expense, Colors.red,
                  subtitle: "Total pengeluaran"),
              _summaryCard("Saldo", saldo, Colors.blue,
                  subtitle: "Saldo sekarang"),
            ],
          ),
          const SizedBox(height: 20),

          // Perbandingan Income & Expense
          _dashboardCard(
            icon: Icons.pie_chart,
            title: "Perbandingan Pemasukan & Pengeluaran",
            child: SizedBox(height: 220, child: _buildPie(income, expense)),
          ),
          const SizedBox(height: 16),

          // Laporan Bulanan
          _dashboardCard(
            icon: Icons.show_chart,
            title: "Laporan Bulanan",
            child: _monthlyChart(),
          ),
          const SizedBox(height: 16),

          // Budget Overview
          _dashboardCard(
            icon: Icons.bar_chart,
            title: "Budget Overview",
            child: _budgetBarChart(),
          ),
          const SizedBox(height: 16),

          // Transaksi terbaru
          _recentTransactionsCard(),
          const SizedBox(height: 16),

          // Status budget
          _budgetStatusList(),
        ],
      ),
    ),
  );
}


Widget _dashboardCard({
  required IconData icon,
  required String title,
  required Widget child,
}) {
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.indigo),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

  

  Widget _summaryCard(String title, double value, Color color, {String? subtitle}) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text("Rp ${_formatCurrency(value)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ],
          ),
        ),
      ),
    );
  }

Widget _buildPie(double income, double expense) {
  final total = income + expense;
  if (total <= 0) {
    return Center(
      child: Text(
        "Belum ada data",
        style: TextStyle(color: Colors.grey[600]),
      ),
    );
  }

  final incomePct = (income / total * 100);
  final expensePct = (expense / total * 100);

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // Pie chart di tengah dengan batas tinggi maksimal
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 160,
            maxWidth: 220,
          ),
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 36,
              sections: [
                PieChartSectionData(
                  value: income,
                  color: Colors.green,
                  title: "${incomePct.toStringAsFixed(0)}%",
                  titleStyle: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  radius: 60,
                ),
                PieChartSectionData(
                  value: expense,
                  color: Colors.red,
                  title: "${expensePct.toStringAsFixed(0)}%",
                  titleStyle: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  radius: 60,
                ),
              ],
              pieTouchData: PieTouchData(enabled: true),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            _legendDot(Colors.green, 'Pemasukan', income, incomePct),
            _legendDot(Colors.red, 'Pengeluaran', expense, expensePct),
          ],
        ),
      ),
    ],
  );
}

Widget _legendDot(Color color, String label, double value, double percent) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        "$label: Rp ${_formatCurrency(value)} • ${percent.toStringAsFixed(0)}%",
        style: const TextStyle(fontSize: 12),
      ),
    ],
  );
}

Widget _recentTransactionsCard() {
  if (recent.isEmpty) return const SizedBox.shrink();

  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.receipt_long, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text(
                    'Transaksi Terbaru',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TransactionsScreen()),
                ),
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...recent.map((t) {
            final amt = ((t['amount'] ?? t['nominal'] ?? 0) as num).toDouble();
            final title = (t['description'] ?? t['note'] ?? t['category_name'] ?? 'Transaksi').toString();
            final created = t['created_at']?.toString() ?? '';
            final isIncome = amt > 0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: isIncome ? Colors.green : Colors.red,
                  child: Icon(
                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                title: Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  created,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                trailing: Text(
                  'Rp ${_formatCurrency(amt.abs())}',
                  style: TextStyle(
                    color: isIncome ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    ),
  );
}

  Widget _monthlyChart() {
    if (monthly.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            "Belum ada data bulanan",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    final spotsIncome = <FlSpot>[];
    final spotsExpense = <FlSpot>[];
    double maxY = 0;
    for (int i = 0; i < monthly.length; i++) {
      final m = monthly[i];
      final inc = ((m["total_income"] ?? 0) as num).toDouble();
      final exp = ((m["total_expense"] ?? 0) as num).toDouble();
      spotsIncome.add(FlSpot(i.toDouble(), inc));
      spotsExpense.add(FlSpot(i.toDouble(), exp));
      maxY = [maxY, inc, exp].reduce((a, b) => a > b ? a : b);
    }
    maxY = (maxY * 1.15).clamp(10.0, double.infinity);

    return SizedBox(
      height: 240,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  int idx = value.toInt();
                  if (idx < 0 || idx >= monthly.length) return const Text("");
                  final m = monthly[idx];
                  final label = (m["month"] ?? m["label"] ?? "").toString();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(label, style: const TextStyle(fontSize: 11)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, interval: maxY / 4),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.indigo.shade700,
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spotsIncome,
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              dotData: FlDotData(show: false),
            ),
            LineChartBarData(
              spots: spotsExpense,
              isCurved: true,
              color: Colors.red,
              barWidth: 3,
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _budgetBarChart() {
    if (budgets.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            "Belum ada data budget",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    // compute robust maxY with margin so bars tidak melewati batas
    double maxY = 0;
    final processed = <Map<String, double>>[];
    for (var b in budgets) {
      final limitRaw = (b["limit_amount"] ?? b["LimitAmount"] ?? 0);
      final spentRaw = (b["total_expense"] ?? b["TotalExpense"] ?? 0);

      final limit = (limitRaw is num)
          ? limitRaw.toDouble()
          : double.tryParse('$limitRaw') ?? 0.0;
      final spent = (spentRaw is num)
          ? spentRaw.toDouble()
          : double.tryParse('$spentRaw') ?? 0.0;

      // ensure we have a positive cap for visualization
      final effectiveLimit = limit > 0
          ? limit
          : (spent > 0 ? spent * 1.2 : 10.0);
      processed.add({"limit": effectiveLimit, "spent": spent});
      maxY = math.max(maxY, math.max(effectiveLimit, spent));
    }

    // add headroom so bars don't touch the top
    maxY = (maxY * 1.25).clamp(10.0, double.infinity);

    // create bar groups
    final groups = processed.asMap().entries.map((entry) {
      final idx = entry.key;
      final data = entry.value;
      return BarChartGroupData(
        x: idx,
        barRods: [
          // limit (background)
          BarChartRodData(
            fromY: 0,
            toY: data["limit"]!,
            width: 12,
            color: Colors.blue.withOpacity(0.25),
            borderRadius: BorderRadius.circular(6),
          ),
          // spent (foreground)
          BarChartRodData(
            fromY: 0,
            toY: data["spent"]!,
            width: 12,
            color: data["spent"]! > data["limit"]!
                ? Colors.redAccent
                : Colors.green,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
        barsSpace: 6,
      );
    }).toList();

    // bottom labels (rotate to avoid overlap)
    Widget bottomTitle(double value, TitleMeta meta) {
      final idx = value.toInt();
      if (idx < 0 || idx >= budgets.length) return const SizedBox.shrink();
      final text =
          budgets[idx]["category_name"] ??
          budgets[idx]["CategoryName"] ??
          "Total";
      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 8,
        child: Transform.rotate(
          angle: -math.pi / 6,
          alignment: Alignment.centerLeft,
          child: Text(
            text.toString(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11),
          ),
        ),
      );
    }

    final mqw = MediaQuery.of(context).size.width;
    // Estimate required width per group to avoid horizontal overflow
    final double groupWidth = 48.0; // bar + spacing
    final double minWidth = mqw - 32; // leave some padding
    final double chartWidth = math.max(minWidth, budgets.length * groupWidth + 80);

    return SizedBox(
      height: 280,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: chartWidth,
          height: 280,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            minY: 0,
            barGroups: groups,
            alignment: BarChartAlignment.spaceAround,
            groupsSpace: math.max(
              12,
              (24 - budgets.length.toDouble()).clamp(4, 24),
            ),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: Colors.indigo,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final idx = group.x.toInt();
                  final b = budgets[idx];
                  final category = b["category_name"] ?? b["CategoryName"] ?? "Total";
                  final val = rod.toY.toStringAsFixed(0);
                  final label = rodIndex == 0 ? "Limit" : "Terpakai";
                  return BarTooltipItem("$category\n$label: $val", const TextStyle(color: Colors.white));
                },
              ),
              touchCallback: (event, response) {
                if (response == null || response.spot == null) return;
                final idx = response.spot!.touchedBarGroupIndex;
                if (idx >= 0 && idx < budgets.length) {
                  _showBudgetQuickDetail(budgets[idx]);
                }
              },
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: bottomTitle,
                  reservedSize: 60,
                  interval: 1,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: maxY / 4,
                  reservedSize: 48,
                  getTitlesWidget: (value, meta) {
                    return Text(value.toStringAsFixed(0), style: const TextStyle(fontSize: 11));
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawHorizontalLine: true,
              checkToShowHorizontalLine: (v) => v % (maxY / 4) == 0,
            ),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    ),
  );
  }

  Widget _budgetStatusList() {
    if (budgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: budgets.map((b) {
        final status = b["status"] ?? "";
        Color color;
        switch (status) {
          case "Over Budget":
            color = Colors.red;
            break;
          case "Near Limit":
            color = Colors.orange;
            break;
          default:
            color = Colors.green;
        }

        final category = b["category_name"] ?? b["CategoryName"] ?? "Total";
        final limit = ((b["limit_amount"] ?? b["LimitAmount"] ?? 0) as num)
            .toDouble();
        final spent = ((b["total_expense"] ?? b["TotalExpense"] ?? 0) as num)
            .toDouble();
        final percent = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1,
          child: ListTile(
            onTap: () => _showBudgetQuickDetail(b),
            leading: CircleAvatar(
              backgroundColor: percent >= 1.0
                  ? Colors.redAccent
                  : (percent > 0.7 ? Colors.orange : Colors.indigo),
              child: Text(
                category.isNotEmpty ? category[0].toUpperCase() : "B",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              category,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: percent,
                  minHeight: 6,
                  backgroundColor: Colors.grey[200],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      "${spent.toStringAsFixed(0)} / ${limit.toStringAsFixed(0)}",
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(status),
                      backgroundColor: color.withOpacity(0.12),
                    ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BudgetScreen()),
                );
              },
            ),
          ),
        );
      }).toList(),
    );
  }
}
