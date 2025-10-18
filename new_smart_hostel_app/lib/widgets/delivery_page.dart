import 'package:flutter/material.dart';
import 'package:new_smart_hostel_app/services/constants.dart';
import '../models/delivery_models.dart';
import 'new_delivery_page.dart';
import 'package:new_smart_hostel_app/services/delivery_api.dart';

class DeliveryPage extends StatefulWidget {
  final String token;

  const DeliveryPage({super.key, required this.token});

  @override
  State<DeliveryPage> createState() => _DeliveryPageState();
}

class _DeliveryPageState extends State<DeliveryPage> {
  String statusFilter = "All";
  String priorityFilter = "All";
  String sortBy = "Recent";
  String pickupFilter = "All"; // New filter

  final statusOptions = ["All", "Pending", "Completed"];
  final priorityOptions = ["All", "High", "Medium", "Low"];
  final sortOptions = ["Recent", "Priority ↑", "Priority ↓"];
  final pickupOptions = ["All", "Self", "Friend"]; // New filter options

  List<DeliveryRequest> deliveries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchDeliveries();
  }

  Future<void> _fetchDeliveries() async {
    setState(() => _loading = true);
    try {
      final fetched = await DeliveryApi.fetchDeliveries(widget.token);
      setState(() {
        deliveries = fetched;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch deliveries: $e")),
      );
    }
  }

  void _addLocalDelivery(DeliveryRequest newDelivery) {
    setState(() {
      deliveries.insert(0, newDelivery);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Apply filters
    List<DeliveryRequest> filteredDeliveries = deliveries.where((delivery) {
      final statusMatch = (statusFilter == "All") ||
          (statusFilter == "Pending" && !delivery.isCompleted) ||
          (statusFilter == "Completed" && delivery.isCompleted);

      final priorityMatch = (priorityFilter == "All") ||
          (priorityFilter.toLowerCase() == delivery.priority.toLowerCase());

      final pickupMatch = (pickupFilter == "All") ||
          (pickupFilter == "Self" && (delivery.alternateReceiver == null || delivery.alternateReceiver.isEmpty)) ||
          (pickupFilter == "Friend" && delivery.alternateReceiver != null && delivery.alternateReceiver.isNotEmpty);

      return statusMatch && priorityMatch && pickupMatch;
    }).toList();

    // Apply sorting
    if (sortBy.contains("Priority")) {
      filteredDeliveries.sort((a, b) {
        int rank(String p) {
          switch (p.toLowerCase()) {
            case "high":
              return 3;
            case "medium":
              return 2;
            case "low":
              return 1;
            default:
              return 0;
          }
        }

        return sortBy.contains("↑")
            ? rank(a.priority).compareTo(rank(b.priority))
            : rank(b.priority).compareTo(rank(a.priority));
      });
    } else {
      filteredDeliveries = filteredDeliveries.reversed.toList(); // Recent first
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            const SizedBox(height: 16),
            const Text(
              "Your Deliveries 📦",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Filters row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildDropdown(
                    width: 140,
                    value: statusFilter,
                    options: statusOptions,
                    label: "Status",
                    itemBuilder: _buildStatusItem,
                    onChanged: (v) => setState(() => statusFilter = v!),
                  ),
                  const SizedBox(width: 16),
                  _buildDropdown(
                    width: 140,
                    value: priorityFilter,
                    options: priorityOptions,
                    label: "Priority",
                    itemBuilder: _buildFilterItem,
                    onChanged: (v) => setState(() => priorityFilter = v!),
                  ),
                  const SizedBox(width: 16),
                  _buildDropdown(
                    width: 140,
                    value: pickupFilter,
                    options: pickupOptions,
                    label: "Pickup",
                    itemBuilder: _buildPickupItem,
                    onChanged: (v) => setState(() => pickupFilter = v!),
                  ),
                  const SizedBox(width: 16),
                  _buildDropdown(
                    width: 140,
                    value: sortBy,
                    options: sortOptions,
                    label: "Sort By",
                    itemBuilder: _buildSortItem,
                    onChanged: (v) => setState(() => sortBy = v!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Deliveries list
            Expanded(
              child: filteredDeliveries.isEmpty
                  ? const Center(
                child: Text(
                  "No deliveries found!",
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              )
                  : RefreshIndicator(
                onRefresh: _fetchDeliveries,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredDeliveries.length,
                  itemBuilder: (_, index) =>
                      DeliveryCard(delivery: filteredDeliveries[index]),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.blueDark,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () async {
          final newDelivery = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NewDeliveryPage(token: widget.token),
            ),
          );

          if (newDelivery != null && newDelivery is DeliveryRequest) {
            _addLocalDelivery(newDelivery); // Add to local list
          }
        },
      ),
    );
  }

  // --- Dropdown builder ---
  Widget _buildDropdown({
    required double width,
    required String value,
    required List<String> options,
    required String label,
    required Widget Function(String) itemBuilder,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: AppColors.cardBg,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
        ),
        style: const TextStyle(color: Colors.white),
        items: options
            .map((s) => DropdownMenuItem(value: s, child: itemBuilder(s)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildStatusItem(String s) {
    final emoji = s == "Pending" ? "⏳" : s == "Completed" ? "✅" : "📦";
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(s, style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  Widget _buildFilterItem(String f) {
    Color color = f == "High"
        ? Colors.red
        : f == "Medium"
        ? Colors.orange
        : f == "Low"
        ? Colors.green
        : AppColors.blueDark;
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 14),
        const SizedBox(width: 6),
        Text(f, style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  Widget _buildPickupItem(String p) {
    String emoji = p == "Self" ? "🫱" : p == "Friend" ? "👫" : "📦";
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(p, style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  Widget _buildSortItem(String s) {
    IconData icon = s.contains("Priority") ? Icons.flash_on : Icons.schedule;
    Color iconColor =
    s.contains("Priority") ? Colors.orangeAccent : Colors.lightBlueAccent;
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 6),
        Text(s, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}

// ---------------- DeliveryCard ----------------
class DeliveryCard extends StatelessWidget {
  final DeliveryRequest delivery;

  const DeliveryCard({super.key, required this.delivery});

  @override
  Widget build(BuildContext context) {
    Color priorityColor;
    switch (delivery.priority?.toLowerCase() ?? "") {
      case "high":
        priorityColor = Colors.red;
        break;
      case "medium":
        priorityColor = Colors.orange;
        break;
      case "low":
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.white70;
    }

    final itemNames = (delivery.items.isNotEmpty)
        ? delivery.items.map((e) => e.itemName).join(", ")
        : "No items";

    return Card(
      color: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(itemNames,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text("Details: ${delivery.description ?? 'No details'}",
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            Text("Priority: ${delivery.priority ?? 'N/A'}",
                style:
                TextStyle(color: priorityColor, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(delivery.isCompleted ? "✅ Completed" : "⏳ Pending",
                style: TextStyle(
                    color:
                    delivery.isCompleted ? Colors.greenAccent : Colors.white70,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
