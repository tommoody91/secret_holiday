// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suggestion_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TravelDates _$TravelDatesFromJson(Map<String, dynamic> json) => TravelDates(
  type: $enumDecode(_$TravelDateTypeEnumMap, json['type']),
  startDate: json['start_date'] as String?,
  endDate: json['end_date'] as String?,
  month: json['month'] as String?,
  preferredMonths: (json['preferred_months'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$TravelDatesToJson(TravelDates instance) =>
    <String, dynamic>{
      'type': _$TravelDateTypeEnumMap[instance.type]!,
      'start_date': instance.startDate,
      'end_date': instance.endDate,
      'month': instance.month,
      'preferred_months': instance.preferredMonths,
    };

const _$TravelDateTypeEnumMap = {
  TravelDateType.specific: 'specific',
  TravelDateType.month: 'month',
  TravelDateType.flexible: 'flexible',
};

SuggestionRequest _$SuggestionRequestFromJson(Map<String, dynamic> json) =>
    SuggestionRequest(
      startingLocation: json['starting_location'] as String,
      travelDates: TravelDates.fromJson(
        json['travel_dates'] as Map<String, dynamic>,
      ),
      budgetPerPerson: (json['budget_per_person'] as num).toInt(),
      travelers: (json['travelers'] as num?)?.toInt() ?? 1,
      tripLengthNights: (json['trip_length_nights'] as num?)?.toInt() ?? 3,
      maxOrigins: (json['max_origins'] as num?)?.toInt() ?? 4,
      maxResults: (json['max_results'] as num?)?.toInt() ?? 30,
      nonStopOnly: json['non_stop_only'] as bool? ?? false,
    );

Map<String, dynamic> _$SuggestionRequestToJson(SuggestionRequest instance) =>
    <String, dynamic>{
      'starting_location': instance.startingLocation,
      'travel_dates': instance.travelDates,
      'budget_per_person': instance.budgetPerPerson,
      'travelers': instance.travelers,
      'trip_length_nights': instance.tripLengthNights,
      'max_origins': instance.maxOrigins,
      'max_results': instance.maxResults,
      'non_stop_only': instance.nonStopOnly,
    };

OriginAirport _$OriginAirportFromJson(Map<String, dynamic> json) =>
    OriginAirport(
      iataCode: json['iata_code'] as String,
      name: json['name'] as String,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$OriginAirportToJson(OriginAirport instance) =>
    <String, dynamic>{
      'iata_code': instance.iataCode,
      'name': instance.name,
      'distance_km': instance.distanceKm,
    };

DestinationSuggestion _$DestinationSuggestionFromJson(
  Map<String, dynamic> json,
) => DestinationSuggestion(
  destinationCode: json['destination_code'] as String,
  destinationName: json['destination_name'] as String?,
  country: json['country'] as String?,
  countryCode: json['country_code'] as String?,
  bestOrigin: json['best_origin'] as String,
  pricePerPerson: (json['price_per_person'] as num).toDouble(),
  totalPrice: (json['total_price'] as num?)?.toDouble(),
  departureDate: json['departure_date'] as String?,
  returnDate: json['return_date'] as String?,
  currency: json['currency'] as String? ?? 'GBP',
  reasons:
      (json['reasons'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  imageUrl: json['image_url'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
);

Map<String, dynamic> _$DestinationSuggestionToJson(
  DestinationSuggestion instance,
) => <String, dynamic>{
  'destination_code': instance.destinationCode,
  'destination_name': instance.destinationName,
  'country': instance.country,
  'country_code': instance.countryCode,
  'best_origin': instance.bestOrigin,
  'price_per_person': instance.pricePerPerson,
  'total_price': instance.totalPrice,
  'departure_date': instance.departureDate,
  'return_date': instance.returnDate,
  'currency': instance.currency,
  'reasons': instance.reasons,
  'image_url': instance.imageUrl,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
};

SuggestionResponse _$SuggestionResponseFromJson(Map<String, dynamic> json) =>
    SuggestionResponse(
      originsUsed: (json['origins_used'] as List<dynamic>)
          .map((e) => OriginAirport.fromJson(e as Map<String, dynamic>))
          .toList(),
      searchCriteria: json['search_criteria'] as Map<String, dynamic>,
      destinations: (json['destinations'] as List<dynamic>)
          .map((e) => DestinationSuggestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalFound: (json['total_found'] as num).toInt(),
    );

Map<String, dynamic> _$SuggestionResponseToJson(SuggestionResponse instance) =>
    <String, dynamic>{
      'origins_used': instance.originsUsed,
      'search_criteria': instance.searchCriteria,
      'destinations': instance.destinations,
      'total_found': instance.totalFound,
    };
