class LoginState {
  final String? selectedCampus;
  final bool isLoading;

  const LoginState({
    this.selectedCampus,
    this.isLoading = false,
  });

  bool get isCampusSelected => selectedCampus != null && selectedCampus!.isNotEmpty;
  bool get canLogin => isCampusSelected && !isLoading;

  LoginState copyWith({
    String? selectedCampus,
    bool? isLoading,
  }) {
    return LoginState(
      selectedCampus: selectedCampus ?? this.selectedCampus,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

