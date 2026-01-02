import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/data/destination_repository.dart';
import '../../../../core/providers/destination_provider.dart';
import '../../../../core/presentation/widgets/widgets.dart';
import '../../../../core/presentation/widgets/s3_image.dart';
import '../../../../core/services/photo_upload_service.dart';
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
  
  // Cover photo
  File? _newCoverPhoto;  // New photo to upload
  String? _existingPhotoUrl;  // Current photo URL from trip
  bool _photoRemoved = false;  // Track if user wants to remove photo
  
  // Track destination selection for coordinates
  Destination? _selectedDestination;
  double? _updatedLatitude;
  double? _updatedLongitude;

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
    _existingPhotoUrl = widget.trip.coverPhotoUrl;
    
    // Check if existing coordinates are valid (not 0,0)
    // If invalid, try to look them up from the destination name
    if (widget.trip.location.latitude == 0.0 && widget.trip.location.longitude == 0.0) {
      final repository = DestinationRepository.instance;
      if (repository.isLoaded) {
        final coords = repository.getCoordinates(
          widget.trip.location.destination,
          widget.trip.location.country,
        );
        if (coords != null) {
          _updatedLatitude = coords.$1;
          _updatedLongitude = coords.$2;
        }
      }
    }
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
      // Upload new cover photo if selected
      String? coverPhotoUrl;
      if (_newCoverPhoto != null) {
        final token = await FirebaseAuth.instance.currentUser?.getIdToken();
        if (!mounted) return;
        
        if (token != null) {
          final result = await PhotoUploadService.uploadPhoto(
            file: _newCoverPhoto!,
            tripId: 'cover_${DateTime.now().millisecondsSinceEpoch}',
            authToken: token,
          );
          if (!mounted) return;
          
          if (result.success && result.url != null) {
            coverPhotoUrl = result.url;
          }
        }
      } else if (!_photoRemoved && _existingPhotoUrl != null) {
        // Keep the existing photo
        coverPhotoUrl = _existingPhotoUrl;
      }
      // If _photoRemoved is true and _newCoverPhoto is null, coverPhotoUrl stays null
      
      // Read the notifier before async operations to avoid using disposed ref
      final notifier = ref.read(tripProvider.notifier);
      
      // Determine which coordinates to use
      // Priority: 1. Selected destination from autocomplete, 2. Looked up coords, 3. Original trip coords
      double finalLatitude = widget.trip.location.latitude;
      double finalLongitude = widget.trip.location.longitude;
      
      if (_selectedDestination != null) {
        finalLatitude = _selectedDestination!.latitude;
        finalLongitude = _selectedDestination!.longitude;
      } else if (_updatedLatitude != null && _updatedLongitude != null) {
        finalLatitude = _updatedLatitude!;
        finalLongitude = _updatedLongitude!;
      }
      
      await notifier.updateTrip(
        groupId: widget.groupId,
        tripId: widget.trip.id,
        tripName: _tripNameController.text.trim(),
        destination: _destinationController.text.trim(),
        country: _countryController.text.trim(),
        countryCode: _selectedDestination?.countryCode ?? widget.trip.location.countryCode,
        startDate: _startDate,
        endDate: _endDate,
        summary: _summaryController.text.trim(),
        budgetPerPerson: int.parse(_budgetController.text.trim()),
        coverPhotoUrl: coverPhotoUrl,
        latitude: finalLatitude,
        longitude: finalLongitude,
        // Keep existing preferences (or defaults) - these are managed via AI Planning
        adventurousness: widget.trip.adventurousness,
        foodFocus: widget.trip.foodFocus,
        urbanVsNature: widget.trip.urbanVsNature,
        budgetFlexibility: widget.trip.budgetFlexibility,
        pacePreference: widget.trip.pacePreference,
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
            // Cover Photo Section
            _buildCoverPhotoSection(theme),
            const SizedBox(height: 24),
            
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
              initialValue: TextEditingValue(text: widget.trip.location.destination),
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty || textEditingValue.text.length < 2) {
                  return const Iterable<Destination>.empty();
                }
                final repository = ref.read(destinationRepositoryProvider);
                if (!repository.isLoaded) return const Iterable<Destination>.empty();
                return repository.search(textEditingValue.text, limit: 5);
              },
              displayStringForOption: (Destination option) => option.displayName,
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                // Sync with our controller
                if (_destinationController.text != controller.text && _selectedDestination == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _destinationController.text = controller.text;
                  });
                }
                return CustomTextField(
                  controller: controller,
                  label: 'Destination',
                  hint: 'e.g., Paris, Tokyo, New York',
                  prefixIcon: Icons.location_on,
                  onChanged: (value) {
                    _destinationController.text = value;
                    // Clear selected destination when user types
                    _selectedDestination = null;
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Destination is required';
                    }
                    return null;
                  },
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: MediaQuery.of(context).size.width - 32,
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          return ListTile(
                            leading: Text(
                              option.countryCode.toUpperCase(),
                              style: const TextStyle(fontSize: 20),
                            ),
                            title: Text(option.city),
                            subtitle: Text(option.country),
                            onTap: () {
                              onSelected(option);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              onSelected: (Destination selection) {
                _selectedDestination = selection;
                _destinationController.text = selection.city;
                _countryController.text = selection.country;
                // Clear manually updated coords since we now have a proper selection
                _updatedLatitude = null;
                _updatedLongitude = null;
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
            const SizedBox(height: 24),

            // Cover Photo Section
            _buildCoverPhotoSection(theme),
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

  Widget _buildCoverPhotoSection(ThemeData theme) {
    final hasNewPhoto = _newCoverPhoto != null;
    final hasExistingPhoto = !_photoRemoved && _existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty;
    final hasAnyPhoto = hasNewPhoto || hasExistingPhoto;
    
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
          'Update the photo that represents your trip',
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
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: hasAnyPhoto
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      // Show the photo (new or existing)
                      if (hasNewPhoto)
                        Image.file(
                          _newCoverPhoto!,
                          fit: BoxFit.cover,
                        )
                      else if (hasExistingPhoto)
                        S3Image(
                          s3Key: _existingPhotoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.broken_image,
                            size: 48,
                            color: AppColors.textSecondary.withValues(alpha: 0.5),
                          ),
                        ),
                      // Action buttons overlay
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
                              _removePhoto,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
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
        _newCoverPhoto = File(pickedFile.path);
        _photoRemoved = false;  // Reset removal flag
      });
    }
  }

  void _removePhoto() {
    setState(() {
      _newCoverPhoto = null;
      _photoRemoved = true;  // Mark that the photo should be removed
    });
  }
}
