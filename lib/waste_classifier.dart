import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:image/image.dart' as img;

// ─── Available models ────────────────────────────────────────────────────────

enum WasteModel {
  resnet(
    label: 'ResNet-50',
    asset: 'assets/models/waste_classifier_v8.onnx',
  ),
  efficientnet(
    label: 'EfficientNet-B0',
    asset: 'assets/models/efficientnet_v8.onnx',
  );

  const WasteModel({required this.label, required this.asset});
  final String label;
  final String asset;
}

// ─── Result ──────────────────────────────────────────────────────────────────

class ClassificationResult {
  final String name;
  final String category;
  final String emoji;
  final String tip;
  final int confidence;
  final bool isLowConfidence;

  const ClassificationResult({
    required this.name,
    required this.category,
    required this.emoji,
    required this.tip,
    required this.confidence,
    this.isLowConfidence = false,
  });
}

// ─── Classifier ──────────────────────────────────────────────────────────────

class WasteClassifier {
  OrtSession? _session;
  bool _initialized = false;
  WasteModel _currentModel = WasteModel.resnet;

  // ── Labels must match your Python training order exactly ──
  // CLASSES = ["recyclable", "organic", "e_waste", "hazardous"]
  static const List<String> labels = [
    'Recyclable',  // index 0
    'Organic',     // index 1
    'E-Waste',     // index 2
    'Hazardous',   // index 3
  ];

  static const List<String> categories = [
    '♻️ Recyclable Waste',
    '🌿 Organic / Compostable',
    '💻 Electronic Waste',
    '⚠️ Hazardous Waste',
  ];

  static const List<String> emojis = [
    '♻️', '🌿', '💻', '⚠️',
  ];

  static const List<String> tips = [
    'Rinse containers before recycling. Check local guidelines — plastics, glass, paper, and metals are commonly accepted curbside.',
    'Food scraps and yard waste can be composted. Avoid meat, dairy, and oils in home compost bins.',
    'Never put electronics in the bin. Take to a certified e-waste recycler to safely recover precious metals and prevent toxic leakage.',
    'Batteries, household chemicals, and medical waste need special handling. Find your nearest hazardous waste drop-off facility.',
  ];

  static const double _confidenceThreshold = 0.70; // 70 %
  static const int _inputSize = 224;
  static const List<double> _mean = [0.485, 0.456, 0.406];
  static const List<double> _std  = [0.229, 0.224, 0.225];

  // ── Model switching ──────────────────────────────────────────────────────

  WasteModel get currentModel => _currentModel;

  Future<void> switchModel(WasteModel model) async {
    if (model == _currentModel && _initialized) return;
    dispose();
    _currentModel = model;
    await init();
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;
    OrtEnv.instance.init();
    final raw = await rootBundle.load(_currentModel.asset);
    final bytes = raw.buffer.asUint8List();
    _session = OrtSession.fromBuffer(bytes, OrtSessionOptions());
    _initialized = true;
  }

  // ── Inference ────────────────────────────────────────────────────────────

  Future<ClassificationResult> classify(File imageFile) async {
    await init();

    final rawBytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) throw Exception('Could not decode image.');

    final resized = img.copyResize(
      decoded,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    final input = Float32List(1 * 3 * _inputSize * _inputSize);
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        final idx = y * _inputSize + x;
        input[0 * _inputSize * _inputSize + idx] = (pixel.r / 255.0 - _mean[0]) / _std[0];
        input[1 * _inputSize * _inputSize + idx] = (pixel.g / 255.0 - _mean[1]) / _std[1];
        input[2 * _inputSize * _inputSize + idx] = (pixel.b / 255.0 - _mean[2]) / _std[2];
      }
    }

    final tensor = OrtValueTensor.createTensorWithDataList(
      input, [1, 3, _inputSize, _inputSize],
    );
    final outputs = await _session!.runAsync(
      OrtRunOptions(), {_session!.inputNames.first: tensor},
    );
    tensor.release();

    final logits = _parseOutput(outputs?.first?.value);
    if (logits.isEmpty) throw Exception('Model returned empty output.');

    // Sanity-check: model output count must match label count
    if (logits.length != labels.length) {
      throw Exception(
        'Model outputs ${logits.length} classes but labels list has '
        '${labels.length}. Update the labels list to match your model.',
      );
    }

    for (final o in outputs ?? []) o?.release();

    // ── Debug logging (remove in release builds) ──
    final softmax = _softmax(logits);
    assert(() {
      final probs = softmax.asMap().map(
        (i, p) => MapEntry(labels[i], '${(p * 100).toStringAsFixed(1)}%'),
      );
      // ignore: avoid_print
      print('[WasteClassifier] model=${_currentModel.label} raw=$logits probs=$probs');
      return true;
    }());

    int topIdx = 0;
    for (int i = 1; i < softmax.length; i++) {
      if (softmax[i] > softmax[topIdx]) topIdx = i;
    }

    // Low-confidence fallback
    if (softmax[topIdx] < _confidenceThreshold) {
      return const ClassificationResult(
        name: 'Uncertain',
        category: '❓ Not Sure',
        emoji: '❓',
        tip: 'Try taking a clearer photo in better lighting, or move closer to the item.',
        confidence: 0,
        isLowConfidence: true,
      );
    }

    return ClassificationResult(
      name: labels[topIdx],
      category: categories[topIdx],
      emoji: emojis[topIdx],
      tip: tips[topIdx],
      confidence: (softmax[topIdx] * 100).round().clamp(1, 99),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  List<double> _parseOutput(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      final first = value.first;
      if (first is List) {
        // Shape [1, numClasses] — unwrap batch dimension
        return first.map<double>((e) => (e as num).toDouble()).toList();
      }
      return value.map<double>((e) => (e as num).toDouble()).toList();
    }
    return [];
  }

  List<double> _softmax(List<double> logits) {
    final maxVal = logits.reduce(math.max);
    final exps = logits.map((v) => math.exp(v - maxVal)).toList();
    final sum = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sum).toList();
  }

  void dispose() {
    _session?.release();
    OrtEnv.instance.release();
    _initialized = false;
  }
}