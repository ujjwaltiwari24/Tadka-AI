class ApiConstants {
  ApiConstants._();

  // Development backend.
  //
  // We will use adb reverse so the physical Android device
  // can access the backend running on this computer.
  static const String baseUrl = 'http://127.0.0.1:3000';

  static const String generateRecipes = '$baseUrl/api/recipes/generate';
}