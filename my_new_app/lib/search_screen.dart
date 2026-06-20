import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _cityController = TextEditingController();
  String _selectedBloodGroup = 'A+';
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  String searchBlood = '';
  String searchCity = '';

  void _sendSMS(String phoneNumber, String bloodGroup) async {
    String message = "Hello, I am looking for a $bloodGroup blood donor urgently in $searchCity. Can you please help us?";
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: <String, String>{'body': message},
    );
    if (await canLaunchUrl(smsUri)) await launchUrl(smsUri);
  }

  void _makeCall(String phoneNumber) async {
    final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(callUri)) await launchUrl(callUri);
  }

  @override
  Widget build(BuildContext context) {
    // ⏱️ අද දිනෙන් දින 90ක් (මාස 3ක්) අඩු කරලා සීමාව හදාගන්නවා
    DateTime threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text('Find Blood Donors', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedBloodGroup,
              decoration: InputDecoration(
                labelText: 'Select Blood Group',
                prefixIcon: const Icon(Icons.bloodtype, color: Colors.red),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _bloodGroups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (v) => setState(() => _selectedBloodGroup = v!),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: 'Enter City',
                prefixIcon: const Icon(Icons.location_on, color: Colors.red),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  searchBlood = _selectedBloodGroup;
                  searchCity = _cityController.text.trim().toLowerCase();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.search, color: Colors.white),
              label: const Text('Search Donors', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: searchBlood.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 10),
                    const Text('Enter details above to find donors', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ],
                ),
              )
                  : StreamBuilder<QuerySnapshot>(
                // 🔥 මෙතනට '.where('lastDonationDate', isLessThanOrEqualTo: threeMonthsAgo)' එකතු කලා
                // ඒ කියන්නේ අන්තිමට ලේ දුන්න දිනේ මාස 3කට වඩා පරණ අයට විතරයි ලේ දෙන්න පුළුවන් 😍
                stream: FirebaseFirestore.instance
                    .collection('donors')
                    .where('bloodGroup', isEqualTo: searchBlood)
                    .where('city', isEqualTo: searchCity)
                    .where('lastDonationDate', isLessThanOrEqualTo: Timestamp.fromDate(threeMonthsAgo))
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.red));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sentiment_dissatisfied, size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 10),
                          const Text('No eligible donors found in this city right now. 😔', style: TextStyle(color: Colors.grey, fontSize: 15)),
                        ],
                      ),
                    );
                  }

                  var donors = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: donors.length,
                    itemBuilder: (context, index) {
                      var donor = donors[index].data() as Map<String, dynamic>;
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.red[50],
                                child: Text(donor['bloodGroup'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(donor['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                                    const SizedBox(height: 4),
                                    Text("Age: ${donor['age']} | City: ${donor['city'].toString().toUpperCase()}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.phone, color: Colors.green, size: 28),
                                onPressed: () => _makeCall(donor['phone']),
                              ),
                              IconButton(
                                icon: const Icon(Icons.message, color: Colors.blue, size: 28),
                                onPressed: () => _sendSMS(donor['phone'], donor['bloodGroup']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}