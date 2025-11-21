import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/presentation/widgets/widgets.dart';
import '../../providers/group_provider.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  
  // Rules
  int _budgetPerPerson = 500;
  int _maxTripDays = 7;
  String _luggageAllowance = 'Carry-on only';
  bool _noRepeatCountries = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final group = await ref.read(groupProvider.notifier).createGroup(
        name: _groupNameController.text.trim(),
        budgetPerPerson: _budgetPerPerson,
        maxTripDays: _maxTripDays,
        luggageAllowance: _luggageAllowance,
        noRepeatCountries: _noRepeatCountries,
      );

      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: 'Group "${group.name}" created!',
          type: SnackBarType.success,
        );
        context.go(RouteConstants.home);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: 'Failed to create group: ${e.toString()}',
          type: SnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(groupProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Text(
                'Create Your Travel Group',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Set your group\'s travel preferences and rules',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // Group Name
              CustomTextField(
                controller: _groupNameController,
                label: 'Group Name',
                hint: 'e.g.Adventure Seekers',
                prefixIcon: Icons.group,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a group name';
                  }
                  if (value.trim().length < 3) {
                    return 'Group name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Rules Section
              _buildSectionHeader('Travel Rules', Icons.rule),
              const SizedBox(height: 16),

              // Budget Per Person
              _buildSliderWithValue(
                label: 'Budget Per Person',
                value: _budgetPerPerson.toDouble(),
                min: 100,
                max: 1000,
                divisions: 18,
                onChanged: (value) => setState(() => _budgetPerPerson = value.round()),
                valueFormatter: (value) => '£${value.round()}',
              ),

              // Max Trip Days
              _buildSliderWithValue(
                label: 'Maximum Trip Days',
                value: _maxTripDays.toDouble(),
                min: 3,
                max: 14,
                divisions: 11,
                onChanged: (value) => setState(() => _maxTripDays = value.round()),
                valueFormatter: (value) => '${value.round()} days',
              ),

              // Luggage Allowance
              _buildDropdownField(
                label: 'Luggage Allowance',
                value: _luggageAllowance,
                items: [
                  'Carry-on only',
                  'Carry-on + personal item',
                  'One checked bag',
                  'Two checked bags',
                ],
                onChanged: (value) => setState(() => _luggageAllowance = value!),
              ),

              // No Repeat Countries
              SwitchListTile(
                title: const Text('No Repeat Countries'),
                subtitle: const Text('Each trip must be to a new country'),
                value: _noRepeatCountries,
                onChanged: (value) => setState(() => _noRepeatCountries = value),
              ),

              const SizedBox(height: 32),

              // Create Button
              PrimaryButton(
                text: 'Create Group',
                onPressed: groupState.isLoading ? null : _createGroup,
                isLoading: groupState.isLoading,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSliderWithValue({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String Function(double) valueFormatter,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              valueFormatter(value),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

}
