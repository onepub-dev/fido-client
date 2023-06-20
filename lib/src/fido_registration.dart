import 'package:fido2_client/authenticator_error.dart';
import 'package:fido2_client/fido2_client.dart';
import 'package:fido2_client/registration_result.dart';
import 'package:flutter/material.dart';

import 'error.dart';
import 'fido_server.dart';
import 'key_repository.dart';

class FidoRegistration extends StatefulWidget {
  const FidoRegistration({Key? key, required this.loggedInUser})
      : super(key: key);
  final String loggedInUser;
  @override
  FidoRegistrationState createState() => FidoRegistrationState();
}

class FidoRegistrationState extends State<FidoRegistration> {
  final _api = FidoServer.testServer();
  RegisterOptions? _registerOptions;
  String status = 'Not started';

  get loggedInUser => widget.loggedInUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Register credentials for $loggedInUser'),
        ),
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('REGISTRATION STATUS: $status'),
            ElevatedButton(
                child: const Text('Press to request registration options'),
                onPressed: () async {
                  setState(() {
                    status = 'Retrieving registration options...';
                  });
                  _registerOptions = await _api.registerRequest(loggedInUser);
                  setState(() {
                    status = 'Registration options retrieved';
                  });
                }),
            ElevatedButton(
                child: const Text('Press to register credentials'),
                onPressed: () async {
                  await _regisiterCredentials(context);
                }),
          ],
        )));
  }

  Future<void> _regisiterCredentials(BuildContext context) async {
    try {
      if (_registerOptions == null) {
        showError(context, "You must 'Request Registration Options' first");
      }
      Fido2Client f = Fido2Client();
      print('relay id: ${_registerOptions!.rpId}');
      RegistrationResult r = await f.initiateRegistration(
          challenge: _registerOptions!.challenge,
          userId: _registerOptions!.userId,
          username: _registerOptions!.username,
          rpDomain: _registerOptions!.rpId,
          rpName: _registerOptions!.rpName,
          coseAlgoValue: "${_registerOptions!.algoId}");
      await KeyRepository.storeKeyHandle(r.keyHandle, loggedInUser);
      User u = await _api.registerResponse(
          loggedInUser,
          _registerOptions!.challenge,
          r.keyHandle,
          r.clientData,
          r.attestationObj);
      if (u.error == null) {
        setState(() {
          status = 'Success!';
          Navigator.of(context).pop();
        });
      } else {
        setState(() {
          status = 'Error!';
        });
      }
    } on AuthenticatorError catch (e) {
      setState(() => status = '${e.errorName} ${e.errMsg}');
    }
  }
}
