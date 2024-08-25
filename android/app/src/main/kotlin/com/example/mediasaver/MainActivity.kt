package com.blackstackhub.mediasaver

import java.net.URL
import java.io.File
import android.net.Uri
import android.util.Log
import android.os.Bundle
import java.io.IOException
import android.widget.Toast
import android.app.Activity
import android.content.Intent
import android.content.Context
import java.io.FileOutputStream
import kotlinx.coroutines.launch
import java.net.HttpURLConnection
import android.webkit.MimeTypeMap
import android.provider.MediaStore
import java.io.BufferedInputStream
import androidx.annotation.NonNull
import android.content.ContentValues
import kotlinx.coroutines.Dispatchers
import android.content.ContentResolver
import kotlinx.coroutines.CoroutineScope
import android.provider.DocumentsContract
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity




class MainActivity : FlutterActivity() {
    private val TAG = "MainActivity"
    private val REQUEST_CODE_MEDIA = 1001
    private val CHANNEL = "com.blackstackhub.mediasaver"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveMedia" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        result.success(saveMedia(filePath))
                    } else {
                        result.error("INVALID_PARAMETERS", "Invalid parameters", null)
                    }
                }
                "getMedias" -> {
                    val appType = call.argument<String>("appType")
                    if (appType != null) {
                        result.success(getMedias(appType))
                    } else {
                        result.error("INVALID_PARAMETERS", "Invalid parameters", null)
                    }
                }
                "launchurl" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        CoroutineScope(Dispatchers.Main).launch {
                            result.success(launchurl(url))
                        }
                    } else {
                        result.error("INVALID_PARAMETERS", "Invalid parameters", null)
                    }
                }
                "shareMedia" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        result.success(shareMedia(filePath))
                    } else {
                        result.error("INVALID_PARAMETERS", "Invalid parameters", null)
                    }
                }
                "deleteMedia" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        result.success(deleteMedia(filePath))
                    } else {
                        result.error("INVALID_PARAMETERS", "Invalid parameters", null)
                    }
                }
                "downloadAndSaveFile" -> {
                    val fileId = call.argument<String>("fileId")
                    val fileUrl = call.argument<String>("fileUrl")
                    if (fileId != null && fileUrl != null) {
                        result.success(downloadAndSaveFile(fileId, fileUrl))
                    } else {
                        result.error("INVALID_PARAMETERS", "Invalid parameters", null)
                    }
                }
                "requestAccessToFolder" -> {
                    requestAccessToFolder()
                    result.success(null)
                }

                "copyText" -> result.success(copyText())
                "shareApp" -> result.success(shareApp())
                "sendEmail" -> result.success(sendEmail())
                "hasFolderAccess" -> result.success(hasFolderAccess())
                else -> result.notImplemented()
            }
        }
    }

    // SAVE, GET, SHARE, DELETE, DOWNLOAD MEDIA
    private fun saveMedia(filePath: String): String {
        // Define the destination directory in app's internal storage
        val appDir = File(context.filesDir, "Media Saver")
        if (!appDir.exists()) {
            appDir.mkdirs()
        }

        // Determine the display name from the file path
        val sourceFile = File(filePath)
        val displayName = sourceFile.name
        val mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(sourceFile.extension) ?: "application/octet-stream"

        // Create a destination file
        val destFile = File(appDir, displayName)

        // Copy the file to the app directory
        sourceFile.copyTo(destFile, overwrite = true)

        // Add the file to the MediaStore to make it visible in the gallery
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, displayName)
            put(MediaStore.Images.Media.MIME_TYPE, mimeType)
            put(MediaStore.Images.Media.DATA, destFile.absolutePath) // Path to the file
            put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/Media Saver") // Custom directory in gallery
        }

        val uri = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
        if (uri != null) {
            Log.d("Gallery", "File added to gallery: $uri")
        } else {
            Log.d("Gallery", "Failed to add file to gallery")
        }
        return "Saved to Gallery successfully"
    }

    private fun shareMedia(filePath: String): String {
        val file = File(filePath)
        if (file.exists()) {
            val uri = FileProvider.getUriForFile(context, "${BuildConfig.APPLICATION_ID}.fileprovider", file)
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = MimeTypeMap.getSingleton().getMimeTypeFromExtension(file.extension) ?: "application/octet-stream"
                putExtra(Intent.EXTRA_STREAM, uri)
                putExtra(Intent.EXTRA_SUBJECT, "Shared via Media Saver")
                putExtra(Intent.EXTRA_TEXT, "Shared with Media Saver—no cost, no ads!")
            }
            val shareIntent = Intent.createChooser(intent, null)
            shareIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            context.startActivity(shareIntent)
            return "Sharing..."
        } else {
            Log.d("ShareMedia", "File does not exist.")
            return "File does not exist."
        }
    }
    
    private fun deleteMedia(filePath: String): String {
        val file = File(filePath)
        if (file.exists()) {
            val deleted = file.delete()
            if (deleted) {
                // Remove the file from MediaStore
                val uri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                val selection = "${MediaStore.Images.Media.DATA} = ?"
                val selectionArgs = arrayOf(filePath)
                val rowsDeleted = contentResolver.delete(uri, selection, selectionArgs)
                
                return if (rowsDeleted > 0) {
                    "File deleted successfully."
                } else {
                    "File not found in MediaStore."
                }
            } else {
                return "Failed to delete file."
            }
        } else {
            return "File does not exist."
        }
    }

    private fun getMedias(appType: String, refresh: Boolean): List<Map<String, String>> {
        Log.d("appType", appType)

        val fileInfoList = mutableListOf<Map<String, String>>()

        when (appType) {
            "SAVED" -> {
                // List and render files from the app's internal directory
                val internalDir = File(context.filesDir, "Media Saver")
                if (internalDir.exists()) {
                    internalDir.listFiles()?.forEach { file ->
                        val mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(file.extension) ?: "application/octet-stream"
                        val url = "file://${file.absolutePath}"
                        fileInfoList.add(mapOf("url" to url, "mimeType" to mimeType))
                    }
                }
            }
            "WHATSAPP", "WHATSAPP4B" -> {
                val internalDir = File(context.filesDir, if (appType == "WHATSAPP") "whatsapp" else "whatsapp4b")

                if (refresh) {
                    // Clear the existing directory if refresh is true
                    if (internalDir.exists()) {
                        internalDir.listFiles()?.forEach { it.delete() }
                    } else {
                        internalDir.mkdirs()
                    }

                    val docUri = if (appType == "WHATSAPP") {
                        Uri.parse("content://com.android.externalstorage.documents/tree/primary%3AAndroid%2Fmedia/document/primary%3AAndroid%2Fmedia%2Fcom.whatsapp%2FWhatsApp%2FMedia%2F.Statuses/children")
                    } else {
                        Uri.parse("content://com.android.externalstorage.documents/tree/primary%3AAndroid%2Fmedia/document/primary%3AAndroid%2Fmedia%2Fcom.whatsapp.w4b%2FWhatsApp%20Business%2FMedia%2F.Statuses/children")
                    }

                    val projection = arrayOf(
                        DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                        DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                        DocumentsContract.Document.COLUMN_MIME_TYPE
                    )
                    val validDocUri = docUri ?: return fileInfoList
                    val cursor = contentResolver.query(validDocUri, projection, null, null, null)
                    cursor?.use { cursorInstance ->
                        while (cursorInstance.moveToNext()) {
                            val documentId = cursorInstance.getString(cursorInstance.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID))
                            val displayName = cursorInstance.getString(cursorInstance.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME))
                            val mimeType = cursorInstance.getString(cursorInstance.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_MIME_TYPE)) ?: "application/octet-stream"
                            val documentUri = DocumentsContract.buildDocumentUriUsingTree(validDocUri, documentId)

                            val inputStream = contentResolver.openInputStream(documentUri)
                            val destFile = File(internalDir, displayName)
                            inputStream?.use { input ->
                                destFile.outputStream().use { output ->
                                    input.copyTo(output)
                                }
                            }

                            val url = "file://${destFile.absolutePath}"
                            fileInfoList.add(mapOf("url" to url, "mimeType" to mimeType))
                        }
                    }
                } else {
                    // Just list existing files in the app directory
                    if (internalDir.exists()) {
                        internalDir.listFiles()?.forEach { file ->
                            val mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(file.extension) ?: "application/octet-stream"
                            val url = "file://${file.absolutePath}"
                            fileInfoList.add(mapOf("url" to url, "mimeType" to mimeType))
                        }
                    }
                }
            }
            else -> Log.d("FileQuery", "Invalid app type.")
        }

        return fileInfoList
    }

    private fun downloadAndSaveFile(fileUrl: String, fileId: String): String {
        val appDir = File(context.filesDir, "Media Saver")
        if (!appDir.exists()) {
            appDir.mkdirs()
        }

        // Extract file name from URL and check if a file with the same name exists
        val fileName = fileUrl.substring(fileUrl.lastIndexOf('/') + 1)
        val fileNameWithoutExt = fileName.substringBeforeLast('.')
        val existingFiles = appDir.listFiles { _, name -> name.substringBeforeLast('.').equals(fileId, ignoreCase = true) }

        if (existingFiles.isNullOrEmpty()) {
            // Download the file
            val urlConnection: HttpURLConnection
            try {
                val url = URL(fileUrl)
                urlConnection = url.openConnection() as HttpURLConnection
                urlConnection.connect()

                val inputStream = BufferedInputStream(urlConnection.inputStream)
                val destFile = File(appDir, fileName)

                FileOutputStream(destFile).use { outputStream ->
                    val buffer = ByteArray(1024)
                    var count: Int
                    while (inputStream.read(buffer).also { count = it } != -1) {
                        outputStream.write(buffer, 0, count)
                    }
                }

                inputStream.close()
                urlConnection.disconnect()

                // Add the file to MediaStore
                val mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(destFile.extension) ?: "application/octet-stream"
                val values = ContentValues().apply {
                    put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
                    put(MediaStore.Images.Media.MIME_TYPE, mimeType)
                    put(MediaStore.Images.Media.DATA, destFile.absolutePath)
                    put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/Media Saver")
                }

                val uri = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                if (uri != null) {
                    Log.d("Gallery", "File added to gallery: $uri")
                } else {
                    Log.d("Gallery", "Failed to add file to gallery")
                }

                return destFile.absolutePath
            } catch (e: IOException) {
                Log.e("Download", "Error downloading file: ${e.message}")
                return "Error downloading file"
            }
        } else {
            return "File already exists"
        }
    }

    // PERMISSION HANDLING

    public fun hasPermission(): Boolean {
        Uri uri = Uri.parse("content://com.android.externalstorage.documents/tree/primary%3AAndroid%2Fmedia");
        try {
            ContentResolver resolver = context.getContentResolver();
            resolver.query(uri, null, null, null, null);
            return true; // Access is granted
        } catch (SecurityException e) {
            return false; // Permission is not granted
        }
    }

    private fun requestAccessToFolder() {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
        startActivityForResult(intent, REQUEST_CODE_MEDIA)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (resultCode == Activity.RESULT_OK) {
            val uri = data?.data ?: return
            Log.d("uri", " $uri")
            if(requestCode == REQUEST_CODE_MEDIA){
                if(uri.toString() != "content://com.android.externalstorage.documents/tree/primary%3AAndroid%2Fmedia"){
                    Toast.makeText(applicationContext, "Please select the Media folder", Toast.LENGTH_SHORT).show()
                    requestAccessToFolder()
                }
            }
        }
    }


    // OTHERS

    private fun copyText(): String{
        val clipboardManager = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        if (clipboardManager.hasPrimaryClip()) {
            val clipData: ClipData? = clipboardManager.primaryClip
            if (clipData != null && clipData.itemCount > 0) {
                val item = clipData.getItemAt(0)
                return item.text.toString()
            }
        }
        return ""
    }

    private fun shareApp(): Boolean{
        // Share intent
        val shareIntent = Intent(Intent.ACTION_SEND)
        shareIntent.type = "text/plain"
    
        // Set the subject and message
        val shareSubject = "Check out this free Media Saver"
        val shareMessage = "$shareSubject\n\nNo Ads, No Cost—Download Videos and Photos From Instagram, Facebook, and TikTok for Free!\n\nGet the app: https://play.google.com/store/apps/details?id=com.blackstackhub.mediasaver"
    
        // shareIntent.putExtra(Intent.EXTRA_SUBJECT, shareSubject)
        shareIntent.putExtra(Intent.EXTRA_TEXT, shareMessage)

        try {
            startActivity(Intent.createChooser(shareIntent, "Share via"))
        } catch (e: Exception) {
            // Handle exceptions
            // e.printStackTrace()
            // You might want to return an error message or handle it differently
        }
        return true
    }

    private fun sendEmail(): Boolean{
        val emailIntent = Intent(Intent.ACTION_SENDTO)

        val packageInfo = applicationContext.packageManager.getPackageInfo(context.packageName, 0)
        val appVersion = packageInfo.versionName

        val locale = Locale.getDefault()
        val country = locale.displayCountry

        val email = "devfemibadmus@gmail.com"
        val subject = "Request a new feature for Media-Saver"
        
        val preBody = "Version: ${appVersion}\nCountry: $country\n\nI want to request feature for..."
        val mailtoLink = "mailto:$email?subject=$subject&body=$preBody"

        // Set the email address
        emailIntent.data = Uri.parse(mailtoLink)

        // Check if there is a package that can handle the intent
        try {
            startActivity(emailIntent)
        } catch (e: Exception) {
            // If no email app is available, open a web browser
            val webIntent = Intent(Intent.ACTION_VIEW)
            webIntent.data = Uri.parse("https://github.com/devfemibadmus/Media-Saver")
            startActivity(webIntent)
        }
        return true
    }

    private fun launchurl(url: String): Boolean{
        val webIntent = Intent(Intent.ACTION_VIEW)
        webIntent.data = Uri.parse(url)
        startActivity(webIntent)
        return true
    }
}

