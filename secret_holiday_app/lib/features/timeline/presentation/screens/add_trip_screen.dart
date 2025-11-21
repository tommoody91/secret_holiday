import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/presentation/widgets/widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/trip_provider.dart';

class AddTripScreen extends ConsumerStatefulWidget {
  final String groupId;

  const AddTripScreen({
    super.key,
    required this.groupId,
  });

  @override
  ConsumerState<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends ConsumerState<AddTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tripNameController = TextEditingController();
  final _destinationController = TextEditingController();
  final _countryController = TextEditingController();
  final _summaryController = TextEditingController();
  final _budgetController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  // Note: Trip preferences (adventurousness, foodFocus, urbanVsNature, budgetFlexibility, pacePreference)
  // will be moved to AI Planning feature when implemented. These preferences guide AI suggestions
  // for trip planning rather than being manually set during trip creation.
  // For now, we use default values (50) for all preferences.

  @override
  void dispose() {
    _tripNameController.dispose();
    _destinationController.dispose();
    _countryController.dispose();
    _summaryController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)), // 2 years
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  String _formatDateRange() {
    if (_startDate == null || _endDate == null) {
      return 'Select dates';
    }

    final formatter = DateFormat('MMM d, yyyy');
    return '${formatter.format(_startDate!)} - ${formatter.format(_endDate!)}';
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null || _endDate == null) {
      AppSnackBar.show(
        context: context,
        message: 'Please select trip dates',
        type: SnackBarType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Read the notifier before async operations to avoid using disposed ref
      final notifier = ref.read(tripProvider.notifier);
      
      // Use default preference values (50) - these will be set via AI Planning in the future
      final trip = await notifier.createTrip(
            groupId: widget.groupId,
            tripName: _tripNameController.text.trim(),
            destination: _destinationController.text.trim(),
            country: _countryController.text.trim(),
            countryCode: 'XX', // TODO: Implement country code lookup
            startDate: _startDate!,
            endDate: _endDate!,
            summary: _summaryController.text.trim(),
            budgetPerPerson: int.parse(_budgetController.text.trim()),
            adventurousness: 50, // Default - will be set by AI Planning
            foodFocus: 50, // Default - will be set by AI Planning
            urbanVsNature: 50, // Default - will be set by AI Planning
            budgetFlexibility: 50, // Default - will be set by AI Planning
            pacePreference: 50, // Default - will be set by AI Planning
          );

      if (!mounted) return;

      // Pop the add trip screen first
      context.pop();
      
      // Show success message
      AppSnackBar.show(
        context: context,
        message: 'Trip added successfully!',
        type: SnackBarType.success,
      );

      // Navigate to trip details
      context.push('/trip/${trip.id}', extra: {
        'groupId': widget.groupId,
      });
    } catch (e) {
      if (!mounted) return;
      
      AppSnackBar.show(
        context: context,
        message: 'Failed to add trip: ${e.toString()}',
        type: SnackBarType.error,
      );
      
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Trip'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Trip Name
            CustomTextField(
              controller: _tripNameController,
              label: 'Trip Name',
              hint: 'e.g., Summer Vacation 2025',
              prefixIcon: Icons.flight_takeoff,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Trip name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Destination
            CustomTextField(
              controller: _destinationController,
              label: 'Destination',
              hint: 'e.g., Paris, Tokyo, New York',
              prefixIcon: Icons.location_on,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Destination is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Country
            CustomTextField(
              controller: _countryController,
              label: 'Country',
              hint: 'e.g., France, Japan, USA',
              prefixIcon: Icons.public,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Country is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date Range Picker
            InkWell(
              onTap: _selectDateRange,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trip Dates',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDateRange(),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: _startDate == null
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Budget Per Person
            CustomTextField(
              controller: _budgetController,
              label: 'Budget Per Person',
              hint: '1000',
              prefixIcon: Icons.attach_money,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Budget is required';
                }
                if (int.tryParse(value) == null) {
                  return 'Must be a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Summary/Description
            CustomTextField(
              controller: _summaryController,
              label: 'Description',
              hint: 'What are you planning for this trip?',
              prefixIcon: Icons.notes,
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Description is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Submit Button
            PrimaryButton(
              text: 'Add Trip',
              onPressed: _isLoading ? null : _handleSubmit,
              isLoading: _isLoading,
              icon: Icons.add,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
