import 'package:flutter/material.dart';

import '../services/api_service.dart';

class WalletScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const WalletScreen({super.key, required this.user});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool isLoading = false;
  bool packageLoading = false;

  int coins = 0;
  List packages = [];

  final transactionController = TextEditingController();
  String paymentMethod = "bKash";

  @override
  void initState() {
    super.initState();
    loadWallet();
    loadPackages();
  }

  Future<void> loadWallet() async {
    setState(() => isLoading = true);

    try {
      final response = await ApiService.wallet(
        userId: widget.user["id"].toString(),
      );

      if (response["status"] == true) {
        setState(() {
          coins = int.parse(response["user"]["coins"].toString());
        });
      }
    } catch (e) {
      debugPrint("Wallet error: $e");
    }

    setState(() => isLoading = false);
  }

  Future<void> loadPackages() async {
    setState(() => packageLoading = true);

    try {
      final response = await ApiService.coinPackages();

      if (response["status"] == true) {
        setState(() {
          packages = response["packages"];
        });
      }
    } catch (e) {
      debugPrint("Package error: $e");
    }

    setState(() => packageLoading = false);
  }

  void showPurchaseSheet(Map<String, dynamic> package) {
    transactionController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Purchase Coins",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "${package["title"]} - ${package["coins"]} Coins",
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "Amount: ৳${package["price"]}",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.pink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  DropdownButtonFormField<String>(
                    value: paymentMethod,
                    decoration: InputDecoration(
                      labelText: "Payment Method",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: "bKash", child: Text("bKash")),
                      DropdownMenuItem(value: "Nagad", child: Text("Nagad")),
                      DropdownMenuItem(value: "Rocket", child: Text("Rocket")),
                      DropdownMenuItem(value: "Bank", child: Text("Bank")),
                    ],
                    onChanged: (value) {
                      setSheetState(() {
                        paymentMethod = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: transactionController,
                    decoration: InputDecoration(
                      labelText: "Transaction ID",
                      hintText: "Enter payment transaction ID",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        if (transactionController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Transaction ID required"),
                            ),
                          );
                          return;
                        }

                        final response = await ApiService.purchaseCoin(
                          userId: widget.user["id"].toString(),
                          packageId: package["id"].toString(),
                          paymentMethod: paymentMethod,
                          transactionId: transactionController.text.trim(),
                        );

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(response["message"])),
                        );
                      },
                      child: const Text(
                        "Submit Request",
                        style: TextStyle(fontSize: 17),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget coinCard(Map<String, dynamic> package) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.pink.shade100,
            child: const Icon(
              Icons.monetization_on,
              color: Colors.pink,
              size: 32,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  package["title"].toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  "${package["coins"]} Coins",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "৳${package["price"]}",
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.pink,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              ElevatedButton(
                onPressed: () {
                  showPurchaseSheet(package);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text("Buy"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await loadWallet();
        await loadPackages();
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xffec4899), Color(0xff8b5cf6)],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  size: 65,
                  color: Colors.white,
                ),

                const SizedBox(height: 12),

                const Text(
                  "My Wallet",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "$coins Coins",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          const Text(
            "Coin Packages",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          if (packageLoading)
            const Center(child: CircularProgressIndicator())
          else if (packages.isEmpty)
            const Center(child: Text("No coin packages found"))
          else
            ...packages.map((p) => coinCard(Map<String, dynamic>.from(p))),
        ],
      ),
    );
  }
}
