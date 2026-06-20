import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import 'dart:math';

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
  final TextEditingController _nicController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String _selectedBloodGroup = 'A+';
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  DateTime? _lastDonationDate;
  bool _neverDonated = true;
  String _generatedOTP = '';

  void _generateAndShowOTP() {
    if (!_neverDonated && _lastDonationDate != null) {
      final DateTime fiveMonthsLater = _lastDonationDate!.add(const Duration(days: 150));
      if (DateTime.now().isBefore(fiveMonthsLater)) {
        final int daysLeft = fiveMonthsLater.difference(DateTime.now()).inDays;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('තවම ලේ දිය නොහැක!'),
            content: Text('ඔබේ අවසාන රුධිර දීමෙන් මාස 5ක් ගතවී නැත.\n\nදින $daysLeft කින් register කළ හැක.'),
            actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('හරි'))],
          ),
        );
        return;
      }
    }

    var random = Random();
    _generatedOTP = (1000 + random.nextInt(9000)).toString();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('OTP Verification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('OTP: $_generatedOTP', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
              TextField(controller: _otpController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Enter 4-digit code')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(onPressed: _verifyOTPAndRegister, child: const Text('Verify & Register')),
          ],
        );
      },
    );
  }

  void _verifyOTPAndRegister() async {
    if (_otpController.text.trim() == _generatedOTP) {
      Navigator.pop(context);

      try {
        String? fcmToken = await FirebaseMessaging.instance.getToken();

        DateTime donationDateToSave = _neverDonated || _lastDonationDate == null
            ? DateTime.now().subtract(const Duration(days: 3650))
            : _lastDonationDate!;

        String nic = _nicController.text.trim().toUpperCase();

        await FirebaseFirestore.instance.collection('donors').doc(nic).set({
          'nic': nic,
          'name': _nameController.text.trim(),
          'age': int.parse(_ageController.text.trim()),
          'phone': _phoneController.text.trim(),
          'bloodGroup': _selectedBloodGroup,
          'city': _cityController.text.trim().toLowerCase(),
          'lastDonationDate': Timestamp.fromDate(donationDateToSave),
          'registeredAt': Timestamp.now(),
          'fcmToken': fcmToken,
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 Registered Successfully!'), backgroundColor: Colors.green));
        }

        _nameController.clear();
        _ageController.clear();
        _phoneController.clear();
        _cityController.clear();
        _nicController.clear();
        _otpController.clear();
        setState(() {
          _lastDonationDate = null;
          _neverDonated = true;
        });

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Invalid OTP!'), backgroundColor: Colors.red));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _lastDonationDate = picked);
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.red),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Become a Donor', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFFDF0EF),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 10),
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFFEF5350),
                child: const Icon(Icons.bloodtype, color: Colors.white, size: 45),
              ),
              const SizedBox(height: 25),

              TextFormField(
                controller: _nameController,
                decoration: _fieldDecoration('Full Name', Icons.person),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name එක ඇතුළත් කරන්න' : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: _fieldDecoration('Age', Icons.cake),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Age එක ඇතුළත් කරන්න' : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _fieldDecoration('Phone Number', Icons.phone),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone number එක ඇතුළත් කරන්න' : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _nicController,
                decoration: _fieldDecoration('NIC Number', Icons.badge),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'NIC number එක ඇතුළත් කරන්න' : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _cityController,
                decoration: _fieldDecoration('Your City', Icons.location_on),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'City එක ඇතුළත් කරන්න' : null,
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: _selectedBloodGroup,
                decoration: InputDecoration(
                  labelText: 'Blood Group',
                  prefixIcon: const Icon(Icons.bloodtype, color: Colors.red),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: _bloodGroups.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                onChanged: (v) => setState(() => _selectedBloodGroup = v!),
              ),
              const SizedBox(height: 15),

              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE4EC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CheckboxListTile(
                  title: const Text("First time donor (කලින් ලේ දී නොමැත)"),
                  value: _neverDonated,
                  activeColor: Colors.red,
                  onChanged: (v) => setState(() => _neverDonated = v!),
                ),
              ),

              if (!_neverDonated)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.calendar_month, color: Colors.red),
                    title: Text(_lastDonationDate == null ? 'Select Date' : DateFormat('yyyy-MM-dd').format(_lastDonationDate!)),
                    trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => _selectDate(context)),
                  ),
                ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  onPressed: () { if (_formKey.currentState!.validate()) _generateAndShowOTP(); },
                  child: const Text('Register as a Donor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}