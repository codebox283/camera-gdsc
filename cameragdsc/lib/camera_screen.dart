import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart';

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({Key? key, required this.camera}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isFrontCamera = false;
  File? _capturedImage;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera(); // Initialize the controller and set _initializeControllerFuture
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    setState(() {
      _controller = CameraController(
        firstCamera,
        ResolutionPreset.medium,
      );
      _initializeControllerFuture = _controller.initialize();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCamera() async {
    final cameras = await availableCameras();
    final newCamera = cameras.firstWhere(
          (camera) => camera.lensDirection != _controller.description.lensDirection,
      orElse: () => _controller.description,
    );

    if (_controller != null) {
      await _controller.dispose();
    }

    setState(() {
      _controller = CameraController(
        newCamera,
        ResolutionPreset.medium,
      );
      _initializeControllerFuture = _controller.initialize();
      _isFrontCamera = !_isFrontCamera;
    });
  }

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;

      if (_isFlashOn) {
        _controller.setFlashMode(FlashMode.torch);
      } else {
        _controller.setFlashMode(FlashMode.off);
      }
    });
  }

  void _takePicture() async {
    try {
      await _initializeControllerFuture;
      final XFile file = await _controller.takePicture();
      final path = file.path;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imageName = 'image_$timestamp.jpg';

      final savedPath = await saveImageToInternalStorage(path, imageName);

      setState(() {
        _capturedImage = File(savedPath);
      });

      print('Image saved at: $savedPath');
    } catch (e) {
      print(e);
    }
  }

  Future<String> saveImageToInternalStorage(String imagePath, String imageName) async {
    try {
      final appDocDir = await path_provider.getApplicationDocumentsDirectory();
      final desiredPath = join(appDocDir.path, 'CameraApp', imageName);

      final File imageFile = File(imagePath);

      final directory = Directory(join(appDocDir.path, 'CameraApp'));
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      await imageFile.copy(desiredPath);

      return desiredPath;
    } catch (e) {
      print(e);
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera App'),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 40.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            FloatingActionButton(
              child: Icon(Icons.camera),
              onPressed: _takePicture,
            ),
            SizedBox(width: 20.0),
            FloatingActionButton(
              child: Icon(Icons.flip_camera_ios),
              onPressed: _toggleCamera,
            ),
            SizedBox(width: 20.0),
            FloatingActionButton(
              child: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
              onPressed: _toggleFlash,
            ),
          ],
        ),
      ),
    );
  }
}
