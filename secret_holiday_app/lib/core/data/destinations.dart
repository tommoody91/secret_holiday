/// Static list of popular travel destinations for autocomplete
/// This can be extended to use Google Places API in the future

class Destination {
  final String city;
  final String country;
  final String countryCode;
  final double latitude;
  final double longitude;

  const Destination({
    required this.city,
    required this.country,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
  });

  String get displayName => '$city, $country';
}

/// Popular travel destinations organized by region
class DestinationData {
  static const List<Destination> destinations = [
    // UK & Ireland
    Destination(city: 'London', country: 'United Kingdom', countryCode: 'GB', latitude: 51.5074, longitude: -0.1278),
    Destination(city: 'Edinburgh', country: 'United Kingdom', countryCode: 'GB', latitude: 55.9533, longitude: -3.1883),
    Destination(city: 'Manchester', country: 'United Kingdom', countryCode: 'GB', latitude: 53.4808, longitude: -2.2426),
    Destination(city: 'Liverpool', country: 'United Kingdom', countryCode: 'GB', latitude: 53.4084, longitude: -2.9916),
    Destination(city: 'Bath', country: 'United Kingdom', countryCode: 'GB', latitude: 51.3811, longitude: -2.3590),
    Destination(city: 'Oxford', country: 'United Kingdom', countryCode: 'GB', latitude: 51.7520, longitude: -1.2577),
    Destination(city: 'Cambridge', country: 'United Kingdom', countryCode: 'GB', latitude: 52.2053, longitude: 0.1218),
    Destination(city: 'York', country: 'United Kingdom', countryCode: 'GB', latitude: 53.9591, longitude: -1.0815),
    Destination(city: 'Brighton', country: 'United Kingdom', countryCode: 'GB', latitude: 50.8225, longitude: -0.1372),
    Destination(city: 'Bristol', country: 'United Kingdom', countryCode: 'GB', latitude: 51.4545, longitude: -2.5879),
    Destination(city: 'Glasgow', country: 'United Kingdom', countryCode: 'GB', latitude: 55.8642, longitude: -4.2518),
    Destination(city: 'Cardiff', country: 'United Kingdom', countryCode: 'GB', latitude: 51.4816, longitude: -3.1791),
    Destination(city: 'Birmingham', country: 'United Kingdom', countryCode: 'GB', latitude: 52.4862, longitude: -1.8904),
    Destination(city: 'Newcastle', country: 'United Kingdom', countryCode: 'GB', latitude: 54.9783, longitude: -1.6178),
    Destination(city: 'Leeds', country: 'United Kingdom', countryCode: 'GB', latitude: 53.8008, longitude: -1.5491),
    Destination(city: 'Nottingham', country: 'United Kingdom', countryCode: 'GB', latitude: 52.9548, longitude: -1.1581),
    Destination(city: 'Cornwall', country: 'United Kingdom', countryCode: 'GB', latitude: 50.2660, longitude: -5.0527),
    Destination(city: 'Lake District', country: 'United Kingdom', countryCode: 'GB', latitude: 54.4609, longitude: -3.0886),
    Destination(city: 'Scottish Highlands', country: 'United Kingdom', countryCode: 'GB', latitude: 57.1219, longitude: -4.7125),
    Destination(city: 'Dublin', country: 'Ireland', countryCode: 'IE', latitude: 53.3498, longitude: -6.2603),
    Destination(city: 'Belfast', country: 'United Kingdom', countryCode: 'GB', latitude: 54.5973, longitude: -5.9301),
    Destination(city: 'Cork', country: 'Ireland', countryCode: 'IE', latitude: 51.8985, longitude: -8.4756),
    Destination(city: 'Galway', country: 'Ireland', countryCode: 'IE', latitude: 53.2707, longitude: -9.0568),
    
    // Western Europe
    Destination(city: 'Paris', country: 'France', countryCode: 'FR', latitude: 48.8566, longitude: 2.3522),
    Destination(city: 'Nice', country: 'France', countryCode: 'FR', latitude: 43.7102, longitude: 7.2620),
    Destination(city: 'Lyon', country: 'France', countryCode: 'FR', latitude: 45.7640, longitude: 4.8357),
    Destination(city: 'Marseille', country: 'France', countryCode: 'FR', latitude: 43.2965, longitude: 5.3698),
    Destination(city: 'Bordeaux', country: 'France', countryCode: 'FR', latitude: 44.8378, longitude: -0.5792),
    Destination(city: 'Montpellier', country: 'France', countryCode: 'FR', latitude: 43.6108, longitude: 3.8767),
    Destination(city: 'Toulouse', country: 'France', countryCode: 'FR', latitude: 43.6047, longitude: 1.4442),
    Destination(city: 'Strasbourg', country: 'France', countryCode: 'FR', latitude: 48.5734, longitude: 7.7521),
    Destination(city: 'Nantes', country: 'France', countryCode: 'FR', latitude: 47.2184, longitude: -1.5536),
    Destination(city: 'Lille', country: 'France', countryCode: 'FR', latitude: 50.6292, longitude: 3.0573),
    Destination(city: 'Cannes', country: 'France', countryCode: 'FR', latitude: 43.5528, longitude: 7.0174),
    Destination(city: 'Monaco', country: 'Monaco', countryCode: 'MC', latitude: 43.7384, longitude: 7.4246),
    Destination(city: 'Amsterdam', country: 'Netherlands', countryCode: 'NL', latitude: 52.3676, longitude: 4.9041),
    Destination(city: 'Rotterdam', country: 'Netherlands', countryCode: 'NL', latitude: 51.9244, longitude: 4.4777),
    Destination(city: 'The Hague', country: 'Netherlands', countryCode: 'NL', latitude: 52.0705, longitude: 4.3007),
    Destination(city: 'Utrecht', country: 'Netherlands', countryCode: 'NL', latitude: 52.0907, longitude: 5.1214),
    Destination(city: 'Brussels', country: 'Belgium', countryCode: 'BE', latitude: 50.8503, longitude: 4.3517),
    Destination(city: 'Bruges', country: 'Belgium', countryCode: 'BE', latitude: 51.2093, longitude: 3.2247),
    Destination(city: 'Antwerp', country: 'Belgium', countryCode: 'BE', latitude: 51.2194, longitude: 4.4025),
    Destination(city: 'Ghent', country: 'Belgium', countryCode: 'BE', latitude: 51.0543, longitude: 3.7174),
    Destination(city: 'Luxembourg City', country: 'Luxembourg', countryCode: 'LU', latitude: 49.6116, longitude: 6.1319),
    
    // Central Europe
    Destination(city: 'Berlin', country: 'Germany', countryCode: 'DE', latitude: 52.5200, longitude: 13.4050),
    Destination(city: 'Munich', country: 'Germany', countryCode: 'DE', latitude: 48.1351, longitude: 11.5820),
    Destination(city: 'Frankfurt', country: 'Germany', countryCode: 'DE', latitude: 50.1109, longitude: 8.6821),
    Destination(city: 'Hamburg', country: 'Germany', countryCode: 'DE', latitude: 53.5511, longitude: 9.9937),
    Destination(city: 'Cologne', country: 'Germany', countryCode: 'DE', latitude: 50.9375, longitude: 6.9603),
    Destination(city: 'Dusseldorf', country: 'Germany', countryCode: 'DE', latitude: 51.2277, longitude: 6.7735),
    Destination(city: 'Stuttgart', country: 'Germany', countryCode: 'DE', latitude: 48.7758, longitude: 9.1829),
    Destination(city: 'Dresden', country: 'Germany', countryCode: 'DE', latitude: 51.0504, longitude: 13.7373),
    Destination(city: 'Leipzig', country: 'Germany', countryCode: 'DE', latitude: 51.3397, longitude: 12.3731),
    Destination(city: 'Nuremberg', country: 'Germany', countryCode: 'DE', latitude: 49.4521, longitude: 11.0767),
    Destination(city: 'Vienna', country: 'Austria', countryCode: 'AT', latitude: 48.2082, longitude: 16.3738),
    Destination(city: 'Salzburg', country: 'Austria', countryCode: 'AT', latitude: 47.8095, longitude: 13.0550),
    Destination(city: 'Innsbruck', country: 'Austria', countryCode: 'AT', latitude: 47.2692, longitude: 11.4041),
    Destination(city: 'Zurich', country: 'Switzerland', countryCode: 'CH', latitude: 47.3769, longitude: 8.5417),
    Destination(city: 'Geneva', country: 'Switzerland', countryCode: 'CH', latitude: 46.2044, longitude: 6.1432),
    Destination(city: 'Bern', country: 'Switzerland', countryCode: 'CH', latitude: 46.9480, longitude: 7.4474),
    Destination(city: 'Basel', country: 'Switzerland', countryCode: 'CH', latitude: 47.5596, longitude: 7.5886),
    Destination(city: 'Lucerne', country: 'Switzerland', countryCode: 'CH', latitude: 47.0502, longitude: 8.3093),
    Destination(city: 'Interlaken', country: 'Switzerland', countryCode: 'CH', latitude: 46.6863, longitude: 7.8632),
    Destination(city: 'Prague', country: 'Czech Republic', countryCode: 'CZ', latitude: 50.0755, longitude: 14.4378),
    Destination(city: 'Brno', country: 'Czech Republic', countryCode: 'CZ', latitude: 49.1951, longitude: 16.6068),
    Destination(city: 'Cesky Krumlov', country: 'Czech Republic', countryCode: 'CZ', latitude: 48.8127, longitude: 14.3175),
    Destination(city: 'Budapest', country: 'Hungary', countryCode: 'HU', latitude: 47.4979, longitude: 19.0402),
    Destination(city: 'Krakow', country: 'Poland', countryCode: 'PL', latitude: 50.0647, longitude: 19.9450),
    Destination(city: 'Warsaw', country: 'Poland', countryCode: 'PL', latitude: 52.2297, longitude: 21.0122),
    Destination(city: 'Gdansk', country: 'Poland', countryCode: 'PL', latitude: 54.3520, longitude: 18.6466),
    Destination(city: 'Wroclaw', country: 'Poland', countryCode: 'PL', latitude: 51.1079, longitude: 17.0385),
    Destination(city: 'Bratislava', country: 'Slovakia', countryCode: 'SK', latitude: 48.1486, longitude: 17.1077),
    Destination(city: 'Ljubljana', country: 'Slovenia', countryCode: 'SI', latitude: 46.0569, longitude: 14.5058),
    
    // Southern Europe
    Destination(city: 'Rome', country: 'Italy', countryCode: 'IT', latitude: 41.9028, longitude: 12.4964),
    Destination(city: 'Venice', country: 'Italy', countryCode: 'IT', latitude: 45.4408, longitude: 12.3155),
    Destination(city: 'Florence', country: 'Italy', countryCode: 'IT', latitude: 43.7696, longitude: 11.2558),
    Destination(city: 'Milan', country: 'Italy', countryCode: 'IT', latitude: 45.4642, longitude: 9.1900),
    Destination(city: 'Naples', country: 'Italy', countryCode: 'IT', latitude: 40.8518, longitude: 14.2681),
    Destination(city: 'Amalfi', country: 'Italy', countryCode: 'IT', latitude: 40.6340, longitude: 14.6027),
    Destination(city: 'Bologna', country: 'Italy', countryCode: 'IT', latitude: 44.4949, longitude: 11.3426),
    Destination(city: 'Turin', country: 'Italy', countryCode: 'IT', latitude: 45.0703, longitude: 7.6869),
    Destination(city: 'Verona', country: 'Italy', countryCode: 'IT', latitude: 45.4384, longitude: 10.9916),
    Destination(city: 'Pisa', country: 'Italy', countryCode: 'IT', latitude: 43.7228, longitude: 10.4017),
    Destination(city: 'Cinque Terre', country: 'Italy', countryCode: 'IT', latitude: 44.1461, longitude: 9.6439),
    Destination(city: 'Sicily', country: 'Italy', countryCode: 'IT', latitude: 37.5994, longitude: 14.0154),
    Destination(city: 'Sardinia', country: 'Italy', countryCode: 'IT', latitude: 40.1209, longitude: 9.0129),
    Destination(city: 'Lake Como', country: 'Italy', countryCode: 'IT', latitude: 45.9946, longitude: 9.2573),
    Destination(city: 'Barcelona', country: 'Spain', countryCode: 'ES', latitude: 41.3851, longitude: 2.1734),
    Destination(city: 'Madrid', country: 'Spain', countryCode: 'ES', latitude: 40.4168, longitude: -3.7038),
    Destination(city: 'Seville', country: 'Spain', countryCode: 'ES', latitude: 37.3891, longitude: -5.9845),
    Destination(city: 'Valencia', country: 'Spain', countryCode: 'ES', latitude: 39.4699, longitude: -0.3763),
    Destination(city: 'Malaga', country: 'Spain', countryCode: 'ES', latitude: 36.7213, longitude: -4.4214),
    Destination(city: 'Ibiza', country: 'Spain', countryCode: 'ES', latitude: 38.9067, longitude: 1.4206),
    Destination(city: 'Bilbao', country: 'Spain', countryCode: 'ES', latitude: 43.2630, longitude: -2.9350),
    Destination(city: 'Granada', country: 'Spain', countryCode: 'ES', latitude: 37.1773, longitude: -3.5986),
    Destination(city: 'San Sebastian', country: 'Spain', countryCode: 'ES', latitude: 43.3183, longitude: -1.9812),
    Destination(city: 'Majorca', country: 'Spain', countryCode: 'ES', latitude: 39.6953, longitude: 3.0176),
    Destination(city: 'Tenerife', country: 'Spain', countryCode: 'ES', latitude: 28.2916, longitude: -16.6291),
    Destination(city: 'Gran Canaria', country: 'Spain', countryCode: 'ES', latitude: 27.9202, longitude: -15.5474),
    Destination(city: 'Lisbon', country: 'Portugal', countryCode: 'PT', latitude: 38.7223, longitude: -9.1393),
    Destination(city: 'Porto', country: 'Portugal', countryCode: 'PT', latitude: 41.1579, longitude: -8.6291),
    Destination(city: 'Faro', country: 'Portugal', countryCode: 'PT', latitude: 37.0194, longitude: -7.9322),
    Destination(city: 'Madeira', country: 'Portugal', countryCode: 'PT', latitude: 32.6669, longitude: -16.9241),
    Destination(city: 'Azores', country: 'Portugal', countryCode: 'PT', latitude: 37.7833, longitude: -25.5333),
    Destination(city: 'Athens', country: 'Greece', countryCode: 'GR', latitude: 37.9838, longitude: 23.7275),
    Destination(city: 'Santorini', country: 'Greece', countryCode: 'GR', latitude: 36.3932, longitude: 25.4615),
    Destination(city: 'Mykonos', country: 'Greece', countryCode: 'GR', latitude: 37.4467, longitude: 25.3289),
    Destination(city: 'Crete', country: 'Greece', countryCode: 'GR', latitude: 35.2401, longitude: 24.8093),
    Destination(city: 'Rhodes', country: 'Greece', countryCode: 'GR', latitude: 36.4349, longitude: 28.2176),
    Destination(city: 'Corfu', country: 'Greece', countryCode: 'GR', latitude: 39.6243, longitude: 19.9217),
    Destination(city: 'Thessaloniki', country: 'Greece', countryCode: 'GR', latitude: 40.6401, longitude: 22.9444),
    Destination(city: 'Dubrovnik', country: 'Croatia', countryCode: 'HR', latitude: 42.6507, longitude: 18.0944),
    Destination(city: 'Split', country: 'Croatia', countryCode: 'HR', latitude: 43.5081, longitude: 16.4402),
    Destination(city: 'Zagreb', country: 'Croatia', countryCode: 'HR', latitude: 45.8150, longitude: 15.9819),
    Destination(city: 'Hvar', country: 'Croatia', countryCode: 'HR', latitude: 43.1729, longitude: 16.4411),
    Destination(city: 'Malta', country: 'Malta', countryCode: 'MT', latitude: 35.9375, longitude: 14.3754),
    Destination(city: 'Cyprus', country: 'Cyprus', countryCode: 'CY', latitude: 35.1264, longitude: 33.4299),
    
    // Nordic
    Destination(city: 'Copenhagen', country: 'Denmark', countryCode: 'DK', latitude: 55.6761, longitude: 12.5683),
    Destination(city: 'Stockholm', country: 'Sweden', countryCode: 'SE', latitude: 59.3293, longitude: 18.0686),
    Destination(city: 'Oslo', country: 'Norway', countryCode: 'NO', latitude: 59.9139, longitude: 10.7522),
    Destination(city: 'Helsinki', country: 'Finland', countryCode: 'FI', latitude: 60.1699, longitude: 24.9384),
    Destination(city: 'Reykjavik', country: 'Iceland', countryCode: 'IS', latitude: 64.1466, longitude: -21.9426),
    
    // North America
    Destination(city: 'New York', country: 'United States', countryCode: 'US', latitude: 40.7128, longitude: -74.0060),
    Destination(city: 'Los Angeles', country: 'United States', countryCode: 'US', latitude: 34.0522, longitude: -118.2437),
    Destination(city: 'San Francisco', country: 'United States', countryCode: 'US', latitude: 37.7749, longitude: -122.4194),
    Destination(city: 'Las Vegas', country: 'United States', countryCode: 'US', latitude: 36.1699, longitude: -115.1398),
    Destination(city: 'Miami', country: 'United States', countryCode: 'US', latitude: 25.7617, longitude: -80.1918),
    Destination(city: 'Chicago', country: 'United States', countryCode: 'US', latitude: 41.8781, longitude: -87.6298),
    Destination(city: 'Boston', country: 'United States', countryCode: 'US', latitude: 42.3601, longitude: -71.0589),
    Destination(city: 'Washington DC', country: 'United States', countryCode: 'US', latitude: 38.9072, longitude: -77.0369),
    Destination(city: 'New Orleans', country: 'United States', countryCode: 'US', latitude: 29.9511, longitude: -90.0715),
    Destination(city: 'Seattle', country: 'United States', countryCode: 'US', latitude: 47.6062, longitude: -122.3321),
    Destination(city: 'Austin', country: 'United States', countryCode: 'US', latitude: 30.2672, longitude: -97.7431),
    Destination(city: 'Hawaii', country: 'United States', countryCode: 'US', latitude: 19.8968, longitude: -155.5828),
    Destination(city: 'Toronto', country: 'Canada', countryCode: 'CA', latitude: 43.6532, longitude: -79.3832),
    Destination(city: 'Vancouver', country: 'Canada', countryCode: 'CA', latitude: 49.2827, longitude: -123.1207),
    Destination(city: 'Montreal', country: 'Canada', countryCode: 'CA', latitude: 45.5017, longitude: -73.5673),
    Destination(city: 'Cancun', country: 'Mexico', countryCode: 'MX', latitude: 21.1619, longitude: -86.8515),
    Destination(city: 'Mexico City', country: 'Mexico', countryCode: 'MX', latitude: 19.4326, longitude: -99.1332),
    Destination(city: 'Tulum', country: 'Mexico', countryCode: 'MX', latitude: 20.2114, longitude: -87.4654),
    
    // Caribbean
    Destination(city: 'Havana', country: 'Cuba', countryCode: 'CU', latitude: 23.1136, longitude: -82.3666),
    Destination(city: 'Punta Cana', country: 'Dominican Republic', countryCode: 'DO', latitude: 18.5601, longitude: -68.3725),
    Destination(city: 'Nassau', country: 'Bahamas', countryCode: 'BS', latitude: 25.0343, longitude: -77.3963),
    Destination(city: 'Montego Bay', country: 'Jamaica', countryCode: 'JM', latitude: 18.4762, longitude: -77.8939),
    Destination(city: 'Barbados', country: 'Barbados', countryCode: 'BB', latitude: 13.1939, longitude: -59.5432),
    
    // South America
    Destination(city: 'Rio de Janeiro', country: 'Brazil', countryCode: 'BR', latitude: -22.9068, longitude: -43.1729),
    Destination(city: 'Sao Paulo', country: 'Brazil', countryCode: 'BR', latitude: -23.5505, longitude: -46.6333),
    Destination(city: 'Buenos Aires', country: 'Argentina', countryCode: 'AR', latitude: -34.6037, longitude: -58.3816),
    Destination(city: 'Lima', country: 'Peru', countryCode: 'PE', latitude: -12.0464, longitude: -77.0428),
    Destination(city: 'Cusco', country: 'Peru', countryCode: 'PE', latitude: -13.5319, longitude: -71.9675),
    Destination(city: 'Bogota', country: 'Colombia', countryCode: 'CO', latitude: 4.7110, longitude: -74.0721),
    Destination(city: 'Cartagena', country: 'Colombia', countryCode: 'CO', latitude: 10.3910, longitude: -75.4794),
    Destination(city: 'Santiago', country: 'Chile', countryCode: 'CL', latitude: -33.4489, longitude: -70.6693),
    
    // Asia - East
    Destination(city: 'Tokyo', country: 'Japan', countryCode: 'JP', latitude: 35.6762, longitude: 139.6503),
    Destination(city: 'Kyoto', country: 'Japan', countryCode: 'JP', latitude: 35.0116, longitude: 135.7681),
    Destination(city: 'Osaka', country: 'Japan', countryCode: 'JP', latitude: 34.6937, longitude: 135.5023),
    Destination(city: 'Seoul', country: 'South Korea', countryCode: 'KR', latitude: 37.5665, longitude: 126.9780),
    Destination(city: 'Hong Kong', country: 'Hong Kong', countryCode: 'HK', latitude: 22.3193, longitude: 114.1694),
    Destination(city: 'Shanghai', country: 'China', countryCode: 'CN', latitude: 31.2304, longitude: 121.4737),
    Destination(city: 'Beijing', country: 'China', countryCode: 'CN', latitude: 39.9042, longitude: 116.4074),
    Destination(city: 'Taipei', country: 'Taiwan', countryCode: 'TW', latitude: 25.0330, longitude: 121.5654),
    
    // Asia - Southeast
    Destination(city: 'Singapore', country: 'Singapore', countryCode: 'SG', latitude: 1.3521, longitude: 103.8198),
    Destination(city: 'Bangkok', country: 'Thailand', countryCode: 'TH', latitude: 13.7563, longitude: 100.5018),
    Destination(city: 'Phuket', country: 'Thailand', countryCode: 'TH', latitude: 7.8804, longitude: 98.3923),
    Destination(city: 'Chiang Mai', country: 'Thailand', countryCode: 'TH', latitude: 18.7883, longitude: 98.9853),
    Destination(city: 'Bali', country: 'Indonesia', countryCode: 'ID', latitude: -8.3405, longitude: 115.0920),
    Destination(city: 'Jakarta', country: 'Indonesia', countryCode: 'ID', latitude: -6.2088, longitude: 106.8456),
    Destination(city: 'Kuala Lumpur', country: 'Malaysia', countryCode: 'MY', latitude: 3.1390, longitude: 101.6869),
    Destination(city: 'Hanoi', country: 'Vietnam', countryCode: 'VN', latitude: 21.0278, longitude: 105.8342),
    Destination(city: 'Ho Chi Minh City', country: 'Vietnam', countryCode: 'VN', latitude: 10.8231, longitude: 106.6297),
    Destination(city: 'Manila', country: 'Philippines', countryCode: 'PH', latitude: 14.5995, longitude: 120.9842),
    Destination(city: 'Siem Reap', country: 'Cambodia', countryCode: 'KH', latitude: 13.3671, longitude: 103.8448),
    
    // Asia - South
    Destination(city: 'Mumbai', country: 'India', countryCode: 'IN', latitude: 19.0760, longitude: 72.8777),
    Destination(city: 'Delhi', country: 'India', countryCode: 'IN', latitude: 28.7041, longitude: 77.1025),
    Destination(city: 'Goa', country: 'India', countryCode: 'IN', latitude: 15.2993, longitude: 74.1240),
    Destination(city: 'Jaipur', country: 'India', countryCode: 'IN', latitude: 26.9124, longitude: 75.7873),
    Destination(city: 'Colombo', country: 'Sri Lanka', countryCode: 'LK', latitude: 6.9271, longitude: 79.8612),
    Destination(city: 'Maldives', country: 'Maldives', countryCode: 'MV', latitude: 3.2028, longitude: 73.2207),
    Destination(city: 'Kathmandu', country: 'Nepal', countryCode: 'NP', latitude: 27.7172, longitude: 85.3240),
    
    // Middle East
    Destination(city: 'Dubai', country: 'UAE', countryCode: 'AE', latitude: 25.2048, longitude: 55.2708),
    Destination(city: 'Abu Dhabi', country: 'UAE', countryCode: 'AE', latitude: 24.4539, longitude: 54.3773),
    Destination(city: 'Tel Aviv', country: 'Israel', countryCode: 'IL', latitude: 32.0853, longitude: 34.7818),
    Destination(city: 'Jerusalem', country: 'Israel', countryCode: 'IL', latitude: 31.7683, longitude: 35.2137),
    Destination(city: 'Istanbul', country: 'Turkey', countryCode: 'TR', latitude: 41.0082, longitude: 28.9784),
    Destination(city: 'Cappadocia', country: 'Turkey', countryCode: 'TR', latitude: 38.6431, longitude: 34.8289),
    Destination(city: 'Doha', country: 'Qatar', countryCode: 'QA', latitude: 25.2854, longitude: 51.5310),
    Destination(city: 'Muscat', country: 'Oman', countryCode: 'OM', latitude: 23.5880, longitude: 58.3829),
    Destination(city: 'Marrakech', country: 'Morocco', countryCode: 'MA', latitude: 31.6295, longitude: -7.9811),
    Destination(city: 'Cairo', country: 'Egypt', countryCode: 'EG', latitude: 30.0444, longitude: 31.2357),
    
    // Africa
    Destination(city: 'Cape Town', country: 'South Africa', countryCode: 'ZA', latitude: -33.9249, longitude: 18.4241),
    Destination(city: 'Johannesburg', country: 'South Africa', countryCode: 'ZA', latitude: -26.2041, longitude: 28.0473),
    Destination(city: 'Nairobi', country: 'Kenya', countryCode: 'KE', latitude: -1.2921, longitude: 36.8219),
    Destination(city: 'Zanzibar', country: 'Tanzania', countryCode: 'TZ', latitude: -6.1659, longitude: 39.2026),
    Destination(city: 'Victoria Falls', country: 'Zimbabwe', countryCode: 'ZW', latitude: -17.9243, longitude: 25.8572),
    Destination(city: 'Mauritius', country: 'Mauritius', countryCode: 'MU', latitude: -20.3484, longitude: 57.5522),
    Destination(city: 'Seychelles', country: 'Seychelles', countryCode: 'SC', latitude: -4.6796, longitude: 55.4920),
    
    // Oceania
    Destination(city: 'Sydney', country: 'Australia', countryCode: 'AU', latitude: -33.8688, longitude: 151.2093),
    Destination(city: 'Melbourne', country: 'Australia', countryCode: 'AU', latitude: -37.8136, longitude: 144.9631),
    Destination(city: 'Brisbane', country: 'Australia', countryCode: 'AU', latitude: -27.4698, longitude: 153.0251),
    Destination(city: 'Perth', country: 'Australia', countryCode: 'AU', latitude: -31.9505, longitude: 115.8605),
    Destination(city: 'Gold Coast', country: 'Australia', countryCode: 'AU', latitude: -28.0167, longitude: 153.4000),
    Destination(city: 'Auckland', country: 'New Zealand', countryCode: 'NZ', latitude: -36.8509, longitude: 174.7645),
    Destination(city: 'Queenstown', country: 'New Zealand', countryCode: 'NZ', latitude: -45.0312, longitude: 168.6626),
    Destination(city: 'Fiji', country: 'Fiji', countryCode: 'FJ', latitude: -17.7134, longitude: 178.0650),
    Destination(city: 'Bora Bora', country: 'French Polynesia', countryCode: 'PF', latitude: -16.5004, longitude: -151.7415),
  ];

  /// Get unique list of countries
  static List<String> get countries {
    final countrySet = <String>{};
    for (final dest in destinations) {
      countrySet.add(dest.country);
    }
    final list = countrySet.toList()..sort();
    return list;
  }

  /// Search destinations by query (matches city or country)
  static List<Destination> search(String query) {
    if (query.isEmpty) return [];
    
    final lowerQuery = query.toLowerCase();
    return destinations.where((dest) {
      return dest.city.toLowerCase().contains(lowerQuery) ||
             dest.country.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get destinations for a specific country
  static List<Destination> getByCountry(String country) {
    return destinations.where((dest) => 
      dest.country.toLowerCase() == country.toLowerCase()
    ).toList();
  }

  /// Find a destination by city name (case-insensitive)
  /// Returns null if not found
  static Destination? findByCity(String city) {
    final lowerCity = city.toLowerCase().trim();
    try {
      return destinations.firstWhere(
        (dest) => dest.city.toLowerCase() == lowerCity,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get coordinates for a city
  /// Returns null if city not found
  static ({double latitude, double longitude})? getCoordinates(String city) {
    final destination = findByCity(city);
    if (destination == null) return null;
    return (latitude: destination.latitude, longitude: destination.longitude);
  }
}
