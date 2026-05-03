import '../../data/models/user_model.dart';

enum DeviceRegistrationStatus {
  none,
  pending,
  active,
}

class ProfileState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isFaceRegistered;
  final DeviceRegistrationStatus deviceStatus;
  final Map<String, dynamic>? activeDevice;
  final Map<String, dynamic>? latestApplication;

  ProfileState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isFaceRegistered = false,
    this.deviceStatus = DeviceRegistrationStatus.none,
    this.activeDevice,
    this.latestApplication,
  });

  factory ProfileState.initial() {
    return ProfileState(
      user: null,
      isLoading: true,
      error: null,
      isFaceRegistered: false,
      deviceStatus: DeviceRegistrationStatus.none,
      activeDevice: null,
      latestApplication: null,
    );
  }

  ProfileState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? isFaceRegistered,
    DeviceRegistrationStatus? deviceStatus,
    Map<String, dynamic>? activeDevice,
    Map<String, dynamic>? latestApplication,
  }) {
    return ProfileState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isFaceRegistered: isFaceRegistered ?? this.isFaceRegistered,
      deviceStatus: deviceStatus ?? this.deviceStatus,
      activeDevice: activeDevice ?? this.activeDevice,
      latestApplication: latestApplication ?? this.latestApplication,
    );
  }
}
