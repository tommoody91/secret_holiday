import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'suggestion_model.g.dart';

/// Type of travel date specification
enum TravelDateType {
  @JsonValue('specific')
  specific,
  @JsonValue('month')
  month,
  @JsonValue('flexible')
  flexible,
}

/// Travel date specification
@JsonSerializable()
class TravelDates extends Equatable {
  final TravelDateType type;
  @JsonKey(name: 'start_date')
  final String? startDate;
  @JsonKey(name: 'end_date')
  final String? endDate;
  final String? month;
  @JsonKey(name: 'preferred_months')
  final List<String>? preferredMonths;

  const TravelDates({
    required this.type,
    this.startDate,
    this.endDate,
    this.month,
    this.preferredMonths,
  });

  factory TravelDates.forMonth(String month) => TravelDates(
        type: TravelDateType.month,
        month: month,
      );

  factory TravelDates.forSpecificDates(String start, String end) => TravelDates(
        type: TravelDateType.specific,
        startDate: start,
        endDate: end,
      );

  factory TravelDates.forFlexibleMonths(List<String> months) => TravelDates(
        type: TravelDateType.flexible,
        preferredMonths: months,
      );

  factory TravelDates.fromJson(Map<String, dynamic> json) =>
      _$TravelDatesFromJson(json);

  Map<String, dynamic> toJson() => _$TravelDatesToJson(this);

  @override
  List<Object?> get props => [type, startDate, endDate, month, preferredMonths];
}

/// Request for destination suggestions
@JsonSerializable()
class SuggestionRequest extends Equatable {
  @JsonKey(name: 'starting_location')
  final String startingLocation;
  @JsonKey(name: 'travel_dates')
  final TravelDates travelDates;
  @JsonKey(name: 'budget_per_person')
  final int budgetPerPerson;
  final int travelers;
  @JsonKey(name: 'trip_length_nights')
  final int tripLengthNights;
  @JsonKey(name: 'max_origins')
  final int maxOrigins;
  @JsonKey(name: 'max_results')
  final int maxResults;
  @JsonKey(name: 'non_stop_only')
  final bool nonStopOnly;

  const SuggestionRequest({
    required this.startingLocation,
    required this.travelDates,
    required this.budgetPerPerson,
    this.travelers = 1,
    this.tripLengthNights = 3,
    this.maxOrigins = 4,
    this.maxResults = 30,
    this.nonStopOnly = false,
  });

  factory SuggestionRequest.fromJson(Map<String, dynamic> json) =>
      _$SuggestionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SuggestionRequestToJson(this);

  @override
  List<Object?> get props => [
        startingLocation,
        travelDates,
        budgetPerPerson,
        travelers,
        tripLengthNights,
        maxOrigins,
        maxResults,
        nonStopOnly,
      ];
}

/// An origin airport used in the search
@JsonSerializable()
class OriginAirport extends Equatable {
  @JsonKey(name: 'iata_code')
  final String iataCode;
  final String name;
  @JsonKey(name: 'distance_km')
  final double? distanceKm;

  const OriginAirport({
    required this.iataCode,
    required this.name,
    this.distanceKm,
  });

  factory OriginAirport.fromJson(Map<String, dynamic> json) =>
      _$OriginAirportFromJson(json);

  Map<String, dynamic> toJson() => _$OriginAirportToJson(this);

  @override
  List<Object?> get props => [iataCode, name, distanceKm];
}

/// A suggested destination
@JsonSerializable()
class DestinationSuggestion extends Equatable {
  @JsonKey(name: 'destination_code')
  final String destinationCode;
  @JsonKey(name: 'destination_name')
  final String? destinationName;
  final String? country;
  @JsonKey(name: 'country_code')
  final String? countryCode;
  @JsonKey(name: 'best_origin')
  final String bestOrigin;
  @JsonKey(name: 'price_per_person')
  final double pricePerPerson;
  @JsonKey(name: 'total_price')
  final double? totalPrice;
  @JsonKey(name: 'departure_date')
  final String? departureDate;
  @JsonKey(name: 'return_date')
  final String? returnDate;
  final String currency;
  final List<String> reasons;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  final double? latitude;
  final double? longitude;

  const DestinationSuggestion({
    required this.destinationCode,
    this.destinationName,
    this.country,
    this.countryCode,
    required this.bestOrigin,
    required this.pricePerPerson,
    this.totalPrice,
    this.departureDate,
    this.returnDate,
    this.currency = 'GBP',
    this.reasons = const [],
    this.imageUrl,
    this.latitude,
    this.longitude,
  });

  /// Display name with fallback to destination code
  String get displayName => destinationName ?? destinationCode;

  /// Full display name with country
  String get fullDisplayName {
    if (country != null) {
      return '$displayName, $country';
    }
    return displayName;
  }

  factory DestinationSuggestion.fromJson(Map<String, dynamic> json) =>
      _$DestinationSuggestionFromJson(json);

  Map<String, dynamic> toJson() => _$DestinationSuggestionToJson(this);

  @override
  List<Object?> get props => [
        destinationCode,
        destinationName,
        country,
        countryCode,
        bestOrigin,
        pricePerPerson,
        totalPrice,
        departureDate,
        returnDate,
        currency,
        reasons,
        imageUrl,
        latitude,
        longitude,
      ];
}

/// Response containing destination suggestions
@JsonSerializable()
class SuggestionResponse extends Equatable {
  @JsonKey(name: 'origins_used')
  final List<OriginAirport> originsUsed;
  @JsonKey(name: 'search_criteria')
  final Map<String, dynamic> searchCriteria;
  final List<DestinationSuggestion> destinations;
  @JsonKey(name: 'total_found')
  final int totalFound;

  const SuggestionResponse({
    required this.originsUsed,
    required this.searchCriteria,
    required this.destinations,
    required this.totalFound,
  });

  factory SuggestionResponse.fromJson(Map<String, dynamic> json) =>
      _$SuggestionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SuggestionResponseToJson(this);

  @override
  List<Object?> get props => [originsUsed, searchCriteria, destinations, totalFound];
}
