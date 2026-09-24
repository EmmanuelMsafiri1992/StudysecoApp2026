class PaymentMethodModel {
  final int id;
  final String name;
  final String type;
  final String region;
  final String? icon;
  final String? color;
  final String? description;
  final String? accountDetails;
  final List<String> currencies;

  PaymentMethodModel({
    required this.id,
    required this.name,
    required this.type,
    required this.region,
    this.icon,
    this.color,
    this.description,
    this.accountDetails,
    this.currencies = const [],
  });

  bool get isPaystack => type == 'paystack';
  bool get isInternational => region == 'international';

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      region: json['region'] ?? 'local',
      icon: json['icon'],
      color: json['color'],
      description: json['description'],
      accountDetails: json['account_details'],
      currencies: List<String>.from(json['currencies'] ?? []),
    );
  }
}

class AccessDurationModel {
  final int months;
  final String label;
  final double price;
  final String currency;
  final String? badge;

  AccessDurationModel({
    required this.months,
    required this.label,
    required this.price,
    required this.currency,
    this.badge,
  });

  static List<AccessDurationModel> getDefaults(String currency) {
    final prices = _getPrices(currency);
    return [
      AccessDurationModel(
        months: 6,
        label: '6 Months',
        price: prices[0],
        currency: currency,
      ),
      AccessDurationModel(
        months: 12,
        label: '1 Year',
        price: prices[1],
        currency: currency,
        badge: 'Popular',
      ),
      AccessDurationModel(
        months: 24,
        label: '2 Years',
        price: prices[2],
        currency: currency,
        badge: 'Best Value',
      ),
    ];
  }

  static List<double> _getPrices(String currency) {
    switch (currency.toUpperCase()) {
      case 'MWK':
        return [15000, 25000, 40000];
      case 'USD':
        return [10, 18, 30];
      case 'ZAR':
        return [180, 320, 550];
      case 'GBP':
        return [8, 14, 25];
      case 'EUR':
        return [9, 16, 28];
      case 'KES':
        return [1300, 2300, 3900];
      case 'ZMW':
        return [250, 450, 750];
      case 'GHS':
        return [150, 270, 450];
      case 'NGN':
        return [15000, 27000, 45000];
      default:
        return [10, 18, 30];
    }
  }

  static double _perSubjectPerMonth(String currency) {
    switch (currency.toUpperCase()) {
      case 'MWK': return 12500;
      case 'USD': return 8;
      case 'ZAR': return 150;
      case 'GBP': return 6;
      case 'EUR': return 7;
      case 'KES': return 1050;
      case 'ZMW': return 200;
      case 'GHS': return 120;
      case 'NGN': return 12000;
      default: return 8;
    }
  }

  static List<AccessDurationModel> getDefaultsForSubjects(String currency, int subjectCount) {
    if (subjectCount <= 0) return getDefaults(currency);
    final rate = _perSubjectPerMonth(currency);
    return [
      AccessDurationModel(
        months: 4,
        label: '4 Months',
        price: rate * 4 * subjectCount,
        currency: currency,
      ),
      AccessDurationModel(
        months: 8,
        label: '8 Months',
        price: rate * 8 * subjectCount,
        currency: currency,
        badge: 'Popular',
      ),
      AccessDurationModel(
        months: 12,
        label: '12 Months',
        price: rate * 12 * subjectCount,
        currency: currency,
        badge: 'Best Value',
      ),
    ];
  }
}

class PaymentModel {
  final int id;
  final int userId;
  final String reference;
  final double amount;
  final String currency;
  final String status;
  final String? method;
  final int? durationMonths;
  final DateTime? paidAt;
  final DateTime createdAt;
  final DateTime? expiresAt;

  PaymentModel({
    required this.id,
    required this.userId,
    required this.reference,
    required this.amount,
    required this.currency,
    required this.status,
    this.method,
    this.durationMonths,
    this.paidAt,
    required this.createdAt,
    this.expiresAt,
  });

  bool get isPaid => status == 'paid' || status == 'verified';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'],
      userId: json['user_id'],
      reference: json['reference'],
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      status: json['status'] ?? 'pending',
      method: json['method'],
      durationMonths: json['duration_months'],
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
    );
  }
}

class PaystackInitResponse {
  final bool status;
  final String message;
  final String authorizationUrl;
  final String accessCode;
  final String reference;

  PaystackInitResponse({
    required this.status,
    required this.message,
    required this.authorizationUrl,
    required this.accessCode,
    required this.reference,
  });

  factory PaystackInitResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return PaystackInitResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      authorizationUrl: data['authorization_url'] ?? '',
      accessCode: data['access_code'] ?? '',
      reference: data['reference'] ?? '',
    );
  }
}
