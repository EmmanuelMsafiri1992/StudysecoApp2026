class AppConstants {
  static const String appName = 'StudySeco';
  static const String appTagline = 'Malawian Secondary Education Platform';

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://192.168.137.155:8000/api',
  );
  static const String paystackPublicKey = 'pk_live_YOUR_PAYSTACK_PUBLIC_KEY';
  static const String paystackBaseUrl = 'https://api.paystack.co';
  static const String paystackCallbackUrl = 'https://studyseco.com/payment/callback';

  static const List<String> forms = ['Form 1', 'Form 2', 'Form 3', 'Form 4'];

  static const List<String> subjects = [
    'Mathematics',
    'English',
    'Biology',
    'Chemistry',
    'Physics',
    'History',
    'Geography',
    'Chichewa',
    'Agriculture',
    'Commerce',
    'Accounting',
    'French',
    'Computer Studies',
    'Life Skills',
    'Physical Education',
    'Religious Studies',
    'Social Studies',
    'Art',
    'Music',
  ];

  static const List<String> currencies = [
    'MWK',
    'USD',
    'ZAR',
    'GBP',
    'EUR',
    'KES',
    'ZMW',
    'GHS',
    'NGN',
  ];

  static const Map<String, String> currencySymbols = {
    'MWK': 'MK',
    'USD': '\$',
    'ZAR': 'R',
    'GBP': '£',
    'EUR': '€',
    'KES': 'KSh',
    'ZMW': 'ZK',
    'GHS': 'GH₵',
    'NGN': '₦',
  };

  static const Map<String, String> countryToCurrency = {
    'MW': 'MWK',
    'ZA': 'ZAR',
    'US': 'USD',
    'GB': 'GBP',
    'KE': 'KES',
    'ZM': 'ZMW',
    'GH': 'GHS',
    'NG': 'NGN',
  };

  static const int connectTimeoutSeconds = 30;
  static const int receiveTimeoutSeconds = 30;

  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String onboardingKey = 'onboarding_done';
  static const String currencyKey = 'selected_currency';
}
