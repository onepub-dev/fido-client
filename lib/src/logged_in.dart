import 'package:flutter/material.dart';

import 'fido_registration.dart';
import 'key_repository.dart';

class LoggedInPage extends StatefulWidget {
  const LoggedInPage({Key? key, required this.loggedInUser}) : super(key: key);
  final String loggedInUser;
  @override
  LoggedInPageState createState() => LoggedInPageState();
}

class LoggedInPageState extends State<LoggedInPage> {
  get loggedInUser => widget.loggedInUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Logged in as $loggedInUser'),
        ),
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Logged in page'),
            FutureBuilder<String?>(
                future: KeyRepository.loadKeyHandle(loggedInUser),
                builder:
                    (BuildContext context, AsyncSnapshot<String?> snapshot) {
                  if (!snapshot.hasData) {
                    return ElevatedButton(
                      child: const Text(
                          'Press to go to FIDO credential registration page'),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) =>
                                FidoRegistration(loggedInUser: loggedInUser)));
                      },
                    );
                  } else {
                    return Container();
                  }
                })
          ],
        )));
  }
}
