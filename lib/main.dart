import 'package:fido/src/error.dart';
import 'package:fido/src/fido_login.dart';
import 'package:fido/src/key_repository.dart';
import 'package:fido/src/logged_in.dart';
import 'package:flutter/material.dart';

import 'src/fido_server.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Fido 2 Client Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page', key: GlobalKey()),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({required Key key, required this.title}) : super(key: key);
  final String title;
  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  bool startedLogin = false;
  bool loggedIn = false;
  final TextEditingController _tc = TextEditingController();
  final _api = FidoServer.testServer();
  String? keyHandle;

  Widget buildTextField() {
    return TextField(
      controller: _tc,
      decoration: const InputDecoration(
        border: InputBorder.none,
        hintText: 'Enter a username',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            buildTextField(),
            (startedLogin && !loggedIn)
                ? const CircularProgressIndicator(value: null)
                : ElevatedButton(
                    child: const Text('Login'),
                    onPressed: () async {
                      createUser(context);
                    },
                  ),
            ElevatedButton(
                child: const Text('Login with FIDO'),
                onPressed: () {
                  _loginWithFido(context);
                }),
            ElevatedButton(
                child: const Text('DEBUG: Press to reset everything'),
                onPressed: () async {
                  _resetDb(); // Client-side
                })
          ],
        ),
      ),
    );
  }

  /// Remove all credentials on the FIDO server.
  void _resetDb() {
    _api.resetDB(); // Server-side
    KeyRepository.removeAllKeys(); // Client-side
  }

  /// createUser on the FIDO server.
  void createUser(BuildContext context) async {
    setState(() => startedLogin = true);
    String username = _tc.text;
    if (username.isEmpty) {
      setState(() => startedLogin = false);
      showError(context, "Please enter a username!");
      return;
    }
    await _api.createUser(username);
    setState(() => loggedIn = true);
    // ignore: use_build_context_synchronously
    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => LoggedInPage(loggedInUser: username)));
  }

  /// Login using FIDO
  void _loginWithFido(BuildContext context) {
    if (loggedIn == false) {
      setState(() => startedLogin = false);
      showError(context, "Please Login first.");
      return;
    }
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => FidoLogin(username: _tc.text)));
  }
}
