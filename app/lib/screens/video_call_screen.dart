import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config/agora_config.dart';
import '../services/api_service.dart';

class VideoCallScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;
  final Map<String, dynamic> matchedUser;
  final String agoraChannel;
  final String callId;

  const VideoCallScreen({
    super.key,
    required this.currentUser,
    required this.matchedUser,
    required this.agoraChannel,
    this.callId = "",
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late RtcEngine engine;

  int? remoteUid;

  bool localUserJoined = false;
  bool micOn = true;
  bool cameraOn = true;
  bool isEnding = false;

  Timer? coinTimer;
  Timer? liveCallTimer;

  int remainingCoins = 0;
  int deductedCoins = 0;

  final reportController = TextEditingController();

  @override
  void initState() {
    super.initState();

    remainingCoins =
        int.tryParse(widget.currentUser["coins"]?.toString() ?? "0") ?? 0;

    initAgora();
    startCoinDeduction();
    startLiveCallChecker();
  }

  Future<void> initAgora() async {
    await [Permission.microphone, Permission.camera].request();

    engine = createAgoraRtcEngine();

    await engine.initialize(
      const RtcEngineContext(
        appId: AgoraConfig.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          if (!mounted) return;
          setState(() => localUserJoined = true);
        },
        onUserJoined: (connection, uid, elapsed) {
          if (!mounted) return;
          setState(() => remoteUid = uid);
        },
        onUserOffline: (connection, uid, reason) {
          if (!mounted) return;
          setState(() => remoteUid = null);
        },
      ),
    );

    await engine.enableVideo();
    await engine.startPreview();

    await engine.joinChannel(
      token: AgoraConfig.token,
      channelId: widget.agoraChannel,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
  }

  void startCoinDeduction() {
    coinTimer?.cancel();

    coinTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => deductCoin(),
    );
  }

  void startLiveCallChecker() {
    liveCallTimer?.cancel();

    if (widget.callId.isEmpty) return;

    liveCallTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => checkLiveCall(),
    );
  }

  Future<void> checkLiveCall() async {
    if (widget.callId.isEmpty || isEnding) return;

    try {
      final response = await ApiService.checkLiveCall(callId: widget.callId);

      if (response["status"] == true &&
          response["call_status"].toString() == "ended") {
        await leaveCallOnly();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Call ended by other user")),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Live call check error: $e");
    }
  }

  Future<void> deductCoin() async {
    if (isEnding) return;

    try {
      final response = await ApiService.deductCoin(
        userId: widget.currentUser["id"].toString(),
        coins: "1",
        callId: widget.callId,
      );

      if (response["status"] == true) {
        if (!mounted) return;

        setState(() {
          deductedCoins++;
          remainingCoins = int.tryParse(response["balance"].toString()) ?? 0;
        });
      } else {
        await endCall(showMessage: response["message"].toString());
      }
    } catch (e) {
      debugPrint("Coin deduction error: $e");
    }
  }

  Future<void> toggleMic() async {
    setState(() => micOn = !micOn);
    await engine.muteLocalAudioStream(!micOn);
  }

  Future<void> toggleCamera() async {
    setState(() => cameraOn = !cameraOn);
    await engine.muteLocalVideoStream(!cameraOn);
  }

  Future<void> submitReport() async {
    if (reportController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter report reason")),
      );
      return;
    }

    try {
      final response = await ApiService.reportUser(
        reporterId: widget.currentUser["id"].toString(),
        reportedUserId: widget.matchedUser["id"].toString(),
        reason: reportController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response["message"].toString())));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Report error: $e")));
    }
  }

  Future<void> blockUser() async {
    try {
      final response = await ApiService.blockUser(
        blockerId: widget.currentUser["id"].toString(),
        blockedUserId: widget.matchedUser["id"].toString(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response["message"].toString())));

      await endCall(showMessage: "User blocked");
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Block error: $e")));
    }
  }

  void showReportDialog() {
    reportController.clear();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Report User"),
        content: TextField(
          controller: reportController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: "Write report reason...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: submitReport,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  void showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.report, color: Colors.orange),
                title: const Text("Report User"),
                onTap: () {
                  Navigator.pop(context);
                  showReportDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: const Text("Block User"),
                subtitle: const Text("This user will not match with you again"),
                onTap: () async {
                  Navigator.pop(context);

                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Block User?"),
                      content: const Text(
                        "Are you sure you want to block this user?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel"),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Block"),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await blockUser();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> leaveCallOnly() async {
    isEnding = true;

    coinTimer?.cancel();
    liveCallTimer?.cancel();

    try {
      await engine.leaveChannel();
      await engine.release();
    } catch (e) {
      debugPrint("Leave call error: $e");
    }
  }

  Future<void> endCall({String? showMessage}) async {
    if (isEnding) return;

    setState(() => isEnding = true);

    coinTimer?.cancel();
    liveCallTimer?.cancel();

    if (widget.callId.isNotEmpty) {
      try {
        await ApiService.endCall(callId: widget.callId);
      } catch (e) {
        debugPrint("End call API error: $e");
      }
    }

    try {
      await engine.leaveChannel();
      await engine.release();
    } catch (e) {
      debugPrint("Agora release error: $e");
    }

    if (!mounted) return;

    if (showMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(showMessage)));
    }

    Navigator.pop(context);
  }

  Widget remoteVideo() {
    if (remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: engine,
          canvas: VideoCanvas(uid: remoteUid),
          connection: RtcConnection(channelId: widget.agoraChannel),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          "Waiting for other user...",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }

  @override
  void dispose() {
    coinTimer?.cancel();
    liveCallTimer?.cancel();

    if (!isEnding) {
      engine.leaveChannel();
      engine.release();
    }

    reportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          remoteVideo(),

          Positioned(
            right: 16,
            top: 90,
            width: 120,
            height: 170,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                color: Colors.black54,
                child: localUserJoined
                    ? AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: engine,
                          canvas: const VideoCanvas(uid: 0),
                        ),
                      )
                    : const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
              ),
            ),
          ),

          Positioned(
            top: 45,
            left: 16,
            right: 16,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => endCall(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Expanded(
                  child: Text(
                    "Live Video Call",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
                IconButton(
                  onPressed: showMoreOptions,
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                ),
              ],
            ),
          ),

          Positioned(
            left: 20,
            bottom: 125,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                "Coins: $remainingCoins | Used: $deductedCoins",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),

          Positioned(
            bottom: 42,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  child: IconButton(
                    onPressed: toggleMic,
                    icon: Icon(
                      micOn ? Icons.mic : Icons.mic_off,
                      color: Colors.white,
                    ),
                  ),
                ),
                CircleAvatar(
                  radius: 38,
                  backgroundColor: Colors.red,
                  child: IconButton(
                    onPressed: () => endCall(),
                    icon: const Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  child: IconButton(
                    onPressed: toggleCamera,
                    icon: Icon(
                      cameraOn ? Icons.videocam : Icons.videocam_off,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
