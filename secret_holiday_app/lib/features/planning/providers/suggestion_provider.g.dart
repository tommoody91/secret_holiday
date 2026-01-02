// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suggestion_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier for managing wizard state

@ProviderFor(SuggestionWizard)
const suggestionWizardProvider = SuggestionWizardProvider._();

/// Notifier for managing wizard state
final class SuggestionWizardProvider
    extends $NotifierProvider<SuggestionWizard, SuggestionWizardState> {
  /// Notifier for managing wizard state
  const SuggestionWizardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'suggestionWizardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$suggestionWizardHash();

  @$internal
  @override
  SuggestionWizard create() => SuggestionWizard();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SuggestionWizardState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SuggestionWizardState>(value),
    );
  }
}

String _$suggestionWizardHash() => r'039164b6787c0a18763917888bdfcd0df06174cf';

/// Notifier for managing wizard state

abstract class _$SuggestionWizard extends $Notifier<SuggestionWizardState> {
  SuggestionWizardState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<SuggestionWizardState, SuggestionWizardState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SuggestionWizardState, SuggestionWizardState>,
              SuggestionWizardState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
