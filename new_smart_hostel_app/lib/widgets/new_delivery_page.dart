import 'package:flutter/material.dart';
import 'package:new_smart_hostel_app/services/constants.dart';
import 'package:new_smart_hostel_app/services/delivery_api.dart';
import 'package:new_smart_hostel_app/services/razorpay_service.dart';
import '../models/delivery_models.dart';
import '../services/auth_service.dart';

class NewDeliveryPage extends StatefulWidget {
  final String? token;

  const NewDeliveryPage({super.key, this.token});

  @override
  State<NewDeliveryPage> createState() => _NewDeliveryPageState();
}

class _NewDeliveryPageState extends State<NewDeliveryPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController detailsController = TextEditingController();
  final TextEditingController companyOtpController = TextEditingController();
  final TextEditingController completionOtpController = TextEditingController();
  String? selectedPriority;
  bool _isSubmitting = false;
  String? _paymentId;

  String pickupOption = "Self"; // added
  Map<String, TextEditingController> controllers = {
    "Name": TextEditingController(),
    "ID": TextEditingController(),
    "Phone": TextEditingController(),
    "Owner Contact": TextEditingController(),
    "Relationship": TextEditingController(),
    "Pickup Time": TextEditingController(),
  };

  late RazorpayService _razorpayService;

  List<Map<String, TextEditingController>> itemsControllers = [
    {
      "item": TextEditingController(),
      "quantity": TextEditingController(text: "1"),
      "address": TextEditingController(),
      "company": TextEditingController(),
    }
  ];

  @override
  void initState() {
    super.initState();
    _razorpayService = RazorpayService();
  }

  @override
  void dispose() {
    detailsController.dispose();
    companyOtpController.dispose();
    completionOtpController.dispose();
    for (var item in itemsControllers) {
      item.values.forEach((c) => c.dispose());
    }
    for (var c in controllers.values) {
      c.dispose();
    }
    _razorpayService.dispose();
    super.dispose();
  }

  void _addItemField() {
    setState(() {
      itemsControllers.add({
        "item": TextEditingController(),
        "quantity": TextEditingController(text: "1"),
        "address": TextEditingController(),
        "company": TextEditingController(),
      });
    });
  }

  void _removeItemField(int index) {
    setState(() {
      itemsControllers[index].values.forEach((c) => c.dispose());
      itemsControllers.removeAt(index);
    });
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF1E1E2C),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.blue),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.blueDark, width: 2),
      ),
    );
  }

  Widget _buildItemCard(int index, Map<String, TextEditingController> item) {
    return Card(
      color: const Color(0xFF111827),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: item["item"],
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Item Name"),
              validator: (v) => v == null || v.isEmpty ? "Enter item name" : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: item["quantity"],
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Quantity"),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? "Enter quantity" : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: item["address"],
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Address"),
              validator: (v) => v == null || v.isEmpty ? "Enter address" : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: item["company"],
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Company / Vendor"),
            ),
            if (itemsControllers.length > 1)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                  onPressed: () => _removeItemField(index),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _priorityDropdownItem(String p) {
    Color color;
    String emoji;
    switch (p) {
      case "High":
        color = Colors.redAccent;
        emoji = "🚨";
        break;
      case "Medium":
        color = Colors.amber;
        emoji = "⚠️";
        break;
      case "Low":
        color = Colors.green;
        emoji = "✅";
        break;
      default:
        color = Colors.white;
        emoji = "";
    }
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 16),
        const SizedBox(width: 8),
        Text("$emoji $p", style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  Future<void> _handleReviewAndPay() async {
    const int totalAmount = 50;
    final paymentId = await _razorpayService.processPayment(totalAmount, context);
    if (paymentId != null) {
      setState(() => _paymentId = paymentId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Payment Successful!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Payment failed or cancelled.")),
      );
    }
  }

  Future<void> _submitDelivery() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final studentId = await AuthService.getStudentId();

      if (studentId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Student ID not found. Login again.")),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final pickupAddress = itemsControllers[0]["address"]!.text.trim();

      List<DeliveryItem> localItems = [];
      List<Map<String, dynamic>> backendItems = [];

      for (var itemCtrl in itemsControllers) {
        int quantity = int.tryParse(itemCtrl["quantity"]!.text.trim()) ?? 1;
        final itemName = itemCtrl["item"]!.text.trim();
        final address = itemCtrl["address"]!.text.trim();
        final company = itemCtrl["company"]!.text.trim();

        localItems.add(
          DeliveryItem(
            itemId: 0,
            deliveryId: 0,
            itemName: itemName,
            quantity: quantity,
            address: address,
            company: company.isNotEmpty ? company : null,
          ),
        );

        backendItems.add({
          "name": itemName,
          "quantity": quantity,
          "drop_address": address,
          "agent_id": null,
          "company": company.isNotEmpty ? company : null,
        });
      }

      // ✅ Fix: alternate_receiver must always be a list
      final alternateReceiver = pickupOption == "Friend"
          ? [
        controllers.entries.map((e) => {
          "key": e.key,
          "value": e.value.text.trim(),
        }).toList()
      ].expand((e) => e).toList()
          : [];

      final deliveryPayload = {
        "student_id": studentId,
        "pickup_address": pickupAddress,
        "items": backendItems,
        "payment_id": _paymentId,
        "price": localItems.fold<double>(0, (sum, item) => sum + (item.quantity * 50.0)),
        "priority": selectedPriority ?? "Low",
        "alternate_receiver": alternateReceiver,
        "company_otp": companyOtpController.text.trim(),
        "completion_otp": completionOtpController.text.trim(),
        "is_test_mode": true,
      };

      final createdDelivery =
      await DeliveryApi.createDelivery(deliveryPayload, widget.token ?? "");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Delivery Added Successfully!")),
      );

      if (mounted) Navigator.pop(context, createdDelivery);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to add delivery: $e")),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendFieldConfigs = [
      {"key": "Name", "label": "Friend Name", "required": true},
      {"key": "ID", "label": "Friend College ID", "required": true},
      {"key": "Phone", "label": "Friend Phone", "required": true},
      {"key": "Owner Contact", "label": "Owner Contact", "required": false},
      {"key": "Relationship", "label": "Relationship / Notes", "required": false},
      {"key": "Pickup Time", "label": "Pickup Time", "required": false},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("📦 New Delivery"),
        backgroundColor: AppColors.blue,
      ),
      backgroundColor: AppColors.cardBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ...itemsControllers
                  .asMap()
                  .entries
                  .map((entry) => _buildItemCard(entry.key, entry.value))
                  .toList(),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _addItemField,
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text(
                  "Add Another Item",
                  style: TextStyle(color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blueDark,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: detailsController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Notes / Details"),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                dropdownColor: AppColors.cardBg,
                decoration: _inputDecoration("Priority"),
                items: ["High", "Medium", "Low"]
                    .map((p) => DropdownMenuItem(
                    value: p, child: _priorityDropdownItem(p)))
                    .toList(),
                onChanged: (val) => setState(() => selectedPriority = val),
                validator: (v) => v == null ? "Select priority" : null,
              ),
              const SizedBox(height: 22),
              DropdownButtonFormField<String>(
                value: pickupOption,
                dropdownColor: AppColors.cardBg,
                decoration: _inputDecoration("Pickup Option"),
                items: const ["Self", "Friend"]
                    .map((p) => DropdownMenuItem(
                  value: p,
                  child: Text(p, style: TextStyle(color: Colors.white)),
                ))
                    .toList(),
                onChanged: (val) => setState(() => pickupOption = val!),
              ),
              const SizedBox(height: 18),
              if (pickupOption == "Friend")
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: friendFieldConfigs.map((f) {
                    final key = f['key'] as String;
                    String hint = "";
                    switch (key) {
                      case "Name":
                        hint = "Enter friend name";
                        break;
                      case "ID":
                        hint = "Enter friend college ID";
                        break;
                      case "Phone":
                        hint = "Enter friend phone number";
                        break;
                      case "Owner Contact":
                        hint = "Enter owner contact";
                        break;
                      case "Relationship":
                        hint = "Enter relationship or notes";
                        break;
                      case "Pickup Time":
                        hint = "Enter pickup time (optional)";
                        break;
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: TextFormField(
                        controller: controllers[key],
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: f['label'] as String,
                          hintText: hint,
                          labelStyle: const TextStyle(color: Colors.white70),
                        ),
                        validator: f['required'] == true
                            ? (v) => v == null || v.isEmpty
                            ? "Enter ${f['label']}"
                            : null
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 22),
              TextFormField(
                controller: companyOtpController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Company OTP"),
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: completionOtpController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Completion OTP"),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _handleReviewAndPay,
                icon: const Icon(Icons.payment, color: Colors.black),
                label: const Text(
                  "Review & Pay",
                  style: TextStyle(color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade200,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: (_paymentId != null && !_isSubmitting)
                    ? _submitDelivery
                    : null,
                child: Text(
                  (_paymentId != null)
                      ? "Add Delivery 🚀"
                      : "Complete Payment First",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
