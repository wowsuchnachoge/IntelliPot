import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraView extends StatefulWidget {
  CameraView({Key key, this.title}) : super(key: key);
  final String title;
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  String _imagePath;
  List _cameras;
  int _selectedCamera;
  CameraController _cameraController;

  Future _initCameraController(CameraDescription cameraDescription) async {
    if (_cameraController != null) {
      await _cameraController.dispose();
    }

    _cameraController =
        CameraController(cameraDescription, ResolutionPreset.high);

    _cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }

      if (_cameraController.value.hasError) {
        print('Camera error ${_cameraController.value.errorDescription}');
      }
    });

    try {
      await _cameraController.initialize();
    } on CameraException catch (e) {
      print(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  Widget _cameraPreviewWidget() {
    if (_cameraController == null || !_cameraController.value.isInitialized) {
      return Center(
        child: Text(
          'Loading...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    return Center(
      child: Stack(
        children: [
          // AspectRatio(
          //   aspectRatio: 9 / 16,
          //   child: CameraPreview(_cameraController),
          // ),
          CameraPreview(_cameraController),
          Column(
            children: [
              Spacer(),
              Padding(
                padding: EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Spacer(),
                    FlatButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Icon(
                        Icons.circle,
                        color: Colors.white.withOpacity(0.5),
                        size: 100,
                      ),
                    ),
                    Spacer(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    availableCameras().then((availableCameras) {
      _cameras = availableCameras;
      if (_cameras.length > 0) {
        setState(() {
          _selectedCamera = 0;
        });
        _initCameraController(_cameras[_selectedCamera]).then((void v) {});
      } else {
        print('No camera available');
      }
    }).catchError((err) {
      print('Error: $err.code\nError Message: $err.message');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _cameraPreviewWidget(),
      backgroundColor: Colors.black,
    );
  }
}
