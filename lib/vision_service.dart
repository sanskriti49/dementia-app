import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

class VisionService {
  Interpreter? _interpreter;
  List<String> _labels = [];

  Future<void> _init() async {

    _interpreter =
    await Interpreter.fromAsset(
      "models/mobilenet.tflite",
    );

    final labelData =
    await rootBundle.loadString(
      "assets/models/labels.txt",
    );

    _labels = labelData.split("\n");
  }

  Future<String> detectObject(File file) async {

    try {

      if (_interpreter == null) {
        await _init();
      }

      final bytes = await file.readAsBytes();

      img.Image? image =
      img.decodeImage(bytes);

      if (image == null) {
        return "No image";
      }

      img.Image resized =
      img.copyResize(
        image,
        width: 224,
        height: 224,
      );

      /// ✅ uint8 input for MobileNet
      var input = List.generate(
        1,
            (_) => List.generate(
          224,
              (_) => List.generate(
            224,
                (_) => List.filled(3, 0),
          ),
        ),
      );

      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {

          var pixel =
          resized.getPixel(x, y);

          input[0][y][x][0] =
              pixel.r.toInt();

          input[0][y][x][1] =
              pixel.g.toInt();

          input[0][y][x][2] =
              pixel.b.toInt();
        }
      }

      var output =
      List.filled(1001, 0.0)
          .reshape([1, 1001]);

      _interpreter!.run(
        input,
        output,
      );

      int maxIndex = 0;
      double maxScore = 0;

      for (int i = 0; i < 1001; i++) {

        if (output[0][i] > maxScore) {
          maxScore = output[0][i];
          maxIndex = i;
        }
      }

      print("Score: $maxScore");
      print("Index: $maxIndex");

      if (maxScore < 0.1) {
        return "Unknown object";
      }

      return _labels[maxIndex];

    } catch (e) {

      print(e);

      return "Detection error";
    }
  }
}