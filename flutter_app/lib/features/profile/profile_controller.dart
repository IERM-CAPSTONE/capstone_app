import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/routes/app_routes.dart';
import '../../config/dependency_injection.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/api_service.dart';
import '../../data/services/face_registration_service.dart';
import 'profile_state.dart';

class ProfileController extends StateNotifier<ProfileState> {
  ProfileController() : super(ProfileState.initial()) {
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    state = state.copyWith(isLoading: true);
    try {
      final authService = DependencyInjection.get<AuthService>();
      var user = await authService.getSavedUserData();

      // Attempt to refresh user from API for latest fields (role, campus, etc.)
      try {
        final apiService = DependencyInjection.get<ApiService>();
        final remoteUser = await apiService.getCurrentUser();
        user = remoteUser;
        // Persist updated user locally
        await authService.saveUserData(user);
      } catch (_) {
        // ignore and fallback to saved user
      }

      if (user != null) {
        state = state.copyWith(
          isLoading: false,
          user: user,
        );

        // Check face registration status
        if (user.id != null) {
          final faceService =
              DependencyInjection.get<FaceRegistrationService>();
          final result = await faceService.checkRegistrationStatus(user.id!);
          if (result['isRegistered'] == true) {
            state = state.copyWith(isFaceRegistered: true);
          }
        }

        // Load device registration status for staff roles that use device approval.
        if (user.role?.toUpperCase() == 'HALL_INVIGILATOR' ||
            user.role?.toUpperCase() == 'PROCTOR') {
          await loadDeviceRegistrationStatus();
        }
      } else {
        // Fallback or handle null user (maybe redirect to login?)
        state = state.copyWith(
          isLoading: false,
          error: 'User data not found',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      final authService = DependencyInjection.get<AuthService>();
      await authService.signOut();

      if (context.mounted) {
        context.go(AppRoutes.login);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  Future<String> _getCurrentDeviceSerial() async {
    final deviceInfo = DeviceInfoPlugin();

    try {
      final androidInfo = await deviceInfo.androidInfo;
      final serial = androidInfo.id;
      if (serial.isNotEmpty) {
        return serial;
      }
    } catch (_) {}

    try {
      final iosInfo = await deviceInfo.iosInfo;
      final serial = iosInfo.identifierForVendor;
      if (serial != null && serial.isNotEmpty) {
        return serial;
      }
    } catch (_) {}

    try {
      final windowsInfo = await deviceInfo.windowsInfo;
      final serial = windowsInfo.computerName;
      if (serial.isNotEmpty) {
        return serial;
      }
    } catch (_) {}

    try {
      final macOsInfo = await deviceInfo.macOsInfo;
      final serial = macOsInfo.computerName;
      if (serial.isNotEmpty) {
        return serial;
      }
    } catch (_) {}

    return '';
  }

  Future<DeviceRegistrationStatus> loadDeviceRegistrationStatus() async {
    try {
      final apiService = DependencyInjection.get<ApiService>();
      final currentSerial = await _getCurrentDeviceSerial();

      final devicesResponse = await apiService.getMyDevices();
      final devices = (devicesResponse.data as List).cast<Map<String, dynamic>>();

      final currentDevice = devices.firstWhere(
        (device) =>
            device['serial']?.toString().toLowerCase() ==
            currentSerial.toLowerCase(),
        orElse: () => {},
      );

      if (currentDevice.isNotEmpty) {
        if (currentDevice['isActive'] == true) {
          state = state.copyWith(
            deviceStatus: DeviceRegistrationStatus.active,
            activeDevice: currentDevice,
            latestApplication: null,
          );
          return DeviceRegistrationStatus.active;
        }

        final applicationsResponse = await apiService.getMyDeviceApplications();
        final applications = (applicationsResponse.data as List).cast<Map<String, dynamic>>();

        final relatedApplications = applications.where(
          (app) => app['deviceId'] == currentDevice['id'],
        );

        if (relatedApplications.isEmpty) {
          state = state.copyWith(
            deviceStatus: DeviceRegistrationStatus.none,
            activeDevice: currentDevice,
            latestApplication: null,
          );
          return DeviceRegistrationStatus.none;
        }

        final sortedApplications = relatedApplications.toList();
        sortedApplications.sort((a, b) {
          final aDate = DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });

        final latest = sortedApplications.first;
        final status = latest['status']?.toString().toUpperCase();
        final resolvedStatus = status == 'PENDING'
            ? DeviceRegistrationStatus.pending
            : DeviceRegistrationStatus.none;

        state = state.copyWith(
          deviceStatus: resolvedStatus,
          activeDevice: currentDevice,
          latestApplication: latest,
        );
        return resolvedStatus;
      }

      // If current device cannot be found by serial, consider not registered.
      state = state.copyWith(
        deviceStatus: DeviceRegistrationStatus.none,
        activeDevice: null,
        latestApplication: null,
      );
      return DeviceRegistrationStatus.none;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return DeviceRegistrationStatus.none;
    }
  }

  Future<void> updateFaceData() async {
    // TODO: Implement face data update
  }

  Future<void> changePassword() async {
    // TODO: Implement password change
  }

  Future<void> requestSupport() async {
    // TODO: Implement support request
  }

  Future<void> verifyNewDevice() async {
    try {
      final apiService = DependencyInjection.get<ApiService>();
      final deviceInfo = DeviceInfoPlugin();

      String serial = '';
      String name = '';
      Map<String, dynamic> metadata = {};

      final androidInfo = await deviceInfo.androidInfo;
      final packageInfo = await PackageInfo.fromPlatform();
      serial = androidInfo.id;
      name = '${androidInfo.manufacturer} ${androidInfo.model}'.trim();
      metadata = {
        'brand': androidInfo.brand,
        'model': androidInfo.model,
        'osName': 'Android',
        'osVersion': androidInfo.version.release,
        'appVersion': packageInfo.version,
        'deviceName': androidInfo.device,
        'buildNumber': packageInfo.buildNumber,
        'manufacturer': androidInfo.manufacturer,
        'isPhysicalDevice': androidInfo.isPhysicalDevice,
        'product': androidInfo.product,
        'androidId': androidInfo.id,
        'sdkInt': androidInfo.version.sdkInt,
      };

      if (serial.isEmpty) {
        throw Exception('Không thể lấy serial của thiết bị');
      }

      final payload = {
        'serial': serial,
        'name': name.isEmpty ? 'Unknown Device' : name,
        'metadata': metadata,
      };

      await apiService.registerDeviceApplication(payload);
      await loadDeviceRegistrationStatus();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> openMyDeviceList(BuildContext context) async {
    if (context.mounted) {
      context.go(AppRoutes.myDeviceList);
    }
  }
}

final profileControllerProvider =
    StateNotifierProvider.autoDispose<ProfileController, ProfileState>((ref) {
  return ProfileController();
});
