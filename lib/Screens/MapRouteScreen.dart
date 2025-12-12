
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../Model/state_model.dart';
import '../Provider/fuel_price_provider.dart';

class MapRouteScreen extends StatefulWidget {
  const MapRouteScreen({Key? key}) : super(key: key);

  @override
  State<MapRouteScreen> createState() => _MapRouteScreenState();
}

class _MapRouteScreenState extends State<MapRouteScreen> {
  GoogleMapController? _mapController;
  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  StateData? _sourceState;
  StateData? _destinationState;
  RouteInfo? _routeInfo;
  bool _showMap = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  void _loadCurrentLocation() async {
    final provider = Provider.of<FuelPriceProvider>(context, listen: false);

    // Set Delhi as default source (current location)
    if (provider.allStates.isNotEmpty) {
      final delhiState = provider.allStates.firstWhere(
            (state) => state.state.toLowerCase().contains('delhi'),
        orElse: () => provider.allStates.first,
      );
      setState(() {
        _sourceState = delhiState;
      });
    }
  }

  Future<void> _searchRoute() async {
    if (_sourceState == null || _destinationState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select both Source and Destination'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _showMap = true;
      _routeInfo = null;
      _setupMarkers();
    });

    final provider = Provider.of<FuelPriceProvider>(context, listen: false);

