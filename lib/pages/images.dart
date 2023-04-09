import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase/pages/profilePage.dart';
import 'package:flutter_firebase/pages/users.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';

import '../auth.dart';

class images extends StatefulWidget {
  @override
  imagesState createState() => imagesState();
}

class ModelTest {
  final String url;
  final String name;
  final String size;
  

  ModelTest(this.url, this.name, this.size);
}

class imagesState extends State<images> {
  void _incrementCounter() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      dialogTitle: 'Выбор файла',
    );
    if (result != null) {
      final size = result.files.first.size;

      final file = io.File(result.files.single.path!);
      final fileExtensions = result.files.first.extension!;
      print("размер:$size file:${file.path} fileExtensions:${fileExtensions}");
      String imageName = '${DateTime.now().millisecondsSinceEpoch}';
      FirebaseStorage.instance.ref().child(imageName).putFile(file);

      if (FirebaseAuth.instance.currentUser != null) {
        final CollectionReference userRef =
            FirebaseFirestore.instance.collection("users");
        final user = <String, dynamic>{
          "image": imageName,
          "size": size,
          "ref": file.path
        };

        userRef.doc(FirebaseAuth.instance.currentUser!.uid).update(user);
      }
    } else {}
  }

  String link = '';
  String name ='';
  String size = '';
  List<ModelTest> fullpath = [];

  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  Random _rnd = Random();
  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  Future<void> initImage() async {
    fullpath.clear();
    final storageReference = FirebaseStorage.instance.ref().list();
    final list = await storageReference;
    list.items.forEach((element) async {
      final url = await element.getDownloadURL();
      final size = await element.getMetadata();
      fullpath.add(ModelTest(url, element.name, size.size.toString()));
      setState(() {});
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 196, 227, 203),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromARGB(255, 104, 133, 110),
                ),
                onPressed: () async {
                  await initImage();
                },
                child: const Text('Загрузить картинки')),
            Expanded(
              flex: 2,
              child: ListView.builder(
                itemCount: fullpath.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: InkWell(
                      onLongPress: () async {
                        link = '';
                        await FirebaseStorage.instance
                            .ref("/" + fullpath[index].name)
                            .delete();
                        await initImage();
                        setState(() {});
                      },
                      onTap: () {
                        
                        setState(() {
                          
                          link = fullpath[index].url;
                        });
                        
                      },
                      child: ListTile(
                        title: Text(fullpath[index].name),
                        subtitle: Text('${fullpath[index].size} bytes'),
                       
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              flex: 2,
              child: Image.network(
                link,
                errorBuilder: (context, error, stackTrace) {
                  return Text('Ошибка');
                },
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
