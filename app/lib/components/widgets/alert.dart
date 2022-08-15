import 'package:flutter/material.dart';

class Alert {
  /**
   * Body sample
   * <Widget>[
      Text('This is a demo alert dialog.'),
      Text('Would you like to approve of this message?'),
      ],
   */
  static Future<void> show(
      BuildContext context,
      String title,
      List<Widget> body) async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: ListBody(
                children: body
              )
            ),
            actions: [
              MaterialButton(
                  child: const Text("OK"),
                  onPressed: () {
                    Navigator.pop(context);
                  }
              )
            ]
          );
        }
    );
  }
}