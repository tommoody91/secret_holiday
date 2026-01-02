import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/providers/destination_provider.dart';
import '../../../../core/presentation/widgets/widgets.dart';
import '../../../../core/services/photo_upload_service.dart';
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
  
  // Selected destination from autocomplete
  Destination? _selectedDestination;
  String _selectedCountryCode = 'XX';
  
  // Cover photo
  File? _coverPhoto;

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
      // IMPORTANT: Do ALL async operations FIRST before reading any providers
      // This prevents "Ref disposed" errors if widget unmounts during async operations
      
      // Upload cover photo if selected
      String? coverPhotoUrl;
      if (_coverPhoto != null) {
        final token = await FirebaseAuth.instance.currentUser?.getIdToken();
        if (!mounted) return;  // Check mounted after async
        
        if (token != null) {
          final result = await PhotoUploadService.uploadPhoto(
            file: _coverPhoto!,
            tripId: 'cover_${DateTime.now().millisecondsSinceEpoch}',
            authToken: token,
          );
          if (!mounted) return;  // Check mounted after async
          
          if (result.success && result.url != null) {
            coverPhotoUrl = result.url;
          }
        }
      }
      
      // Now that all async operations are done and we're still mounted,
      // read the provider and call it immediately (no awaits between read and use)
      final notifier = ref.read(tripProvider.notifier);
      
      // Collect all values before the async call
      final groupId = widget.groupId;
      final tripName = _tripNameController.text.trim();
      final destination = _destinationController.text.trim();
      final country = _countryController.text.trim();
      final countryCode = _selectedCountryCode;
      final startDate = _startDate!;
      final endDate = _endDate!;
      final summary = _summaryController.text.trim();
      final budget = int.parse(_budgetController.text.trim());
      
      // Get coordinates from selected destination (if available)
      final latitude = _selectedDestination?.latitude;
      final longitude = _selectedDestination?.longitude;
      
      // Use default preference values (50) - these will be set via AI Planning in the future
      final trip = await notifier.createTrip(
            groupId: groupId,
            tripName: tripName,
            destination: destination,
            country: country,
            countryCode: countryCode,
            startDate: startDate,
            endDate: endDate,
            summary: summary,
            budgetPerPerson: budget,
            latitude: latitude,
            longitude: longitude,
            coverPhotoUrl: coverPhotoUrl,
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

            // Destination with Autocomplete
            Autocomplete<Destination>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty || textEditingValue.text.length < 2) {
                  return const Iterable<Destination>.empty();
                }
                final repository = ref.read(destinationRepositoryProvider);
                if (!repository.isLoaded) return const Iterable<Destination>.empty();
                return repository.search(textEditingValue.text, limit: 8);
              },
              displayStringForOption: (Destination option) => option.city,
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                // Sync with our controller
                if (_destinationController.text != controller.text && _selectedDestination == null) {
                  controller.text = _destinationController.text;
                }
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Destination',
                    hintText: 'Start typing to search...',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Destination is required';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _destinationController.text = value;
                    _selectedDestination = null;
                  },
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: MediaQuery.of(context).size.width - 32,
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          return ListTile(
                            leading: const Icon(Icons.location_on_outlined),
                            title: Text(option.city),
                            subtitle: Text(option.country),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              onSelected: (Destination selection) {
                setState(() {
                  _selectedDestination = selection;
                  _destinationController.text = selection.city;
                  _countryController.text = selection.country;
                  _selectedCountryCode = selection.countryCode;
                });
              },
            ),
            const SizedBox(height: 16),

            // Country with Autocomplete
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                final repository = ref.read(destinationRepositoryProvider);
                if (!repository.isLoaded) return const Iterable<String>.empty();
                if (textEditingValue.text.isEmpty) {
                  return repository.countries.take(10);
                }
                return repository.searchCountries(textEditingValue.text, limit: 8);
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                // Sync with our controller when country is auto-filled
                if (_countryController.text.isNotEmpty && controller.text.isEmpty) {
                  controller.text = _countryController.text;
                }
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Country',
                    hintText: 'Start typing or select from destination',
                    prefixIcon: const Icon(Icons.public),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Country is required';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _countryController.text = value;
                  },
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: MediaQuery.of(context).size.width - 32,
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          return ListTile(
                            leading: const Icon(Icons.flag_outlined),
                            title: Text(option),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              onSelected: (String selection) {
                _countryController.text = selection;
                // Try to find country code
                final repository = ref.read(destinationRepositoryProvider);
                _selectedCountryCode = repository.getCountryCode(selection) ?? 'XX';
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
            TextFormField(
              controller: _budgetController,
              decoration: InputDecoration(
                labelText: 'Budget Per Person',
                hintText: '1000',
                prefixText: '£ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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

            // Notes/Description
            CustomTextField(
              controller: _summaryController,
              label: 'Description / Notes (Optional)',
              hint: 'What are you planning for this trip?',
              prefixIcon: Icons.notes,
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // Cover Photo Section
            _buildCoverPhotoSection(theme),
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

  Widget _buildCoverPhotoSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trip Cover Photo',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Add a photo to represent your trip',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickCoverPhoto,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                width: 1,
              ),
              image: _coverPhoto != null
                  ? DecorationImage(
                      image: FileImage(_coverPhoto!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _coverPhoto == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 48,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to add cover photo',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Row(
                          children: [
                            _buildPhotoActionButton(
                              Icons.edit,
                              'Change',
                              _pickCoverPhoto,
                            ),
                            const SizedBox(width: 8),
                            _buildPhotoActionButton(
                              Icons.delete,
                              'Remove',
                              () => setState(() => _coverPhoto = null),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoActionButton(IconData icon, String tooltip, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Future<void> _pickCoverPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _coverPhoto = File(pickedFile.path);
      });
    }
  }
}
