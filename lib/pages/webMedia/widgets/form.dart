import 'package:flutter/material.dart';
import 'package:mediasaver/model.dart';

class WebMediaForm extends StatefulWidget {
  const WebMediaForm({
    super.key,
    required this.onUrlChanged,
    required this.onPasteButtonPressed,
    required this.textController,
    required this.errorMessage,
  });

  final Function(String) onUrlChanged;
  final Function() onPasteButtonPressed;
  final TextEditingController textController;
  final String? errorMessage;

  @override
  WebMediaFormState createState() => WebMediaFormState();
}

class WebMediaFormState extends State<WebMediaForm> {
  late FocusNode _focusNode;
  String pastebtn = "Paste";

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          pastebtn = "Search";
        });
      } else {
        setState(() {
          pastebtn = "Paste";
        });
      }
    });
    /*
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
    */
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextFormField(
            onChanged: widget.onUrlChanged,
            style: TextStyle(color: Theme.of(context).primaryColor),
            controller: widget.textController,
            focusNode: _focusNode,
            cursorColor: Theme.of(context).primaryColor,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              errorText: widget.errorMessage,
              labelText: 'Media URL',
              labelStyle: TextStyle(color: Theme.of(context).primaryColor),
              contentPadding: const EdgeInsets.all(5.0),
              isDense: true,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        TextButton(
          onPressed: () async {
            final value = await fetchClipboardContent();
            if (pastebtn == "Paste") {
              widget.textController.text = value;
            }
            widget.onPasteButtonPressed();
            _focusNode.unfocus();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            padding: const EdgeInsets.all(6),
            minimumSize: Size.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: pastebtn == "Paste"
              ? const Icon(Icons.paste)
              : const Icon(Icons.search),
        ),
      ],
    );
  }
}
