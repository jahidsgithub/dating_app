import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import 'blocked_users_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Map<String, dynamic> currentUser;

  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController genderController;
  late TextEditingController ageController;
  late TextEditingController countryController;

  bool isLoading = false;
  bool photoLoading = false;

  String profilePhoto = "";

  @override
  void initState() {
    super.initState();

    currentUser = Map<String, dynamic>.from(widget.user);

    nameController = TextEditingController();
    phoneController = TextEditingController();
    genderController = TextEditingController();
    ageController = TextEditingController();
    countryController = TextEditingController();

    fillControllers();
    refreshUserDetails();
  }

  void fillControllers() {
    profilePhoto = currentUser["profile_photo"]?.toString() ?? "";

    nameController.text = currentUser["name"]?.toString() ?? "";
    phoneController.text = currentUser["phone"]?.toString() ?? "";
    genderController.text = currentUser["gender"]?.toString() ?? "";
    ageController.text = currentUser["age"]?.toString() ?? "";
    countryController.text = currentUser["country"]?.toString() ?? "";
  }

  Future<void> refreshUserDetails() async {
    try {
      final response = await ApiService.userDetails(
        userId: currentUser["id"].toString(),
      );

      if (response["status"] == true) {
        setState(() {
          currentUser = Map<String, dynamic>.from(response["user"]);
          fillControllers();
        });
      }
    } catch (e) {
      debugPrint("User refresh error: $e");
    }
  }

  Future<void> updateProfile() async {
    setState(() => isLoading = true);

    try {
      final response = await ApiService.updateProfile(
        userId: currentUser["id"].toString(),
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        gender: genderController.text.trim(),
        age: ageController.text.trim(),
        country: countryController.text.trim(),
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response["message"].toString())));

      await refreshUserDetails();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Update error: $e")));
    }

    setState(() => isLoading = false);
  }

  Future<void> pickProfilePhoto() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (picked == null) return;

    setState(() => photoLoading = true);

    File imageFile = File(picked.path);

    try {
      final response = await ApiService.uploadProfilePhoto(
        userId: currentUser["id"].toString(),
        imageFile: imageFile,
      );

      if (response["status"] == true) {
        setState(() {
          profilePhoto = response["profile_photo"]?.toString() ?? "";
        });

        await refreshUserDetails();
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response["message"].toString())));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload error: $e")));
    }

    setState(() => photoLoading = false);
  }

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget profileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xffec4899), Color(0xff8b5cf6)],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: photoLoading ? null : pickProfilePhoto,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 58,
                  backgroundColor: Colors.white,
                  backgroundImage: profilePhoto.isNotEmpty
                      ? NetworkImage(
                          "http://127.0.0.1/dating_app/$profilePhoto",
                        )
                      : null,
                  child: profilePhoto.isEmpty
                      ? const Icon(Icons.person, size: 60, color: Colors.pink)
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: photoLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.pink,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            color: Colors.pink,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            currentUser["name"]?.toString() ?? "",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currentUser["email"]?.toString() ?? "",
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget blockedUsersButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlockedUsersScreen(user: currentUser),
            ),
          );
        },
        icon: const Icon(Icons.block),
        label: const Text(
          "Blocked Users",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    genderController.dispose();
    ageController.dispose();
    countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            profileHeader(),

            const SizedBox(height: 28),

            buildTextField(label: "Name", controller: nameController),

            buildTextField(
              label: "Phone",
              controller: phoneController,
              keyboardType: TextInputType.phone,
            ),

            buildTextField(label: "Gender", controller: genderController),

            buildTextField(
              label: "Age",
              controller: ageController,
              keyboardType: TextInputType.number,
            ),

            buildTextField(label: "Country", controller: countryController),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Update Profile",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 18),

            blockedUsersButton(),
          ],
        ),
      ),
    );
  }
}
