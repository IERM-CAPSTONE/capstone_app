import '../../data/models/user_model.dart';

class ProfileState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isFaceRegistered;

  ProfileState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isFaceRegistered = true, // Default to true based on design
  });

  factory ProfileState.initial() {
    return ProfileState(
      user: null,
      isLoading: true,
      error: null,
      isFaceRegistered: true,
    );
  }

  ProfileState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? isFaceRegistered,
  }) {
    return ProfileState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isFaceRegistered: isFaceRegistered ?? this.isFaceRegistered,
    );
  }
}
