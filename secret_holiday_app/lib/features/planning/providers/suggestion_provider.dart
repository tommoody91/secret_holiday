import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/models/suggestion_model.dart';
import '../data/services/suggestion_service.dart';

part 'suggestion_provider.g.dart';

/// State for the suggestion wizard
class SuggestionWizardState {
  final int currentStep;
  final int totalSteps;
  
  // Step 1: Budget
  final int budgetPerPerson;
  
  // Step 2: Travelers
  final int travelers;
  
  // Step 3: Travel dates
  final TravelDateType dateType;
  final String? selectedMonth;
  final List<String> selectedMonths;
  final DateTime? startDate;
  final DateTime? endDate;
  
  // Step 4: Starting location
  final String startingLocation;
  
  // Trip length
  final int tripLengthNights;
  
  // Results
  final bool isLoading;
  final String? error;
  final SuggestionResponse? results;

  const SuggestionWizardState({
    this.currentStep = 0,
    this.totalSteps = 4,
    this.budgetPerPerson = 200,
    this.travelers = 2,
    this.dateType = TravelDateType.month,
    this.selectedMonth,
    this.selectedMonths = const [],
    this.startDate,
    this.endDate,
    this.startingLocation = '',
    this.tripLengthNights = 3,
    this.isLoading = false,
    this.error,
    this.results,
  });

  SuggestionWizardState copyWith({
    int? currentStep,
    int? totalSteps,
    int? budgetPerPerson,
    int? travelers,
    TravelDateType? dateType,
    String? selectedMonth,
    List<String>? selectedMonths,
    DateTime? startDate,
    DateTime? endDate,
    String? startingLocation,
    int? tripLengthNights,
    bool? isLoading,
    String? error,
    SuggestionResponse? results,
    bool clearResults = false,
    bool clearError = false,
  }) {
    return SuggestionWizardState(
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      budgetPerPerson: budgetPerPerson ?? this.budgetPerPerson,
      travelers: travelers ?? this.travelers,
      dateType: dateType ?? this.dateType,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedMonths: selectedMonths ?? this.selectedMonths,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startingLocation: startingLocation ?? this.startingLocation,
      tripLengthNights: tripLengthNights ?? this.tripLengthNights,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      results: clearResults ? null : (results ?? this.results),
    );
  }

  /// Check if we can proceed to the next step
  bool canProceed() {
    switch (currentStep) {
      case 0: // Budget
        return budgetPerPerson > 0;
      case 1: // Travelers
        return travelers > 0;
      case 2: // Dates
        if (dateType == TravelDateType.month) {
          return selectedMonth != null;
        } else if (dateType == TravelDateType.flexible) {
          return selectedMonths.isNotEmpty;
        } else {
          return startDate != null && endDate != null;
        }
      case 3: // Location
        return startingLocation.trim().isNotEmpty;
      default:
        return false;
    }
  }

  /// Build the request from current state
  SuggestionRequest buildRequest() {
    TravelDates travelDates;
    
    switch (dateType) {
      case TravelDateType.month:
        travelDates = TravelDates.forMonth(selectedMonth!);
      case TravelDateType.flexible:
        travelDates = TravelDates.forFlexibleMonths(selectedMonths);
      case TravelDateType.specific:
        String formatDate(DateTime d) => 
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        travelDates = TravelDates.forSpecificDates(
          formatDate(startDate!),
          formatDate(endDate!),
        );
    }

    return SuggestionRequest(
      startingLocation: startingLocation,
      travelDates: travelDates,
      budgetPerPerson: budgetPerPerson,
      travelers: travelers,
      tripLengthNights: tripLengthNights,
    );
  }
}

/// Notifier for managing wizard state
@riverpod
class SuggestionWizard extends _$SuggestionWizard {
  @override
  SuggestionWizardState build() {
    return const SuggestionWizardState();
  }

  /// Initialize with group defaults
  void initializeWithGroupDefaults({
    required int budgetPerPerson,
    required int memberCount,
  }) {
    state = state.copyWith(
      budgetPerPerson: budgetPerPerson,
      travelers: memberCount,
    );
  }

  /// Go to next step
  void nextStep() {
    if (state.currentStep < state.totalSteps - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  /// Go to previous step
  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  /// Go to specific step
  void goToStep(int step) {
    if (step >= 0 && step < state.totalSteps) {
      state = state.copyWith(currentStep: step);
    }
  }

  /// Update budget
  void setBudget(int budget) {
    state = state.copyWith(budgetPerPerson: budget);
  }

  /// Update travelers
  void setTravelers(int count) {
    state = state.copyWith(travelers: count);
  }

  /// Update date type
  void setDateType(TravelDateType type) {
    state = state.copyWith(dateType: type);
  }

  /// Select a single month
  void selectMonth(String month) {
    state = state.copyWith(selectedMonth: month);
  }

  /// Toggle a month in flexible selection
  void toggleMonth(String month) {
    final current = List<String>.from(state.selectedMonths);
    if (current.contains(month)) {
      current.remove(month);
    } else {
      current.add(month);
    }
    state = state.copyWith(selectedMonths: current);
  }

  /// Set specific date range
  void setDateRange(DateTime start, DateTime end) {
    state = state.copyWith(startDate: start, endDate: end);
  }

  /// Update starting location
  void setStartingLocation(String location) {
    state = state.copyWith(startingLocation: location);
  }

  /// Update trip length
  void setTripLength(int nights) {
    state = state.copyWith(tripLengthNights: nights);
  }

  /// Submit and get suggestions
  Future<void> getSuggestions() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Please log in to get suggestions',
        );
        return;
      }

      final token = await user.getIdToken();
      if (token == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Authentication error',
        );
        return;
      }

      final request = state.buildRequest();
      final result = await SuggestionService.getSuggestions(
        request: request,
        authToken: token,
      );

      if (result.isSuccess && result.data != null) {
        state = state.copyWith(
          isLoading: false,
          results: result.data,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error ?? 'Failed to get suggestions',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An error occurred: ${e.toString()}',
      );
    }
  }

  /// Reset wizard to initial state
  void reset() {
    state = const SuggestionWizardState();
  }

  /// Clear results only
  void clearResults() {
    state = state.copyWith(clearResults: true);
  }
}
