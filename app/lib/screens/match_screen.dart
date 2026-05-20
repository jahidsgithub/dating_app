import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'video_call_screen.dart';

class MatchScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const MatchScreen({super.key, required this.user});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  bool isSearching = false;
  bool callLoading = false;

  String lookingFor = "female";

  Map<String, dynamic>? matchedUser;

  String callRequestId = "";
  String agoraChannel = "";
  String callId = "";

  Timer? callStatusTimer;
  Timer? timeoutTimer;

  int ringingSeconds = 0;
  int maxRingingSeconds = 30;

  Future<void> findMatch() async {
    setState(() {
      isSearching = true;
      matchedUser = null;
      callRequestId = "";
      agoraChannel = "";
      callId = "";
      ringingSeconds = 0;
    });

    try {
      final response = await ApiService.findMatch(
        userId: widget.user["id"].toString(),
        lookingFor: lookingFor,
      );

      setState(() => isSearching = false);

      if (response["status"] == true) {
        setState(() {
          matchedUser = Map<String, dynamic>.from(response["matched_user"]);
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response["message"].toString())));
      }
    } catch (e) {
      setState(() => isSearching = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> sendCallRequest() async {
    if (matchedUser == null) return;

    setState(() {
      callLoading = true;
      ringingSeconds = 0;
    });

    try {
      final response = await ApiService.sendCallRequest(
        callerId: widget.user["id"].toString(),
        receiverId: matchedUser!["id"].toString(),
      );

      if (response["status"] == true) {
        callRequestId = response["request_id"].toString();
        agoraChannel = response["agora_channel"].toString();

        showRingingDialog();
        startCheckingCallStatus();
        startCallTimeout();
      } else {
        setState(() => callLoading = false);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response["message"].toString())));
      }
    } catch (e) {
      setState(() => callLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Call request error: $e")));
    }
  }

  void startCallTimeout() {
    timeoutTimer?.cancel();

    timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return;

      setState(() {
        ringingSeconds++;
      });

      if (ringingSeconds >= maxRingingSeconds) {
        timer.cancel();
        await timeoutCall();
      }
    });
  }

  Future<void> timeoutCall() async {
    callStatusTimer?.cancel();
    timeoutTimer?.cancel();

    if (callRequestId.isNotEmpty) {
      try {
        await ApiService.respondCall(
          requestId: callRequestId,
          responseText: "ended",
        );
      } catch (e) {
        debugPrint("Timeout call error: $e");
      }
    }

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    setState(() => callLoading = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Call timeout. No answer.")));
  }

  void showRingingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Timer.periodic(const Duration(seconds: 1), (timer) {
              if (!mounted || !callLoading) {
                timer.cancel();
                return;
              }

              setDialogState(() {});
            });

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text("Calling..."),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.pink),

                  const SizedBox(height: 20),

                  Text(
                    "Ringing ${matchedUser?["name"] ?? "User"}...",
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Timeout in ${maxRingingSeconds - ringingSeconds}s",
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: cancelCallRequest,
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void startCheckingCallStatus() {
    callStatusTimer?.cancel();

    callStatusTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (callRequestId.isEmpty) return;

      try {
        final response = await ApiService.checkCallStatus(
          requestId: callRequestId,
        );

        if (response["status"] == true) {
          String status = response["call_status"].toString();

          if (status == "accepted") {
            callStatusTimer?.cancel();
            timeoutTimer?.cancel();

            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }

            setState(() => callLoading = false);

            callId = response["call_id"]?.toString() ?? "";

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VideoCallScreen(
                  currentUser: widget.user,
                  matchedUser: matchedUser!,
                  agoraChannel: agoraChannel,
                  callId: callId,
                ),
              ),
            );
          }

          if (status == "rejected" || status == "ended") {
            callStatusTimer?.cancel();
            timeoutTimer?.cancel();

            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }

            setState(() => callLoading = false);

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Call $status")));
          }
        }
      } catch (e) {
        debugPrint("Call status error: $e");
      }
    });
  }

  Future<void> cancelCallRequest() async {
    callStatusTimer?.cancel();
    timeoutTimer?.cancel();

    if (callRequestId.isNotEmpty) {
      try {
        await ApiService.respondCall(
          requestId: callRequestId,
          responseText: "ended",
        );
      } catch (e) {
        debugPrint("Cancel call error: $e");
      }
    }

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    setState(() => callLoading = false);
  }

  Widget matchedUserCard() {
    if (matchedUser == null) return const SizedBox();

    String photo = matchedUser!["profile_photo"]?.toString() ?? "";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 55,
            backgroundColor: Colors.pink.shade100,
            backgroundImage: photo.isNotEmpty
                ? NetworkImage("http://127.0.0.1/dating_app/$photo")
                : null,
            child: photo.isEmpty
                ? const Icon(Icons.person, size: 60, color: Colors.white)
                : null,
          ),

          const SizedBox(height: 18),

          Text(
            matchedUser!["name"]?.toString() ?? "Unknown",
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            "${matchedUser!["gender"] ?? ""}, ${matchedUser!["country"] ?? ""}",
            style: const TextStyle(color: Colors.grey, fontSize: 15),
          ),

          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: callLoading ? null : sendCallRequest,
              icon: const Icon(Icons.videocam),
              label: Text(
                callLoading ? "Calling..." : "Start Video Call",
                style: const TextStyle(fontSize: 17),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    callStatusTimer?.cancel();
    timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xffec4899), Color(0xff8b5cf6)],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              children: [
                const Icon(Icons.favorite, size: 70, color: Colors.white),
                const SizedBox(height: 15),
                const Text(
                  "Find Your Match",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Meet random people instantly",
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 25),
                DropdownButtonFormField<String>(
                  value: lookingFor,
                  dropdownColor: Colors.white,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: "male", child: Text("Male")),
                    DropdownMenuItem(value: "female", child: Text("Female")),
                    DropdownMenuItem(value: "any", child: Text("Any")),
                  ],
                  onChanged: (value) {
                    setState(() => lookingFor = value!);
                  },
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isSearching ? null : findMatch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.pink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: isSearching
                        ? const CircularProgressIndicator()
                        : const Text(
                            "Start Matching",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          matchedUserCard(),
        ],
      ),
    );
  }
}
