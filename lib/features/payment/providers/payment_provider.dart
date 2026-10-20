import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';

final paymentMethodsProvider = FutureProvider<List<PaymentMethodModel>>((ref) {
  return ref.read(apiServiceProvider).getPaymentMethods();
});

final subscriptionPlansProvider = FutureProvider.family<List<AccessDurationModel>, String>((ref, currency) async {
  final pending = ref.watch(pendingEnrollmentSubjectsProvider);
  final enrolledCount = pending.isNotEmpty
      ? pending.length
      : (ref.watch(authProvider).user?.enrolledSubjectIds.length ?? 0);
  return AccessDurationModel.getDefaultsForSubjects(currency, enrolledCount);
});

final paymentHistoryProvider = FutureProvider<List<PaymentModel>>((ref) {
  return ref.read(apiServiceProvider).getPaymentHistory();
});

class PaymentFlowState {
  final int step;
  final AccessDurationModel? selectedDuration;
  final PaymentMethodModel? selectedMethod;
  final bool isLoading;
  final String? error;
  final PayChanguCheckout? checkout;
  final bool isSuccess;
  final String currency;

  const PaymentFlowState({
    this.step = 0,
    this.selectedDuration,
    this.selectedMethod,
    this.isLoading = false,
    this.error,
    this.checkout,
    this.isSuccess = false,
    this.currency = 'MWK',
  });

  PaymentFlowState copyWith({
    int? step,
    AccessDurationModel? selectedDuration,
    PaymentMethodModel? selectedMethod,
    bool? isLoading,
    String? error,
    PayChanguCheckout? checkout,
    bool? isSuccess,
    String? currency,
    bool clearError = false,
    bool clearInit = false,
  }) {
    return PaymentFlowState(
      step: step ?? this.step,
      selectedDuration: selectedDuration ?? this.selectedDuration,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      checkout: clearInit ? null : (checkout ?? this.checkout),
      isSuccess: isSuccess ?? this.isSuccess,
      currency: currency ?? this.currency,
    );
  }
}

class PaymentFlowNotifier extends StateNotifier<PaymentFlowState> {
  final ApiService _apiService;

  PaymentFlowNotifier(this._apiService) : super(const PaymentFlowState());

  void selectCurrency(String currency) {
    state = state.copyWith(currency: currency);
  }

  void selectDuration(AccessDurationModel duration) {
    state = state.copyWith(selectedDuration: duration, step: 1);
  }

  void selectMethod(PaymentMethodModel method) {
    state = state.copyWith(selectedMethod: method, step: 2);
  }

  void goBack() {
    if (state.step > 0) {
      state = state.copyWith(step: state.step - 1);
    }
  }

  Future<PayChanguCheckout?> initializePayChangu(List<int> subjectIds) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final checkout = await _apiService.initializePayChanguPayment(
        subjectIds: subjectIds,
        durationMonths: state.selectedDuration!.months,
        currency: state.currency,
      );
      if (checkout.checkoutUrl.isEmpty) throw Exception('No checkout URL');
      state = state.copyWith(checkout: checkout, isLoading: false);
      return checkout;
    } catch (e) {
      String msg = 'Failed to start payment. Please try again.';
      if (e is DioException && e.response?.data is Map) {
        msg = e.response?.data['message']?.toString() ?? msg;
      }
      state = state.copyWith(isLoading: false, error: msg);
      return null;
    }
  }

  /// Asks the server to confirm with PayChangu. Returns 'success', 'pending' or 'failed'.
  Future<String> verifyPayChangu(String txRef) async {
    state = state.copyWith(isLoading: true);
    try {
      final status = await _apiService.verifyPayChanguPayment(txRef);
      state = state.copyWith(isLoading: false, isSuccess: status == 'success');
      return status;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return 'pending';
    }
  }

  Future<bool> submitManualPayment({
    String? proofPath,
    String? transactionRef,
    List<int>? subjectIds,
    String? gradeLevel,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _apiService.submitManualPayment(
        methodId: state.selectedMethod!.id,
        amount: state.selectedDuration!.price,
        currency: state.currency,
        durationMonths: state.selectedDuration!.months,
        subjectIds: subjectIds,
        gradeLevel: gradeLevel,
        proofPath: proofPath,
        transactionReference: transactionRef,
      );
      final statusOk = result['status'] == true || result['status'] == 'success';
      final hasData = result['data'] != null;
      final hasMessage = result['message'] != null;
      final ok = statusOk || hasData || hasMessage;
      state = state.copyWith(isLoading: false, isSuccess: ok);
      if (!ok) {
        state = state.copyWith(error: 'Payment submission failed. Please try again.');
      }
      return ok;
    } catch (e) {
      String userMsg = 'Failed to submit payment. Please try again.';
      if (e is DioException) {
        final status = e.response?.statusCode;
        final data = e.response?.data;
        if (data is Map) {
          final serverMsg = data['message']?.toString() ?? '';
          final errors = data['errors'];
          if (errors is Map && errors.isNotEmpty) {
            userMsg = errors.values
                .map((v) => v is List ? v.first.toString() : v.toString())
                .join('\n');
          } else if (serverMsg.isNotEmpty) {
            userMsg = serverMsg;
          } else if (status == 422) {
            userMsg = 'Invalid payment details. Please check and try again.';
          } else if (status == 401) {
            userMsg = 'Session expired. Please log in again.';
          }
        } else if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          userMsg = 'No internet connection. Please check your connection.';
        }
      }
      state = state.copyWith(isLoading: false, error: userMsg);
      return false;
    }
  }

  void reset() {
    state = const PaymentFlowState();
  }
}

final paymentFlowProvider =
    StateNotifierProvider<PaymentFlowNotifier, PaymentFlowState>((ref) {
  return PaymentFlowNotifier(ref.read(apiServiceProvider));
});

final pendingEnrollmentSubjectsProvider = StateProvider<List<int>>((ref) => []);
