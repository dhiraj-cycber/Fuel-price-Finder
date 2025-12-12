
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../Model/state_model.dart';
import '../Provider/fuel_price_provider.dart';

class StateDetailScreen extends StatefulWidget {
  final StateData state;

  const StateDetailScreen({Key? key, required this.state}) : super(key: key);

  @override
  State<StateDetailScreen> createState() => _StateDetailScreenState();
}

class _StateDetailScreenState extends State<StateDetailScreen> {
  late GoogleMapController _mapController;
  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _setupMarkers();
  }

  void _setupMarkers() {
    final provider = Provider.of<FuelPriceProvider>(context, listen: false);

    _markers.add(
      Marker(
        markerId: MarkerId('destination'),
        position: LatLng(widget.state.lat, widget.state.long),
        infoWindow: InfoWindow(
          title: widget.state.state,
          snippet: 'Petrol: ₹${widget.state.fuelPrices.petrolPrice}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    if (provider.currentLocation != null) {
      final delhiState = provider.allStates.firstWhere(
            (state) => state.state.toLowerCase().contains('delhi'),
        orElse: () => provider.allStates.first,
      );

      _markers.add(
        Marker(
          markerId: MarkerId('origin'),
          position: LatLng(
            provider.currentLocation!['lat']!,
            provider.currentLocation!['lng']!,
          ),
          infoWindow: InfoWindow(
            title: 'Delhi (Current Location)',
            snippet: 'Petrol: ₹${delhiState.fuelPrices.petrolPrice}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
      if (provider.routeInfo != null &&
          provider.routeInfo!.polylinePoints.isNotEmpty) {
        List<LatLng> polylineCoordinates = provider.routeInfo!.polylinePoints
            .map((point) => LatLng(point['lat']!, point['lng']!))
            .toList();

        _polylines.add(
          Polyline(
            polylineId: PolylineId('route'),
            points: polylineCoordinates,
            color: Color(0xFF0d47a1),
            width: 5,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Maps
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.state.lat, widget.state.long),
              zoom: 6,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            zoomControlsEnabled: false,
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 15,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              elevation: 4,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.arrow_back,
                    color: Color(0xFF1a237e),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1a237e), Color(0xFF0d47a1)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.location_city,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.state.state,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1a237e),
                            ),
                          ),
                          Text(
                            'Fuel Prices (per liter)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),
                _buildFuelPricesGrid(),
                Consumer<FuelPriceProvider>(
                  builder: (context, provider, child) {
                    if (provider.routeInfo != null) {
                      return Column(
                        children: [
                          SizedBox(height: 20),
                          _buildRouteInfo(provider.routeInfo!),
                        ],
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuelPricesGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFuelPriceCard(
                'Petrol',
                widget.state.fuelPrices.petrolPrice,
                Icons.local_gas_station,
                Colors.green,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildFuelPriceCard(
                'Diesel',
                widget.state.fuelPrices.dieselPrice,
                Icons.oil_barrel,
                Colors.orange,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildFuelPriceCard(
                'CNG',
                widget.state.fuelPrices.cngPrice,
                Icons.ev_station,
                Colors.blue,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildFuelPriceCard(
                'Electric',
                widget.state.fuelPrices.electricityPrice,
                Icons.electric_bolt,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFuelPriceCard(
      String label, double price, IconData icon, Color color) {
    final bool isAvailable = price > 0;

    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: isAvailable
            ? LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        )
            : LinearGradient(
          colors: [
            Colors.grey[100]!,
            Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isAvailable ? color.withOpacity(0.3) : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isAvailable ? color : Colors.grey[400],
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isAvailable ? Colors.grey[700] : Colors.grey[400],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            isAvailable ? '₹ $price' : 'N/A',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isAvailable ? color : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo(RouteInfo routeInfo) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1a237e).withOpacity(0.1),
            Color(0xFF0d47a1).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Color(0xFF0d47a1).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_car,
                color: Color(0xFF0d47a1),
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Route Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a237e),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildRouteInfoItem(
                  Icons.straighten,
                  'Distance',
                  routeInfo.distance,
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: _buildRouteInfoItem(
                  Icons.access_time,
                  'Duration',
                  routeInfo.duration,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Color(0xFF0d47a1)),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1a237e),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}