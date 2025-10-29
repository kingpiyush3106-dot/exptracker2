import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:exp2/database/db_helper.dart';
import 'package:exp2/home_screen.dart';

class TextRecognitionScreen extends StatefulWidget {
  final String userId;
  const TextRecognitionScreen({required this.userId, Key? key}) : super(key: key);

  @override
  State<TextRecognitionScreen> createState() => _TextRecognitionScreenState();
}

class _TextRecognitionScreenState extends State<TextRecognitionScreen> {
  File? _image;
  bool _isLoading = false;
  final _picker = ImagePicker();
  final _productController = TextEditingController();
  final _mfgController = TextEditingController();
  final _expController = TextEditingController();
  final dbHelper = DBHelper();

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;
    setState(() => _image = File(picked.path));
    await _processImage(File(picked.path));
  }

  Future<void> _processImage(File image) async {
    setState(() => _isLoading = true);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final inputImage = InputImage.fromFile(image);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    String fullText = recognizedText.text;
    debugPrint("🔍 OCR TEXT: $fullText");

    fullText = fullText.toLowerCase().replaceAll('\n', ' ').replaceAll(':', ' ');

    final RegExp datePattern = RegExp(
      r'(\b\d{1,2}[\/\-.]\d{1,2}[\/\-.]\d{2,4}\b|' // 12/08/2025
      r'\b\d{1,2}\s*(jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)[a-z]*\s*\d{2,4}\b|' // 12 Aug 2025
      r'\b(jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)[a-z]*\s*\d{2,4}\b|' // Aug 2025
      r'\b\d{2,4}\s*(jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)\b)', // 2025 Aug
      caseSensitive: false,
    );

    final matches = datePattern.allMatches(fullText).map((m) => m.group(0)!).toList();
    String? mfg;
    String? exp;

    for (final match in matches) {
      final idx = fullText.indexOf(match);
      if (idx == -1) continue;
      final window = fullText.substring(
        (idx - 25).clamp(0, fullText.length),
        (idx + 25).clamp(0, fullText.length),
      );
      if (window.contains('mfg') || window.contains('manufact') || window.contains('packed')) {
        mfg ??= match;
      } else if (window.contains('exp') || window.contains('expiry') || window.contains('best') || window.contains('use by')) {
        exp ??= match;
      }
    }

    if (mfg == null && matches.isNotEmpty) mfg = matches.first;
    if (exp == null && matches.length > 1) exp = matches.last;

    _mfgController.text = mfg ?? '';
    _expController.text = exp ?? '';

    await textRecognizer.close();
    setState(() => _isLoading = false);

    if (mfg == null && exp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Could not detect dates. Please enter manually.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Dates detected. Please verify before saving.')),
      );
    }
  }

  Future<void> _saveToLocalDB() async {
    final product = _productController.text.trim();
    final mfg = _mfgController.text.trim();
    final exp = _expController.text.trim();

    if (product.isEmpty || exp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please enter Product Name and Expiry Date.')),
      );
      return;
    }

    await dbHelper.insertItem({
      'userId': widget.userId,
      'productName': product,
      'manufactureDate': mfg.isEmpty ? 'Unknown' : mfg,
      'expiryDate': exp,
      'imagePath': _image?.path ?? '',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Item saved locally!')),
    );

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(userId: widget.userId)),
      );
    }
  }

  @override
  void dispose() {
    _productController.dispose();
    _mfgController.dispose();
    _expController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product (Scan or Manual)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!, height: 200, fit: BoxFit.cover),
              ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _productController,
                    decoration: const InputDecoration(
                      labelText: 'Product Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.shopping_bag),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _mfgController,
                    decoration: const InputDecoration(
                      labelText: 'Manufacturing Date',
                      hintText: 'e.g. 12/08/2024',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.factory),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _expController,
                    decoration: const InputDecoration(
                      labelText: 'Expiry Date',
                      hintText: 'e.g. 12/12/2025',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_month),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _saveToLocalDB,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Item'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickImage,
        icon: const Icon(Icons.camera_alt),
        label: const Text('Scan Image'),
      ),
    );
  }
}
