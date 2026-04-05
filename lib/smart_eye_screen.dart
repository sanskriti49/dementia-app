import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'vision_service.dart';

class SmartEyeScreen extends StatefulWidget {
  const SmartEyeScreen({super.key});

  @override
  State<SmartEyeScreen> createState() => _SmartEyeScreenState();
}

class _SmartEyeScreenState extends State<SmartEyeScreen> {

  File? image;
  String result = "";
  bool loading = false;

  final picker = ImagePicker();
  final vision = VisionService();

  Future<void> scan() async {

    final photo = await picker.pickImage(
      source: ImageSource.camera,
    );

    if (photo == null) return;

    setState(() {
      image = File(photo.path);
      loading = true;
    });

    final r = await vision.detectObject(image!);

    setState(() {
      result = r;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("Smart Eye")),

      body: Column(
        children: [

          Expanded(
            child: image == null
                ? Icon(Icons.camera, size: 120)
                : Image.file(image!),
          ),

          if (loading)
            CircularProgressIndicator(),

          Text(
            result,
            style: TextStyle(fontSize: 26),
          ),

          SizedBox(height: 20),

          ElevatedButton(
            onPressed: scan,
            child: Text("SCAN"),
          ),

          SizedBox(height: 40),
        ],
      ),
    );
  }
}