import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:new_smart_hostel_app/services/constants.dart';
import '../models/delivery_models.dart';

class DeliveryDetailsPage extends StatefulWidget {
  final DeliveryRequest delivery;

  const DeliveryDetailsPage({super.key, required this.delivery});

  @override
  State<DeliveryDetailsPage> createState() => _DeliveryDetailsPageState();
}

class _DeliveryDetailsPageState extends State<DeliveryDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final delivery = widget.delivery;
    final hasAlternateReceiver = delivery.alternateReceiver.values
        .any((v) => v.toString().trim().isNotEmpty);

    // Reusable Row with Icon and Text
    Widget detailRow(IconData icon, String text, {Color? color}) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF93C5FD), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color ?? Colors.white70, fontSize: 14),
            ),
          ),
        ],
      );
    }

    // Reusable Card
    Widget infoCard(String title, List<Widget> children, {IconData? icon}) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null)
                  Icon(icon, color: const Color(0xFF93C5FD), size: 18),
                if (icon != null) const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFBFDBFE),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...children
          ],
        ),
      );
    }

    // Items section
    List<Widget> itemCards = delivery.items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return infoCard(
        "Item ${index + 1}",
        [
          detailRow(Icons.inventory_2, "Name: ${item.itemName}"),
          detailRow(Icons.format_list_numbered, "Quantity: ${item.quantity}"),
          detailRow(Icons.location_on, "Address: ${item.address}"),
          if (item.company != null && item.company!.isNotEmpty)
            detailRow(Icons.business, "Company: ${item.company}"),
        ],
        icon: Icons.shopping_bag,
      );
    }).toList();

    // Alternate receiver card
    Widget? friendCard;
    if (hasAlternateReceiver) {
      friendCard = Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ExpansionTile(
          iconColor: const Color(0xFF93C5FD),
          collapsedIconColor: const Color(0xFF93C5FD),
          title: const Row(
            children: [
              Icon(Icons.person_add, color: Color(0xFF93C5FD)),
              SizedBox(width: 6),
              Text(
                "Alternate Receiver",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          children: delivery.alternateReceiver.entries
              .where((e) => e.value.toString().trim().isNotEmpty)
              .map(
                (e) => ListTile(
              leading:
              const Icon(Icons.person, color: Color(0xFF93C5FD)),
              title: Text("${e.key}: ${e.value}",
                  style: const TextStyle(color: Colors.white70)),
            ),
          )
              .toList(),
        ),
      );
    }

    // Tracking logs
    List<Widget> trackingCards =
    delivery.trackingLogs.asMap().entries.map((entry) {
      final t = entry.value;
      return infoCard(
        DateFormat('dd MMM yyyy, hh:mm a').format(t.createdAt.toLocal()),
        [
          detailRow(
            Icons.check_circle,
            t.status,
            color: t.status.toLowerCase().contains("completed")
                ? Colors.greenAccent
                : const Color(0xFFFBBF24),
          ),
          if (t.location != null && t.location!.isNotEmpty)
            detailRow(Icons.location_on, t.location!),
        ],
        icon: Icons.timeline,
      );
    }).toList();

    // Flags section
    List<Widget> flagCards = delivery.flags
        .map(
          (f) => infoCard(
        "Flag",
        [
          detailRow(Icons.flag, "${f.flaggedBy} - ${f.reason} (${f.status})",
              color: const Color(0xFFFCA5A5)),
        ],
        icon: Icons.report_problem,
      ),
    )
        .toList();

    // Payment Status Card
    Widget paymentCard = infoCard(
      "Payment Status",
      [
        detailRow(
          Icons.payment,
          delivery.paymentStatus == "Paid" ? "Paid ✅" : "Pending ⏳",
          color: delivery.paymentStatus == "Paid" ? Colors.greenAccent : const Color(0xFFFBBF24),
        ),
      ],
      icon: Icons.payment,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: Text(
          delivery.studentName != null && delivery.studentName!.isNotEmpty
              ? "Hi ${delivery.studentName}"
              : "Delivery Details",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFBFDBFE),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            infoCard(
              "Summary",
              [
                detailRow(Icons.priority_high,
                    "Priority: ${delivery.priority.isNotEmpty ? delivery.priority : 'Normal'}"),
                detailRow(
                    Icons.access_time_filled,
                    delivery.isCompleted ? "Completed ✅" : "Pending ⏳",
                    color: delivery.isCompleted
                        ? Colors.greenAccent
                        : const Color(0xFFFBBF24)),
              ],
              icon: Icons.info_outline,
            ),
            paymentCard, // ✅ Added Payment Status Card
            ...itemCards,
            if (friendCard != null) friendCard,
            if (delivery.description != null &&
                delivery.description!.isNotEmpty)
              infoCard(
                "Notes",
                [
                  Text(delivery.description!,
                      style: const TextStyle(color: Colors.white70)),
                ],
                icon: Icons.note_alt,
              ),
            ...flagCards,
            if (trackingCards.isNotEmpty)
              infoCard("Tracking Logs", trackingCards, icon: Icons.local_shipping),
          ],
        ),
      ),
    );
  }
}
