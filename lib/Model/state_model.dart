
class StateData {
  final String state;
  final double lat;
  final double long;
  final FuelPrices fuelPrices;

  StateData({
    required this.state,
    required this.lat,
    required this.long,
    required this.fuelPrices,
  });

  factory StateData.fromJson(Map<String, dynamic> json) {
    return StateData(
      state: json['state'] ?? '',
      lat: (json['lat'] ?? 0.0).toDouble(),
      long: (json['long'] ?? 0.0).toDouble(),
      fuelPrices: FuelPrices.fromJson(json['fuel_prices'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'state': state,
      'lat': lat,
      'long': long,
      'fuel_prices': fuelPrices.toJson(),
    };
  }
}

class FuelPrices {
  final double petrolPrice;
  final double dieselPrice;
  final double cngPrice;
  final double electricityPrice;

  FuelPrices({
    required this.petrolPrice,
    required this.dieselPrice,
    required this.cngPrice,
    required this.electricityPrice,
  });

  factory FuelPrices.fromJson(Map<String, dynamic> json) {
    return FuelPrices(
      petrolPrice: (json['petrol_price'] ?? 0.0).toDouble(),
      dieselPrice: (json['diesel_price'] ?? 0.0).toDouble(),
      cngPrice: (json['cng_price'] ?? 0.0).toDouble(),
      electricityPrice: (json['electricity_price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'petrol_price': petrolPrice,
      'diesel_price': dieselPrice,
      'cng_price': cngPrice,
      'electricity_price': electricityPrice,
    };
  }
}

class RouteInfo {
  final String distance;
  final String duration;
  final List<Map<String, double>> polylinePoints;

  RouteInfo({
    required this.distance,
    required this.duration,
    required this.polylinePoints,
  });
}