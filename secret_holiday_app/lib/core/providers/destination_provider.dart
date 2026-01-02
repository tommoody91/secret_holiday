import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/destination_repository.dart';

export '../data/destination_repository.dart' show Destination;

/// Provider for the destination repository singleton
final destinationRepositoryProvider = Provider<DestinationRepository>((ref) {
  return DestinationRepository.instance;
});

/// FutureProvider that initializes the destination repository
/// Use this to ensure data is loaded before accessing destinations
final destinationDataProvider = FutureProvider<void>((ref) async {
  final repository = ref.watch(destinationRepositoryProvider);
  await repository.initialize();
});

/// Provider for searching destinations
/// Returns a function that can be called with a query string
final destinationSearchProvider =
    Provider.family<List<Destination>, String>((ref, query) {
  final repository = ref.watch(destinationRepositoryProvider);
  if (!repository.isLoaded) return [];
  return repository.search(query);
});

/// Provider for the list of countries
final countriesProvider = Provider<List<String>>((ref) {
  final repository = ref.watch(destinationRepositoryProvider);
  if (!repository.isLoaded) return [];
  return repository.countries;
});

/// Provider for searching countries
final countrySearchProvider =
    Provider.family<List<String>, String>((ref, query) {
  final repository = ref.watch(destinationRepositoryProvider);
  if (!repository.isLoaded) return [];
  return repository.searchCountries(query);
});