    try {
      print('Fetching route info from Google Directions API...');
      final routeInfo = await provider.fetchRouteInfoBetweenStates(
        _sourceState!.lat,
        _sourceState!.long,
        _destinationState!.lat,
        _destinationState!.long,
      );

      if (routeInfo != null) {
        print(' Distance: ${routeInfo.distance}');
        print(' Duration: ${routeInfo.duration}');
        print(' Polyline points: ${routeInfo.polylinePoints.length}');
      } else {
        print(' Route info is NULL - API call may have failed');
      }

      if (mounted) {
        setState(() {
          _routeInfo = routeInfo;
          _setupPolyline();
        });

        Future.delayed(Duration(milliseconds: 800), () {
          if (_mapController != null && mounted) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLngBounds(
                LatLngBounds(
                  southwest: LatLng(
                    _sourceState!.lat < _destinationState!.lat
                        ? _sourceState!.lat
                        : _destinationState!.lat,
                    _sourceState!.long < _destinationState!.long
                        ? _sourceState!.long
                        : _destinationState!.long,
                  ),
                  northeast: LatLng(
                    _sourceState!.lat > _destinationState!.lat
                        ? _sourceState!.lat
                        : _destinationState!.lat,
                    _sourceState!.long > _destinationState!.long
                        ? _sourceState!.long
                        : _destinationState!.long,
                  ),
                ),
                100,
              ),
            );
          }
        });
      }
    } catch (e) {
      print('Error searching route: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error finding route. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _setupMarkers() {
    _markers.clear();

    if (_sourceState != null) {
      _markers.add(
        Marker(
          markerId: MarkerId('source'),
          position: LatLng(_sourceState!.lat, _sourceState!.long),
          infoWindow: InfoWindow(
            title: _sourceState!.state,
            snippet: 'Petrol: ₹${_sourceState!.fuelPrices.petrolPrice}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    if (_destinationState != null) {
      _markers.add(
        Marker(
          markerId: MarkerId('destination'),
          position: LatLng(_destinationState!.lat, _destinationState!.long),
          infoWindow: InfoWindow(
            title: _destinationState!.state,
            snippet: 'Petrol: ₹${_destinationState!.fuelPrices.petrolPrice}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
  }

  void _setupPolyline() {
    _polylines.clear();

    if (_routeInfo != null && _routeInfo!.polylinePoints.isNotEmpty) {
      print('Setting up polyline with ${_routeInfo!.polylinePoints.length} points');

      List<LatLng> polylineCoordinates = _routeInfo!.polylinePoints
          .map((point) => LatLng(point['lat']!, point['lng']!))
          .toList();
      _polylines.add(
        Polyline(
          polylineId: PolylineId('route'),
          points: polylineCoordinates,
          color: Color(0xFF2196F3),
          width: 6,
          geodesic: true,
          visible: true,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      );

      print(' Polyline added to map. Total polylines: ${_polylines.length}');

      // Force UI refresh
      if (mounted) {
        setState(() {});
      }
    } else {
      print('No route info or empty polyline points');
      if (_routeInfo == null) {
        print('  - _routeInfo is NULL');
      } else if (_routeInfo!.polylinePoints.isEmpty) {
        print('  - polylinePoints is EMPTY');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a237e),
              Color(0xFF0d47a1),
              Color(0xFF01579b),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),

              _buildSelectors(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: _buildSearchButton(),
              ),
              if (_showMap)
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: _buildMap(),
                            ),
                          ),
                        ),
                        SizedBox(height: 15),
                        _buildCompactPriceFooter(),
                      ],
                    ),
                  ),
                ),

              if (!_showMap)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 80,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Select locations and search',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        if (!_controller.isCompleted) {
          _controller.complete(controller);
          _mapController = controller;
        }
      },
      initialCameraPosition: CameraPosition(
        target: LatLng(
          _sourceState?.lat ?? 28.6139,
          _sourceState?.long ?? 77.2090,
        ),
        zoom: 6.0,
      ),
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      mapType: MapType.normal,
      zoomControlsEnabled: true,
      compassEnabled: true,
      mapToolbarEnabled: false,
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.arrow_back, color: Color(0xFF1a237e)),
              ),
            ),
          ),
          SizedBox(width: 15),
          Text(
            'Map Route',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectors() {
    return Consumer<FuelPriceProvider>(
      builder: (context, provider, child) {
        if (provider.allStates.isEmpty) {
          return Center(child: CircularProgressIndicator(color: Colors.white));
        }

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildCompactLocationSelector(
                label: 'Source',
                icon: Icons.my_location,
                value: _sourceState,
                states: provider.allStates,
                onChanged: (StateData? newValue) {
                  setState(() {
                    _sourceState = newValue;
                  });
                },
              ),
              SizedBox(height: 15),
              _buildCompactLocationSelector(
                label: 'Destination',
                icon: Icons.location_on,
                value: _destinationState,
                states: provider.allStates,
                onChanged: (StateData? newValue) {
                  setState(() {
                    _destinationState = newValue;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactLocationSelector({
    required String label,
    required IconData icon,
    required StateData? value,
    required List<StateData> states,
    required ValueChanged<StateData?> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: Color(0xFF0d47a1), size: 20),
        SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<StateData>(
            value: value,
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              isDense: true,
            ),
            items: states.map((StateData state) {
              return DropdownMenuItem<StateData>(
                value: state,
                child: Text(state.state, style: TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchButton() {
    bool _isSameSelected =
        _sourceState != null &&
            _destinationState != null &&
            _sourceState!.state == _destinationState!.state;

    return Column(
      children: [
        if (_isSameSelected)
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              "Source and Destination cannot be same!",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ElevatedButton.icon(
          onPressed: _isSameSelected ? null : _searchRoute,
          icon: Icon(Icons.search, size: 22),
          label: Text(
            'Search Route',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isSameSelected ? Colors.grey : Color(0xFF1a237e),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 5,
          ),
        ),
      ],
    );
  }

  Widget _buildRouteInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Color(0xFF0d47a1), size: 24),
        SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1a237e),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactPriceFooter() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 0),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_routeInfo != null)
            Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: Color(0xFF0d47a1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildRouteInfoItem(
                    Icons.straighten,
                    'Distance',
                    _routeInfo!.distance,
                  ),
                  Container(
                    width: 1,
                    height: 35,
                    color: Color(0xFF0d47a1).withOpacity(0.3),
                  ),
                  _buildRouteInfoItem(
                    Icons.access_time,
                    'Duration',
                    _routeInfo!.duration,
                  ),
                ],
              ),
            ),

          if (_routeInfo == null)
            Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              margin: EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0d47a1).withOpacity(0.1),
                    Color(0xFF2196F3).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(0xFF2196F3).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.route,
                    color: Color(0xFF0d47a1),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Finding best route for you...',
                    style: TextStyle(
                      color: Color(0xFF0d47a1),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

          _buildAllPricesCard(_sourceState!, 'Source', Colors.blue),
          SizedBox(height: 12),

          _buildAllPricesCard(_destinationState!, 'Destination', Colors.red),
        ],
      ),
    );
  }

  Widget _buildAllPricesCard(StateData state, String label, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  label == 'Source' ? Icons.my_location : Icons.location_on,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    state.state,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildPriceItem(
                  'Petrol',
                  state.fuelPrices.petrolPrice,
                  Colors.green,
                  Icons.local_gas_station,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildPriceItem(
                  'Diesel',
                  state.fuelPrices.dieselPrice,
                  Colors.orange,
                  Icons.oil_barrel,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildPriceItem(
                  'CNG',
                  state.fuelPrices.cngPrice,
                  Colors.blue,
                  Icons.ev_station,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceItem(String label, double price, Color color, IconData icon) {
    final bool isAvailable = price > 0;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: isAvailable ? color.withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAvailable ? color.withOpacity(0.4) : Colors.grey[300]!,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 16,
            color: isAvailable ? color : Colors.grey[400],
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: isAvailable ? Colors.grey[700] : Colors.grey[400],
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2),
          Text(
            isAvailable ? '₹$price' : 'N/A',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isAvailable ? color : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}