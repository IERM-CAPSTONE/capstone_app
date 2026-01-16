import '../../data/models/user_model.dart';

class ProctorProfileState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  ProctorProfileState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  factory ProctorProfileState.initial() {
    return ProctorProfileState(
      user: null,
      isLoading: true,
      error: null,
    );
  }

  ProctorProfileState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
  }) {
    return ProctorProfileState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}