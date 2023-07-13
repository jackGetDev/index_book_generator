import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PDF Upload',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: UploadScreen(),
    );
  }
}

class UploadScreen extends StatefulWidget {
  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? selectedFile;
  bool isUploading = false;
  Map<String, List<int>>? indexData;

  Future<void> selectFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> uploadFile() async {
    if (selectedFile == null) {
      return;
    }

    setState(() {
      isUploading = true;
    });

    final url = 'http://localhost:5000/api/upload';
    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.files.add(await http.MultipartFile.fromPath('pdf', selectedFile!.path));

    try {
      final response = await request.send();
      final jsonResponse = await response.stream.bytesToString();
      final data = jsonDecode(jsonResponse) as Map<String, dynamic>;

      setState(() {
        indexData = data.map((key, value) => MapEntry(key, List<int>.from(value['page'])));
      });
    } catch (e) {
      print('Upload error: $e');
    }

    setState(() {
      isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Upload'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: selectFile,
                child: Text('Select PDF File'),
              ),
              SizedBox(height: 16),
              if (selectedFile != null)
                Text('Selected File: ${selectedFile!.path ?? ''}'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: isUploading ? null : uploadFile,
                child: isUploading
                    ? SpinKitCircle(color: Colors.white)
                    : Text('Upload'),
              ),
              SizedBox(height: 16),
              if (isUploading)
                CircularProgressIndicator()
              else if (indexData != null)
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: indexData!.length,
                  itemBuilder: (context, index) {
                    final entry = indexData!.entries.elementAt(index);
                    final word = entry.key;
                    final pages = entry.value;
                    final firstLetter = word.substring(0, 1).toUpperCase();
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(firstLetter),
                      ),
                      title: Text(word),
                      subtitle: Text('Pages: ${pages.join(', ')}'),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
