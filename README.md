# Whatsapp Status Saver

## To-Do
   1. Use stream instead of updating full widget
   2. recently view
   2. recently post
   3. image byte return
   4. delete, repost, share
   5. query already saved

## :bug: flutter file(image/video) not working with android ACTION_OPEN_DOCUMENT_TREE but works fine in kotlin

```dart
// android/ap/src/main/kotlin/*/MainActivity.kt
// assuming you've configure your channel 
// taking image from file will result error `permission denied`
// filePath will be inside /storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/
Image.file(File(filePath,fit: BoxFit.contain,))

Error: accessing /storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/ Permission Denied
```