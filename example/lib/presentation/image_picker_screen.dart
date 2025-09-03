import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:opencv_edge_detection_example/presentation/result_screen.dart';
import 'package:opencv_edge_detection_example/utils/image_processor.dart';
import 'package:opencv_edge_detection_example/utils/util.dart';
import 'package:path_provider/path_provider.dart';

class ImagePickerScreen extends StatefulWidget {
  const ImagePickerScreen({super.key});

  @override
  State<ImagePickerScreen> createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
 final _imagePicker = ImagePicker();
 late String _appTempDirectoryPath;
 bool _isLoading = true;

 @override
  void initState() {
    super.initState();
    _init();
  }

 Future<void> _init() async {
   try {
     final directory = await getTemporaryDirectory();
     _appTempDirectoryPath = directory.path;
     setState(() {});
   }
   finally {
    _isLoading = false;
    setState(() {});
   }
 }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading ? Center(child: CircularProgressIndicator()) :  ElevatedButton(onPressed: () async{
          _isLoading = true;
          setState(() {});
         final pickedImage = await _imagePicker.pickImage(source: ImageSource.gallery);
         if(pickedImage == null || !mounted){
           _isLoading = false;
           setState(() {});
           return;
         }
      
         final inputPath = pickedImage.path;
         imageCache.clear();
         final tempFilePath = '$_appTempDirectoryPath/temp.jpeg';
      
         final edgeDetectionResult = await processLiveImage(
             inputPath: inputPath,
             outputPath: tempFilePath,
         );
      
         if (edgeDetectionResult == null || !mounted) {
           _isLoading = false;
           setState(() {});
           return;
         }
      
         if(Platform.isAndroid){
           await rotateImage(File(tempFilePath),angle: 90);
         }
      
         if(!mounted){
           _isLoading = false;
           setState(() {});
           return;
         }

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => ResultScreen(croppedFilePath: tempFilePath),
            ),
                (_) => false,
          );
        }, child: Text('Pick image')),
      ),
    );
  }
}
