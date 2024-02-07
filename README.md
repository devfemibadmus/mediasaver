# Whatsapp Status Saver

WhatsApp Status Saver offers a user-friendly experience for managing and saving WhatsApp status updates. Check out the key features:

| #  | To-Do                      | Description                                                                                        | Status |
| -- | -------------------------- | -------------------------------------------------------------------------------------------------- | ------ |
| 1  | Efficient Updates          | Uses streams for quick and efficient updates, reducing the need for full widget refresh.           | ✅     |
| 2  | Recently Viewed            | Access recently saved status updates easily through a dedicated section.                           | ✅     |
| 3  | Chronological View         | Displays recently viewed status updates in chronological order.                                    | ✅     |
| 4  | Video Thumbnails           | Provides video thumbnails for a quick preview of the content.                                      | ✅     |
| 5  | Single Refresh Option      | Allows a single refresh option in development mode for testing purposes.                           | ✅     |
| 6  | Universal WhatsApp Support | Compatible with various WhatsApp versions for a hassle-free setup.                                 | ✅     |
| 7  | Media Handling             | Manages file not found issues while streaming status.                                              | ✅     |
| 8  | Status Management          | Delete, download, share and save status updates effortlessly.                                      | ✅     |
| 9  | Query Functionality        | Check if a status update has already been saved with the query feature.                            | ✅     |
| 10 | Refresh Handling           | Improved refresh handling for both individual and all status updates.                              | ✅     |
| 11 | Navigation Menu            | Introduces a navigation menu for more info.                                                        | ❌     |
| 12 | Video Playing              | Error while playing viddeo, solve the slight error.                                                | ✅     |
| 13 | WhatsApp Theme             | Adopts a WhatsApp theme for a cohesive and visually appealing interface.                           | ✅     |
| 14 | Platform iOs               | null                                                                                               | ❌     |
| 15 | Platform Android           | >=5.0                                                                                              | ✅     |
| 16 | PlayStore                  | Production Full rollout In review                                                                  | ❌     |

Explore the streamlined features of WhatsApp Status Saver and enjoy an enriched experience! If you have any concerns or suggestions, please feel free to share them.

## Dependecncies :alien: we dont ask much here  :poop:

```yaml
dependencies:
  flutter:
    sdk: flutter


  # The following adds the Cupertino Icons font to your application.
  # Use with the CupertinoIcons class for iOS style icons.
  cupertino_icons: ^1.0.6
  video_player: ^2.8.2
```
## Media

| Screenshot | Screenshot |
|-------------------------------------------------------------|-------------------------------------------------------------|
| ![Whatsapp](media/Screenshot_20240206_235829.jpeg?raw=true) | ![Whatsapp](media/Screenshot_20240206_235840.jpeg?raw=true) |
| ![Whatsapp](media/Screenshot_20240206_235852.jpeg?raw=true) | ![Whatsapp](media/Screenshot_20240206_235903.jpeg?raw=true) |
| ![Whatsapp](media/Screenshot_20240206_235908.jpeg?raw=true) | ![Whatsapp](media/Screenshot_20240206_235923.jpeg?raw=true) |
| ![Whatsapp](media/Screenshot_20240206_235930.jpeg?raw=true) |-------------------------------------------------------------|

| ![Whatsapp](media/Screenshot_20240207_000018_Android%20System.jpeg?raw=true) | ![Whatsapp](media/Screenshot_20240206_235958_Android%20System.jpeg?raw=true) |

| ![Whatsapp](media/corver.jpg?raw=true)


#### :bug: flutter file(image/video) not working with android ACTION_OPEN_DOCUMENT_TREE but works fine in kotlin

```dart
// android/ap/src/main/kotlin/*/MainActivity.kt
// assuming you've configure your channel 
// taking image from file will result error `permission denied`
// filePath will be inside /storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/
Image.file(File(filePath,fit: BoxFit.contain,))

Error: accessing /storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/ Permission Denied
```