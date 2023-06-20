// ignore_for_file: library_private_types_in_public_api

import 'package:fido2_client/fido2_client.dart';
import 'package:fido2_client/signing_result.dart';
import 'package:flutter/material.dart';

import 'fido_server.dart';
import 'key_repository.dart';
import 'logged_in.dart';

class FidoLogin extends StatefulWidget {
  const FidoLogin({Key? key, required this.username}) : super(key: key);

  final String username;
  @override
  _FidoLoginPageState createState() => _FidoLoginPageState();
}

class _FidoLoginPageState extends State<FidoLogin> {
  final _api = FidoServer.testServer();
  SigningOptions? _signingOptions;
  String status = 'Not started';

  get username => widget.username;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Trying to login to $username using FIDO'),
        ),
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
                'Request signing options and then use them to login with FIDO'),
            Text('SIGNING STATUS: $status'),
            ElevatedButton(
                child: const Text('Press to request signing options'),
                onPressed: () async {
                  setState(() {
                    status = 'Retrieving signing options...';
                  });
                  String? keyHandle =
                      await KeyRepository.loadKeyHandle(username);
                  if (keyHandle == null) {
                    setState(() {
                      status =
                          'Key handle not found! User did not register FIDO credentials.';
                    });
                    return;
                  }
                  SigningOptions response =
                      await _api.signingRequest(username, keyHandle);
                  _signingOptions = response;
                  setState(() {
                    status = 'Signing options retrieved.';
                  });
                }),
            ElevatedButton(
                child: const Text('Press to sign using credentials'),
                onPressed: () async {
                  setState(() {
                    status = 'Signing process initiating...';
                  });
                  Fido2Client f = Fido2Client();
                  String? kh = await KeyRepository.loadKeyHandle(username);
                  SigningResult res = await f.initiateSigning(
                      kh!, _signingOptions!.challenge,
                      rpDomain: _signingOptions!.rpId);
                  KeyRepository.storeKeyHandle(res.keyHandle, username);
                  User u = await _api.signingResponse(
                      username,
                      res.keyHandle,
                      _signingOptions!.challenge,
                      res.clientData,
                      res.authData,
                      res.signature,
                      res.userHandle);
                  // If no error, then user has been logged in successfully
                  if (u.error == null) {
                    setState(() {
                      status = 'Successful signing!';
                    });
                    // ignore: use_build_context_synchronously
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) =>
                            LoggedInPage(loggedInUser: u.username!)));
                  } else {
                    setState(() {
                      status = 'Error!';
                    });
                  }
                })
          ],
        )));
  }
}
