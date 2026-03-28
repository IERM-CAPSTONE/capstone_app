import '../models/user_model.dart';
import '../services/api_service.dart';

class UserRepository {
  final ApiService _apiService;
  
  UserRepository(this._apiService);
  
  // Get current user
  Future<UserModel> getCurrentUser() async {
    try {
      return await _apiService.getCurrentUser();
    } catch (e) {
      throw Exception('Cannot get user information: ${e.toString()}');
    }
  }
  
  // Update user
  Future<UserModel> updateUser(Map<String, dynamic> userData) async {
    try {
      final response = await _apiService.updateUser(userData);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Cannot update user information: ${e.toString()}');
    }
  }
}

