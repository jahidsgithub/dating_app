import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

import '../services/api_service.dart';
import 'call_history_screen.dart';
import 'login_screen.dart';
import 'match_screen.dart';
import 'profile_screen.dart';
import 'video_call_screen.dart';
import 'wallet_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  Timer? incomingCallTimer;
  Timer? vibrationTimer;

  bool incomingDialogOpen = false;

  late List<Widget> pages;

  @override
  void initState() {
    super.initState();

    pages = [
      MatchScreen(user: widget.user),
      WalletScreen(user: widget.user),
      CallHistoryScreen(user: widget.user),
      ProfileScreen(user: widget.user),
    ];

    startIncomingCallChecker();
  }

  void startIncomingCallChecker() {
    incomingCallTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => checkIncomingCall(),
    );
  }

  Future<void> startVibration() async {
    bool? hasVibrator = await Vibration.hasVibrator();

    if (hasVibrator == true) {
      vibrationTimer?.cancel();

      vibrationTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        Vibration.vibrate(duration: 600);
      });
    }
  }

  void stopVibration() {
    vibrationTimer?.cancel();
    Vibration.cancel();
  }

  Future<void> checkIncomingCall() async {
    if (incomingDialogOpen) return;

    try {
      final response = await ApiService.checkIncomingCall(
        userId: widget.user["id"].toString(),
      );

      if (response["status"] == true) {
        incomingDialogOpen = true;

        await startVibration();

        showIncomingCallDialog(Map<String, dynamic>.from(response["call"]));
      }
    } catch (e) {
      debugPrint("Incoming call check error: $e");
    }
  }

  void closeIncomingDialog() {
    stopVibration();
    incomingDialogOpen = false;

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void showIncomingCallDialog(Map<String, dynamic> call) {
    String callerName = call["caller_name"]?.toString() ?? "Unknown";
    String callerGender = call["caller_gender"]?.toString() ?? "";
    String callerCountry = call["caller_country"]?.toString() ?? "";
    String callerPhoto = call["caller_photo"]?.toString() ?? "";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xffec4899), Color(0xff8b5cf6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.25),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Incoming Video Call",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 25),

                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(.7),
                      width: 3,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 58,
                    backgroundColor: Colors.white,
                    backgroundImage: callerPhoto.isNotEmpty
                        ? NetworkImage(
                            "http://127.0.0.1/dating_app/$callerPhoto",
                          )
                        : null,
                    child: callerPhoto.isEmpty
                        ? const Icon(Icons.person, size: 65, color: Colors.pink)
                        : null,
                  ),
                ),

                const SizedBox(height: 22),

                Text(
                  callerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "$callerGender  •  $callerCountry",
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),

                const SizedBox(height: 12),

                const Text(
                  "is calling you...",
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),

                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.red,
                      child: IconButton(
                        icon: const Icon(
                          Icons.call_end,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () async {
                          final response = await ApiService.respondCall(
                            requestId: call["id"].toString(),
                            responseText: "rejected",
                          );

                          closeIncomingDialog();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(response["message"].toString()),
                            ),
                          );
                        },
                      ),
                    ),

                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.green,
                      child: IconButton(
                        icon: const Icon(
                          Icons.videocam,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () async {
                          final response = await ApiService.respondCall(
                            requestId: call["id"].toString(),
                            responseText: "accepted",
                          );

                          closeIncomingDialog();

                          if (response["status"] == true) {
                            Map<String, dynamic> callerUser = {
                              "id": call["caller_id"],
                              "name": call["caller_name"],
                              "gender": call["caller_gender"],
                              "country": call["caller_country"],
                              "profile_photo": call["caller_photo"],
                              "coins": widget.user["coins"],
                            };

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VideoCallScreen(
                                  currentUser: widget.user,
                                  matchedUser: callerUser,
                                  agoraChannel: response["agora_channel"]
                                      .toString(),
                                  callId: response["call_id"].toString(),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text("Reject", style: TextStyle(color: Colors.white70)),
                    Text("Accept", style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      stopVibration();
      incomingDialogOpen = false;
    });
  }

  Future<void> logout() async {
    incomingCallTimer?.cancel();
    stopVibration();

    try {
      await ApiService.logout(userId: widget.user["id"].toString());
    } catch (e) {
      debugPrint("Logout API error: $e");
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("user");

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    incomingCallTimer?.cancel();
    stopVibration();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.pink,
        title: const Text("Dating App", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Match"),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: "Wallet",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
