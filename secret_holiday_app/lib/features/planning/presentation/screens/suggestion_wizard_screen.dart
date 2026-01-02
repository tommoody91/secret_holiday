import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../groups/data/models/group_model.dart';
import '../../../groups/providers/group_provider.dart';
import '../../data/models/suggestion_model.dart';
import '../../providers/suggestion_provider.dart';
import 'suggestion_results_screen.dart';

/// Wizard screen for collecting trip search criteria
class SuggestionWizardScreen extends ConsumerStatefulWidget {
  final GroupModel group;

  const SuggestionWizardScreen({
    super.key,
    required this.group,
  });

  @override
  ConsumerState<SuggestionWizardScreen> createState() => _SuggestionWizardScreenState();
}

class _SuggestionWizardScreenState extends ConsumerState<SuggestionWizardScreen> {
  final _locationController = TextEditingController();
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    // Initialize with group defaults
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(suggestionWizardProvider.notifier).initializeWithGroupDefaults(
            budgetPerPerson: widget.group.rules.budgetPerPerson,
            memberCount: widget.group.members.length,
          );
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    final state = ref.read(suggestionWizardProvider);
    if (state.canProceed()) {
      if (state.currentStep == state.totalSteps - 1) {
        // Last step - submit
        _submit();
      } else {
        ref.read(suggestionWizardProvider.notifier).nextStep();
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _previousStep() {
    ref.read(suggestionWizardProvider.notifier).previousStep();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submit() async {
    await ref.read(suggestionWizardProvider.notifier).getSuggestions();
    
    final state = ref.read(suggestionWizardProvider);
    if (state.results != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SuggestionResultsScreen(
            response: state.results!,
            groupId: widget.group.id,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(suggestionWizardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Destinations'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(state, theme),
          
          // Step content
          Expanded(
            child: state.isLoading
                ? _buildLoadingState(theme)
                : state.error != null
                    ? _buildErrorState(state, theme)
                    : PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildBudgetStep(state, theme),
                          _buildTravelersStep(state, theme),
                          _buildDatesStep(state, theme),
                          _buildLocationStep(state, theme),
                        ],
                      ),
          ),
          
          // Navigation buttons
          if (!state.isLoading && state.error == null)
            _buildNavigationButtons(state, theme),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(SuggestionWizardState state, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            children: List.generate(state.totalSteps, (index) {
              final isActive = index <= state.currentStep;
              final isCurrent = index == state.currentStep;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < state.totalSteps - 1 ? 8 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary
                        : AppColors.textSecondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            _getStepTitle(state.currentStep),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Set Your Budget';
      case 1:
        return 'Number of Travelers';
      case 2:
        return 'When Do You Want to Go?';
      case 3:
        return 'Where Are You Starting From?';
      default:
        return '';
    }
  }

  Widget _buildBudgetStep(SuggestionWizardState state, ThemeData theme) {
    final groupBudget = widget.group.rules.budgetPerPerson;
    final isUsingGroupBudget = state.budgetPerPerson == groupBudget;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How much per person for flights?',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          // Group budget hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.group, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Group budget: £$groupBudget per person',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!isUsingGroupBudget) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      ref.read(suggestionWizardProvider.notifier).setBudget(groupBudget);
                    },
                    child: Text(
                      'Reset',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '£${state.budgetPerPerson}',
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Slider(
            value: state.budgetPerPerson.toDouble().clamp(50, 500),
            min: 50,
            max: 500,
            divisions: 45,
            label: '£${state.budgetPerPerson}',
            onChanged: (value) {
              ref.read(suggestionWizardProvider.notifier).setBudget(value.round());
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('£50', style: theme.textTheme.bodySmall),
              Text('£500', style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 32),
          _buildQuickBudgetButtons(state, theme),
        ],
      ),
    );
  }

  Widget _buildQuickBudgetButtons(SuggestionWizardState state, ThemeData theme) {
    final budgets = [100, 150, 200, 250, 300];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: budgets.map((budget) {
        final isSelected = state.budgetPerPerson == budget;
        return ChoiceChip(
          label: Text('£$budget'),
          selected: isSelected,
          onSelected: (_) {
            ref.read(suggestionWizardProvider.notifier).setBudget(budget);
          },
        );
      }).toList(),
    );
  }

  Widget _buildTravelersStep(SuggestionWizardState state, ThemeData theme) {
    final groupMemberCount = widget.group.members.length;
    final isUsingGroupCount = state.travelers == groupMemberCount;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How many people are traveling?',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          // Group member count hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.group, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Group has $groupMemberCount ${groupMemberCount == 1 ? 'member' : 'members'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!isUsingGroupCount) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      ref.read(suggestionWizardProvider.notifier).setTravelers(groupMemberCount);
                    },
                    child: Text(
                      'Reset',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filled(
                  onPressed: state.travelers > 1
                      ? () => ref.read(suggestionWizardProvider.notifier)
                          .setTravelers(state.travelers - 1)
                      : null,
                  icon: const Icon(Icons.remove),
                  iconSize: 32,
                ),
                const SizedBox(width: 32),
                Column(
                  children: [
                    Text(
                      '${state.travelers}',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      state.travelers == 1 ? 'person' : 'people',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 32),
                IconButton.filled(
                  onPressed: state.travelers < 20
                      ? () => ref.read(suggestionWizardProvider.notifier)
                          .setTravelers(state.travelers + 1)
                      : null,
                  icon: const Icon(Icons.add),
                  iconSize: 32,
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          Center(
            child: Text(
              'Total budget: £${state.budgetPerPerson * state.travelers}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatesStep(SuggestionWizardState state, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date type selector
          SegmentedButton<TravelDateType>(
            segments: const [
              ButtonSegment(
                value: TravelDateType.month,
                label: Text('Pick a Month'),
                icon: Icon(Icons.calendar_month),
              ),
              ButtonSegment(
                value: TravelDateType.flexible,
                label: Text('Flexible'),
                icon: Icon(Icons.date_range),
              ),
            ],
            selected: {state.dateType},
            onSelectionChanged: (selection) {
              ref.read(suggestionWizardProvider.notifier)
                  .setDateType(selection.first);
            },
          ),
          const SizedBox(height: 24),
          
          if (state.dateType == TravelDateType.month)
            _buildMonthSelector(state, theme),
          
          if (state.dateType == TravelDateType.flexible)
            _buildFlexibleMonthSelector(state, theme),
            
          const SizedBox(height: 24),
          _buildTripLengthSelector(state, theme),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(SuggestionWizardState state, ThemeData theme) {
    final now = DateTime.now();
    final months = List.generate(12, (i) {
      final date = DateTime(now.year, now.month + i);
      return (
        value: '${date.year}-${date.month.toString().padLeft(2, '0')}',
        label: DateFormat('MMMM yyyy').format(date),
        shortLabel: DateFormat('MMM').format(date),
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Which month?',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: months.length,
            itemBuilder: (context, index) {
              final month = months[index];
              final isSelected = state.selectedMonth == month.value;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(month.shortLabel),
                  selected: isSelected,
                  onSelected: (_) {
                    ref.read(suggestionWizardProvider.notifier)
                        .selectMonth(month.value);
                  },
                ),
              );
            },
          ),
        ),
        if (state.selectedMonth != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              months.firstWhere((m) => m.value == state.selectedMonth).label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFlexibleMonthSelector(SuggestionWizardState state, ThemeData theme) {
    final now = DateTime.now();
    final months = List.generate(12, (i) {
      final date = DateTime(now.year, now.month + i);
      return (
        value: '${date.year}-${date.month.toString().padLeft(2, '0')}',
        label: DateFormat('MMM yyyy').format(date),
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select preferred months (up to 3)',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: months.map((month) {
            final isSelected = state.selectedMonths.contains(month.value);
            final canSelect = isSelected || state.selectedMonths.length < 3;
            return FilterChip(
              label: Text(month.label),
              selected: isSelected,
              onSelected: canSelect
                  ? (_) => ref.read(suggestionWizardProvider.notifier)
                      .toggleMonth(month.value)
                  : null,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTripLengthSelector(SuggestionWizardState state, ThemeData theme) {
    final lengths = [
      (nights: 2, label: 'Weekend'),
      (nights: 3, label: 'Long Weekend'),
      (nights: 5, label: '5 Nights'),
      (nights: 7, label: 'Week'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trip length',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: lengths.map((length) {
            final isSelected = state.tripLengthNights == length.nights;
            return ChoiceChip(
              label: Text(length.label),
              selected: isSelected,
              onSelected: (_) {
                ref.read(suggestionWizardProvider.notifier)
                    .setTripLength(length.nights);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLocationStep(SuggestionWizardState state, ThemeData theme) {
    if (_locationController.text != state.startingLocation) {
      _locationController.text = state.startingLocation;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter your UK postcode or city',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: 'Starting Location',
              hintText: 'e.g., SW1A 1AA or London',
              prefixIcon: const Icon(Icons.location_on),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            textCapitalization: TextCapitalization.characters,
            onChanged: (value) {
              ref.read(suggestionWizardProvider.notifier)
                  .setStartingLocation(value);
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Quick select:',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'London',
              'Manchester',
              'Birmingham',
              'Edinburgh',
              'Bristol',
              'Leeds',
            ].map((city) {
              return ActionChip(
                label: Text(city),
                onPressed: () {
                  _locationController.text = city;
                  ref.read(suggestionWizardProvider.notifier)
                      .setStartingLocation(city);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(SuggestionWizardState state, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (state.currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Back'),
              ),
            ),
          if (state.currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: state.currentStep > 0 ? 1 : 2,
            child: FilledButton(
              onPressed: state.canProceed() ? _nextStep : null,
              child: Text(
                state.currentStep == state.totalSteps - 1
                    ? 'Find Destinations'
                    : 'Continue',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Finding the best destinations for you...',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Searching airports and flights',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(SuggestionWizardState state, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.error ?? 'Unknown error',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                ref.read(suggestionWizardProvider.notifier).goToStep(3);
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
