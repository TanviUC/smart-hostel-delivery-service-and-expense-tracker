import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ExpenseStatsPage extends StatefulWidget {
  const ExpenseStatsPage({Key? key}) : super(key: key);

  @override
  State<ExpenseStatsPage> createState() => _ExpenseStatsPageState();
}

// ✅ SnackBar Helper (Fade in + Fade out)
mixin SnackBarHelper<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  void showExpenseSnackBar(
      BuildContext context,
      Map<String, dynamic> expense,
      NumberFormat currencyFormat,
      Map<String, String> typeEmojis,
      ) {
    final controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 400),
      vsync: this,
    );

    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.black.withOpacity(0.85),
      duration: const Duration(seconds: 5), // auto-hide after 5s
      content: FadeTransition(
        opacity: animation, // 🎬 fade-in/out
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              typeEmojis[expense['type']] ?? "💰",
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${expense['name']} • ${currencyFormat.format(expense['amount'])}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "${expense['type']} • ${DateFormat('dd MMM, HH:mm').format(expense['date'])}",
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    controller.forward();

    // When Snackbar closes → fade out smoothly
    ScaffoldMessenger.of(context)
        .showSnackBar(snackBar)
        .closed
        .then((_) => controller.reverse());
  }
}

class _ExpenseStatsPageState extends State<ExpenseStatsPage>
    with TickerProviderStateMixin, SnackBarHelper {
  List<Map<String, dynamic>> expenses = [];
  String selectedTypeFilter = "All";
  String selectedDateSort = "Recent";
  String chartType = "Line"; // Line, Bar, Pie

  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  final List<String> types = ["All", "Food", "Travel", "Shopping", "Other"];

  final Map<String, String> typeEmojis = {
    "Food": "🍕",
    "Travel": "🛫",
    "Shopping": "🛒",
    "Other": "💰",
  };

  final Map<String, Color> typeColors = {
    "Food": Color(0xFFfca5a5),
    "Travel": Color(0xFF7dd3fc),
    "Shopping": Color(0xFFd8b4fe),
    "Other": Color(0xFFfde68a),
  };

  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  // -------------------- EXPENSE FUNCTIONS -------------------- //
  void addExpense() {
    nameController.clear();
    amountController.clear();
    showDialog(
      context: context,
      builder: (context) {
        String selectedType = "Other";
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title:
          const Text("Add Expense", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: "Name",
                    labelStyle: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: "Amount",
                    labelStyle: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedType,
                dropdownColor: Colors.grey[900],
                style: const TextStyle(color: Colors.white),
                items: types
                    .where((t) => t != "All")
                    .map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(
                    "${typeEmojis[t]} $t",
                    style: TextStyle(color: typeColors[t]),
                  ),
                ))
                    .toList(),
                onChanged: (val) => selectedType = val!,
                decoration: const InputDecoration(
                    labelText: "Type",
                    labelStyle: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.amber)),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    amountController.text.isNotEmpty) {
                  setState(() {
                    expenses.add({
                      "name": nameController.text,
                      "amount": double.tryParse(amountController.text) ?? 0,
                      "type": selectedType,
                      "date": DateTime.now(),
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Add", style: TextStyle(color: Colors.amber)),
            ),
          ],
        );
      },
    );
  }

  void editExpense(int index) {
    final expense = expenses[index];
    nameController.text = expense['name'];
    amountController.text = expense['amount'].toString();
    String selectedType = expense['type'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title:
          const Text("Edit Expense", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: "Name",
                    labelStyle: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: "Amount",
                    labelStyle: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedType,
                dropdownColor: Colors.grey[900],
                style: const TextStyle(color: Colors.white),
                items: types
                    .where((t) => t != "All")
                    .map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(
                    "${typeEmojis[t]} $t",
                    style: TextStyle(color: typeColors[t]),
                  ),
                ))
                    .toList(),
                onChanged: (val) => selectedType = val!,
                decoration: const InputDecoration(
                    labelText: "Type",
                    labelStyle: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
              const Text("Cancel", style: TextStyle(color: Colors.amber)),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    amountController.text.isNotEmpty) {
                  setState(() {
                    expenses[index] = {
                      "name": nameController.text,
                      "amount": double.tryParse(amountController.text) ?? 0,
                      "type": selectedType,
                      "date": expense['date'],
                    };
                  });
                  Navigator.pop(context);
                }
              },
              child:
              const Text("Update", style: TextStyle(color: Colors.amber)),
            ),
          ],
        );
      },
    );
  }

  void deleteExpense(int index) {
    setState(() {
      expenses.removeAt(index);
    });
  }

  // -------------------- FILTER + CHART DATA -------------------- //
  List<Map<String, dynamic>> get filteredExpenses {
    List<Map<String, dynamic>> list = selectedTypeFilter == "All"
        ? List.from(expenses)
        : expenses.where((e) => e['type'] == selectedTypeFilter).toList();

    if (selectedDateSort == "Recent") {
      list.sort((a, b) => b['date'].compareTo(a['date']));
    } else {
      list.sort((a, b) => a['date'].compareTo(b['date']));
    }

    return list;
  }

  List<FlSpot> get lineChartData {
    return List.generate(
        filteredExpenses.length,
            (index) =>
            FlSpot(index.toDouble(), filteredExpenses[index]['amount']));
  }

  List<BarChartGroupData> get barChartData {
    return List.generate(filteredExpenses.length, (index) {
      final amount = filteredExpenses[index]['amount'];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(toY: amount, color: Colors.blue[300], width: 16)
        ],
      );
    });
  }

  Map<String, double> get pieChartData {
    Map<String, double> map = {};
    for (var e in filteredExpenses) {
      map[e['type']] = (map[e['type']] ?? 0) + e['amount'];
    }
    return map;
  }

  double get averageAmount {
    if (filteredExpenses.isEmpty) return 0;
    return filteredExpenses.fold(0.0, (sum, e) => sum + e['amount']) /
        filteredExpenses.length;
  }

  Color getCategoryColor(String category) {
    return typeColors[category] ?? Colors.white;
  }

  // -------------------- SMART SUGGESTIONS -------------------- //
  Widget buildSuggestions() {
    if (expenses.isEmpty) return const SizedBox();

    DateTime now = DateTime.now();
    DateTime weekStart = now.subtract(Duration(days: now.weekday - 1));

    double weeklyFood = expenses
        .where((e) => e['type'] == "Food" && e['date'].isAfter(weekStart))
        .fold(0.0, (sum, e) => sum + e['amount']);

    double totalWeekly = expenses
        .where((e) => e['date'].isAfter(weekStart))
        .fold(0.0, (sum, e) => sum + e['amount']);

    String suggestion = "";
    if (totalWeekly > 0) {
      double percent = (weeklyFood / totalWeekly) * 100;
      if (percent > 30) {
        suggestion =
        "You spent ${percent.toStringAsFixed(0)}% on food this week 🍕";
      } else {
        suggestion = "Try setting a ₹500 weekly limit 💡";
      }
    }

    return suggestion.isEmpty
        ? const SizedBox()
        : Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.blue[200]?.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12)),
      child: Text(
        suggestion,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text("💸 Expenses Dashboard",
            style: TextStyle(color: Colors.white)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        child: const Icon(Icons.add),
        onPressed: addExpense,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------- FILTERS ROW -------------------- //
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Category Filter
                Row(
                  children: [
                    const Icon(Icons.filter_list, color: Colors.amber),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: selectedTypeFilter,
                      dropdownColor: Colors.grey[900],
                      style: const TextStyle(color: Colors.white),
                      items: types
                          .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(
                          t == "All" ? t : "${typeEmojis[t]} $t",
                          style: TextStyle(
                              color: t == "All"
                                  ? Colors.white
                                  : typeColors[t]),
                        ),
                      ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => selectedTypeFilter = val!),
                    ),
                  ],
                ),

                // Date Sort Filter
                Row(
                  children: [
                    const Icon(Icons.schedule, color: Colors.amber),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: selectedDateSort,
                      dropdownColor: Colors.grey[900],
                      style: const TextStyle(color: Colors.white),
                      items: ["Recent", "Oldest"]
                          .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(
                          t,
                          style: TextStyle(
                              color: t == "Recent"
                                  ? Color(0xFF86efac)
                                  : Color(0xFFfca5a5)),
                        ),
                      ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => selectedDateSort = val!),
                    ),
                  ],
                ),

                // Chart Type
                Row(
                  children: [
                    const Icon(Icons.show_chart, color: Colors.amber),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: chartType,
                      dropdownColor: Colors.grey[900],
                      style: const TextStyle(color: Colors.white),
                      items: ["Line", "Bar", "Pie"]
                          .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(
                          t,
                          style: TextStyle(
                            color: t == "Line"
                                ? Color(0xFF86efac)
                                : t == "Bar"
                                ? Color(0xFFfcd34d)
                                : Color(0xFFfca5a5),
                          ),
                        ),
                      ))
                          .toList(),
                      onChanged: (val) => setState(() => chartType = val!),
                    ),
                  ],
                ),
              ],
            ),

            // -------------------- SMART SUGGESTIONS -------------------- //
            buildSuggestions(),

            const SizedBox(height: 20),

            // -------------------- CHART -------------------- //
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12)),
              child: chartType == "Line"
                  ? SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                        show: true, drawVerticalLine: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          getTitlesWidget: (value, meta) => Text(
                            currencyFormat.format(value),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index < 0 ||
                                index >= filteredExpenses.length) {
                              return const SizedBox();
                            }
                            return Text(
                              filteredExpenses[index]['name'],
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey[700]!),
                    ),

                    // ✅ Line chart tooltip
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchCallback: (event, response) {
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.lineBarSpots == null) return;

                        final spot = response.lineBarSpots!.first;
                        final expense =
                        filteredExpenses[spot.spotIndex];
                        showExpenseSnackBar(context, expense,
                            currencyFormat, typeEmojis);
                      },
                    ),

                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        if (filteredExpenses.isNotEmpty)
                          HorizontalLine(
                            y: averageAmount,
                            color: Colors.redAccent,
                            strokeWidth: 2,
                            dashArray: [6, 4],
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.topRight,
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold),
                              labelResolver: (_) => 'Avg',
                            ),
                          ),
                      ],
                    ),

                    lineBarsData: [
                      LineChartBarData(
                        spots: lineChartData,
                        isCurved: true,
                        color: Colors.amber,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              )
                  : chartType == "Bar"
                  ? SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchCallback: (event, response) {
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.spot == null) return;

                        final index = response.spot!.touchedBarGroupIndex;
                        if (index >= 0 &&
                            index < filteredExpenses.length) {
                          final expense = filteredExpenses[index];
                          showExpenseSnackBar(context, expense,
                              currencyFormat, typeEmojis);
                        }
                      },
                    ),
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          getTitlesWidget: (value, meta) => Text(
                            currencyFormat.format(value),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index < 0 ||
                                index >= filteredExpenses.length) {
                              return const SizedBox();
                            }
                            return Text(
                              filteredExpenses[index]['name'],
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: barChartData,
                  ),
                ),
              )
                  : SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: pieChartData.entries
                        .map((e) => PieChartSectionData(
                      value: e.value,
                      color: getCategoryColor(e.key),
                      title:
                      "${typeEmojis[e.key]} ${e.value.toStringAsFixed(0)}",
                      radius: 60,
                      titleStyle: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ))
                        .toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    pieTouchData: PieTouchData(
                      enabled: true,
                      touchCallback: (event, response) {
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.touchedSection == null) return;

                        final index = response
                            .touchedSection!.touchedSectionIndex;
                        if (index >= 0 &&
                            index < pieChartData.keys.length) {
                          final key = pieChartData.keys.toList()[index];
                          final amount = pieChartData[key] ?? 0.0;
                          final expense = {
                            "name": key,
                            "amount": amount,
                            "type": key,
                            "date": DateTime.now(),
                          };
                          showExpenseSnackBar(context, expense,
                              currencyFormat, typeEmojis);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

        // -------------------- EXPENSES LIST -------------------- //
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredExpenses.length,
          itemBuilder: (context, index) {
            final expense = filteredExpenses[index];
            return Card(
              color: Colors.grey[800],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Text(
                  typeEmojis[expense['type']] ?? "💰",
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(
                  expense['name'],
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "${expense['type']} • ${DateFormat('dd MMM yyyy').format(expense['date'])}",
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✏️ Edit Button with confirmation
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.amber),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Colors.grey[900],
                            title: const Text("Confirm Edit",
                                style: TextStyle(color: Colors.white)),
                            content: const Text(
                              "Do you want to edit this expense? ✏️",
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text("Cancel",
                                    style: TextStyle(color: Colors.amber)),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx); // close confirm
                                  editExpense(index); // open edit dialog
                                },
                                child: const Text("Yes, Edit",
                                    style: TextStyle(color: Colors.greenAccent)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // 🗑️ Delete Button with confirmation
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Colors.grey[900],
                            title: const Text("Confirm Delete",
                                style: TextStyle(color: Colors.white)),
                            content: const Text(
                              "Are you sure you want to delete this expense? 🗑️",
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text("Cancel",
                                    style: TextStyle(color: Colors.amber)),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    expenses.removeAt(index);
                                  });
                                  Navigator.pop(ctx);
                                },
                                child: const Text("Yes, Delete",
                                    style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                onTap: () => showExpenseSnackBar(
                    context, expense, currencyFormat, typeEmojis),
              ),
            );
          },
        ),
          ],
        ),
      ),
    );
  }
}
