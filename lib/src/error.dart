import 'package:flutter/material.dart';

void showError(BuildContext context, String errorMessage) {
  final snackBar = SnackBar(
    content: Text(errorMessage),
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
