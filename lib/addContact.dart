import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class AddContactPage extends StatefulWidget {
  final String contactName;
  final String phoneNumber;

  const AddContactPage({
    super.key,
    required this.contactName,
    required this.phoneNumber,
  });

  @override
  State<AddContactPage> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  bool _isLoading = false;
  List<Contact> _contacts = [];

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoadContacts();
  }

  Future<void> _checkPermissionAndLoadContacts() async {
    final status = await Permission.contacts.status;
    if (status.isGranted) {
      await _loadContacts();
    }
  }

  Future<void> _loadContacts() async {
    try {
      setState(() => _isLoading = true);
      _contacts = await FlutterContacts.getContacts(withProperties: true);
    } catch (e) {
      _showErrorSnackBar('Failed to load contacts: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addContact() async {
    try {
      setState(() => _isLoading = true);

      if (!await _requestContactPermission()) {
        return;
      }

      final contact = await _createContact();
      await FlutterContacts.insertContact(contact);

      await _loadContacts(); // Refresh contact list
      _showSuccessSnackBar('Contact added successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to add contact: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _requestContactPermission() async {
    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      _showErrorSnackBar('Permission denied to access contacts.');
      return false;
    }
    return true;
  }

  Future<Contact> _createContact() async {
    final nameParts = widget.contactName.trim().split(' ');
    return Contact(
      name: Name(
        first: nameParts.first,
        last: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
      ),
      displayName: widget.contactName,
      phones: [Phone(widget.phoneNumber)],
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                ProfileSection(
                  contactName: widget.contactName,
                  phoneNumber: widget.phoneNumber,
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height - 340,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildAddButton(),
                ),
              ],
            ),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _addContact,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF007BFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          disabledBackgroundColor: Colors.grey,
        ),
        child: Text(
          _isLoading ? "Adding..." : "Add Contact",
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class ProfileSection extends StatelessWidget {
  final String contactName;
  final String phoneNumber;
  const ProfileSection(
      {super.key, required this.contactName, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, left: 20, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phone Account',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w300,
                  color: Colors.black,
                ),
          ),
          const SizedBox(height: 24),
          ContactInfo(
            contactName: contactName,
            phoneNumber: phoneNumber,
          ),
          const SizedBox(height: 16),
          Divider(
            color: Colors.black.withOpacity(0.2),
            thickness: 0.5,
            height: 30,
          ),
        ],
      ),
    );
  }
}

class ContactInfo extends StatelessWidget {
  final String contactName;
  final String phoneNumber;
  const ContactInfo(
      {super.key, required this.contactName, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              CircleAvatar(
                radius: 28.5,
                backgroundColor: Colors.grey[300],
                child: Image.asset(
                  'assets/images/user.png',
                  height: 30,
                  width: 30,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.person);
                  },
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contactName,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 17,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      phoneNumber,
                      style: const TextStyle(
                        color: Color(0xFF6D6B6B),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey,
          size: 20,
        ),
      ],
    );
  }
}
