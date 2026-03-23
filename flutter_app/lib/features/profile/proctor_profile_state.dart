import '../../data/models/user_model.dart';

enum DeviceRegistrationStatus {
  none,
  pending,
  active,
}

class ProctorProfileState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final DeviceRegistrationStatus deviceStatus;
  final Map<String, dynamic>? activeDevice;
  final Map<String, dynamic>? latestApplication;

  ProctorProfileState({
    this.user,
    this.isLoading = false,
    this.error,
    this.deviceStatus = DeviceRegistrationStatus.none,
    this.activeDevice,
    this.latestApplication,
  });

  factory ProctorProfileState.initial() {
    return ProctorProfileState(
      user: null,
      isLoading: true,
      error: null,
      deviceStatus: DeviceRegistrationStatus.none,
      activeDevice: null,
      latestApplication: null,
    );
  }

  ProctorProfileState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    DeviceRegistrationStatus? deviceStatus,
    Map<String, dynamic>? activeDevice,
    Map<String, dynamic>? latestApplication,
  }) {
    return ProctorProfileState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      deviceStatus: deviceStatus ?? this.deviceStatus,
      activeDevice: activeDevice ?? this.activeDevice,
      latestApplication: latestApplication ?? this.latestApplication,
    );
  }
}
