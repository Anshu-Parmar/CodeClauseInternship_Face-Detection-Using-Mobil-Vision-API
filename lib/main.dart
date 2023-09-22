import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui' as ui;

const COLOR_PRIMARY = Colors.teal;
const COLOR_ACCENT = Colors.tealAccent;

void main() => runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: COLOR_PRIMARY,
            appBarTheme: const AppBarTheme(
              backgroundColor: COLOR_PRIMARY,
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: COLOR_PRIMARY,
              elevation: 30,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              hoverColor: COLOR_ACCENT,
              splashColor: COLOR_ACCENT,
            )),
        home: const MyApp(),
      ),
    );

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  File? _mainImageFile;
  List<Face>? _faces;
  bool isLoading = false;
  ui.Image? _image;
  final picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            "Face-Detector",
            style: GoogleFonts.robotoCondensed(
              fontSize: 30
            ),
          ),
          centerTitle: true,
          elevation: 30,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _getImage,
          child: const Icon(Icons.add_a_photo_outlined),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: isLoading
            ? (_mainImageFile == null)
                ? Center(
                      child: Text(
                        'No image selected',
                        style: GoogleFonts.robotoCondensed(),
                      ),
                    )
                : const Center(child: CircularProgressIndicator())
            : (_mainImageFile == null)
                ? Center(
                    child: Text(
                    'No image selected.',
                    style: GoogleFonts.robotoCondensed(),
                  ))
                : SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width*0.60,
                        height: 30,
                        color: COLOR_ACCENT,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text("Total Head Count:  ", style: GoogleFonts.robotoCondensed(),),
                            const SizedBox(width: 3,),
                            AnimatedTextKit(animatedTexts: [
                              ScaleAnimatedText("${_faces!.length}", duration: const Duration(seconds: 3), scalingFactor: 4, ),
                            ], repeatForever: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20,),
                      const Divider(color: COLOR_PRIMARY, thickness: 3),
                      const SizedBox(height: 20,),
                      Center(
                          child: FittedBox(
                          child: SizedBox(
                            width: _image!.width.toDouble(),
                            height: _image!.height.toDouble(),
                            child: CustomPaint(
                              painter: FacePainter(_image!, _faces!),
                            ),
                          ),
                        )),

                    ],
                  ),
                ));
  }

  _getImage() async {
    final imageFile = (await ImagePicker().pickImage(source: ImageSource.gallery));
    setState(() {
      isLoading = true;
    });

    final image = InputImage.fromFilePath(imageFile!.path);
    final faceDetector = GoogleMlKit.vision.faceDetector(FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableLandmarks: true,
        enableTracking: true));
    List<Face> faces = await faceDetector.processImage(image);

    if (mounted) {
      setState(() {
        _mainImageFile = File(imageFile.path);
        _faces = faces;
        _loadImage(File(imageFile.path));

      });
    }
  }

  _loadImage(File file) async {
    final data = await file.readAsBytes();
    await decodeImageFromList(data).then((value) => setState(() {
          _image = value;
          isLoading = false;
        }));
  }

}

class FacePainter extends CustomPainter {
  final ui.Image image;
  final List<Face> faces;
  final List<Rect> rects = [];

  FacePainter(this.image, this.faces) {
    for (var i = 0; i < faces.length; i++) {
      rects.add(faces[i].boundingBox);
    }
  }

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.yellow;

    canvas.drawImage(image, Offset.zero, Paint());
    for (var i = 0; i < faces.length; i++) {
      canvas.drawRect(rects[i], paint);
    }
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return image != oldDelegate.image || faces != oldDelegate.faces;
  }
}


