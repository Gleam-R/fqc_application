import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../Models/fish_history.dart';
import '../services/local_storage.dart';
import '../services/freshness_service.dart';

import 'result_page.dart';

class InputPage extends StatefulWidget {
  const InputPage({super.key});

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  String? imagePath;

  final picker = ImagePicker();
  late TFLiteService tfliteService; // ✅ late, bukan final

  bool loading = false;
  bool isModelLoading = true;
  String? loadError;

  @override
  void initState() {
    super.initState();
    tfliteService = TFLiteService(); // ✅ Initialize di sini
    _loadModels();
  }

  Future<void> _loadModels() async {
    setState(() {
      isModelLoading = true;
      loadError = null;
    });

    try {
      await tfliteService.loadModels();
      if (mounted) {
        // ✅ Check mounted
        setState(() {
          isModelLoading = false;
        });
      }
      print('✅ Models loaded successfully');
    } catch (e) {
      if (mounted) {
        // ✅ Check mounted
        setState(() {
          isModelLoading = false;
          loadError = e.toString();
        });
      }
      print('❌ Error loading models: $e');
    }
  }

  Future<void> pickImage(bool fromCamera) async {
    final XFile? pickedFile = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 95,
    );

    if (pickedFile != null) {
      setState(() {
        imagePath = pickedFile.path;
      });
    }
  }

  @override
  void dispose() {
    tfliteService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isModelLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Input Ikan")),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading AI Models...'),
            ],
          ),
        ),
      );
    }

    if (loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Input Ikan")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load AI models',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  loadError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadModels, // ✅ Langsung panggil _loadModels
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Input Ikan")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: imagePath == null
                    ? const Center(
                        child: Text(
                          "No image selected",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(imagePath!), fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: loading ? null : () => pickImage(false),
                  icon: const Icon(Icons.image),
                  label: const Text("Gallery"),
                ),
                ElevatedButton.icon(
                  onPressed: loading ? null : () => pickImage(true),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Camera"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: imagePath == null || loading
                    ? null
                    : () async {
                        setState(() => loading = true);

                        try {
                          final result = await tfliteService.predict(
                            imagePath!,
                          );

                          final data = FishHistory(
                            id: const Uuid().v4(),
                            speciesLabel: result["species"],
                            speciesConfidence: result["species_conf"],
                            freshnessLabel: result["freshness"],
                            freshnessConfidence: result["freshness_conf"],
                            imagePath: imagePath!,
                            createdAt: DateTime.now(),
                          );

                          await LocalStorage().addPrediction(data);

                          if (mounted) {
                            setState(() => loading = false);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ResultPage(result: data),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() => loading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Prediction failed: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          print('❌ Prediction error: $e');
                        }
                      },
                child: loading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text("Processing..."),
                        ],
                      )
                    : const Text("Predict", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
