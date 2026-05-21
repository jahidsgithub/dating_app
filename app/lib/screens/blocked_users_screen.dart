import 'package:flutter/material.dart';

import '../services/api_service.dart';

class BlockedUsersScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const BlockedUsersScreen({super.key, required this.user});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  bool isLoading = true;
  List users = [];

  @override
  void initState() {
    super.initState();
    loadBlockedUsers();
  }

  Future<void> loadBlockedUsers() async {
    setState(() => isLoading = true);

    try {
      final response = await ApiService.blockedUsers(
        userId: widget.user["id"].toString(),
      );

      if (response["status"] == true) {
        setState(() {
          users = response["users"];
        });
      }
    } catch (e) {
      debugPrint("Blocked users error: $e");
    }

    setState(() => isLoading = false);
  }

  Future<void> unblockUser(Map user) async {
    final response = await ApiService.unblockUser(
      blockerId: widget.user["id"].toString(),
      blockedUserId: user["blocked_user_id"].toString(),
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(response["message"].toString())));

    loadBlockedUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        backgroundColor: Colors.pink,
        title: const Text(
          "Blocked Users",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
          ? const Center(child: Text("No blocked users"))
          : RefreshIndicator(
              onRefresh: loadBlockedUsers,
              child: ListView.builder(
                padding: const EdgeInsets.all(18),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final photo = user["profile_photo"]?.toString() ?? "";

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
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
                          radius: 30,
                          backgroundColor: Colors.pink.shade100,
                          backgroundImage: photo.isNotEmpty
                              ? NetworkImage(
                                  "http://127.0.0.1/dating_app/$photo",
                                )
                              : null,
                          child: photo.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 34,
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user["name"]?.toString() ?? "Unknown",
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${user["gender"] ?? ""} • ${user["country"] ?? ""}",
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => unblockUser(user),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Unblock"),
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
