import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math'; // 💡 Random OTP එකක් හදාගන්න මේක ඕනේ

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _otpController = TextEditingController(); // 💡 OTP Controller

  String _selectedBloodGroup = 'A+';
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  DateTime? _lastDonationDate;
  bool _neverDonated = true;

  String _generatedOTP = ''; // 💡 හැදෙන OTP එක තියාගන්න වෙනස්වන සුළු අගයක්

  // 🎲 ඉලක්කම් 4ක Random OTP එකක් හදන කොටස
  void _generateAndShowOTP() {
    var random = Random();
    // 1000 සහ 9999 අතර ඉලක්කමක් හදනවා
    _generatedOTP = (1000 + random.nextInt(9000)).toString();

    // 📱 OTP එක ඇතුළත් කරන්න ලස්සන Popup එකක් (Dialog) පෙන්වනවා
    showDialog(
      context: context,
      barrierDismissible: false, // බාහිරින් එබුවට වැහෙන්නේ නැහැ
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Row(
            children: [
              Icon(Icons.security, color: Colors.red),
              SizedBox(width: 10),
              Text('OTP Verification', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'For Testing, Your OTP Code is: \n',
                style: TextStyle(color: Colors.grey[600]),
              ),
              // 🔥 මෙන්න OTP එක screen එකේ පේනවා (SMS එකක් ආවා වගේ)
              Text(
                _generatedOTP,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red, letterSpacing: 5),
              ),
              const SizedBox(height: 20),
              const Text('Enter the 4-digit OTP code below:'),
              const SizedBox(height: 10),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: 'XXXX',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _otpController.clear();
                Navigator.pop(context); // Cancel කරලා Dialog එක වහනවා
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: _verifyOTPAndRegister, // 🚀 OTP එක Check කරන තැනට යනවා
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Verify & Register', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // 🔑 OTP එක නිවැරදිද බලලා Firebase එකට දත්ත දාන කොටස
  void _verifyOTPAndRegister() async {
    if (_otpController.text.trim() == _generatedOTP) {
      Navigator.pop(context); // Dialog එක වහනවා

      try {
        DateTime donationDateToSave = _neverDonated || _lastDonationDate == null
            ? DateTime.now().subtract(const Duration(days: 3650))
            : _lastDonationDate!;

        // 💾 හැමදේම හරි නිසා දැන් Firebase සේව් කරනවා
        await FirebaseFirestore.instance.collection('donors').add({
          'name': _nameController.text.trim(),
          'age': int.parse(_ageController.text.trim()),
          'phone': _phoneController.text.trim(),
          'bloodGroup': _selectedBloodGroup,
          'city': _cityController.text.trim().toLowerCase(),
          'lastDonationDate': Timestamp.fromDate(donationDateToSave),
          'registeredAt': Timestamp.now(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 OTP Verified & Registered Successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Form එක Clear කිරීම
        _nameController.clear();
        _ageController.clear();
        _phoneController.clear();
        _cityController.clear();
        _otpController.clear();
        setState(() {
          _lastDonationDate = null;
          _neverDonated = true;
        });

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      // ❌ වැරදි OTP එකක් ගැහුවොත්
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Invalid OTP Code! Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.red),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _lastDonationDate) {
      setState(() {
        _lastDonationDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text('Become a Donor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.redAccent,
                  child: Icon(Icons.water_drop, size: 45, color: Colors.white),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person, color: Colors.red),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v!.isEmpty ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Age',
                    prefixIcon: const Icon(Icons.cake, color: Colors.red),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v!.isEmpty ? 'Please enter your age' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone, color: Colors.red),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v!.isEmpty ? 'Please type phone number' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: 'Your City',
                    prefixIcon: const Icon(Icons.location_on, color: Colors.red),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v!.isEmpty ? 'Please enter your city' : null,
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: _selectedBloodGroup,
                  decoration: InputDecoration(
                    labelText: 'Blood Group',
                    prefixIcon: const Icon(Icons.bloodtype, color: Colors.red),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _bloodGroups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (v) => setState(() => _selectedBloodGroup = v!),
                ),
                const SizedBox(height: 15),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey[400]!), borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          title: const Text("First time donor (කලින් ලේ දී නොමැත)"),
                          value: _neverDonated,
                          activeColor: Colors.red,
                          onChanged: (bool? value) {
                            setState(() {
                              _neverDonated = value!;
                              if (_neverDonated) _lastDonationDate = null;
                            });
                          },
                        ),
                        if (!_neverDonated) ...[
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.calendar_month, color: Colors.red),
                            title: Text(_lastDonationDate == null
                                ? 'Select Last Donation Date'
                                : 'Last Donation: ${DateFormat('yyyy-MM-dd').format(_lastDonationDate!)}'),
                            trailing: ElevatedButton(
                              onPressed: () => _selectDate(context),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50]),
                              child: const Text('Choose', style: TextStyle(color: Colors.red)),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // 🚀 Register බොත්තම එබුවාම කෙලින්ම OTP එක හැදෙන තැනට යනවා
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _generateAndShowOTP(); // 💡 OTP Popup එක ඕපන් කරනවා
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Register as a Donor', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}