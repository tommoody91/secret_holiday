import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';

/// Represents a destination with city, country, and coordinates
class Destination {
  final String city;
  final String country;
  final String countryCode;
  final double latitude;
  final double longitude;
  final String? admin1;
  final String? type;
  final int? rank;
  final int? geonameId;
  final int? population;

  const Destination({
    required this.city,
    required this.country,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
    this.admin1,
    this.type,
    this.rank,
    this.geonameId,
    this.population,
  });

  String get displayName => '$city, $country';

  /// Create from the ext array format:
  /// [city, country, countryCode, lat, lng, admin1, type, rank, geonameId, population]
  factory Destination.fromExtArray(List<dynamic> arr) {
    return Destination(
      city: arr[0] as String,
      country: arr[1] as String,
      countryCode: arr[2] as String,
      latitude: (arr[3] as num).toDouble(),
      longitude: (arr[4] as num).toDouble(),
      admin1: arr.length > 5 ? arr[5] as String? : null,
      type: arr.length > 6 ? arr[6] as String? : null,
      rank: arr.length > 7 ? (arr[7] as num?)?.toInt() : null,
      geonameId: arr.length > 8 ? (arr[8] as num?)?.toInt() : null,
      population: arr.length > 9 ? (arr[9] as num?)?.toInt() : null,
    );
  }
}

/// Repository for accessing destination data from gzipped JSON assets
/// Uses lazy loading and 2-letter prefix indexing for fast autocomplete
class DestinationRepository {
  static DestinationRepository? _instance;

  /// Singleton instance
  static DestinationRepository get instance {
    _instance ??= DestinationRepository._();
    return _instance!;
  }

  DestinationRepository._();

  // Cached data
  List<List<dynamic>>? _rawDestinations;
  Map<String, List<int>>? _destinationIndex;
  List<String>? _countries;
  Map<String, List<String>>? _countryIndex;
  Map<String, String>? _countryNameToCode;

  bool _isLoading = false;
  bool _isLoaded = false;

  /// Whether the data has been loaded
  bool get isLoaded => _isLoaded;

