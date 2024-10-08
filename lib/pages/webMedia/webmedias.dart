import 'package:flutter/material.dart';
import 'package:mediasaver/model.dart';
import 'package:mediasaver/widgets/overlay.dart';
import 'package:mediasaver/pages/webmedia/models/webmedia.dart';
import 'package:mediasaver/pages/webmedia/widgets/form.dart';
import 'package:mediasaver/pages/webmedia/widgets/medias.dart';

class WebMedias extends StatefulWidget {
  const WebMedias({super.key});

  @override
  WebMediasState createState() => WebMediasState();
}

class WebMediasState extends State<WebMedias>
    with AutomaticKeepAliveClientMixin<WebMedias> {
  WebMedia? mediaData;
  Map<int, bool> isDownloadingMap = {};
  double downloadPercentage = 0.0;
  late TextEditingController _textController;
  late FocusNode _focusNode;
  String? errorMessage;
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
    _textController.text = value;
    setState(() {
      mediaData = null;
      CustomOverlay().removeOverlayLoader();
      if (isSupportUrl(value)) {
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
    if (isSupportUrl(_textController.text)) {
      final response = await fetchMediaFromServer(_textController.text);
      setState(() {
        if (response != null && response['success'] != null) {
          mediaData = response['data'];
          if (mediaData?.medias?.isNotEmpty ?? false) {
            selectedQuality = mediaData!.medias!.first;
          }
        } else {
          errorMessage = response?['message'] ?? 'Try again!';
        }
      });
    } else {
      setState(() {
        mediaData = null;
        errorMessage = 'Not a valid URL';
      });
    }
    CustomOverlay().removeOverlayLoader();
  }

  void onDownloadPressed(int index) async {
    setState(() {
      isDownloadingMap[index] = true;
    });
    late String result;
    if (mediaData!.videoUrl != null && mediaData!.audioUrl != null) {
      result = await downloadFile(
          mediaData!.videoUrl, mediaData!.audioUrl, '${mediaData!.id}_$index');
    } else {
      result = await downloadFile(
          mediaData!.medias![index].address, null, '${mediaData!.id}_$index');
    }

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
            errorMessage: errorMessage,
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
