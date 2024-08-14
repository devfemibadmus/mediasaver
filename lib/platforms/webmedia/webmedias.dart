import 'package:flutter/material.dart';
import 'package:mediasaver/model.dart';
import 'package:mediasaver/widgets/overlay.dart';
import 'package:mediasaver/platforms/webMedia/models/webmedia.dart';
import 'package:mediasaver/platforms/webMedia/widgets/medias.dart';
import 'package:mediasaver/platforms/webMedia/widgets/form.dart';

class WebMedias extends StatefulWidget {
  const WebMedias({super.key});

  @override
  WebMediasState createState() => WebMediasState();
}

class WebMediasState extends State<WebMedias>
    with AutomaticKeepAliveClientMixin<WebMedias> {
  String? errorMessage;
  WebMedia? mediaData;
  Map<int, bool> isDownloadingMap = {};
  double downloadPercentage = 0.0;
  late TextEditingController _textController;
  late FocusNode _focusNode;
  Media? selectedQuality;
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode();
  }

  void onUrlChanged(String value) {
    setState(() {
      mediaData = null;
      CustomOverlay().removeOverlayLoader();
      if (isValidUrl(value)) {
        errorMessage = null;
      } else {
        errorMessage = 'Not a valid URL';
      }
    });
  }

  Future<void> onPasteButtonPressed() async {
    setState(() {
      mediaData = null;
      CustomOverlay().showOverlayLoader(context);
    });

    if (isValidUrl(_textController.text)) {
      final response = await fetchMediaFromServer(_textController.text);

      setState(() {
        if (response != null && response['success'] == true) {
          mediaData = response['data'];
          if (mediaData?.medias?.isNotEmpty ?? false) {
            selectedQuality = mediaData!.medias!.first;
          }
          CustomOverlay().removeOverlayLoader();
        } else {
          mediaData = null;
          CustomOverlay().removeOverlayLoader();
          errorMessage = response?['error'] ?? 'Try again!';
        }
      });
    } else {
      setState(() {
        mediaData = null;
        CustomOverlay().removeOverlayLoader();
        errorMessage = 'Not a valid URL';
      });
    }
  }

  void onDownloadPressed(int index) async {
    setState(() {
      isDownloadingMap[index] = true;
    });

    final result = await downloadFile(
        mediaData!.medias![index].address, '${mediaData!.id}_$index');

    if (!mounted) return;

    setState(() {
      isDownloadingMap[index] = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: <Widget>[
          WebMediaForm(
            onUrlChanged: onUrlChanged,
            onPasteButtonPressed: onPasteButtonPressed,
            textController: _textController,
          ),
          const SizedBox(height: 20),
          MediaDisplay(
            mediaData: mediaData,
            onDownloadPressed: onDownloadPressed,
            isDownloadingMap: isDownloadingMap,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
