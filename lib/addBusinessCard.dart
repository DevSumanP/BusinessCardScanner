import 'package:card_scanner/addContact.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';

class CardScanScreen extends StatefulWidget {
  const CardScanScreen({super.key});

  @override
  State<CardScanScreen> createState() => _CardScanScreenState();
}

class _CardScanScreenState extends State<CardScanScreen> {
  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  String _errorMessage = '';
  String _recognizedText = '';
  String _phoneNumber = '';
  String _email = '';
  String _contactName = '';

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 100,
      );

      if (image != null) {
        await _recognizeText(image.path);
      } else {
        setState(() => _errorMessage = 'No image selected');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to capture image: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _recognizeText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      setState(() {
        _recognizedText = recognizedText.text;
        _extractContactInfo(_recognizedText);
      });

      if (_phoneNumber != "Not Found" && _contactName != "Not Found") {
        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddContactPage(
                contactName: _contactName,
                phoneNumber: _phoneNumber,
              ),
            ),
          );
        }
      } else {
        setState(
            () => _errorMessage = 'Could not detect valid contact information');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error recognizing text: $e');
    }
  }

  void _extractContactInfo(String recognizedText) {
    // Enhanced regex patterns for better matching
    final phoneRegex = RegExp(
      r'(?:\+?\d{1,4}[-.\s]?)?\(?\d{2,4}\)?[-.\s]?\d{2,4}[-.\s]?\d{2,4}',
      multiLine: true,
    );

    final emailRegex = RegExp(
      r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
      multiLine: true,
    );

    final phoneMatches = phoneRegex.allMatches(recognizedText);
    final emailMatches = emailRegex.allMatches(recognizedText);

    // Get the first valid phone number
    String? extractedPhoneNumber = phoneMatches.isNotEmpty
        ? phoneMatches.first.group(0)?.replaceAll(RegExp(r'[^\d+]'), '')
        : null;

    // Get the first valid email
    String? extractedEmail =
        emailMatches.isNotEmpty ? emailMatches.first.group(0) : null;

    // Extract contact name (first line without numbers that's not an email)
    String? extractedContactName;
    final lines = recognizedText.split('\n');
    for (String line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isNotEmpty &&
          !trimmedLine.contains(RegExp(r'\d')) &&
          !trimmedLine.contains('@')) {
        extractedContactName = trimmedLine;
        break;
      }
    }

    setState(() {
      _phoneNumber = extractedPhoneNumber ?? "Not Found";
      _email = extractedEmail ?? "Not Found";
      _contactName = extractedContactName ?? "Not Found";
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            _buildMainContent(),
            if (_isLoading)
              Container(
                color: Colors.white54,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF007BFF),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, size: 24),
        onPressed: () => Navigator.pop(context),
        tooltip: 'Back',
      ),
    );
  }

  Widget _buildMainContent() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 15),
          _buildHeaderSection(),
          const SizedBox(height: 60),
          _buildScannerFrame(),
          const Spacer(),
          _buildErrorMessage(),
          _buildStartButton(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        const Text(
          "Add card data",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 25),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            "Make sure all parts of your card aren't covered by objects and are clearly visible. Your card should be well-lit as well.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color.fromARGB(255, 105, 105, 105),
                  letterSpacing: 0.2,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildScannerFrame() {
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildCardPreview(),
        _buildScanAnimation(),
        ..._buildCornerFrames(),
      ],
    );
  }

  Widget _buildCardPreview() {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          'assets/images/person.jpg',
          width: 180,
          height: 180,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: const Icon(Icons.image_not_supported),
            );
          },
        ),
      ),
    );
  }

  Widget _buildScanAnimation() {
    return SizedBox(
      width: 180,
      height: 180,
      child: Lottie.asset(
        'assets/images/scan.json',
        fit: BoxFit.contain,
        alignment: Alignment.center,
      ),
    );
  }

  List<Widget> _buildCornerFrames() {
    return const [
      _CornerFrame(position: _CornerPosition.topLeft),
      _CornerFrame(position: _CornerPosition.topRight),
      _CornerFrame(position: _CornerPosition.bottomLeft),
      _CornerFrame(position: _CornerPosition.bottomRight),
    ];
  }

  Widget _buildErrorMessage() {
    if (_errorMessage.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        _errorMessage,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: 350,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _pickImage,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF007BFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          disabledBackgroundColor: Colors.grey,
        ),
        child: Text(
          _isLoading ? "Processing..." : "Start",
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

enum _CornerPosition { topLeft, topRight, bottomLeft, bottomRight }

class _CornerFrame extends StatelessWidget {
  final _CornerPosition position;

  const _CornerFrame({
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: position == _CornerPosition.topLeft ||
              position == _CornerPosition.topRight
          ? 0
          : null,
      bottom: position == _CornerPosition.bottomLeft ||
              position == _CornerPosition.bottomRight
          ? 0
          : null,
      left: position == _CornerPosition.topLeft ||
              position == _CornerPosition.bottomLeft
          ? 0
          : null,
      right: position == _CornerPosition.topRight ||
              position == _CornerPosition.bottomRight
          ? 0
          : null,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: position == _CornerPosition.topLeft ||
                    position == _CornerPosition.topRight
                ? const BorderSide(color: Color(0xFFB1B1B1), width: 5)
                : BorderSide.none,
            bottom: position == _CornerPosition.bottomLeft ||
                    position == _CornerPosition.bottomRight
                ? const BorderSide(color: Color(0xFFB1B1B1), width: 5)
                : BorderSide.none,
            left: position == _CornerPosition.topLeft ||
                    position == _CornerPosition.bottomLeft
                ? const BorderSide(color: Color(0xFFB1B1B1), width: 5)
                : BorderSide.none,
            right: position == _CornerPosition.topRight ||
                    position == _CornerPosition.bottomRight
                ? const BorderSide(color: Color(0xFFB1B1B1), width: 5)
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: position == _CornerPosition.topLeft
                ? const Radius.circular(20)
                : Radius.zero,
            topRight: position == _CornerPosition.topRight
                ? const Radius.circular(20)
                : Radius.zero,
            bottomLeft: position == _CornerPosition.bottomLeft
                ? const Radius.circular(20)
                : Radius.zero,
            bottomRight: position == _CornerPosition.bottomRight
                ? const Radius.circular(20)
                : Radius.zero,
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: const Text('', style: TextStyle(color: Colors.transparent)),
      ),
    );
  }
}
