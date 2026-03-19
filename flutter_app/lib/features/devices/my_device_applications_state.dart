class MyDeviceApplicationsState {
  final List<Map<String, dynamic>> applications;
  final bool isLoading;
  final String? error;

  const MyDeviceApplicationsState({
    this.applications = const [],
    this.isLoading = true,
    this.error,
  });

  MyDeviceApplicationsState copyWith({
    List<Map<String, dynamic>>? applications,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return MyDeviceApplicationsState(
      applications: applications ?? this.applications,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
