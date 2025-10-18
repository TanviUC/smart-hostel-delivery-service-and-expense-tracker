/// -----------------
/// Delivery Item Model
/// -----------------
class DeliveryItem {
  final int itemId;
  final int deliveryId; // backend key = delivery_id
  final String itemName;
  final int quantity;
  final String address;
  final String? company;

  DeliveryItem({
    required this.itemId,
    required this.deliveryId,
    required this.itemName,
    required this.quantity,
    required this.address,
    this.company,
  });

  factory DeliveryItem.fromJson(Map<String, dynamic> json) => DeliveryItem(
    itemId: json['item_id'] ?? 0,
    deliveryId: json['delivery_id'] ?? 0,
    itemName: json['item_name'] ?? "Unknown Item",
    quantity: json['quantity'] ?? 1,
    address: json['address'] ?? "Unknown Address",
    company: json['company'],
  );

  Map<String, dynamic> toJson() => {
    'item_id': itemId,
    'delivery_id': deliveryId,
    'item_name': itemName,
    'quantity': quantity,
    'address': address,
    'company': company,
  };
}

/// -----------------
/// Delivery Flag Model
/// -----------------
class DeliveryFlag {
  final int flagId;
  final int requestId;
  final String flaggedBy;
  final String reason;
  final String status;
  final DateTime flagTime;

  DeliveryFlag({
    required this.flagId,
    required this.requestId,
    required this.flaggedBy,
    required this.reason,
    required this.status,
    required this.flagTime,
  });

  factory DeliveryFlag.fromJson(Map<String, dynamic> json) => DeliveryFlag(
    flagId: json['flag_id'] ?? 0,
    requestId: json['request_id'] ?? 0,
    flaggedBy: json['flagged_by'] ?? "Unknown",
    reason: json['reason'] ?? "No reason",
    status: json['status'] ?? "pending",
    flagTime: DateTime.parse(
        json['flag_time'] ?? DateTime.now().toIso8601String()),
  );

  Map<String, dynamic> toJson() => {
    'flag_id': flagId,
    'request_id': requestId,
    'flagged_by': flaggedBy,
    'reason': reason,
    'status': status,
    'flag_time': flagTime.toIso8601String(),
  };
}

/// -----------------
/// Delivery Tracking Log Model
/// -----------------
class DeliveryTrackingLog {
  final int logId;
  final int requestId;
  final String status;
  final String? location;
  final DateTime createdAt;

  DeliveryTrackingLog({
    required this.logId,
    required this.requestId,
    required this.status,
    this.location,
    required this.createdAt,
  });

  factory DeliveryTrackingLog.fromJson(Map<String, dynamic> json) =>
      DeliveryTrackingLog(
        logId: json['logID'] ?? 0,
        requestId: json['request_id'] ?? 0,
        status: json['status'] ?? "Unknown",
        location: json['location'],
        createdAt: DateTime.parse(
            json['created_at'] ?? DateTime.now().toIso8601String()),
      );

  Map<String, dynamic> toJson() => {
    'logID': logId,
    'request_id': requestId,
    'status': status,
    'location': location,
    'created_at': createdAt.toIso8601String(),
  };
}

/// -----------------
/// Delivery Request Model
/// -----------------
class DeliveryRequest {
  final int requestId;
  final int studentId;
  final String? studentName;
  final int? agentId;
  final String priority;
  final String? description;
  final double? price;
  final String? status;
  final bool isActive;
  final bool isCompleted;
  final String? completionOtp;
  final String? companyOtp;
  final Map<String, dynamic> alternateReceiver;
  final List<DeliveryItem> items;
  final List<DeliveryFlag> flags;
  final List<DeliveryTrackingLog> trackingLogs;

  // NEW FIELDS FOR PAYMENT
  final String? paymentId;
  final double? amount;
  final String? paymentStatus;

  // NEW FIELDS FOR UI
  final String? pickupOption;
  final Map<String, String>? friendDetails;

