import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_colors.dart';

class NearbyHospitalsScreen extends StatefulWidget {
  const NearbyHospitalsScreen({super.key});

  @override
  State<NearbyHospitalsScreen> createState() => _NearbyHospitalsScreenState();
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class _NearbyHospitalsScreenState extends State<NearbyHospitalsScreen> {
  LatLng? _userLocation;
  bool _isLoading = true;
  String _errorMsg = '';
  List<HospitalData> _hospitals = [];

  final List<Color> _lineColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    _initLocationAndFetchHospitals();
  }

  Future<void> _initLocationAndFetchHospitals() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMsg = 'Location services are disabled.';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMsg = 'Location permissions are denied';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMsg = 'Location permissions are permanently denied.';
          _isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      final userLoc = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _userLocation = userLoc;
      });

      await _fetchNearbyHospitals(userLoc);

    } catch (e) {
      setState(() {
        _errorMsg = 'Error getting location: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchNearbyHospitals(LatLng userLoc) async {
    try {
      // Overpass API query for hospitals within 10km (10000 meters)
      // Optimized query: limited timeout to 10s and removed 'relation' to speed up processing
      final query = '''
      [out:json][timeout:10];
      (
        node["amenity"="hospital"](around:10000, ${userLoc.latitude}, ${userLoc.longitude});
        way["amenity"="hospital"](around:10000, ${userLoc.latitude}, ${userLoc.longitude});
      );
      out center;
      ''';

      HttpOverrides.global = MyHttpOverrides();
      
      final response = await http.post(
        Uri.parse('https://lz4.overpass-api.de/api/interpreter'),
        headers: {
          'User-Agent': 'HealthCall_AI_PatientPortal/1.0 (contact@healthcall.ai)',
          'Referer': 'https://healthcall.ai'
        },
        body: {'data': query},
      ).timeout(const Duration(seconds: 15));
      
      HttpOverrides.global = null;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List;
        
        List<HospitalData> hospitals = [];
        final Distance distanceCalc = const Distance();

        for (var i = 0; i < elements.length; i++) {
          final el = elements[i];
          double lat = el['lat'] ?? el['center']['lat'];
          double lon = el['lon'] ?? el['center']['lon'];
          String name = el['tags']?['name'] ?? 'Unknown Hospital';
          
          final hospLoc = LatLng(lat, lon);
          final distanceInMeters = distanceCalc.as(LengthUnit.Meter, userLoc, hospLoc);
          
          hospitals.add(HospitalData(
            name: name,
            location: hospLoc,
            distanceInMeters: distanceInMeters,
            color: _lineColors[i % _lineColors.length],
          ));
        }

        // Sort by distance
        hospitals.sort((a, b) => a.distanceInMeters.compareTo(b.distanceInMeters));
        
        // Take top 5
        if (hospitals.length > 5) {
          hospitals = hospitals.sublist(0, 5);
        }

        setState(() {
          _hospitals = hospitals;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMsg = 'Failed to fetch hospitals. Status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Error fetching hospitals: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nearby Hospitals',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    
    if (_errorMsg.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMsg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMsg = '';
                  });
                  _initLocationAndFetchHospitals();
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_userLocation == null) {
      return const Center(child: Text('Unable to determine location.', style: TextStyle(color: AppColors.textPrimary)));
    }

    return Column(
      children: [
        Expanded(
          flex: 2,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: _userLocation!,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.healthcare',
              ),
              PolylineLayer(
                polylines: _hospitals.map((hosp) {
                  return Polyline(
                    points: [_userLocation!, hosp.location],
                    color: hosp.color,
                    strokeWidth: 4.0,
                  );
                }).toList(),
              ),
              MarkerLayer(
                markers: [
                  // User marker
                  Marker(
                    point: _userLocation!,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.my_location, color: Colors.blueAccent, size: 30),
                  ),
                  // Hospital markers
                  ..._hospitals.map((hosp) {
                    return Marker(
                      point: hosp.location,
                      width: 40,
                      height: 40,
                      child: Icon(Icons.local_hospital, color: hosp.color, size: 30),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            color: AppColors.backgroundSecondary,
            child: _hospitals.isEmpty 
              ? const Center(
                  child: Text('No hospitals found nearby.', style: TextStyle(color: AppColors.textPrimary)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _hospitals.length,
                  itemBuilder: (context, index) {
                    final hosp = _hospitals[index];
                    return Card(
                      color: AppColors.surface,
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: hosp.color.withValues(alpha: 0.2),
                          child: Icon(Icons.local_hospital, color: hosp.color),
                        ),
                        title: Text(
                          hosp.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${(hosp.distanceInMeters / 1000).toStringAsFixed(2)} km away',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ),
      ],
    );
  }
}

class HospitalData {
  final String name;
  final LatLng location;
  final double distanceInMeters;
  final Color color;

  HospitalData({
    required this.name,
    required this.location,
    required this.distanceInMeters,
    required this.color,
  });
}
