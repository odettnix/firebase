import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_firebase/main.dart';
import 'package:flutter_firebase/pages/profilePage.dart';

class Auth extends StatefulWidget {
  const Auth({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return AuthState();
  }
}

class AuthState extends State<Auth> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController loginController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  Future<void> anon() async {
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      print("Signed in with temporary account.");
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "operation-not-allowed":
          print("Anonymous auth hasn't been enabled for this project.");
          break;
        default:
          print("Unknown error.");
      }
    }
  }

  void emailLink(String email) async {
    var acs = ActionCodeSettings(
        url: 'https://flutterfirebase123.page.link/rniX',
        handleCodeInApp: true,
        androidPackageName: 'com.example.flutter_firebase',
        androidInstallApp: false,
        androidMinimumVersion: '12');

    FirebaseAuth.instance
        .sendSignInLinkToEmail(email: email, actionCodeSettings: acs)
        .catchError(
            (onError) => print('Error sending email verification $onError'))
        .then((value) => print('Successfully sent email verification'));

    PendingDynamicLinkData dynamicLink =
        await FirebaseDynamicLinks.instance.onLink.first;
    String link = dynamicLink.link.toString();
    if (FirebaseAuth.instance.isSignInWithEmailLink(link)) {
      try {
        final userCredential = await FirebaseAuth.instance
            .signInWithEmailLink(email: email, emailLink: link);

        final emailAddress = userCredential.user?.email;

        print(userCredential.user?.email);
        print('Successfully signed in with email link!');
        // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Успешный вход', textAlign: TextAlign.center)));
        // Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MyHomePage()));
      } catch (error) {
        print('Error signing in with email link.');
        // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Неуспешный вход', textAlign: TextAlign.center)));
      }
    }
  }

  final CollectionReference userRef =
      FirebaseFirestore.instance.collection("users");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 196, 227, 203),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Form(
              key: formKey,
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.all(25),
                  child: TextFormField(
                    controller: loginController,
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
                    controller: passwordController,
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
                      labelText: "Пароль",
                    ),
                  ),
                ),
                Column(
                  children: [
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor:
                              const Color.fromARGB(255, 104, 133, 110),
                        ),
                        onPressed: () async {
                          try {
                            final credential = await FirebaseAuth.instance
                                .createUserWithEmailAndPassword(
                              email: loginController.text,
                              password: passwordController.text,
                            );
                            print('Пользователь создан успешно');
                            final uid = credential.user?.uid.toString();
                            final user = <String, dynamic>{
                              "email": "${credential.user?.email}",
                              "password": passwordController.text,
                              "image": '',
                              "size": '',
                              "ref": '',
                            };

                            var postID = credential.user?.uid;

                            userRef.doc(postID.toString()).set(user);

                            // FirebaseFirestore.instance.collection("users").doc(credential.user?.uid.toString()).set(user);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Пользователь создан успешно',
                                        textAlign: TextAlign.center)));
                            print(credential.user?.uid);
                          } on FirebaseAuthException catch (e) {
                            if (e.code == 'weak-password') {
                              print('The password provided is too weak.');
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Слабый пароль',
                                          textAlign: TextAlign.center)));
                            } else if (e.code == 'email-already-in-use') {
                              print(
                                  'The account already exists for that email.');
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Аккаунт с такой почтой уже существует',
                                          textAlign: TextAlign.center)));
                            }
                          } catch (e) {
                            print(e);
                          }
                        },
                        child: const Text('Создать пользователя')),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor:
                              const Color.fromARGB(255, 104, 133, 110),
                        ),
                        onPressed: () async {
                          try {
                            final credential = await FirebaseAuth.instance
                                .signInWithEmailAndPassword(
                              email: loginController.text,
                              password: passwordController.text,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Успешный вход',
                                        textAlign: TextAlign.center)));
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => profilePage()));
                          } on FirebaseAuthException catch (e) {
                            if (e.code == 'user-not-found') {
                              print('No user found for that email.');
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Неверная почта',
                                          textAlign: TextAlign.center)));
                            } else if (e.code == 'wrong-password') {
                              print('Wrong password provided for that user.');
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Неверный пароль',
                                          textAlign: TextAlign.center)));
                            }
                          }
                        },
                        child: const Text('Войти в аккаунт')),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor:
                              const Color.fromARGB(255, 104, 133, 110),
                        ),
                        onPressed: () async {
                          emailLink(loginController.text);
                          print('Успешный chggh');
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Письмо выслано на почту',
                                      textAlign: TextAlign.center)));
                        },
                        child: const Text('Войти с почтой')),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor:
                              const Color.fromARGB(255, 104, 133, 110),
                        ),
                        onPressed: () async {
                          anon();
                          print('Успешный анониный вход');
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Успешный анонимный вход',
                                      textAlign: TextAlign.center)));
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => profilePage()));
                        },
                        child: const Text('Анонимный вход'))
                  ],
                )
              ]),
            )
          ],
        ));
  }
}
