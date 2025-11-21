import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/presentation/widgets/widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/trip_model.dart';
import '../../providers/trip_provider.dart';

class EditTripScreen extends ConsumerStatefulWidget {
  final String groupId;
  final TripModel trip;

  const EditTripScreen({
    super.key,
    required this.groupId,
    required this.trip,
  });

  @override
  ConsumerState<EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends ConsumerState<EditTripScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tripNameController;
  late final TextEditingController _destinationController;
  late final TextEditingController _countryController;
  late final TextEditingController _summaryController;
  late final TextEditingController _budgetController;

  late DateTime _startDate;
  late DateTime _endDate;
  bool _isLoading = false;

  // Trip preferences (0-100 scale)
  late double _adventurousness;
  late double _foodFocus;
  late double _urbanVsNature;
  late double _budgetFlexibility;
  late double _pacePreference;

  @override
  void initState() {
    super.initState();
    _tripNameController = TextEditingController(text: widget.trip.tripName);
    _destinationController = TextEditingController(text: widget.trip.location.destination);
    _countryController = TextEditingController(text: widget.trip.location.country);
    _summaryController = TextEditingController(text: widget.trip.summary);
    _budgetController = TextEditingController(text: widget.trip.costPerPerson.toString());
    _startDate = widget.trip.startDate;
    _endDate = widget.trip.endDate;
    _adventurousness = widget.trip.adventurousness.toDouble();
    _foodFocus = widget.trip.foodFocus.toDouble();
    _urbanVsNature = widget.trip.urbanVsNature.toDouble();
    _budgetFlexibility = widget.trip.budgetFlexibility.toDouble();
    _pacePreference = widget.trip.pacePreference.toDouble();
  }

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
      firstDate: DateTime.now().subtract(const Duration(days: 365)), // Allow editing past trips
      lastDate: DateTime.now().add(const Duration(days: 730)), // 2 years
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
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
    final formatter = DateFormat('MMM d, yyyy');
    return '${formatter.format(_startDate)} - ${formatter.format(_endDate)}';
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Read the notifier before async operations to avoid using disposed ref
      final notifier = ref.read(tripProvider.notifier);
      
      await notifier.updateTrip(
        groupId: widget.groupId,
        tripId: widget.trip.id,
        tripName: _tripNameController.text.trim(),
        destination: _destinationController.text.trim(),
        country: _countryController.text.trim(),
        countryCode: widget.trip.location.countryCode, // Keep existing
        startDate: _startDate,
        endDate: _endDate,
        summary: _summaryController.text.trim(),
        budgetPerPerson: int.parse(_budgetController.text.trim()),
        latitude: widget.trip.location.latitude,
        longitude: widget.trip.location.longitude,
        adventurousness: _adventurousness.round(),
        foodFocus: _foodFocus.round(),
        urbanVsNature: _urbanVsNature.round(),
        budgetFlexibility: _budgetFlexibility.round(),
        pacePreference: _pacePreference.round(),
      );

      if (!mounted) return;

      // Pop the edit screen
      context.pop();
      
      // Show success message
      AppSnackBar.show(
        context: context,
        message: 'Trip updated successfully!',
        type: SnackBarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      
      AppSnackBar.show(
        context: context,
        message: 'Failed to update trip: ${e.toString()}',
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
        title: const Text('Edit Trip'),
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
                              color: AppColors.textPrimary,
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

            // Trip Preferences Section
            Text(
              'Trip Preferences',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set preferences for this specific trip',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Adventurousness
            _buildPreferenceSlider(
              label: 'Adventure Level',
              value: _adventurousness,
              leftLabel: 'Relaxing',
              rightLabel: 'Adventurous',
              onChanged: (value) => setState(() => _adventurousness = value),
            ),

            // Food Focus
            _buildPreferenceSlider(
              label: 'Food Importance',
              value: _foodFocus,
              leftLabel: 'Not Important',
              rightLabel: 'Foodie',
              onChanged: (value) => setState(() => _foodFocus = value),
            ),

            // Urban vs Nature
            _buildPreferenceSlider(
              label: 'Environment',
              value: _urbanVsNature,
              leftLabel: 'Nature',
              rightLabel: 'Urban',
              onChanged: (value) => setState(() => _urbanVsNature = value),
            ),

            // Budget Flexibility
            _buildPreferenceSlider(
              label: 'Budget Flexibility',
              value: _budgetFlexibility,
              leftLabel: 'Strict',
              rightLabel: 'Flexible',
              onChanged: (value) => setState(() => _budgetFlexibility = value),
            ),

            // Pace Preference
            _buildPreferenceSlider(
              label: 'Travel Pace',
              value: _pacePreference,
              leftLabel: 'Slow/Relaxed',
              rightLabel: 'Fast-paced',
              onChanged: (value) => setState(() => _pacePreference = value),
            ),

            const SizedBox(height: 32),

            // Submit Button
            PrimaryButton(
              text: 'Update Trip',
              onPressed: _isLoading ? null : _handleSubmit,
              isLoading: _isLoading,
              icon: Icons.save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceSlider({
    required String label,
    required double value,
    required String leftLabel,
    required String rightLabel,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                leftLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Expanded(
              child: Text(
                rightLabel,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 100,
          divisions: 20,
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
