import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class TFLiteService {
  Interpreter? speciesInterpreter;
  Map<String, Interpreter>? freshnessModels;
  final int inputSize = 128;
  bool isModelLoaded = false;

  // ✅ Load model sebagai buffer
  Future<Interpreter> _loadModelFromAsset(String assetPath) async {
    print('📦 Loading model from: $assetPath');

    // Load sebagai ByteData
    final ByteData data = await rootBundle.load(assetPath);
    print('✅ ByteData loaded: ${data.lengthInBytes} bytes');

    // Convert ke Uint8List
    final Uint8List bytes = data.buffer.asUint8List();
    print('✅ Converted to Uint8List');

    // Create interpreter from buffer
    final interpreter = Interpreter.fromBuffer(bytes);
    print('✅ Interpreter created from buffer');

    return interpreter;
  }

  Future<void> loadModels() async {
    try {
      print('🔍 Starting model loading process...');

      // Load species model
      print('📦 Loading species model...');
      speciesInterpreter = await _loadModelFromAsset(
        'assets/species_model.tflite',
      );
      print('✅ Species model loaded successfully!');

      // Load Nila model
      print('📦 Loading Nila freshness model...');
      final nilaModel = await _loadModelFromAsset(
        'assets/Freshness_nila.tflite',
      );
      print('✅ Nila model loaded successfully!');

      // Load Bandeng model
      print('📦 Loading Bandeng freshness model...');
      final bandengModel = await _loadModelFromAsset(
        'assets/Freshness_Bandeng.tflite',
      );
      print('✅ Bandeng model loaded successfully!');

      freshnessModels = {"Nila": nilaModel, "Bandeng": bandengModel};

      isModelLoaded = true;
      print('🎉🎉🎉 ALL MODELS LOADED SUCCESSFULLY! 🎉🎉🎉');
    } catch (e, stackTrace) {
      print('❌ Error loading models: $e');
      print('❌ Stack trace: $stackTrace');
      isModelLoaded = false;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> predict(String path) async {
    if (!isModelLoaded ||
        speciesInterpreter == null ||
        freshnessModels == null) {
      throw Exception('Models not loaded yet. Call loadModels() first.');
    }

    print('🔍 Starting prediction for: $path');

    // Load & decode image
    final image = await img.decodeImageFile(path);
    if (image == null) throw Exception('Failed to decode image');
    print('✅ Image decoded: ${image.width}x${image.height}');

    // Resize
    img.Image resized = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
    );
    print('✅ Image resized to: ${inputSize}x$inputSize');

    // Prepare input tensor
    final buffer = Float32List(inputSize * inputSize * 3);
    int idx = 0;

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final p = resized.getPixel(x, y);
        buffer[idx++] = p.r / 255.0;
        buffer[idx++] = p.g / 255.0;
        buffer[idx++] = p.b / 255.0;
      }
    }

    final input = buffer.reshape([1, inputSize, inputSize, 3]);
    print('✅ Input tensor prepared');

    // Predict species
    print('🔍 Predicting species...');
    final speciesOut = List<double>.filled(2, 0.0).reshape([1, 2]);
    speciesInterpreter!.run(input, speciesOut);

    // ✅ FIX: Cast ke List<double> dengan explicit type
    final speciesScores = (speciesOut[0] as List)
        .map((e) => e as double)
        .toList();

    // Cari index dengan confidence tertinggi
    int speciesIdx = 0;
    double maxSpeciesScore = speciesScores[0];
    for (int i = 1; i < speciesScores.length; i++) {
      if (speciesScores[i] > maxSpeciesScore) {
        maxSpeciesScore = speciesScores[i];
        speciesIdx = i;
      }
    }

    String speciesName = ["Bandeng", "Nila"][speciesIdx];
    double speciesConfidence = speciesScores[speciesIdx];
    print('✅ Species predicted: $speciesName (confidence: $speciesConfidence)');

    // Predict freshness
    print('🔍 Predicting freshness for $speciesName...');
    final freshInterpreter = freshnessModels![speciesName]!;
    final freshOut = List<double>.filled(2, 0.0).reshape([1, 2]);
    freshInterpreter.run(input, freshOut);

    // ✅ FIX: Cast ke List<double> dengan explicit type
    final freshScores = (freshOut[0] as List).map((e) => e as double).toList();

    // Cari index dengan confidence tertinggi
    int freshIdx = 0;
    double maxFreshScore = freshScores[0];
    for (int i = 1; i < freshScores.length; i++) {
      if (freshScores[i] > maxFreshScore) {
        maxFreshScore = freshScores[i];
        freshIdx = i;
      }
    }

    String freshnessLabel = ["Kurang Segar", "Segar"][freshIdx];
    double freshnessConfidence = freshScores[freshIdx];
    print(
      '✅ Freshness predicted: $freshnessLabel (confidence: $freshnessConfidence)',
    );

    return {
      "species": speciesName,
      "species_conf": speciesConfidence,
      "freshness": freshnessLabel,
      "freshness_conf": freshnessConfidence,
    };
  }

  void dispose() {
    try {
      speciesInterpreter?.close();
      freshnessModels?.forEach((key, interpreter) {
        interpreter.close();
      });
      speciesInterpreter = null;
      freshnessModels = null;
      isModelLoaded = false;
      print('✅ All interpreters disposed');
    } catch (e) {
      print('⚠️ Error disposing interpreters: $e');
    }
  }
}
