import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/s3_image.dart';
import '../../../groups/providers/group_provider.dart';
import '../../../timeline/data/models/trip_model.dart';
import '../../../timeline/providers/trip_provider.dart';
import '../../../timeline/providers/memory_provider.dart';

/// Journey Map - An interactive map showing all group travel destinations
class JourneyMapScreen extends ConsumerStatefulWidget {
  const JourneyMapScreen({super.key});

  @override
  ConsumerState<JourneyMapScreen> createState() => _JourneyMapScreenState();
}

class _JourneyMapScreenState extends ConsumerState<JourneyMapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  TripModel? _selectedTrip;
  bool _showJourneyPath = true;
  bool _isAnimatingJourney = false;
  int _currentJourneyIndex = 0;
  Timer? _journeyTimer;
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _markerScaleController;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    _markerScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }
  
  @override
  void dispose() {
    _journeyTimer?.cancel();
    _pulseController.dispose();
    _markerScaleController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupId = ref.watch(selectedGroupProvider);
    final theme = Theme.of(context);

    if (groupId == null) {
      return _buildNoGroupSelected(theme);
    }

    final tripsAsync = ref.watch(groupTripsProvider(groupId));

    return tripsAsync.when(
      data: (trips) {
        // Filter trips with valid coordinates (not at 0,0 which is the default/invalid)
        final tripsWithLocation = trips.where((t) => 
          t.location.latitude != 0.0 || t.location.longitude != 0.0
        ).toList();
        
        // Sort by date for journey path
        tripsWithLocation.sort((a, b) => a.startDate.compareTo(b.startDate));

        if (tripsWithLocation.isEmpty) {
          return _buildNoTrips(theme);
        }

        return Stack(
          children: [
            // The Map
            _buildMap(tripsWithLocation, groupId),
            
            // Top gradient overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            
            // Stats Card
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _buildStatsCard(tripsWithLocation, theme),
            ),
            
            // Control buttons
            Positioned(
              right: 16,
              bottom: _selectedTrip != null ? 340 : 100,
              child: _buildControlButtons(tripsWithLocation, theme),
            ),
            
            // Journey Progress Indicator (when animating)
            if (_isAnimatingJourney)
              Positioned(
                bottom: _selectedTrip != null ? 350 : 110,
                left: 16,
                right: 80,
                child: _buildJourneyProgress(tripsWithLocation, theme),
              ),
            
            // Bottom sheet for selected trip
            if (_selectedTrip != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildTripPreviewSheet(groupId, theme),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error loading trips: $e'),
      ),
    );
  }

  Widget _buildMap(List<TripModel> trips, String groupId) {
    // Calculate bounds to fit all markers
    final bounds = _calculateBounds(trips);
    
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: bounds.center,
        initialZoom: 3,
        minZoom: 2,
        maxZoom: 18,
        onTap: (_, __) {
          setState(() => _selectedTrip = null);
        },
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // Map tiles - using a beautiful style
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.secretholiday.app',
        ),
        
        // Journey path lines
        if (_showJourneyPath && trips.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: trips.map((t) => LatLng(
                  t.location.latitude,
                  t.location.longitude,
                )).toList(),
                color: AppColors.primary.withValues(alpha: 0.6),
                strokeWidth: 3,
                borderStrokeWidth: 1,
                borderColor: AppColors.primary.withValues(alpha: 0.3),
              ),
            ],
          ),
        
        // Custom markers for each trip
        MarkerLayer(
          markers: trips.asMap().entries.map((entry) {
            final index = entry.key;
            final trip = entry.value;
            final isSelected = _selectedTrip?.id == trip.id;
            final isCurrentInJourney = _isAnimatingJourney && index == _currentJourneyIndex;
            
            return Marker(
              point: LatLng(trip.location.latitude, trip.location.longitude),
              width: isSelected || isCurrentInJourney ? 80 : 60,
              height: isSelected || isCurrentInJourney ? 80 : 60,
              child: GestureDetector(
                onTap: () => _selectTrip(trip),
                child: _buildMarker(trip, index + 1, isSelected, isCurrentInJourney),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMarker(TripModel trip, int number, bool isSelected, bool isCurrentInJourney) {
    final isPast = trip.endDate.isBefore(DateTime.now());
    
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = isCurrentInJourney 
            ? 1.0 + (math.sin(_pulseController.value * math.pi * 2) * 0.1)
            : 1.0;
        
        return Transform.scale(
          scale: isSelected ? 1.2 : scale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulse ring for current journey marker
              if (isCurrentInJourney)
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(
                      alpha: 0.3 * (1 - _pulseController.value),
                    ),
                  ),
                ),
              
              // Selection ring
              if (isSelected)
                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 3,
                    ),
                  ),
                ),
              
              // Main marker container
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: trip.coverPhotoUrl != null
                      ? S3Image(
                          s3Key: trip.coverPhotoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _buildPlaceholderMarker(
                            trip, number, isPast,
                          ),
                          errorWidget: (_, __, ___) => _buildPlaceholderMarker(
                            trip, number, isPast,
                          ),
                        )
                      : _buildPlaceholderMarker(trip, number, isPast),
                ),
              ),
              
              // Trip number badge
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isPast ? AppColors.textSecondary : AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderMarker(TripModel trip, int number, bool isPast) {
    return Container(
      color: isPast 
          ? AppColors.textSecondary.withValues(alpha: 0.2)
          : AppColors.primary.withValues(alpha: 0.2),
      child: Center(
        child: Text(
          trip.location.country.isNotEmpty 
              ? trip.location.country.substring(0, 2).toUpperCase()
              : '?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isPast ? AppColors.textSecondary : AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(List<TripModel> trips, ThemeData theme) {
    final countries = trips.map((t) => t.location.country).toSet().length;
    final totalDays = trips.fold<int>(0, (sum, t) => sum + t.durationDays);
    final pastTrips = trips.where((t) => t.endDate.isBefore(DateTime.now())).length;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.public,
            value: '$countries',
            label: 'Countries',
            color: AppColors.primary,
          ),
          _buildStatDivider(),
          _buildStatItem(
            icon: Icons.flight_takeoff,
            value: '$pastTrips',
            label: 'Adventures',
            color: AppColors.accent,
          ),
          _buildStatDivider(),
          _buildStatItem(
            icon: Icons.calendar_today,
            value: '$totalDays',
            label: 'Days',
            color: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: AppColors.textSecondary.withValues(alpha: 0.2),
    );
  }

  Widget _buildControlButtons(List<TripModel> trips, ThemeData theme) {
    return Column(
      children: [
        // Toggle journey path
        _buildControlButton(
          icon: _showJourneyPath ? Icons.timeline : Icons.timeline_outlined,
          onTap: () => setState(() => _showJourneyPath = !_showJourneyPath),
          isActive: _showJourneyPath,
          tooltip: 'Toggle journey path',
        ),
        const SizedBox(height: 8),
        
        // Play journey animation
        _buildControlButton(
          icon: _isAnimatingJourney ? Icons.stop : Icons.play_arrow,
          onTap: () => _toggleJourneyAnimation(trips),
          isActive: _isAnimatingJourney,
          tooltip: _isAnimatingJourney ? 'Stop journey' : 'Play journey',
        ),
        const SizedBox(height: 8),
        
        // Fit all markers
        _buildControlButton(
          icon: Icons.fit_screen,
          onTap: () => _fitAllMarkers(trips),
          tooltip: 'Fit all destinations',
        ),
        const SizedBox(height: 8),
        
        // Current location / home
        _buildControlButton(
          icon: Icons.my_location,
          onTap: _goToHome,
          tooltip: 'Go to UK',
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: isActive ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: isActive ? Colors.white : AppColors.textSecondary,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJourneyProgress(List<TripModel> trips, ThemeData theme) {
    final currentTrip = trips[_currentJourneyIndex];
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_currentJourneyIndex + 1}/${trips.length}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Trip info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentTrip.location.destination,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('MMM yyyy').format(currentTrip.startDate),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Progress bar
          SizedBox(
            width: 60,
            child: LinearProgressIndicator(
              value: (_currentJourneyIndex + 1) / trips.length,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripPreviewSheet(String groupId, ThemeData theme) {
    final trip = _selectedTrip!;
    final isPast = trip.endDate.isBefore(DateTime.now());
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Trip cover
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: trip.coverPhotoUrl != null
                          ? S3Image(
                              s3Key: trip.coverPhotoUrl!,
                              fit: BoxFit.cover,
                            )
                          : Icon(
                              Icons.flight_takeoff,
                              color: AppColors.primary,
                              size: 28,
                            ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Trip info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isPast)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.textSecondary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'PAST',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  trip.location.destination,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${trip.location.country} • ${DateFormat('MMM d, yyyy').format(trip.startDate)}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${trip.durationDays} days',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Close button
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _selectedTrip = null),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Memory preview (if past trip)
                if (isPast) _buildMemoryPreview(groupId, trip, theme),
                
                const SizedBox(height: 16),
                
                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/trip/${trip.id}', extra: {
                        'groupId': groupId,
                        'tripId': trip.id,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isPast ? 'View Memories' : 'View Trip Details',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryPreview(String groupId, TripModel trip, ThemeData theme) {
    final memoriesAsync = ref.watch(
      tripMemoriesProvider((groupId: groupId, tripId: trip.id)),
    );
    
    return memoriesAsync.when(
      data: (memories) {
        if (memories.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.photo_camera_outlined,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  'No memories yet',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }
        
        // Show memory carousel
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: AppColors.accent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '${memories.length} Memories',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: memories.length.clamp(0, 6),
                itemBuilder: (context, index) {
                  final memory = memories[index];
                  return Container(
                    width: 80,
                    margin: EdgeInsets.only(right: index < 5 ? 8 : 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: S3Image(
                      s3Key: memory.url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      errorWidget: (_, __, ___) => Icon(
                        Icons.image,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildNoGroupSelected(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore_outlined,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Select a Group',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Choose a group from the menu to see your journey map',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoTrips(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_location_alt_outlined,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Adventures Yet',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first trip and it will appear on the map!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  
  LatLngBounds _calculateBounds(List<TripModel> trips) {
    if (trips.isEmpty) {
      // Default to world view
      return LatLngBounds(
        const LatLng(-60, -180),
        const LatLng(70, 180),
      );
    }
    
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    
    for (final trip in trips) {
      final lat = trip.location.latitude;
      final lng = trip.location.longitude;
      
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }
    
    // Add some padding
    const padding = 2.0;
    return LatLngBounds(
      LatLng(minLat - padding, minLng - padding),
      LatLng(maxLat + padding, maxLng + padding),
    );
  }

  void _selectTrip(TripModel trip) {
    setState(() => _selectedTrip = trip);
    
    // Animate to the selected marker
    _mapController.move(
      LatLng(trip.location.latitude, trip.location.longitude),
      _mapController.camera.zoom.clamp(5, 10),
    );
  }

  void _fitAllMarkers(List<TripModel> trips) {
    final bounds = _calculateBounds(trips);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
    setState(() => _selectedTrip = null);
  }

  void _goToHome() {
    // Default to UK
    _mapController.move(const LatLng(54.5, -2.5), 5);
  }

  void _toggleJourneyAnimation(List<TripModel> trips) {
    if (_isAnimatingJourney) {
      _journeyTimer?.cancel();
      setState(() {
        _isAnimatingJourney = false;
        _currentJourneyIndex = 0;
      });
    } else {
      setState(() {
        _isAnimatingJourney = true;
        _currentJourneyIndex = 0;
      });
      _animateToTrip(trips, 0);
      
      _journeyTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (_currentJourneyIndex < trips.length - 1) {
          setState(() => _currentJourneyIndex++);
          _animateToTrip(trips, _currentJourneyIndex);
        } else {
          timer.cancel();
          setState(() {
            _isAnimatingJourney = false;
            _currentJourneyIndex = 0;
          });
        }
      });
    }
  }

  void _animateToTrip(List<TripModel> trips, int index) {
    final trip = trips[index];
    _mapController.move(
      LatLng(trip.location.latitude, trip.location.longitude),
      6,
    );
    setState(() => _selectedTrip = trip);
  }
}
