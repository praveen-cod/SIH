import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/glass_card.dart';
import '../../repositories/auth_repository.dart';

class ActivityLogScreen extends ConsumerStatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  ConsumerState<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends ConsumerState<ActivityLogScreen> {
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _skip = 0;
  final int _limit = 20;
  List<dynamic> _activities = [];
  String? _error;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchActivity();
    
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_hasMore && !_isLoadingMore) {
      _fetchActivity(loadMore: true);
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _fetchActivity({bool loadMore = false}) async {
    if (loadMore) {
      setState(() => _isLoadingMore = true);
    }
    
    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() {
        _error = "User not logged in.";
        _isLoading = false;
        _isLoadingMore = false;
      });
      return;
    }

    String endpoint = '/api/patients/me/activity?skip=$_skip&limit=$_limit';
    if (user.role.name == 'doctor') {
      endpoint = '/api/doctor/me/activity?skip=$_skip&limit=$_limit';
    } else if (user.role.name == 'admin') {
      endpoint = '/api/admin/audit-logs?skip=$_skip&limit=$_limit';
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(endpoint, requireAuth: true);
      final newActivities = response as List<dynamic>;
      
      setState(() {
        if (loadMore) {
          _activities.addAll(newActivities);
        } else {
          _activities = newActivities;
        }
        
        _skip += newActivities.length;
        _hasMore = newActivities.length == _limit;
        
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        if (!loadMore) _error = "Failed to load activity logs: $e";
        _isLoading = false;
        _isLoadingMore = false;
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
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              final user = ref.read(currentUserProvider);
              if (user?.role.name == 'doctor') {
                context.go('/doctor-dashboard');
              } else if (user?.role.name == 'admin') {
                context.go('/admin-dashboard');
              } else {
                context.go('/patient-dashboard');
              }
            }
          },
        ),
        title: const Text('Recent Activity', style: TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: AppColors.error)))
              : _activities.isEmpty
                  ? const Center(child: Text("No recent activity.", style: TextStyle(color: AppColors.textMuted)))
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _activities.length,
                            itemBuilder: (context, index) {
                        final act = _activities[index];
                        final date = DateTime.tryParse(act['created_at'] ?? '');
                        final dateString = date != null ? '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}' : '';
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        (act['user_role'] != null ? '[${act['user_role'].toString().toUpperCase()}${act['user_id'] != null ? ' - ${act['user_id']}' : ''}] ' : '') + (act['action'] ?? 'Unknown Action'),
                                        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Text(
                                      dateString,
                                      style: AppTextStyles.caption.copyWith(color: AppColors.primaryLight),
                                    ),
                                  ],
                                ),
                                if (act['details'] != null && act['details'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    act['details'],
                                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                                  ),
                                ]
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_hasMore || _skip > _limit)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_skip > _limit)
                             ElevatedButton.icon(
                               onPressed: _isLoadingMore ? null : () {
                                 setState(() {
                                   _skip = (_skip - _limit * 2).clamp(0, 99999);
                                 });
                                 _fetchActivity(loadMore: false);
                               },
                               icon: const Icon(Icons.arrow_back_ios, size: 14),
                               label: const Text('Previous'),
                             ),
                          if (_skip > _limit && _hasMore) const SizedBox(width: 16),
                          if (_hasMore)
                             ElevatedButton(
                               onPressed: _isLoadingMore ? null : _nextPage,
                               child: Row(
                                 mainAxisSize: MainAxisSize.min,
                                 children: const [
                                   Text('Next'),
                                   SizedBox(width: 8),
                                   Icon(Icons.arrow_forward_ios, size: 14),
                                 ],
                               ),
                             ),
                        ],
                      ),
                    ),
                ],
              ),
    );
  }
}

