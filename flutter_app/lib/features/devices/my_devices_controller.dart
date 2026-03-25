import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/dependency_injection.dart';
import '../../data/services/api_service.dart';
import 'my_devices_state.dart';

class MyDevicesController extends StateNotifier<MyDevicesState> {
  MyDevicesController() : super(const MyDevicesState()) {
    loadDevices();
  }

  Future<void> loadDevices() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final apiService = DependencyInjection.get<ApiService>();
      final result = await apiService.getMyDevices();
      List<Map<String, dynamic>> devices = [];
      if (result is List) {
        devices = List<Map<String, dynamic>>.from(result);
      } else if (result is Map && result['devices'] != null) {
        devices = List<Map<String, dynamic>>.from(result['devices']);
      }
      state = state.copyWith(
        devices: devices,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

}

final myDevicesControllerProvider =
    StateNotifierProvider.autoDispose<MyDevicesController, MyDevicesState>((ref) {
  return MyDevicesController();
});
