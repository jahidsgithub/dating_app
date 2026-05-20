import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final ageController = TextEditingController();
  final countryController = TextEditingController();

  String gender = "male";
  String profilePhoto = "";

  bool isLoading = false;
  bool photoLoading = false;

  @override
  void initState() {
    super.initState();

    nameController.text = widget.user["name"]?.toString() ?? "";
    phoneController.text = widget.user["phone"]?.toString() ?? "";
    ageController.text = widget.user["age"]?.toString() ?? "18";
    countryController.text = widget.user["country"]?.toString() ?? "";
    gender = widget.user["gender"]?.toString() ?? "male";
    profilePhoto = widget.user["profile_photo"]?.toString() ?? "";
  }

  Future<void> updateProfile() async {
    setState(() => isLoading = true);

    try {
      final response = await ApiService.updateProfile(
        userId: widget.user["id"].toString(),
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        gender: gender,
        age: ageController.text.trim(),
        country: countryController.text.trim(),
      );

      setState(() => isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response["message"])));
    } catch (e) {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();

    final pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (pickedImage == null) return;

    setState(() => photoLoading = true);

    try {
      final response = await ApiService.uploadProfilePhoto(
        userId: widget.user["id"].toString(),
        imageFile: File(pickedImage.path),
      );

      setState(() => photoLoading = false);

      if (response["status"] == true) {
        setState(() {
          profilePhoto = response["profile_photo"];
        });
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response["message"])));
    } catch (e) {
      setState(() => photoLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload error: $e")));
    }
  }

  Widget inputBox({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? photoProvider;

    if (profilePhoto.isNotEmpty) {
      photoProvider = NetworkImage("http://10.0.2.2/dating_app/$profilePhoto");
    }

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
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      backgroundImage: photoProvider,
                      child: profilePhoto.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 70,
                              color: Colors.pink,
                            )
                          : null,
                    ),

                    InkWell(
                      onTap: photoLoading ? null : pickAndUploadImage,
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white,
                        child: photoLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.camera_alt, color: Colors.pink),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                Text(
                  nameController.text.isEmpty ? "User" : nameController.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  widget.user["email"]?.toString() ?? "",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.06),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                inputBox(
                  controller: nameController,
                  hint: "Full Name",
                  icon: Icons.person,
                ),

                const SizedBox(height: 15),

                inputBox(
                  controller: phoneController,
                  hint: "Phone",
                  icon: Icons.phone,
                  type: TextInputType.phone,
                ),

                const SizedBox(height: 15),

                DropdownButtonFormField<String>(
                  value: gender,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.wc),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: "male", child: Text("Male")),
                    DropdownMenuItem(value: "female", child: Text("Female")),
                    DropdownMenuItem(value: "other", child: Text("Other")),
                  ],
                  onChanged: (value) {
                    setState(() => gender = value!);
                  },
                ),

                const SizedBox(height: 15),

                inputBox(
                  controller: ageController,
                  hint: "Age",
                  icon: Icons.cake,
                  type: TextInputType.number,
                ),

                const SizedBox(height: 15),

                inputBox(
                  controller: countryController,
                  hint: "Country",
                  icon: Icons.public,
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Update Profile",
                            style: TextStyle(fontSize: 17),
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
