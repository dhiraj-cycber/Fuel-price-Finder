
import 'package:flutter/material.dart';
import '../Model/state_model.dart';
import '../Service/api_service.dart';

class FuelPriceProvider with ChangeNotifier {
  List<StateData> _allStates = [];
  List<StateData> _filteredStates = [];
  StateData? _selectedState;
  RouteInfo? _routeInfo;
  bool _isLoading = false;
  String _searchQuery = '';
  Map<String, double>? _currentLocation;

  List<StateData> get allStates => _allStates;
  List<StateData> get filteredStates => _filteredStates;
  StateData? get selectedState => _selectedState;
  RouteInfo? get routeInfo => _routeInfo;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  Map<String, double>? get currentLocation => _currentLocation;

  // Load all fuel prices
  Future<void> loadFuelPrices() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allStates = await ApiService.loadFuelPrices();
      _filteredStates = _allStates;
    } catch (e) {
      print('Error loading fuel prices: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Search states
  Future<void> searchStates(String query) async {
    _searchQuery = query;

    if (query.isEmpty) {
      _filteredStates = _allStates;
    } else {
      _filteredStates = _allStates.where((state) {
        return state.state.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }

    notifyListeners();
  }

  // Select a state
  void selectState(StateData state) {
    _selectedState = state;
    notifyListeners();

    // Calculate route info when state is selected
    fetchRouteInfo();
  }

  // Clear selection
  void clearSelection() {
    _selectedState = null;
    _routeInfo = null;
    notifyListeners();
  }

  // Get current location
  Future<void> getCurrentLocation() async {
    try {
      _currentLocation = await ApiService.getCurrentLocation();
      notifyListeners();
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  // Fetch route info from current location to selected state
  Future<void> fetchRouteInfo() async {
    if (_selectedState == null || _currentLocation == null) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _routeInfo = await ApiService.getRouteInfo(
        originLat: _currentLocation!['lat']!,
        originLng: _currentLocation!['lng']!,
        destLat: _selectedState!.lat,
        destLng: _selectedState!.long,
      );
    } catch (e) {
      print('Error calculating route info: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // NEW: Fetch route info between any two states
  Future<RouteInfo?> fetchRouteInfoBetweenStates(
      double originLat,
      double originLng,
      double destLat,
      double destLng,
      ) async {
    _isLoading = true;
    notifyListeners();

    RouteInfo? routeInfo;
    try {
      routeInfo = await ApiService.getRouteInfo(
        originLat: originLat,
        originLng: originLng,
        destLat: destLat,
        destLng: destLng,
      );
    } catch (e) {
      print('Error calculating route between states: $e');
    }

    _isLoading = false;
    notifyListeners();

    return routeInfo;
  }

  // Reset search
  void resetSearch() {
    _searchQuery = '';
    _filteredStates = _allStates;
    notifyListeners();
  }
}