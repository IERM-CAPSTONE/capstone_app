class LoginState {
  final String? selectedCampus;
  final bool isLoading;
  final String? errorMessage;

  const LoginState({
    this.selectedCampus,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isCampusSelected => selectedCampus != null && selectedCampus!.isNotEmpty;
  bool get canLogin => isCampusSelected && !isLoading;

  LoginState copyWith({
    String? selectedCampus,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LoginState(
      selectedCampus: selectedCampus ?? this.selectedCampus,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

