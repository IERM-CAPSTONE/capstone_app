import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/dependency_injection.dart';
import '../../data/services/api_service.dart';
import 'my_device_applications_state.dart';

class MyDeviceApplicationsController
    extends StateNotifier<MyDeviceApplicationsState> {
  MyDeviceApplicationsController() : super(const MyDeviceApplicationsState()) {
    loadApplications();
  }

  Future<void> loadApplications() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final apiService = DependencyInjection.get<ApiService>();
      final applications = await apiService.getMyDeviceApplications();
      state = state.copyWith(
        applications: (applications.data as List).cast<Map<String, dynamic>>(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteApplication(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      final apiService = DependencyInjection.get<ApiService>();
      await apiService.deleteDeviceApplication(id);
      await loadApplications();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final myDeviceApplicationsControllerProvider =
    StateNotifierProvider.autoDispose<MyDeviceApplicationsController,
        MyDeviceApplicationsState>((ref) {
  return MyDeviceApplicationsController();
});
