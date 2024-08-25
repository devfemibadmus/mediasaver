package com.blackstackhub.mediasaver

import java.net.URL
import java.io.File
import android.net.Uri
import android.util.Log
import java.util.Locale
import android.os.Bundle
import java.io.IOException
import android.widget.Toast
import android.app.Activity
import android.content.Intent
import android.content.Context
import android.content.ClipData
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
import android.content.ClipboardManager
import kotlinx.coroutines.CoroutineScope
import android.provider.DocumentsContract
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
                    val fileUri = call.argument<String>("fileUri")
                    if (fileUri != null) {
                        result.success(saveMedia(fileUri))
                    } else {
                        result.error("INVALID_PARAMETERS", "Invalid parameters", null)
                    }
                }
                "getMedias" -> {
                    val appType = call.argument<String>("appType")
                    if (appType != null) {
                        result.success(getMedias(appType, refresh))
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
                    val fileUri = call.argument<String>("fileUri")
                    if (fileUri != null) {
                        result.success(shareMedia(fileUri))
                    } else {
                        result.error("INVALID_PARAMETERS", "Invalid parameters", null)
                    }
                }
                "deleteMedia" -> {
                    val fileUri = call.argument<String>("fileUri")
                    if (fileUri != null) {
                        result.success(deleteMedia(fileUri))
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
                "requestAccessToMedia" -> {
                    requestAccessToMedia()
                    result.success(null)
                }

                "copyText" -> result.success(copyText())
                "shareApp" -> result.success(shareApp())
                "sendEmail" -> result.success(sendEmail())
                "hasPermission" -> result.success(hasPermission())
                else -> result.notImplemented()
            }
        }
    }


    // SAVE, GET, SHARE, DELETE, DOWNLOAD MEDIA
    private fun saveMedia(fileUri: String): String {
        val resolver = context.contentResolver

        val fileName = Uri.parse(fileUri).lastPathSegment ?: "unknown_file"
        val mimeType = resolver.getType(Uri.parse(fileUri)) ?: "application/octet-stream"

        val contentValues = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
            put(MediaStore.Images.Media.MIME_TYPE, mimeType)
            put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/Media Saver")
        }

        val newUri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues)
        if (newUri == null) return "Failed to save file"

        val inputStream = resolver.openInputStream(Uri.parse(fileUri)) ?: return "Unable to open input stream"
        val outputStream = resolver.openOutputStream(newUri) ?: return "Unable to open output stream"

        try {
            inputStream.copyTo(outputStream)
        } catch (e: Exception) {
            return "Error copying file: ${e.message}"
        } finally {
            inputStream.close()
            outputStream.close()
        }

        return "Saved to Gallery successfully"
    }

    private fun shareMedia(fileUri: String): String {
        try {
            val mimeType = context.contentResolver.getType(Uri.parse(fileUri)) ?: "application/octet-stream"
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = mimeType
                putExtra(Intent.EXTRA_STREAM, Uri.parse(fileUri))
                putExtra(Intent.EXTRA_SUBJECT, "Shared via Media Saver")
                putExtra(Intent.EXTRA_TEXT, "Shared with Media Saver—no cost, no ads!")
            }
            val shareIntent = Intent.createChooser(intent, null)
            shareIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            context.startActivity(shareIntent)
            return "Sharing..."
        } catch (e: Exception) {
            Log.e("ShareMedia", "Error sharing media: ${e.message}")
            return "Error sharing media."
        }
    }
    
    private fun deleteMedia(fileUri: String): String {
        val rowsDeleted = context.contentResolver.delete(Uri.parse(fileUri), null, null)
        
        return if (rowsDeleted > 0) {
            "File deleted successfully."
        } else {
            "File not found in MediaStore or failed to delete."
        }
    }

    private fun getMedias(appType: String): List<Map<String, String>> {
        Log.d("appType", appType)

        val fileInfoList = mutableListOf<Map<String, String>>()

        when (appType) {
            "SAVED" -> {
                val uri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                val projection = arrayOf(
                    MediaStore.Images.Media._ID,
                    MediaStore.Images.Media.DISPLAY_NAME,
                    MediaStore.Images.Media.MIME_TYPE,
                    MediaStore.Images.Media.DATA
                )
                val selection = "${MediaStore.Images.Media.DATA} LIKE ?"
                val selectionArgs = arrayOf("Pictures/Media Saver/%")

                val cursor = contentResolver.query(uri, projection, selection, selectionArgs, null)
                cursor?.use { cursorInstance ->
                    while (cursorInstance.moveToNext()) {
                        val id = cursorInstance.getLong(cursorInstance.getColumnIndexOrThrow(MediaStore.Images.Media._ID))
                        val displayName = cursorInstance.getString(cursorInstance.getColumnIndexOrThrow(MediaStore.Images.Media.DISPLAY_NAME))
                        val mimeType = cursorInstance.getString(cursorInstance.getColumnIndexOrThrow(MediaStore.Images.Media.MIME_TYPE)) ?: "application/octet-stream"
                        val contentUri = ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id)
                        fileInfoList.add(mapOf("filePath" to contentUri.toString(), "mimeType" to mimeType))
                    }
                }
            }
            "WHATSAPP", "WHATSAPP4B" -> {
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
                        fileInfoList.add(mapOf("filePath" to documentUri.toString(), "mimeType" to mimeType))
                    }
                }
            }
            else -> Log.d("FileQuery", "Invalid app type.")
        }

        return fileInfoList
    }

    private fun downloadAndSaveFile(fileUrl: String, fileId: String): String {
        val fileName = fileUrl.substring(fileUrl.lastIndexOf('/') + 1)
        
        val projection = arrayOf(MediaStore.Images.Media._ID)
        val selection = "${MediaStore.Images.Media.DISPLAY_NAME} = ?"
        val selectionArgs = arrayOf(fileName)
        val cursor = contentResolver.query(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            projection,
            selection,
            selectionArgs,
            null
        )
        
        cursor?.use {
            if (it.moveToFirst()) {
                return "File already exists in MediaStore"
            }
        }

        val mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(fileName.substringAfterLast('.')) ?: "application/octet-stream"
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
            put(MediaStore.Images.Media.MIME_TYPE, mimeType)
            put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/Media Saver")
        }

        val uri = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values) ?: return "Failed to add file to MediaStore"

        try {
            val outputStream = contentResolver.openOutputStream(uri) ?: return "Failed to open output stream"
            val urlConnection: HttpURLConnection = URL(fileUrl).openConnection() as HttpURLConnection
            
            try {
                urlConnection.connect()
                val inputStream = BufferedInputStream(urlConnection.inputStream)
                outputStream.use { output ->
                    val buffer = ByteArray(1024)
                    var count: Int
                    while (inputStream.read(buffer).also { count = it } != -1) {
                        output.write(buffer, 0, count)
                    }
                }
                
                inputStream.close()
            } catch (e: IOException) {
                Log.e("Download", "IO error during download: ${e.message}")
                return "Error downloading file: ${e.message}"
            } finally {
                urlConnection.disconnect()
            }

            return "File downloaded and saved successfully."
        } catch (e: IOException) {
            Log.e("Download", "Error opening output stream: ${e.message}")
            return "Error opening output stream: ${e.message}"
        } catch (e: Exception) {
            Log.e("Download", "Unexpected error: ${e.message}")
            return "Unexpected error: ${e.message}"
        }
    }


    // PERMISSION HANDLING

    private fun hasPermission(): Boolean {
        val documentFile = DocumentFile.fromTreeUri(context, Uri.parse("content://com.android.externalstorage.documents/tree/primary%3AAndroid%2Fmedia"))
        return documentFile?.exists() == true
    }

    private fun requestAccessToMedia() {
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
                    requestAccessToMedia()
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

