import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase/pages/images.dart';
import 'package:flutter_firebase/pages/users.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';

import '../auth.dart';

class profilePage extends StatefulWidget {
  @override
  profilePageState createState() => profilePageState();
}

class ModelTest {
  final String url;
  final String name;
  final String size;

  ModelTest(this.url, this.name, this.size);
}

class profilePageState extends State<profilePage> {
  static FirebaseStorage storage = FirebaseStorage.instance;

  String avatar = '';

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
      await FirebaseStorage.instance.ref().child(imageName).putFile(file);

      final path = await FirebaseStorage.instance
          .ref()
          .child(imageName)
          .getDownloadURL();

      if (FirebaseAuth.instance.currentUser != null) {
        final CollectionReference userRef =
            FirebaseFirestore.instance.collection("users");
        final user = <String, dynamic>{
          "image": imageName,
          "size": size,
          "ref": path
        };

        userRef.doc(FirebaseAuth.instance.currentUser!.uid).update(user);

        setState(() {
          avatar = path;
        });
      }
    } else {}
  }

  String link = '';
  List<ModelTest> fullpath = [];

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

  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController oldPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  @override
  void initState() {
    if (FirebaseAuth.instance.currentUser != null) {
      emailController.text = FirebaseAuth.instance.currentUser!.email!;
       final CollectionReference userRef =
        FirebaseFirestore.instance.collection("users");
    final docRef =
        userRef.doc(FirebaseAuth.instance.currentUser!.uid.toString());
    docRef.get().then((DocumentSnapshot doc) async {
      final data = doc.data() as Map<String, dynamic>;
      print(data['image']);
      avatar = data['ref'];
      setState(() {});
    });
    } else {
      emailController.text = 'Аноним';
    }

    

   

    super.initState();
  }

  Future<bool> _changePassword(
      String currentPassword, String newPassword) async {
    bool success = false;

    String email = FirebaseAuth.instance.currentUser!.email!;
    var user = await FirebaseAuth.instance.currentUser!;

    await user.updatePassword(newPassword);
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: newPassword);
      success = true;
    } on FirebaseAuthException catch (e) {
      print(e.message);
    }

    return success;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 196, 227, 203),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(avatar),
                child: Card(
                  elevation: 0,
                  color: Colors.transparent,
                  child: InkWell(
                    
                    onLongPress: () async {
                      final CollectionReference userRef =
                          FirebaseFirestore.instance.collection("users");
                      final docRef = userRef.doc(
                          FirebaseAuth.instance.currentUser!.uid.toString());
                      docRef.get().then((DocumentSnapshot doc) async {
                        final data = doc.data() as Map<String, dynamic>;
                        print(data['image']);
                        FirebaseStorage.instance
                            .ref()
                            .child(data['image'])
                            .delete()
                            .then((value) async {
                          if (FirebaseAuth.instance.currentUser != null) {
                            final CollectionReference userRef =
                                FirebaseFirestore.instance.collection("users");
                            final user = <String, dynamic>{
                              "image": '',
                              "size": '',
                              "ref":
                                  'https://pic.rutubelist.ru/video/de/ec/deec01f1a6b0cc169f292a672c9206a9.jpg',
                            };

                            await userRef
                                .doc(FirebaseAuth.instance.currentUser!.uid)
                                .update(user);

                            setState(() {
                              avatar =
                                  'https://pic.rutubelist.ru/video/de/ec/deec01f1a6b0cc169f292a672c9206a9.jpg';
                            });
                          }
                        });
                      });
                    },
                    onTap: _incrementCounter
                  ),
                )),
            Form(
              key: formKey,
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.all(25),
                  child: TextFormField(
                    controller: emailController,
                    validator: (value) {
                      if (value == "") {
                        return "Поле не должны быть пустым";
                      }
                    },
                    style: const TextStyle(
                        color: Color.fromARGB(255, 104, 133, 110)),
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color.fromARGB(255, 104, 133, 110))),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color.fromARGB(255, 74, 97, 78))),
                      labelStyle:
                          TextStyle(color: Color.fromARGB(255, 104, 133, 110)),
                      labelText: "Почта",
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(right: 25, left: 25, bottom: 25),
                  child: TextFormField(
                    controller: oldPasswordController,
                    style:
                        const TextStyle(color: Color.fromARGB(255, 70, 90, 74)),
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color.fromARGB(255, 70, 90, 74))),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color.fromARGB(255, 74, 97, 78))),
                      labelStyle:
                          TextStyle(color: Color.fromARGB(255, 104, 133, 110)),
                      labelText: "Старый пароль",
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(right: 25, left: 25, bottom: 25),
                  child: TextFormField(
                    controller: newPasswordController,
                    style:
                        const TextStyle(color: Color.fromARGB(255, 70, 90, 74)),
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color.fromARGB(255, 70, 90, 74))),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color.fromARGB(255, 74, 97, 78))),
                      labelStyle:
                          TextStyle(color: Color.fromARGB(255, 104, 133, 110)),
                      labelText: "Новый пароль",
                    ),
                  ),
                ),
              ]),
            ),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromARGB(255, 104, 133, 110),
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const Auth()));
                },
                child: const Text('Выйти из аккаунта')),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromARGB(255, 104, 133, 110),
                ),
                onPressed: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (context) => images()));
                },
                child: const Text('Картинки')),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromARGB(255, 104, 133, 110),
                ),
                onPressed: () async {
                  final CollectionReference userRef =
                      FirebaseFirestore.instance.collection("users");
                  final docRef = userRef
                      .doc(FirebaseAuth.instance.currentUser!.uid.toString());
                  docRef.get().then((DocumentSnapshot doc) async {
                    final data = doc.data() as Map<String, dynamic>;
                    print(data['image']);
                    FirebaseStorage.instance
                        .ref()
                        .child(data['image'])
                        .delete()
                        .then((value) async {
                      if (FirebaseAuth.instance.currentUser != null) {
                        final CollectionReference userRef =
                            FirebaseFirestore.instance.collection("users");
                        final user = <String, dynamic>{
                          "image": '',
                          "size": '',
                          "ref":
                              'https://pic.rutubelist.ru/video/de/ec/deec01f1a6b0cc169f292a672c9206a9.jpg',
                        };

                        await userRef
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .update(user);

                        setState(() {
                          avatar =
                              'https://pic.rutubelist.ru/video/de/ec/deec01f1a6b0cc169f292a672c9206a9.jpg';
                        });
                      }
                    });
                  });
                },
                child: const Text('Удалить картинку')),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromARGB(255, 104, 133, 110),
                ),
                onPressed: () async {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => UserInformation()));
                  FirebaseFirestore.instance.collection("users").get().then(
                    (querySnapshot) {
                      print("Successfully completed");
                      for (var docSnapshot in querySnapshot.docs) {
                        print('${docSnapshot.id} => ${docSnapshot.data()}');
                      }
                    },
                    onError: (e) => print("Error completing: $e"),
                  );
                },
                child: const Text('Пользователи')),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromARGB(255, 104, 133, 110),
                ),
                onPressed: () async {
                  final CollectionReference userRef =
                      FirebaseFirestore.instance.collection("users");
                  userRef
                      .doc(FirebaseAuth.instance.currentUser!.uid.toString())
                      .delete()
                      .then(
                        (doc) => print("Document deleted"),
                        onError: (e) => print("Error updating document $e"),
                      );

                  FirebaseAuth.instance.authStateChanges().listen((User? user) {
                    if (user != null) {
                      user.delete();
                    }
                  });

                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const Auth()));
                },
                child: const Text('Удалить аккаунт')),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromARGB(255, 104, 133, 110),
                ),
                onPressed: () async {
                  try {
                    if (FirebaseAuth.instance.currentUser != null) {
                      final CollectionReference userRef =
                          FirebaseFirestore.instance.collection("users");
                      String pass = newPasswordController.text.toString();
                      final docRef = userRef.doc(
                          FirebaseAuth.instance.currentUser!.uid.toString());

                      docRef.get().then(
                        (DocumentSnapshot doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          FirebaseAuth.instance
                              .authStateChanges()
                              .listen((User? user) async {
                            if (user != null) {
                              if (oldPasswordController.text.isNotEmpty) {
                                pass = newPasswordController.text;
                                print(data['password']);
                                await _changePassword(
                                    oldPasswordController.text, pass);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Пароль успешно обновлен',
                                            textAlign: TextAlign.center)));
                              } else {
                                pass = data['password'];
                              }
                              user?.updateEmail(emailController.text);
                            }
                          });
                        },
                        onError: (e) => print("Error getting document: $e"),
                      );
                      final user = <String, dynamic>{
                        "email": emailController.text,
                        "password": pass
                      };
                      userRef
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .set(user);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Аноним не может менять данные',
                              textAlign: TextAlign.center)));
                    }
                  } on FirebaseAuthException catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text('Ошибка: ${e}', textAlign: TextAlign.center)));
                  }
                },
                child: const Text('Обновить данные')),
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
