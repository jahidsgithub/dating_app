import 'dart:async';
import 'dart:ui';

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
  Timer? onlineCountTimer;

  int ringingSeconds = 0;
  int maxRingingSeconds = 30;
  int onlineUsers = 0;

  @override
  void initState() {
    super.initState();

    loadOnlineUsersCount();

    onlineCountTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => loadOnlineUsersCount(),
    );
  }

  Future<void> loadOnlineUsersCount() async {
    try {
      final response = await ApiService.onlineUsersCount();

      if (response["status"] == true) {
        setState(() {
          onlineUsers = int.parse(response["online_users"].toString());
        });
      }
    } catch (e) {
      debugPrint("Online count error: $e");
    }
  }

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
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              title: const Text("Calling...", textAlign: TextAlign.center),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  const CircularProgressIndicator(color: Colors.pink),
                  const SizedBox(height: 24),
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
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: cancelCallRequest,
                  child: const Text(
                    "Cancel Call",
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

  Widget glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.18),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(.25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.18),
                blurRadius: 35,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget onlineCountCard() {
    return glassCard(
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.circle,
              color: Colors.greenAccent,
              size: 16,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              "Live Online Now",
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            onlineUsers.toString(),
            style: const TextStyle(
              fontSize: 30,
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget heroMatchCard() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(-0.04)
        ..rotateY(0.04),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          gradient: const LinearGradient(
            colors: [Color(0xffff4f9a), Color(0xff8b5cf6), Color(0xff3b82f6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xffff4f9a).withOpacity(.35),
              blurRadius: 35,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 90,
              width: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(.20),
                border: Border.all(color: Colors.white.withOpacity(.35)),
              ),
              child: const Icon(Icons.favorite, size: 54, color: Colors.white),
            ),
            const SizedBox(height: 18),
            const Text(
              "Find Your Match",
              style: TextStyle(
                color: Colors.white,
                fontSize: 31,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Random live video dating experience",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 26),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.95),
                borderRadius: BorderRadius.circular(20),
              ),
              child: DropdownButtonFormField<String>(
                value: lookingFor,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.tune, color: Colors.pink),
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
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: isSearching ? null : findMatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.pink,
                  elevation: 12,
                  shadowColor: Colors.black.withOpacity(.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: isSearching
                    ? const CircularProgressIndicator(color: Colors.pink)
                    : const Text(
                        "Start Matching",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget matchedUserCard() {
    if (matchedUser == null) return const SizedBox();

    String photo = matchedUser!["profile_photo"]?.toString() ?? "";

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(0.035)
        ..rotateY(-0.035),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.14),
              blurRadius: 32,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xffff4f9a), Color(0xff8b5cf6)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(.35),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 62,
                backgroundColor: Colors.pink.shade100,
                backgroundImage: photo.isNotEmpty
                    ? NetworkImage("http://127.0.0.1/dating_app/$photo")
                    : null,
                child: photo.isEmpty
                    ? const Icon(Icons.person, size: 65, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              matchedUser!["name"]?.toString() ?? "Unknown",
              style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              "${matchedUser!["gender"] ?? ""} • ${matchedUser!["country"] ?? ""}",
              style: const TextStyle(color: Colors.grey, fontSize: 15),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(.10),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                "Online & Ready to Connect",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton.icon(
                onPressed: callLoading ? null : sendCallRequest,
                icon: const Icon(Icons.videocam),
                label: Text(
                  callLoading ? "Calling..." : "Start Video Call",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  elevation: 15,
                  shadowColor: Colors.pink.withOpacity(.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    callStatusTimer?.cancel();
    timeoutTimer?.cancel();
    onlineCountTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff1e1b4b), Color(0xff831843), Color(0xff312e81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            onlineCountCard(),
            const SizedBox(height: 22),
            heroMatchCard(),
            const SizedBox(height: 34),
            matchedUserCard(),
          ],
        ),
      ),
    );
  }
}
