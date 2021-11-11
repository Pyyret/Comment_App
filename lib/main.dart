import 'package:cmt_projekt/viewmodel/createaccviewmodel.dart';
import 'package:cmt_projekt/viewmodel/loginpageviewmodel.dart';
import 'package:cmt_projekt/viewmodel/page_navigator_viewmodel.dart';
import 'package:cmt_projekt/website/View/web_loginpage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/View/app_loginpage.dart';

void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LoginPageViewModel()),
      ChangeNotifierProvider(create: (_) => CreateAccountViewModel()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: kIsWeb ? const WebLoginPage() : AppLoginPage(),
      routes: PageNavigator().routes,
    );
  }
}