  DeliveryRequest({
    required this.requestId,
    required this.studentId,
    this.studentName,
    this.agentId,
    required this.priority,
    this.description,
    this.price,
    this.status,
    required this.isActive,
    this.isCompleted = false,
    this.completionOtp,
    this.companyOtp,
    Map<String, dynamic>? alternateReceiver,
    List<DeliveryItem>? items,
    List<DeliveryFlag>? flags,
    List<DeliveryTrackingLog>? trackingLogs,
    this.paymentId,
    this.amount,
    this.paymentStatus,
    this.pickupOption,
    this.friendDetails,
  })  : alternateReceiver = alternateReceiver ??
      {
        "Name": "Unknown",
        "Phone": "0000000000",
        "Address": items != null && items.isNotEmpty
            ? items[0].address
            : "Unknown Address"
      },
        items = items ?? [],
        flags = flags ?? [],
        trackingLogs = trackingLogs ?? [];

  factory DeliveryRequest.fromJson(Map<String, dynamic> json) {
    final itemList = (json['items'] as List?)
        ?.map((i) => DeliveryItem.fromJson(i))
        .toList() ??
        [];

    final addr = itemList.isNotEmpty ? itemList[0].address : "Unknown Address";

    final altReceiver = json['alternate_receiver'] != null
        ? Map<String, dynamic>.from(json['alternate_receiver'])
        : {"Name": "Unknown", "Phone": "0000000000", "Address": addr};

    final flagList = (json['flags'] as List?)
        ?.map((f) => DeliveryFlag.fromJson(f))
        .toList() ??
        [];

    final trackingList = (json['tracking_logs'] as List?)
        ?.map((t) => DeliveryTrackingLog.fromJson(t))
        .toList() ??
        [];

    double? parsedPrice;
    if (json['price'] != null) {
      if (json['price'] is String) {
        parsedPrice = double.tryParse(json['price']);
      } else if (json['price'] is num) {
        parsedPrice = (json['price'] as num).toDouble();
      }
    }

    double? parsedAmount;
    if (json['amount'] != null) {
      if (json['amount'] is String) {
        parsedAmount = double.tryParse(json['amount']);
      } else if (json['amount'] is num) {
        parsedAmount = (json['amount'] as num).toDouble();
      }
    }

    return DeliveryRequest(
      requestId: json['request_id'] ?? 0,
      studentId: json['student_id'] ?? 0,
      studentName: json['student_name'],
      agentId: json['agent_id'],
      priority: json['priority'] ?? "Low",
      description: json['description'],
      price: parsedPrice ?? 0.0,
      status: json['status'],
      isActive: json['is_active'] ?? true,
      isCompleted: json['is_completed'] ?? false,
      completionOtp: json['completion_otp'],
      companyOtp: json['company_otp'],
      alternateReceiver: altReceiver,
      items: itemList,
      flags: flagList,
      trackingLogs: trackingList,
      paymentId: json['payment_id'],
      amount: parsedAmount,
      paymentStatus: json['payment_status'],
      pickupOption: json['pickup_option'],
      friendDetails: json['friend_details'] != null
          ? Map<String, String>.from(json['friend_details'])
          : null,
    );
  }

  DeliveryRequest copyWith({
    bool? isCompleted,
    String? companyOtp,
  }) {
    return DeliveryRequest(
      requestId: requestId,
      studentId: studentId,
      studentName: studentName,
      agentId: agentId,
      priority: priority,
      description: description,
      price: price,
      status: status,
      isActive: isActive,
      isCompleted: isCompleted ?? this.isCompleted,
      completionOtp: completionOtp,
      companyOtp: companyOtp ?? this.companyOtp,
      alternateReceiver: alternateReceiver,
      items: items,
      flags: flags,
      trackingLogs: trackingLogs,
      paymentId: paymentId,
      amount: amount,
      paymentStatus: paymentStatus,
      pickupOption: pickupOption,
      friendDetails: friendDetails,
    );
  }

  Map<String, dynamic> toJson() => {
    'request_id': requestId,
    'student_id': studentId,
    'student_name': studentName,
    'agent_id': agentId,
    'priority': priority,
    'description': description,
    'price': price,
    'status': status,
    'is_active': isActive,
    'is_completed': isCompleted,
    'completion_otp': completionOtp,
    'company_otp': companyOtp,
    'alternate_receiver': alternateReceiver,
    'items': items.map((i) => i.toJson()).toList(),
    'flags': flags.map((f) => f.toJson()).toList(),
    'tracking_logs': trackingLogs.map((t) => t.toJson()).toList(),
    'payment_id': paymentId,
    'amount': amount,
    'payment_status': paymentStatus,
    'pickup_option': pickupOption,
    'friend_details': friendDetails,
  };
}