  /// Initialize and load all data - call this early in app startup
  Future<void> initialize() async {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;

    try {
      // Load all files in parallel
      final results = await Future.wait([
        _loadGzippedJson('assets/data/europe_destinations_ext.json.gz'),
        _loadGzippedJson('assets/data/europe_destinations_idx2.json.gz'),
        _loadGzippedJson('assets/data/europe_countries.json.gz'),
        _loadGzippedJson('assets/data/europe_countries_idx2.json.gz'),
        _loadGzippedJson('assets/data/europe_country_name_to_code.json.gz'),
      ]);

      _rawDestinations = (results[0] as List).cast<List<dynamic>>();
      _destinationIndex = _parseIndex(results[1] as Map<String, dynamic>);
      _countries = (results[2] as List).cast<String>();
      _countryIndex = _parseStringIndex(results[3] as Map<String, dynamic>);
      _countryNameToCode = (results[4] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v as String));

      _isLoaded = true;
    } finally {
      _isLoading = false;
    }
  }

  /// Load and decompress a gzipped JSON file from assets
  Future<dynamic> _loadGzippedJson(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    final Uint8List bytes = data.buffer.asUint8List();
    final List<int> decompressed = GZipDecoder().decodeBytes(bytes);
    final String jsonString = utf8.decode(decompressed);
    return json.decode(jsonString);
  }

  /// Parse index from JSON map to `Map<String, List<int>>`
  Map<String, List<int>> _parseIndex(Map<String, dynamic> raw) {
    return raw.map((key, value) => MapEntry(
          key,
          (value as List).cast<int>(),
        ));
  }

  /// Parse string index from JSON map to `Map<String, List<String>>`
  Map<String, List<String>> _parseStringIndex(Map<String, dynamic> raw) {
    return raw.map((key, value) => MapEntry(
          key,
          (value as List).cast<String>(),
        ));
  }

  /// Get all countries (sorted alphabetically)
  List<String> get countries {
    _ensureLoaded();
    return _countries ?? [];
  }

  /// Get country code from country name
  String? getCountryCode(String countryName) {
    _ensureLoaded();
    return _countryNameToCode?[countryName];
  }

  /// Search destinations by query string
  /// Uses 2-letter prefix index for O(1) initial lookup, then filters
  /// Returns destinations sorted by rank (most popular first)
  List<Destination> search(String query, {int limit = 20}) {
    _ensureLoaded();
    if (query.isEmpty || _rawDestinations == null || _destinationIndex == null) {
      return [];
    }

    final lowerQuery = query.toLowerCase();
    
    // Need at least 2 characters to use the index
    if (lowerQuery.length < 2) {
      return [];
    }

    // Get the 2-letter prefix
    final prefix = lowerQuery.substring(0, 2);
    
    // Look up indices from the index
    final indices = _destinationIndex![prefix];
    if (indices == null || indices.isEmpty) {
      return [];
    }

    // Filter destinations that match the query
    final matches = <Destination>[];
    for (final idx in indices) {
      if (idx >= _rawDestinations!.length) continue;
      
      final row = _rawDestinations![idx];
      final city = (row[0] as String).toLowerCase();
      
      // Check if city starts with the full query
      if (city.startsWith(lowerQuery)) {
        matches.add(Destination.fromExtArray(row));
      }
    }

    // Sort by rank (higher rank = more popular, should come first)
    matches.sort((a, b) {
      final rankA = a.rank ?? 0;
      final rankB = b.rank ?? 0;
      return rankB.compareTo(rankA);
    });

    return matches.take(limit).toList();
  }

  /// Search countries by query string
  /// Uses 2-letter prefix index for fast lookup
  List<String> searchCountries(String query, {int limit = 10}) {
    _ensureLoaded();
    if (query.isEmpty || _countries == null) {
      return _countries?.take(limit).toList() ?? [];
    }

    final lowerQuery = query.toLowerCase();

    // Use index if query is at least 2 characters
    if (lowerQuery.length >= 2 && _countryIndex != null) {
      final prefix = lowerQuery.substring(0, 2);
      final indexed = _countryIndex![prefix];
      if (indexed != null) {
        return indexed
            .where((c) => c.toLowerCase().startsWith(lowerQuery))
            .take(limit)
            .toList();
      }
    }

    // Fallback to linear search for 1-character queries
    return _countries!
        .where((c) => c.toLowerCase().startsWith(lowerQuery))
        .take(limit)
        .toList();
  }

  /// Find a destination by exact city and country match
  Destination? findByCity(String city, String country) {
    _ensureLoaded();
    if (_rawDestinations == null || _destinationIndex == null) return null;

    final lowerCity = city.toLowerCase();
    if (lowerCity.length < 2) return null;

    final prefix = lowerCity.substring(0, 2);
    final indices = _destinationIndex![prefix];
    if (indices == null) return null;

    for (final idx in indices) {
      if (idx >= _rawDestinations!.length) continue;
      
      final row = _rawDestinations![idx];
      if ((row[0] as String).toLowerCase() == lowerCity &&
          (row[1] as String).toLowerCase() == country.toLowerCase()) {
        return Destination.fromExtArray(row);
      }
    }
    return null;
  }

  /// Get coordinates for a city and country
  /// Returns [latitude, longitude] or null if not found
  (double, double)? getCoordinates(String city, String country) {
    final dest = findByCity(city, country);
    if (dest != null) {
      return (dest.latitude, dest.longitude);
    }
    return null;
  }

  /// Ensure data is loaded, throw if not
  void _ensureLoaded() {
    if (!_isLoaded) {
      throw StateError(
        'DestinationRepository not initialized. '
        'Call initialize() before accessing data.',
      );
    }
  }
}
