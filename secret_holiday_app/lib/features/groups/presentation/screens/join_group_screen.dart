import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/presentation/widgets/widgets.dart';
import '../../data/models/group_model.dart';
import '../../providers/group_provider.dart';

class JoinGroupScreen extends ConsumerStatefulWidget {
  final String? inviteCode;

  const JoinGroupScreen({super.key, this.inviteCode});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inviteCodeController = TextEditingController();
  GroupModel? _previewGroup;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    // If invite code was provided in URL, pre-fill and validate
    if (widget.inviteCode != null) {
      _inviteCodeController.text = widget.inviteCode!.toUpperCase();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _validateInviteCode();
      });
    }
  }

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _validateInviteCode() async {
    if (_inviteCodeController.text.length != 6) {
      return;
    }

    setState(() {
      _isValidating = true;
      _previewGroup = null;
    });

    try {
      final group = await ref
          .read(groupProvider.notifier)
          .validateInviteCode(_inviteCodeController.text.toUpperCase());

      if (mounted) {
        setState(() {
          _previewGroup = group;
          _isValidating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isValidating = false;
        });
        AppSnackBar.show(
          context: context,
          message: 'Invalid invite code',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _joinGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final group = await ref
          .read(groupProvider.notifier)
          .joinGroup(_inviteCodeController.text.toUpperCase());

      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: 'Joined "${group.name}" successfully!',
          type: SnackBarType.success,
        );
        context.go(RouteConstants.home);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: 'Failed to join group: ${e.toString()}',
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
        title: const Text('Join Group'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Text(
                'Join a Travel Group',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-character invite code',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // Invite Code Input
              CustomTextField(
                controller: _inviteCodeController,
                label: 'Invite Code',
                hint: 'ABC123',
                prefixIcon: Icons.lock_open,
                keyboardType: TextInputType.text,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                  UpperCaseTextFormatter(),
                ],
                onChanged: (value) {
                  if (value.length == 6) {
                    _validateInviteCode();
                  } else {
                    setState(() {
                      _previewGroup = null;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an invite code';
                  }
                  if (value.length != 6) {
                    return 'Invite code must be 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Validating indicator
              if (_isValidating)
                Center(
                  child: Column(
                    children: [
                      const LoadingIndicator(),
                      const SizedBox(height: 8),
                      Text(
                        'Validating code...',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

              // Group Preview
              if (_previewGroup != null) ...[
                const SizedBox(height: 16),
                _buildGroupPreview(_previewGroup!, theme),
                const SizedBox(height: 32),
                
                // Join Button
                PrimaryButton(
                  text: 'Join Group',
                  onPressed: groupState.isLoading ? null : _joinGroup,
                  isLoading: groupState.isLoading,
                  icon: Icons.group_add,
                ),
              ],

              if (_previewGroup == null && !_isValidating)
                const SizedBox(height: 32),

              // Alternative: Create Group
              if (_previewGroup == null && !_isValidating) ...[
                const Divider(),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Don\'t have an invite code?',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 16),
                SecondaryButton(
                  text: 'Create New Group',
                  onPressed: () => context.go(RouteConstants.createGroup),
                  icon: Icons.add,
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupPreview(GroupModel group, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              Icon(
                Icons.group,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${group.members.length} ${group.members.length == 1 ? 'member' : 'members'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          
          // Group Rules Preview
          _buildRuleItem(
            Icons.attach_money,
            'Budget',
            '\$${group.rules.budgetPerPerson} per person',
            theme,
          ),
          _buildRuleItem(
            Icons.calendar_today,
            'Trip Length',
            'Up to ${group.rules.maxTripDays} days',
            theme,
          ),
          _buildRuleItem(
            Icons.luggage,
            'Luggage',
            group.rules.luggageAllowance,
            theme,
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Text formatter to convert input to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
