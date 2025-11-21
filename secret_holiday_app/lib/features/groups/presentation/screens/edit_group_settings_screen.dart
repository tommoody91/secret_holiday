import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/widgets/widgets.dart';
import '../../data/models/group_model.dart';
import '../../providers/group_provider.dart';

class EditGroupSettingsScreen extends ConsumerStatefulWidget {
  final String groupId;

  const EditGroupSettingsScreen({super.key, required this.groupId});

  @override
  ConsumerState<EditGroupSettingsScreen> createState() => _EditGroupSettingsScreenState();
}

class _EditGroupSettingsScreenState extends ConsumerState<EditGroupSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _budgetController;
  late TextEditingController _maxDaysController;
  
  String _luggageAllowance = 'Carry-on only';
  bool _noRepeatCountries = false;
  
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    _maxDaysController.dispose();
    super.dispose();
  }

  void _initializeControllers(GroupModel group) {
    if (!_isInitialized) {
      _nameController = TextEditingController(text: group.name);
      _budgetController = TextEditingController(
        text: group.rules.budgetPerPerson.toString(),
      );
      _maxDaysController = TextEditingController(
        text: group.rules.maxTripDays.toString(),
      );
      _luggageAllowance = group.rules.luggageAllowance;
      _noRepeatCountries = group.rules.noRepeatCountries;
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupRepository = ref.watch(groupRepositoryProvider);
    final theme = Theme.of(context);

    return StreamBuilder<GroupModel>(
      stream: groupRepository.getGroupStream(widget.groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: LoadingIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Edit Settings')),
            body: ErrorDisplay(
              message: 'Failed to load group: ${snapshot.error}',
              onRetry: () => setState(() {}),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Edit Settings')),
            body: const ErrorDisplay(
              message: 'Group not found',
            ),
          );
        }

        final group = snapshot.data!;
        _initializeControllers(group);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Group Settings'),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Group Name Section
                Text(
                  'Group Information',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    hintText: 'Enter group name',
                    prefixIcon: Icon(Icons.group),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a group name';
                    }
                    if (value.trim().length < 3) {
                      return 'Group name must be at least 3 characters';
                    }
                    if (value.trim().length > 50) {
                      return 'Group name must be less than 50 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Travel Rules Section
                Text(
                  'Travel Rules',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _budgetController,
                  decoration: const InputDecoration(
                    labelText: 'Budget Per Person',
                    hintText: 'Enter budget',
                    prefixIcon: Icon(Icons.attach_money),
                    suffixText: 'USD',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a budget';
                    }
                    final budget = int.tryParse(value);
                    if (budget == null) {
                      return 'Please enter a valid number';
                    }
                    if (budget < 100) {
                      return 'Budget must be at least \$100';
                    }
                    if (budget > 100000) {
                      return 'Budget must be less than \$100,000';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _maxDaysController,
                  decoration: const InputDecoration(
                    labelText: 'Maximum Trip Days',
                    hintText: 'Enter max days',
                    prefixIcon: Icon(Icons.calendar_today),
                    suffixText: 'days',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter maximum trip days';
                    }
                    final days = int.tryParse(value);
                    if (days == null) {
                      return 'Please enter a valid number';
                    }
                    if (days < 1) {
                      return 'Must be at least 1 day';
                    }
                    if (days > 365) {
                      return 'Must be less than 365 days';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _luggageAllowance,
                  decoration: const InputDecoration(
                    labelText: 'Luggage Allowance',
                    prefixIcon: Icon(Icons.luggage),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Carry-on only',
                      child: Text('Carry-on only'),
                    ),
                    DropdownMenuItem(
                      value: 'One checked bag',
                      child: Text('One checked bag'),
                    ),
                    DropdownMenuItem(
                      value: 'Two checked bags',
                      child: Text('Two checked bags'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _luggageAllowance = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 16),

                SwitchListTile(
                  title: const Text('No Repeat Countries'),
                  subtitle: const Text(
                    'Each trip must visit a different country',
                  ),
                  value: _noRepeatCountries,
                  onChanged: (value) {
                    setState(() {
                      _noRepeatCountries = value;
                    });
                  },
                  secondary: const Icon(Icons.public),
                ),

                const SizedBox(height: 32),

                // Save Button
                PrimaryButton(
                  text: 'Save Changes',
                  onPressed: _isLoading ? null : _saveSettings,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 16),

                // Cancel Button
                SecondaryButton(
                  text: 'Cancel',
                  onPressed: _isLoading ? null : () => context.pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final newName = _nameController.text.trim();
      final newBudget = int.parse(_budgetController.text);
      final newMaxDays = int.parse(_maxDaysController.text);

      // BUG FIX: Call repository directly to avoid provider disposal issues
      // Going through the notifier can cause disposal race conditions with navigation
      await ref.read(groupRepositoryProvider).updateGroupSettings(
        groupId: widget.groupId,
        name: newName,
        rules: GroupRules(
          budgetPerPerson: newBudget,
          maxTripDays: newMaxDays,
          luggageAllowance: _luggageAllowance,
          noRepeatCountries: _noRepeatCountries,
        ),
      );

      if (mounted) {
        // Navigate away AFTER the operation completes
        context.pop();
        
        // Show success message
        AppSnackBar.show(
          context: context,
          message: 'Settings updated successfully',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: 'Failed to update settings: ${e.toString()}',
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
