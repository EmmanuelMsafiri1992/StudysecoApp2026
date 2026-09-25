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
  final PaystackInitResponse? paystackInit;
  final bool isSuccess;
  final String currency;

  const PaymentFlowState({
    this.step = 0,
    this.selectedDuration,
    this.selectedMethod,
    this.isLoading = false,
    this.error,
    this.paystackInit,
    this.isSuccess = false,
    this.currency = 'MWK',
  });

  PaymentFlowState copyWith({
    int? step,
    AccessDurationModel? selectedDuration,
    PaymentMethodModel? selectedMethod,
    bool? isLoading,
    String? error,
    PaystackInitResponse? paystackInit,
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
      paystackInit: clearInit ? null : (paystackInit ?? this.paystackInit),
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

  Future<PaystackInitResponse?> initializePaystack(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final ref = 'SS_${DateTime.now().millisecondsSinceEpoch}';
      final init = await _apiService.initializePaystackPayment(
        email: email,
        amount: state.selectedDuration!.price,
        currency: state.currency,
        reference: ref,
        durationMonths: state.selectedDuration!.months,
      );
      state = state.copyWith(paystackInit: init, isLoading: false);
      return init;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Failed to initialize payment');
      return null;
    }
  }

  Future<bool> verifyPaystack(String reference) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _apiService.verifyPaystackPayment(reference);
      final success = result['data']?['status'] == 'success' ||
          result['status'] == true;
      state = state.copyWith(isLoading: false, isSuccess: success);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Payment verification failed');
      return false;
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
      final msg = e.toString();
      String userMsg = 'Failed to submit payment. Please try again.';
      if (msg.contains('422') || msg.contains('Unprocessable')) {
        userMsg = 'Invalid payment details. Please check and try again.';
      } else if (msg.contains('401') || msg.contains('Unauthorized')) {
        userMsg = 'Session expired. Please log in again.';
      } else if (msg.contains('SocketException') || msg.contains('network') || msg.contains('connection')) {
        userMsg = 'No internet connection. Please check your connection.';
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
