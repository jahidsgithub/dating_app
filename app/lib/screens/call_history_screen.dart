import 'package:flutter/material.dart';

import '../services/api_service.dart';

class CallHistoryScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const CallHistoryScreen({super.key, required this.user});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  bool isLoading = true;
  List history = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    setState(() => isLoading = true);

    final response = await ApiService.callHistory(
      userId: widget.user["id"].toString(),
    );

    if (response["status"] == true) {
      setState(() {
        history = response["history"];
      });
    }

    setState(() => isLoading = false);
  }

  String otherUserName(Map call) {
    String myId = widget.user["id"].toString();

    if (call["caller_id"].toString() == myId) {
      return call["receiver_name"]?.toString() ?? "Unknown";
    }

    return call["caller_name"]?.toString() ?? "Unknown";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        backgroundColor: Colors.pink,
        title: const Text(
          "Call History",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : history.isEmpty
          ? const Center(child: Text("No call history found"))
          : RefreshIndicator(
              onRefresh: loadHistory,
              child: ListView.builder(
                padding: const EdgeInsets.all(18),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final call = history[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.06),
                          blurRadius: 14,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.pink.shade100,
                          child: const Icon(Icons.videocam, color: Colors.pink),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                otherUserName(call),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                "Status: ${call["status"]}",
                                style: const TextStyle(color: Colors.grey),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                "Coins Used: ${call["coins_deducted"]}",
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "#${call["id"]}",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              call["start_time"]?.toString() ?? "",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
