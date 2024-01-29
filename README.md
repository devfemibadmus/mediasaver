# whatsappstatus

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## :bug: flutter file(image/video) not working with android ACTION_OPEN_DOCUMENT_TREE but works fine in kotlin

### Kotlin code

```kotlin
private val PICK_DIRECTORY_REQUEST_CODE = 123
private var STATUS_DIRECTORY: DocumentFile? = null
private var BASE_DIRECTORY: Uri = Uri.parse("/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/")


private fun requestSpecificFolderAccess(): Boolean {
    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
    intent.putExtra(DocumentsContract.EXTRA_INITIAL_URI, BASE_DIRECTORY)
    startActivityForResult(intent, PICK_DIRECTORY_REQUEST_CODE)
    return true
}

override fun onActivityResult(requestCode: Int, resultCode: Int, resultData: Intent?) {
    super.onActivityResult(requestCode, resultCode, resultData)
    if (requestCode == PICK_DIRECTORY_REQUEST_CODE && resultCode == Activity.RESULT_OK) {
        val treeUri: Uri? = resultData?.data
        treeUri?.let {
            // Take persistable URI permission
            contentResolver.takePersistableUriPermission(
                it,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            )
            // Append .Statuses to the existing URI
            STATUS_DIRECTORY = DocumentFile.fromTreeUri(this, Uri.withAppendedPath(it, ".Statuses"))
        }
    }
}

private fun getStatusFilesInfo(): List<Map<String, Any>> {
    val statusFilesInfo = mutableListOf<Map<String, Any>>()

    STATUS_DIRECTORY?.let { rootDirectory ->
        rootDirectory.listFiles()?.forEach { file ->
            if (file.isFile && file.canRead()) {
                val fileInfo = mutableMapOf<String, Any>()
                fileInfo["name"] = file.name ?: "DefaultName"
                fileInfo["path"] = file.absolutePath
                fileInfo["size"] = file.length()
                fileInfo["format"] = getFileFormat(file.name ?: "DefaultName")
                statusFilesInfo.add(fileInfo)
            } else {
                val fileInfo = mutableMapOf<String, Any>()
                fileInfo["name"] = "DefaultName"
                fileInfo["path"] = "DefaultPath"
                fileInfo["size"] = 0L
                fileInfo["format"] = "DefaultFormat"
                statusFilesInfo.add(fileInfo)
            }
        }
    }

    return statusFilesInfo
}

private fun getAbsolutePath(rootDirectory: DocumentFile, file: DocumentFile): String {
    val pathSegments = mutableListOf(file.name ?: "DefaultName")
    var parent = file.getParentFile()

    while (parent != null && parent != rootDirectory) {
        pathSegments.add(parent.name ?: "DefaultName")
        parent = parent.getParentFile()
    }

    return pathSegments.reversed().joinToString("/")
}

```

### Flutter code

```dart
// assuming you've configure your channel 
// taking image from file will result error `permission denied`
// filePath will be inside /storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/
Image.file(File(filePath,fit: BoxFit.contain,))

Error: accessing /storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/ Permission Denied
```