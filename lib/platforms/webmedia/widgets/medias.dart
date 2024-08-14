import 'package:flutter/material.dart';
import 'package:mediasaver/widgets/image_loader.dart';
import 'package:mediasaver/platforms/webMedia/models/webmedia.dart';

class MediaDisplay extends StatelessWidget {
  final WebMedia? mediaData;
  final Function(int) onDownloadPressed;
  final Map<int, bool> isDownloadingMap;

  const MediaDisplay({
    super.key,
    required this.mediaData,
    required this.onDownloadPressed,
    required this.isDownloadingMap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (mediaData != null)
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: CustomImageLoader(
                  imageUrl: mediaData!.cover,
                  height: MediaQuery.of(context).size.height / 3,
                  width: MediaQuery.of(context).size.width / 2,
                ),
              ),
            ],
          ),
        if (mediaData != null)
          mediaData!.desc.isEmpty ? Text(mediaData!.id) : Text(mediaData!.desc),
        if (mediaData != null) const SizedBox(height: 20),
        if (mediaData != null && mediaData!.medias != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: mediaData!.medias!.asMap().entries.map((entry) {
              int index = entry.key;
              Media media = entry.value;
              String formattedSize = media.size != null
                  ? '${(int.parse(media.size!) / (1024 * 1024)).toStringAsFixed(2)} MB'
                  : 'Size not available';
              String displayText = 'Quality: $index, Size: $formattedSize';

              Widget disc = media.cover != null
                  ? CustomImageLoader(
                      imageUrl: media.cover!,
                    )
                  : Text(displayText,
                      style: TextStyle(color: Theme.of(context).primaryColor));

              bool isDownloading = isDownloadingMap[index] ?? false;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: disc,
                  ),
                  TextButton(
                    onPressed: () async {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      if (isDownloadingMap[index] == true) return;

                      onDownloadPressed(index);
                    },
                    child: isDownloading
                        ? const CircularProgressIndicator()
                        : Icon(Icons.download,
                            color: Theme.of(context).primaryColor),
                  )
                ],
              );
            }).toList(),
          ),
        const SizedBox(height: 50),
      ],
    );
  }
}
