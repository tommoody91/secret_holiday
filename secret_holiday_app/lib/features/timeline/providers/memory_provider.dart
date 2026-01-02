import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/memory_model.dart';
import '../data/repositories/memory_repository.dart';

/// Provider for memory repository
final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  return MemoryRepository();
});

/// Provider to watch all memories for a trip
final tripMemoriesProvider = StreamProvider.family<List<MemoryModel>, ({String groupId, String tripId})>(
  (ref, params) {
    final repository = ref.watch(memoryRepositoryProvider);
    return repository.watchMemories(params.groupId, params.tripId);
  },
);

/// Provider to watch memories for a specific day
final dayMemoriesProvider = StreamProvider.family<List<MemoryModel>, ({String groupId, String tripId, int dayNumber})>(
  (ref, params) {
    final repository = ref.watch(memoryRepositoryProvider);
    return repository.watchMemoriesByDay(params.groupId, params.tripId, params.dayNumber);
  },
);

/// Provider to watch memories for a specific activity
final activityMemoriesProvider = StreamProvider.family<List<MemoryModel>, ({String groupId, String tripId, String activityId})>(
  (ref, params) {
    final repository = ref.watch(memoryRepositoryProvider);
    return repository.watchMemoriesByActivity(params.groupId, params.tripId, params.activityId);
  },
);

/// Enum for memory filter type
enum MemoryFilterType { all, day, activity }

/// State for memory filtering (used locally in the widget)
class MemoryFilterState {
  final MemoryFilterType filterType;
  final int? selectedDay;
  final String? selectedActivityId;
  final String? selectedActivityName;

  const MemoryFilterState({
    this.filterType = MemoryFilterType.all,
    this.selectedDay,
    this.selectedActivityId,
    this.selectedActivityName,
  });

  /// Create a filter showing all memories
  static MemoryFilterState all() => const MemoryFilterState(filterType: MemoryFilterType.all);

  /// Create a filter for a specific day
  static MemoryFilterState forDay(int dayNumber) => MemoryFilterState(
    filterType: MemoryFilterType.day,
    selectedDay: dayNumber,
  );

  /// Create a filter for a specific activity
  static MemoryFilterState forActivity(String activityId, String activityName) => MemoryFilterState(
    filterType: MemoryFilterType.activity,
    selectedActivityId: activityId,
    selectedActivityName: activityName,
  );
}
