
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../Model/state_model.dart';

class ApiService {
  static const String _googleApiKey = 'AIzaSyCvdeAoYN2VQGbZcKs3CrygjE_XgyGTCIY';

  static Future<List<StateData>> loadFuelPrices() async {
    try {
      final String response = await rootBundle.loadString('assets/fuel_prices.json');
      final data = json.decode(response);

      List<StateData> states = [];
      for (var item in data['data']) {
        states.add(StateData.fromJson(item));
      }

      return states;
    } catch (e) {
      print('Error loading fuel prices: $e');
      return [];
    }
  }

  static Future<List<StateData>> searchStates(String query) async {
    final allStates = await loadFuelPrices();

    if (query.isEmpty) {
      return allStates;
    }

    return allStates.where((state) {
      return state.state.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  static Future<RouteInfo?> getRouteInfo({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?'
              'origin=$originLat,$originLng'
              '&destination=$destLat,$destLng'
              '&optimize=true'
              '&key=$_googleApiKey'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          List<Map<String, double>> polylinePoints = [];
          if (route['overview_polyline'] != null) {
            final points = _decodePolyline(route['overview_polyline']['points']);
            polylinePoints = points;
          }

          return RouteInfo(
            distance: leg['distance']['text'],
            duration: leg['duration']['text'],
            polylinePoints: polylinePoints,
          );
        }
      }

      return null;
    } catch (e) {
      print('Error fetching route: $e');
      return null;
    }
  }

  static List<Map<String, double>> _decodePolyline(String encoded) {
    List<Map<String, double>> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add({
        'lat': lat / 1E5,
        'lng': lng / 1E5,
      });
    }

    return points;
  }

  static Future<Map<String, double>> getCurrentLocation() async {
    return {
      'lat': 28.6139,
      'lng': 77.2090,
    };
  }
}