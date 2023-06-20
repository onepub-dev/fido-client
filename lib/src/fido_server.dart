import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class FidoServer {
  String baseUrl;
  FidoServer(this.baseUrl);

  factory FidoServer.testServer() {
    return FidoServer(testURl);
  }

  String get name => "OnePub Fido Server";

  // static const String testURl = 'http://localhost:8080';
  /// connect to local fido server from emulator
  static const String testURl = 'http://squarephone.biz:8080';

  final _client = http.Client();

  /// Create a user on the server with the [username].
  /// This user is NOT validated.
  Future<String?> createUser(String username) async {
    var uri = Uri.parse('$baseUrl/create-user');
    print(await InternetAddress.lookup(uri.host));

    var response = await _client.post(uri,
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        body: jsonEncode({'username': username}));
    String? rawCookie = response.headers[HttpHeaders.setCookieHeader];
    if (rawCookie == null) return null;
    Cookie user = Cookie.fromSetCookieValue(rawCookie);
    print(response.body);
    return user.value;
  }

  Future<RegisterOptions> registerRequest(String username) async {
    var response = await _client.post(Uri.parse('$baseUrl/register-request'),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.cookieHeader: 'username=$username; signed-in=yes',
          'X-Requested-With': 'XMLHttpRequest'
        },
        body: jsonEncode(
          {
            'attestation': 'none',
            'authenticatorSelection': {
              'authenticatorAttachment': 'platform',
              'userVerification': 'required'
            },
          },
        ));
    print(response.body);
    return _parseRegisterReq(response.body);
  }

  Future<User> registerResponse(String username, String challenge,
      String keyHandle, String clientDataJSON, String attestationObj) async {
    var response = await _client.post(Uri.parse('$baseUrl/register-response'),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.cookieHeader:
              'username=$username; challenge=$challenge; signed-in=yes',
          'X-Requested-With': 'XMLHttpRequest'
        },
        body: jsonEncode(
          {
            'id': keyHandle,
            'type': 'public-key',
            'rawId': keyHandle,
            'response': {
              'clientDataJSON': clientDataJSON,
              'attestationObject': attestationObj,
            }
          },
        ));
    print(response.body);
    return _parseUser(response.body);
  }

  Future<SigningOptions> signingRequest(
      String username, String keyHandle) async {
    var url = Uri.parse('$baseUrl/signingRequest?credId=$keyHandle');
    var response = await _client.post(url,
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.cookieHeader: 'username=$username',
          'X-Requested-With': 'XMLHttpRequest'
        },
        body: jsonEncode({}));
    print(response.body);
    return _parseSigningReq(response.body);
  }

  Future<User> signingResponse(
      String username,
      String keyHandle,
      String challenge,
      String clientData,
      String authData,
      String signature,
      String userHandle) async {
    var url = Uri.parse('$baseUrl/signingResponse');
    var response = await _client.post(url,
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.cookieHeader: 'username=$username; challenge=$challenge',
          'X-Requested-With': 'XMLHttpRequest'
        },
        body: jsonEncode({
          'id': keyHandle,
          'type': 'public-key',
          'rawId': keyHandle,
          'response': {
            'clientDataJSON': clientData,
            'authenticatorData': authData,
            'signature': signature,
            'userHandle': userHandle
          }
        }));
    print(response.body);
    return _parseUser(response.body);
  }

  Future<void> resetDB() async {
    await _client.post(Uri.parse('$baseUrl/resetDB'), headers: {}, body: {});
  }

  RegisterOptions _parseRegisterReq(String responseBody) {
    var json = jsonDecode(responseBody);
    String rpId = json['rp']['id'];
    String rpName = json['rp']['name'];
    String username = json['user']['name'];
    String userId = json['user']['id'];
    int algoId = json['pubKeyCredParams'][0]['alg'];
    String challenge = json['challenge'];
    return RegisterOptions(
        rpId: rpId,
        rpName: rpName,
        userId: userId,
        username: username,
        algoId: algoId,
        challenge: challenge);
  }

  SigningOptions _parseSigningReq(String responseBody) {
    var json = jsonDecode(responseBody);
    String rpId = json['rpId'];
    String challenge = json['challenge'];
    return SigningOptions(rpId: rpId, challenge: challenge);
  }

  User _parseUser(String responseBody) {
    var json = jsonDecode(responseBody);
    if (json['error'] != null) {
      return User(error: json['error']);
    }
    String username = json['username'];
    String userId = json['id'];
    return User(username: username, id: userId);
  }

  Future<String> fetchChallenge(String userEmail) async {
    final url = Uri.parse('http://$baseUrl/challenge');

    // Replace 'userId' with the parameter name expected by your server
    final response = await http.post(
      url,
      body: {'userId': userEmail},
    );

    if (response.statusCode == 200) {
      // Assuming the challenge is returned as a plain text response
      return response.body;
    } else {
      throw Exception(
          'Failed to fetch challenge. Status code: ${response.statusCode}');
    }
  }
}

class User {
  User({this.username, this.id, this.error});

  String? username;
  String? id;
  String? error;
}

class SigningOptions {
  SigningOptions({required this.rpId, required this.challenge});

  String rpId;
  String challenge;
}

class RegisterOptions {
  RegisterOptions(
      {required this.rpId,
      required this.rpName,
      required this.userId,
      required this.username,
      required this.algoId,
      required this.challenge});

  String rpId;
  String rpName;
  String username;
  String userId;
  int algoId;
  String challenge;
}
