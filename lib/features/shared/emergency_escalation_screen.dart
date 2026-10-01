import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/admin_dashboard_models.dart';
import '../../repositories/admin_repository.dart';

class EmergencyEscalationScreen extends ConsumerStatefulWidget {
 const EmergencyEscalationScreen({super.key});

 @override
 ConsumerState<EmergencyEscalationScreen> createState() => _EmergencyEscalationScreenState();
}

class _EmergencyEscalationScreenState extends ConsumerState<EmergencyEscalationScreen> {
 List<EmergencyAlert>? _alerts;
 bool _isLoading = true;
 bool _isListVisible = true;

 @override
 void initState() {
  super.initState();
  _loadAlerts();
 }

 Future<void> _loadAlerts() async {
  try {
   final alerts = await ref.read(adminRepositoryProvider).getEmergencyAlerts();
   if (mounted) {
    setState(() {
     _alerts = alerts;
     _isLoading = false;
    });
   }
  } catch (e) {
   if (mounted) {
    setState(() {
     _isLoading = false;
    });
   }
  }
 }

 void _showPatientDetails(EmergencyAlert alert) {
  showModalBottomSheet(
   context: context,
   backgroundColor: AppColors.backgroundSecondary,
   shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
   ),
   builder: (context) {
    return SafeArea(
     child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
       child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
          Text('Patient Details', style: AppTextStyles.headingSmall),
          Container(
           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
           decoration: BoxDecoration(
            color: alert.severityLevel == 'critical' 
              ? AppColors.error 
              : AppColors.warning,
            borderRadius: BorderRadius.circular(6),
           ),
           child: Text(
            alert.severityLevel.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
           ),
          ),
         ],
        ),
        const SizedBox(height: 16),
        Text('Patient Name: ${alert.patientName ?? 'Unknown'}', style: AppTextStyles.labelLarge),
        const SizedBox(height: 4),
        Text('Patient ID: ${alert.patientId}', style: AppTextStyles.labelMedium),
        const SizedBox(height: 8),
        Text('Reported: ${alert.requestedTimeAgo}', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 16),
        Text('Symptoms Summary:', style: AppTextStyles.labelSmall),
        const SizedBox(height: 4),
        Text(alert.symptomSummary, style: AppTextStyles.bodyMedium),
         if (alert.emergencyImageUrl != null) ...[
          const SizedBox(height: 16),
          Text('Emergency Image:', style: AppTextStyles.labelSmall),
          const SizedBox(height: 8),
          ClipRRect(
           borderRadius: BorderRadius.circular(12),
           child: Image.network(
            alert.emergencyImageUrl!,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
           ),
          ),
         ],
         if (alert.latitude != null && alert.longitude != null) ...[
          const SizedBox(height: 16),
          Text('Patient Location:', style: AppTextStyles.labelSmall),
          const SizedBox(height: 8),
          ClipRRect(
           borderRadius: BorderRadius.circular(14),
           child: SizedBox(
            height: 200,
            child: FlutterMap(
             options: MapOptions(
              initialCenter: LatLng(double.parse(alert.latitude!), double.parse(alert.longitude!)),
              initialZoom: 15.0,
             ),
             children: [
              TileLayer(
               urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
               userAgentPackageName: 'com.healthcallai.app',
              ),
              MarkerLayer(
               markers: [
                Marker(
                 point: LatLng(double.parse(alert.latitude!), double.parse(alert.longitude!)),
                 width: 36,
                 height: 36,
                 child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                ),
               ],
              ),
             ],
            ),
           ),
          ),
         ],
        const SizedBox(height: 24),
        SizedBox(
         width: double.infinity,
         child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
           backgroundColor: AppColors.primary,
           foregroundColor: Colors.white,
           padding: const EdgeInsets.symmetric(vertical: 14),
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Close'),
         ),
        ),
       ],
      ),
     ),
    ),
   );
  },
  );
 }

 @override
 Widget build(BuildContext context) {
  return Scaffold(
   backgroundColor: AppColors.background,
   appBar: AppBar(
    backgroundColor: AppColors.background,
    elevation: 0,
    title: const Text('Emergency Alerts', style: TextStyle(color: AppColors.textPrimary)),
    iconTheme: const IconThemeData(color: AppColors.textPrimary),
   ),
   body: _isLoading 
    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
    : Stack(
     children: [
      Column(
       children: [
        Expanded(
         flex: _isListVisible ? 2 : 5,
         child: _buildMapView(),
        ),
        if (_isListVisible)
         Container(
          height: 2,
          color: AppColors.border,
         ),
        if (_isListVisible)
         Expanded(
          flex: 3,
          child: _buildListView(),
         ),
       ],
      ),
      Positioned(
       right: 16,
       bottom: 16,
       child: FloatingActionButton.small(
        onPressed: () {
         setState(() {
          _isListVisible = !_isListVisible;
         });
        },
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        child: Icon(_isListVisible ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up),
       ),
      ),
     ],
    ),
  );
 }

 Widget _buildMapView() {
  if (_alerts == null || _alerts!.isEmpty) {
   return const Center(child: Text('No map data available.', style: TextStyle(color: AppColors.textSecondary)));
  }

  final markers = _alerts!.where((a) => a.latitude != null && a.longitude != null).map((alert) {
   final color = alert.severityLevel == 'critical' ? Colors.red : Colors.orange;
   return Marker(
    point: LatLng(double.parse(alert.latitude!), double.parse(alert.longitude!)),
    width: 40,
    height: 40,
    child: GestureDetector(
     onTap: () => _showPatientDetails(alert),
     child: alert.emergencyImageUrl != null
         ? Container(
             decoration: BoxDecoration(
               shape: BoxShape.circle,
               border: Border.all(color: color, width: 3),
             ),
             child: CircleAvatar(
               backgroundImage: NetworkImage(alert.emergencyImageUrl!),
               radius: 20,
             ),
           )
         : Icon(Icons.location_on, color: color, size: 40),
    ),
   );
  }).toList();

  final initialAlert = _alerts!.firstWhere((a) => a.latitude != null && a.longitude != null, orElse: () => _alerts!.first);
  final initialPos = (initialAlert.latitude != null && initialAlert.longitude != null) 
    ? LatLng(double.parse(initialAlert.latitude!), double.parse(initialAlert.longitude!))
    : const LatLng(37.7749, -122.4194);

  return FlutterMap(
   options: MapOptions(
    initialCenter: initialPos,
    initialZoom: 12.0,
   ),
   children: [
    TileLayer(
     urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
     userAgentPackageName: 'com.healthcallai.app',
    ),
    MarkerLayer(markers: markers),
   ],
  );
 }

 Widget _buildListView() {
  if (_alerts == null || _alerts!.isEmpty) {
   return const Center(child: Text('No emergency patients found.', style: TextStyle(color: AppColors.textSecondary)));
  }

  return ListView.builder(
   padding: const EdgeInsets.all(16),
   itemCount: _alerts!.length,
   itemBuilder: (context, index) {
    final alert = _alerts![index];
    return Card(
     color: AppColors.surface,
     margin: const EdgeInsets.only(bottom: 12),
     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
     child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: Container(
       width: 12,
       decoration: BoxDecoration(
        color: alert.severityLevel == 'critical' ? AppColors.error : AppColors.warning,
        borderRadius: BorderRadius.circular(6),
       ),
      ),
      title: Text(alert.patientName ?? 'Patient ${alert.patientId}', style: AppTextStyles.labelLarge),
      subtitle: Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
        const SizedBox(height: 6),
        Text(alert.symptomSummary, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodySmall),
        const SizedBox(height: 6),
        Text('Reported: ${alert.requestedTimeAgo}', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
       ],
      ),
      onTap: () => _showPatientDetails(alert),
     ),
    );
   },
  );
 }
}
