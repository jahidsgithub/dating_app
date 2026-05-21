import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiService {
  /* LOGIN */
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/login.php"),
      body: {"email": email, "password": password},
    );

    return jsonDecode(response.body);
  }

  /* REGISTER */
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String gender,
    required String age,
    required String country,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/register.php"),
      body: {
        "name": name,
        "email": email,
        "phone": phone,
        "password": password,
        "gender": gender,
        "age": age,
        "country": country,
      },
    );

    return jsonDecode(response.body);
  }

  /* USER DETAILS */
  static Future<Map<String, dynamic>> userDetails({
    required String userId,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/user_details.php"),
      body: {"user_id": userId},
    );

    return jsonDecode(response.body);
  }

  /* UPDATE PROFILE */
  static Future<Map<String, dynamic>> updateProfile({
    required String userId,
    required String name,
    required String phone,
    required String gender,
    required String age,
    required String country,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/update_profile.php"),
      body: {
        "user_id": userId,
        "name": name,
        "phone": phone,
        "gender": gender,
        "age": age,
        "country": country,
      },
    );

    return jsonDecode(response.body);
  }

  /* UPDATE ACTIVITY */
  static Future<Map<String, dynamic>> updateActivity({
    required String userId,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/update_activity.php"),
      body: {"user_id": userId},
    );

    return jsonDecode(response.body);
  }

  /* ONLINE USERS COUNT */
  static Future<Map<String, dynamic>> onlineUsersCount() async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/online_users_count.php"),
    );

    return jsonDecode(response.body);
  }

  /* FIND MATCH */
  static Future<Map<String, dynamic>> findMatch({
    required String userId,
    required String lookingFor,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/find_match.php"),
      body: {"user_id": userId, "looking_for": lookingFor},
    );

    return jsonDecode(response.body);
  }

  /* WALLET */
  static Future<Map<String, dynamic>> wallet({required String userId}) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/wallet.php"),
      body: {"user_id": userId},
    );

    return jsonDecode(response.body);
  }

  /* COIN PACKAGES */
  static Future<Map<String, dynamic>> coinPackages() async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/coin_packages.php"),
    );

    return jsonDecode(response.body);
  }

  /* PURCHASE COIN */
  static Future<Map<String, dynamic>> purchaseCoin({
    required String userId,
    required String packageId,
    required String paymentMethod,
    required String transactionId,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/purchase_coin.php"),
      body: {
        "user_id": userId,
        "package_id": packageId,
        "payment_method": paymentMethod,
        "transaction_id": transactionId,
      },
    );

    return jsonDecode(response.body);
  }

  /* DEDUCT COIN */
  static Future<Map<String, dynamic>> deductCoin({
    required String userId,
    required String coins,
    String callId = "",
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/deduct_coin.php"),
      body: {"user_id": userId, "coins": coins, "call_id": callId},
    );

    return jsonDecode(response.body);
  }

  /* END CALL */
  static Future<Map<String, dynamic>> endCall({required String callId}) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/end_call.php"),
      body: {"call_id": callId},
    );

    return jsonDecode(response.body);
  }

  /* SEND CALL REQUEST */
  static Future<Map<String, dynamic>> sendCallRequest({
    required String callerId,
    required String receiverId,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/send_call_request.php"),
      body: {"caller_id": callerId, "receiver_id": receiverId},
    );

    return jsonDecode(response.body);
  }

  /* CHECK INCOMING CALL */
  static Future<Map<String, dynamic>> checkIncomingCall({
    required String userId,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/check_incoming_call.php"),
      body: {"user_id": userId},
    );

    return jsonDecode(response.body);
  }

  /* RESPOND CALL */
  static Future<Map<String, dynamic>> respondCall({
    required String requestId,
    required String responseText,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/respond_call.php"),
      body: {"request_id": requestId, "response": responseText},
    );

    return jsonDecode(response.body);
  }

  /* CHECK CALL STATUS */
  static Future<Map<String, dynamic>> checkCallStatus({
    required String requestId,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/check_call_status.php"),
      body: {"request_id": requestId},
    );

    return jsonDecode(response.body);
  }

  /* CHECK LIVE CALL */
  static Future<Map<String, dynamic>> checkLiveCall({
    required String callId,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/check_live_call.php"),
      body: {"call_id": callId},
    );

    return jsonDecode(response.body);
  }

  /* CALL HISTORY */
  static Future<Map<String, dynamic>> callHistory({
    required String userId,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/call_history.php"),
      body: {"user_id": userId},
    );

    return jsonDecode(response.body);
  }

  /* BLOCK USER */
  static Future<Map<String, dynamic>> blockUser({
    required String blockerId,
    required String blockedUserId,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/block_user.php"),
      body: {"blocker_id": blockerId, "blocked_user_id": blockedUserId},
    );

    return jsonDecode(response.body);
  }

  /* BLOCKED USERS */
  static Future<Map<String, dynamic>> blockedUsers({
    required String userId,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/blocked_users.php"),
      body: {"user_id": userId},
    );

    return jsonDecode(response.body);
  }

  /* UNBLOCK USER */
  static Future<Map<String, dynamic>> unblockUser({
    required String blockerId,
    required String blockedUserId,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/unblock_user.php"),
      body: {"blocker_id": blockerId, "blocked_user_id": blockedUserId},
    );

    return jsonDecode(response.body);
  }

  /* LOGOUT */
  static Future<Map<String, dynamic>> logout({required String userId}) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/logout.php"),
      body: {"user_id": userId},
    );

    return jsonDecode(response.body);
  }

  /* REPORT USER */
  static Future<Map<String, dynamic>> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/report_user.php"),
      body: {
        "reporter_id": reporterId,
        "reported_user_id": reportedUserId,
        "reason": reason,
      },
    );

    return jsonDecode(response.body);
  }

  /* UPLOAD PROFILE PHOTO */
  static Future<Map<String, dynamic>> uploadProfilePhoto({
    required String userId,
    required File imageFile,
  }) async {
    var request = http.MultipartRequest(
      "POST",
      Uri.parse("${ApiConfig.baseUrl}/upload_profile_photo.php"),
    );

    request.fields["user_id"] = userId;

    request.files.add(
      await http.MultipartFile.fromPath("photo", imageFile.path),
    );

    var response = await request.send();

    var responseData = await response.stream.bytesToString();

    return jsonDecode(responseData);
  }
}
