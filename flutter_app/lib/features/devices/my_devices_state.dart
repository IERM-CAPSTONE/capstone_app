class MyDevicesState {
  final List<Map<String, dynamic>> devices;
  final bool isLoading;
  final String? error;

  const MyDevicesState({
    this.devices = const [],
    this.isLoading = true,
    this.error,
  });

  MyDevicesState copyWith({
    List<Map<String, dynamic>>? devices,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return MyDevicesState(
      devices: devices ?? this.devices,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
