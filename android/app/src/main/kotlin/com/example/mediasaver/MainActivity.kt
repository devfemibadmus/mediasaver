package com.blackstackhub.mediasaver

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileFilter

import android.graphics.BitmapFactory

import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import java.io.ByteArrayOutputStream

import androidx.core.content.FileProvider
import android.webkit.MimeTypeMap

import kotlinx.coroutines.GlobalScope

import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

import android.content.Context
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

import java.io.IOException
import java.io.FileInputStream
import java.io.FileOutputStream
import io.flutter.plugin.common.PluginRegistry.Registrar

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

import android.content.ClipData
import android.content.ClipboardManager


import kotlinx.coroutines.CoroutineScope
import java.util.concurrent.TimeUnit
import okhttp3.OkHttpClient
import okhttp3.Request


import android.content.ContentUris
import android.content.ContentValues
import android.content.res.Resources
import android.provider.MediaStore

import java.io.InputStream
import java.io.OutputStream
import java.net.URL

import okhttp3.Response
import android.content.ContentResolver

import android.content.SharedPreferences
import android.widget.Toast

import fi.iki.elonen.NanoHTTPD
import java.net.BindException
import java.util.concurrent.Executors

import android.provider.DocumentsContract
import android.app.Activity

import android.database.Cursor

import androidx.documentfile.provider.DocumentFile

import java.io.ByteArrayInputStream

import android.media.ThumbnailUtils





object Common {
    private const val PREFS_NAME = "ServerPrefs"
    private const val KEY_SERVER_PORT = "server_port"
    private const val KEY_PERMISSION = "folder_access"
    private const val KEY_SERVER_RUNNING = "server_running"

    const val REQUEST_CODE_WHATSAPP_FOLDER = 1001
    
    private const val PORT = 8080
    private var server: NanoHTTPD? = null

    // Function to get the SharedPreferences instance
    private fun getSharedPreferences(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    // Permission border
    fun updatePermission(isPermit: Boolean, context: Context) {
        val prefs = getSharedPreferences(context)
        prefs.edit().putBoolean(KEY_PERMISSION, isPermit).apply()
    }
    fun hasPermission(context: Context): Boolean {
        val prefs = getSharedPreferences(context)
        return prefs.getBoolean(KEY_PERMISSION, false)
    }

    // Function to save Server State
    fun saveServerState(isRunning: Boolean, context: Context) {
        val prefs = getSharedPreferences(context)
        prefs.edit().putBoolean(KEY_SERVER_RUNNING, isRunning).apply()
    }
    // Function to load Server State
    fun loadServerState(context: Context): Boolean {
        val prefs = getSharedPreferences(context)
        return prefs.getBoolean(KEY_SERVER_RUNNING, false)
    }

    // Function to start the server
    fun startServer(context: Context): String {
        return try {
            val server = object : NanoHTTPD(PORT) {
                override fun serve(session: IHTTPSession?): Response {
                    val uriString = session?.uri?.removePrefix("/files/")

                    return try {
                        if (uriString != null) {
                            if (uriString.contains("Android/media/")) {
                                val mainUrl = uriString.split("/getThumbnail").first()
                                val pathSegments = mainUrl.split("Android/media/").last().split("/")

                                val getThumbnail = uriString.contains("/getThumbnail")

                                // Root folder where permission is granted
                                val treeUri = Uri.parse("content://com.android.externalstorage.documents/tree/primary%3AAndroid%2Fmedia")
                                val documentFile = DocumentFile.fromTreeUri(context, treeUri)

                                // Navigate through subdirectories
                                var currentDir: DocumentFile? = documentFile
                                for (segment in pathSegments.dropLast(1)) {
                                    currentDir = currentDir?.findFile(segment)
                                    if (currentDir == null || !currentDir.isDirectory) {
                                        return newFixedLengthResponse(Response.Status.NOT_FOUND, "text/plain", "Directory not found")
                                    }
                                }

                                // Find the target file
                                val targetFile = currentDir?.findFile(pathSegments.last())
                                if (targetFile != null && targetFile.isFile) {
                                    // Open the input stream and return the file content
                                    val inputStream = context.contentResolver.openInputStream(targetFile.uri)
                                    val mimeType = context.contentResolver.getType(targetFile.uri) ?: "application/octet-stream"

                                    if (getThumbnail) {
                                        Log.d("targetFile.uri.toString()", targetFile.uri.toString())
                                        val retriever = MediaMetadataRetriever()
                                        try {
                                            retriever.setDataSource(context, targetFile.uri)
                                            val bitmap = retriever.getFrameAtTime(0, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
                                            if (bitmap != null) {
                                                val outputStream = ByteArrayOutputStream()
                                                bitmap.compress(Bitmap.CompressFormat.JPEG, 90, outputStream)
                                                val imageData = outputStream.toByteArray()
                                                return newFixedLengthResponse(Response.Status.OK, "image/jpeg", ByteArrayInputStream(imageData), imageData.size.toLong())
                                            } else {
                                                return newFixedLengthResponse(Response.Status.NOT_FOUND, "text/plain", "Thumbnail not available")
                                            }
                                        } catch (e: Exception) {
                                            return newFixedLengthResponse(Response.Status.NOT_FOUND, "text/plain", "Error retrieving thumbnail: ${e.message}")
                                        } finally {
                                            retriever.release()
                                        }
                                    }

                                    if (inputStream != null) {
                                        val length = inputStream.available().toLong()
                                        return newFixedLengthResponse(Response.Status.OK, mimeType, inputStream, length)
                                    } else {
                                        return newFixedLengthResponse(Response.Status.NOT_FOUND, "text/plain", "File not found")
                                    }
                                } else {
                                    return newFixedLengthResponse(Response.Status.NOT_FOUND, "text/plain", "File not found")
                                }

                            } else {
                                // This is a MediaStore ID (SAVED case)
                                val fileId = uriString.toLongOrNull()

                                if (fileId != null) {
                                    // Query the file using the ID
                                    val contentResolver = context.contentResolver
                                    val uri = ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, fileId)
                                    val mimeType = contentResolver.getType(uri) ?: "application/octet-stream"
                                    val inputStream = contentResolver.openInputStream(uri)

                                    if (inputStream != null) {
                                        val length = inputStream.available().toLong()
                                        return newFixedLengthResponse(Response.Status.OK, mimeType, inputStream, length)
                                    } else {
                                        return newFixedLengthResponse(Response.Status.NOT_FOUND, "text/plain", "File not found")
                                    }
                                } else {
                                    return newFixedLengthResponse(Response.Status.BAD_REQUEST, "text/plain", "Invalid file ID")
                                }
                            }
                        } else {
                            return newFixedLengthResponse(Response.Status.BAD_REQUEST, "text/plain", "Invalid request")
                        }
                    } catch (e: IOException) {
                        return newFixedLengthResponse(Response.Status.INTERNAL_ERROR, "text/plain", "I/O error: ${e.message}")
                    }
                }
            }

            // Start the server
            server.start(NanoHTTPD.SOCKET_READ_TIMEOUT, false)
            // Save server state
            saveServerState(true, context)

            "Server started successfully on port $PORT"
        } catch (e: BindException) {
            // Handle the case where the port is already in use
            "Error: Port $PORT is already in use. Please try another port."
        } catch (e: SecurityException) {
            // Handle the case where the server doesn't have permission to bind to the port
            "Error: Insufficient permissions to start the server on port $PORT."
        } catch (e: IOException) {
            // Handle general I/O errors during server startup
            "Error: Failed to start the server due to an I/O error: ${e.message}"
        } catch (e: Exception) {
            // Catch any unexpected errors
            "Error: Unexpected error while starting the server: ${e.message}"
        }
    }

    // Function to stop Server State
    fun stopServer(context: Context): String {
        return try {
            // Check if the server is running before stopping it
            if (loadServerState(context)) {
                server?.stop()
                server = null

                // Save server state
                saveServerState(false, context)

                "Server stopped successfully."
            } else {
                "Server is not running."
            }
        } catch (e: Exception) {
            "Error: Failed to stop the server: ${e.message}"
        }
    }

    // cursor Query for media folder
    fun savedMediasQuery(contentResolver: ContentResolver): Cursor? {
        val folderPath = "Pictures/Media Saver"
        val mediaStoreUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI

        // Check if the folder exists
        val projection = arrayOf(MediaStore.Images.Media._ID)
        val selection = "${MediaStore.Images.Media.RELATIVE_PATH} LIKE ?"
        val selectionArgs = arrayOf("$folderPath%")

        var folderExists = false
        contentResolver.query(mediaStoreUri, projection, selection, selectionArgs, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                folderExists = true
            }
        }

        // Query for files in the folder
        return contentResolver.query(
            mediaStoreUri,
            arrayOf(MediaStore.Images.Media._ID, MediaStore.Images.Media.DISPLAY_NAME),
            selection,
            selectionArgs,
            null
        )
    }

    fun whatsappMediaQuery(contentResolver: ContentResolver): Uri? {
        val treeUri = Uri.parse("content://com.android.externalstorage.documents/tree/primary%3AAndroid%2Fmedia")
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, DocumentsContract.getTreeDocumentId(treeUri))

        // Fetch child directories under "media"
        val projection = arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID, DocumentsContract.Document.COLUMN_DISPLAY_NAME)
        val cursor = contentResolver.query(childrenUri, projection, null, null, null)

        cursor?.use {
            while (cursor.moveToNext()) {
                val displayName = cursor.getString(cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME))
                if (displayName == "com.whatsapp") {
                    // Once we find "com.whatsapp.w4b", build the Uri for its children
                    val documentId = cursor.getString(cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID))
                    val whatsappChildrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, documentId)

                    // Now go deeper to find "WhatsApp Business" -> "Media" -> ".Statuses"
                    val innerCursor = contentResolver.query(whatsappChildrenUri, projection, null, null, null)
                    innerCursor?.use {
                        while (innerCursor.moveToNext()) {
                            val innerDisplayName = innerCursor.getString(innerCursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME))
                            if (innerDisplayName == "WhatsApp") {
                                val innerDocumentId = innerCursor.getString(innerCursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID))
                                val whatsappBusinessChildrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, innerDocumentId)

                                // Enter the "Media" folder
                                val mediaCursor = contentResolver.query(whatsappBusinessChildrenUri, projection, null, null, null)
                                mediaCursor?.use {
                                    while (mediaCursor.moveToNext()) {
                                        val mediaDisplayName = mediaCursor.getString(mediaCursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME))
                                        if (mediaDisplayName == "Media") {
                                            val mediaDocumentId = mediaCursor.getString(mediaCursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID))
                                            val mediaChildrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, mediaDocumentId)

                                            // Finally, go into the ".Statuses" folder
                                            val statusesCursor = contentResolver.query(mediaChildrenUri, projection, null, null, null)
                                            statusesCursor?.use {
                                                while (statusesCursor.moveToNext()) {
                                                    val statusesDisplayName = statusesCursor.getString(statusesCursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME))
                                                    if (statusesDisplayName == ".Statuses") {
                                                        // Return the Uri for the .Statuses directory
                                                        val statusesDocumentId = statusesCursor.getString(statusesCursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID))
                                                        return DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, statusesDocumentId)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return null
    }

    fun whatsappBusinessMediaQuery(contentResolver: ContentResolver): Uri? {
        val treeUri = Uri.parse("content://com.android.externalstorage.documents/tree/primary%3AAndroid%2Fmedia")
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, DocumentsContract.getTreeDocumentId(treeUri))

        // Fetch child directories under "media"
        val projection = arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID, DocumentsContract.Document.COLUMN_DISPLAY_NAME)
        val cursor = contentResolver.query(childrenUri, projection, null, null, null)

        cursor?.use {
            while (cursor.moveToNext()) {
                val displayName = cursor.getString(cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME))
                if (displayName == "com.whatsapp.w4b") {
                    // Once we find "com.whatsapp.w4b", build the Uri for its children
                    val documentId = cursor.getString(cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID))
                    val whatsappChildrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, documentId)

                    // Now go deeper to find "WhatsApp Business" -> "Media" -> ".Statuses"
                    val innerCursor = contentResolver.query(whatsappChildrenUri, projection, null, null, null)
                    innerCursor?.use {
                        while (innerCursor.moveToNext()) {
                            val innerDisplayName = innerCursor.getString(innerCursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME))
                            if (innerDisplayName == "WhatsApp Business") {
                                val innerDocumentId = innerCursor.getString(innerCursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID))
                                val whatsappBusinessChildrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, innerDocumentId)

                                // Enter the "Media" folder
                                val mediaCursor = contentResolver.query(whatsappBusinessChildrenUri, projection, null, null, null)
                                mediaCursor?.use {
                                    while (mediaCursor.moveToNext()) {
                                        val mediaDisplayName = mediaCursor.getString(mediaCursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME))
                                        if (mediaDisplayName == "Media") {
                                            val mediaDocumentId = mediaCursor.getString(mediaCursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID))
                                            val mediaChildrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, mediaDocumentId)

                                            // Finally, go into the ".Statuses" folder
                                            val statusesCursor = contentResolver.query(mediaChildrenUri, projection, null, null, null)
                                            statusesCursor?.use {
                                                while (statusesCursor.moveToNext()) {
                                                    val statusesDisplayName = statusesCursor.getString(statusesCursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME))
                                                    if (statusesDisplayName == ".Statuses") {
                                                        // Return the Uri for the .Statuses directory
                                                        val statusesDocumentId = statusesCursor.getString(statusesCursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID))
                                                        return DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, statusesDocumentId)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return null
    }

}

class MainActivity : FlutterActivity() {
    private val TAG = "MainActivity"
    private val CHANNEL = "com.blackstackhub.mediasaver"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveMedia" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        CoroutineScope(Dispatchers.Main).launch {
                            result.success(saveMedia(url))
                        }
                    } else {
                        result.error("INVALID_PARAMETERS", "Invalid parameters", null)
                    }
                }
                "shareMedia" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        result.success(shareMedia(url))
                    } else {
                        result.error("INVALID_PARAMETERS", "Invalid parameters", null)
                    }
                }
                "deleteMedia" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        result.success(deleteMedia(url))
                    } else {
                        result.error("INVALID_PARAMETERS", "Invalid parameters", null)
                    }
                }
                "getMedias" -> {
                    val appType = call.argument<String>("appType")
                    if (appType != null) {
                        CoroutineScope(Dispatchers.Main).launch {
                            result.success(getMedias(appType))
                        }
                    } else {
                        result.error("INVALID_PARAMETERS", "Invalid parameters", null)
                    }
                }
                "downloadAndSaveFile" -> {
                    val fileUrl = call.argument<String>("fileUrl")
                    if (fileUrl != null) {
                        CoroutineScope(Dispatchers.Main).launch {
                            result.success(downloadAndSaveFile(fileUrl))
                        }
                    } else {
                        result.error("INVALID_PARAMETERS", "Invalid parameters", null)
                    }
                }

                "hasFolderAccess" -> result.success(hasFolderAccess())
                "requestAccessToFolder" -> {
                    CoroutineScope(Dispatchers.Main).launch {
                        requestAccessToFolder()
                        result.success(null)
                    }
                }

                "copyText" -> result.success(copyText())
                "shareApp" -> result.success(shareApp())
                "sendEmail" -> result.success(sendEmail())
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
                else -> result.notImplemented()
            }
        }
    }

    // SAVE, GET, SHARE, DELETE, DOWNLOAD MEDIA
fun saveMedia(url: String): Boolean {
    val theFileName = url.substringAfterLast('/')
    Log.d("MediaSaver", "theFileName: $theFileName")
    val contentResolver = context.contentResolver

    // Base URI for the external storage
    val treeUri = Uri.parse("content://com.android.externalstorage.documents/tree/primary%3AAndroid%2Fmedia")
    val documentId = DocumentsContract.getTreeDocumentId(treeUri)
    val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, documentId)

    // Projection to retrieve document IDs and display names
    val projection = arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID, DocumentsContract.Document.COLUMN_DISPLAY_NAME)

    // Find the ".Statuses" directory
    val sourceUri: Uri?

// Determine the value of the variable based on the condition
sourceUri = if (url.contains("com.whatsapp.w4b")) {
    Uri.parse("content://com.android.externalstorage.documents/tree/primary%3AAndroid%2Fmedia/document/primary%3AAndroid%2Fmedia%2Fcom.whatsapp.w4b%2FWhatsApp%20Business%2FMedia%2F.Statuses/children")
} else {
    Uri.parse("content://com.android.externalstorage.documents/tree/primary%3AAndroid%2Fmedia/document/primary%3AAndroid%2Fmedia%2Fcom.whatsapp%2FWhatsApp%2FMedia%2F.Statuses/children")
}
/*
    val cursor = contentResolver.query(childrenUri, projection, null, null, null)
    cursor?.use { c ->
        while (c.moveToNext()) {
            val displayName = c.getString(c.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME))
            if (displayName == "com.whatsapp") {
                val documentId = c.getString(c.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID))
                val whatsappChildrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, documentId)

                val innerCursor = contentResolver.query(whatsappChildrenUri, projection, null, null, null)
                innerCursor?.use { ic ->
                    while (ic.moveToNext()) {
                        val innerDisplayName = ic.getString(ic.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME))
                        if (innerDisplayName == "WhatsApp") {
                            val innerDocumentId = ic.getString(ic.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID))
                            val whatsappBusinessChildrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, innerDocumentId)

                            val mediaCursor = contentResolver.query(whatsappBusinessChildrenUri, projection, null, null, null)
                            mediaCursor?.use { mc ->
                                while (mc.moveToNext()) {
                                    val mediaDisplayName = mc.getString(mc.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME))
                                    if (mediaDisplayName == "Media") {
                                        val mediaDocumentId = mc.getString(mc.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID))
                                        val mediaChildrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, mediaDocumentId)

                                        val statusesCursor = contentResolver.query(mediaChildrenUri, projection, null, null, null)
                                        statusesCursor?.use { sc ->
                                            while (sc.moveToNext()) {
                                                val statusesDisplayName = sc.getString(sc.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME))
                                                if (statusesDisplayName == ".Statuses") {
                                                    val statusesDocumentId = sc.getString(sc.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID))
                                                    sourceUri = DocumentsContract.buildChildDocumentsUriUsingTree(mediaChildrenUri, statusesDocumentId)
                                                    return@use
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
 */
                 val mediaUri: Uri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
    val projectionName = arrayOf(MediaStore.Images.Media.DISPLAY_NAME)
    val selection = "${MediaStore.Images.Media.DISPLAY_NAME} = ?"
    val selectionArgs = arrayOf("MediaSaver_$theFileName")

    val cursor = contentResolver.query(mediaUri, projectionName, selection, selectionArgs, null)
    val fileExists = cursor?.use { it.count > 0 }
    if (fileExists == true) {
            Log.d("Mediasaver", "File with the name 'MediaSaver_$theFileName' already exists.")
            return false
        }

    Log.d("MdiaSaver", "sourceUri: $sourceUri")



    // Get the first file in the .Statuses directory
    val fileProjection = arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID, DocumentsContract.Document.COLUMN_DISPLAY_NAME)
    val fileCursor = contentResolver.query(sourceUri!!, fileProjection, null, null, null)
    fileCursor?.use { fc ->
        while (fc.moveToNext()) {
        val fileName = fc.getString(fc.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME))

        // Check if the file name matches the desired name
        if (fileName == theFileName) {
            val fileDocumentId = fc.getString(fc.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID))
            val fileUri = DocumentsContract.buildDocumentUriUsingTree(sourceUri, fileDocumentId)
            Log.d("Mediasaver", "$fileName")
            Log.d("Mediasaver", "$fileUri")

            // Target directory and MIME type
            val mimeType = when {
                fileName.endsWith(".mp4", ignoreCase = true) -> "video/mp4"
                fileName.endsWith(".jpg", ignoreCase = true) || fileName.endsWith(".jpeg", ignoreCase = true) -> "image/jpeg"
                fileName.endsWith(".png", ignoreCase = true) -> "image/png"
                else -> throw IllegalArgumentException("Unsupported file type")
            }
            Log.d("Mediasaver", "$mimeType")

            val mediaCollectionUri = when {
                mimeType.startsWith("image/") -> MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                mimeType.startsWith("video/") -> MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                else -> throw IllegalArgumentException("Unsupported MIME type")
            }
            Log.d("Mediasaver", "$mediaCollectionUri")

            // Create the target file in the MediaStore
            val targetFileValues = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, "MediaSaver_$fileName")
                put(MediaStore.MediaColumns.RELATIVE_PATH, "Pictures/Media Saver/")
                put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            }
            Log.d("Mediasaver", "$targetFileValues")

            val targetUri = contentResolver.insert(mediaCollectionUri, targetFileValues)
                ?: throw IOException("Failed to create target file")

            Log.d("Mediasaver", "$targetUri")
            // Copy file content from source to target
            Log.d("Mediasaver", "InputStream wants to start")
            contentResolver.openInputStream(fileUri)?.use { inputStream ->
            Log.d("Mediasaver", "InputStream opened successfully: $inputStream")
                contentResolver.openOutputStream(targetUri)?.use { outputStream ->
                Log.d("Mediasaver", "OutputStream opened successfully: $outputStream")
                    inputStream.copyTo(outputStream)
                    Log.d("Mediasaver", "File copied successfully")
                    return true
                } ?: throw IOException("Failed to open output stream for target file")
            } ?: throw IOException("Failed to open input stream for source file")
        }
        }
    }
    return false
}





private fun shareMedia(url: String): Boolean {
    val contentResolver = applicationContext.contentResolver

    // Check if the URL contains "Android/media" indicating it's not an ID
    return if (url.contains("Android/media")) {
        // Handle URL with DocumentFile traversal
        val uri = Uri.parse(url)
        val pathSegments = uri.pathSegments
        val lastSegment = pathSegments.last()
        
        // Handle specific file retrieval with DocumentFile
        val treeUri = Uri.parse("content://com.android.externalstorage.documents/tree/primary%3AAndroid%2Fmedia")
        val documentFile = DocumentFile.fromTreeUri(applicationContext, treeUri)
        
        // Navigate through subdirectories
        var currentDir: DocumentFile? = documentFile
        for (segment in pathSegments.dropLast(1)) {
            currentDir = currentDir?.findFile(segment)
            if (currentDir == null || !currentDir.isDirectory) {
                return false
            }
        }

        // Find the target file
        val targetFile = currentDir?.findFile(lastSegment)
        if (targetFile != null && targetFile.isFile) {
            val mimeType = contentResolver.getType(targetFile.uri) ?: "application/octet-stream"
            val subject = "Saved with Media Saver—no cost, no ads!"
            val body = "$subject\n\nDownload it: https://play.google.com/store/apps/details?id=com.blackstackhub.mediasaver"
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = mimeType
                putExtra(Intent.EXTRA_STREAM, targetFile.uri)
                putExtra(Intent.EXTRA_SUBJECT, subject)
                putExtra(Intent.EXTRA_TEXT, body)
            }
            val shareIntent = Intent.createChooser(intent, null)
            startActivity(shareIntent)
            return true
        }
        
        false
    } else {
        // Handle URL with MediaStore ID
        val fileId = try {
            val pathSegments = Uri.parse(url).pathSegments
            if (pathSegments.isNotEmpty()) {
                pathSegments.last().toLongOrNull()
            } else {
                null
            }
        } catch (e: Exception) {
            null
        } ?: return false
        
        val fileUri = ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, fileId)
        
        return try {
            val mimeType = contentResolver.getType(fileUri) ?: "application/octet-stream"
            val subject = "Saved with Media Saver—no cost, no ads!"
            val body = "$subject\n\nDownload it: https://play.google.com/store/apps/details?id=com.blackstackhub.mediasaver"
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = mimeType
                putExtra(Intent.EXTRA_STREAM, fileUri)
                putExtra(Intent.EXTRA_SUBJECT, subject)
                putExtra(Intent.EXTRA_TEXT, body)
            }
            val shareIntent = Intent.createChooser(intent, null)
            startActivity(shareIntent)
            true
        } catch (e: Exception) {
            false
        }
    }
}

    
private fun deleteMedia(url: String): Boolean {
    val contentResolver = applicationContext.contentResolver

    // Check if the URL contains "Android/media" indicating it's not an ID
    return if (url.contains("Android/media")) {
        // Handle URL with DocumentFile traversal
        val uri = Uri.parse(url)
        val pathSegments = uri.pathSegments
        val lastSegment = pathSegments.last()
        
        // Handle specific file deletion with DocumentFile
        val treeUri = Uri.parse("content://com.android.externalstorage.documents/tree/primary%3AAndroid%2Fmedia")
        val documentFile = DocumentFile.fromTreeUri(applicationContext, treeUri)
        
        // Navigate through subdirectories
        var currentDir: DocumentFile? = documentFile
        for (segment in pathSegments.dropLast(1)) {
            currentDir = currentDir?.findFile(segment)
            if (currentDir == null || !currentDir.isDirectory) {
                return false
            }
        }

        // Find the target file
        val targetFile = currentDir?.findFile(lastSegment)
        if (targetFile != null && targetFile.isFile) {
            return targetFile.delete()
        }
        
        false
    } else {
        // Handle URL with MediaStore ID
        val fileId = try {
            val pathSegments = Uri.parse(url).pathSegments
            if (pathSegments.isNotEmpty()) {
                pathSegments.last().toLongOrNull()
            } else {
                null
            }
        } catch (e: Exception) {
            null
        } ?: return false
        
        val fileUri = ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, fileId)
        
        return try {
            val rowsDeleted = contentResolver.delete(fileUri, null, null)
            rowsDeleted > 0
        } catch (e: Exception) {
            false
        }
    }
}


    private fun getMedias(appType: String): List<Map<String, String>> {
        Common.startServer(context)
        Log.d("appType", appType)

        val fileInfoList = mutableListOf<Map<String, String>>()

        when (appType) {
            "SAVED" -> {
                val cursor = Common.savedMediasQuery(contentResolver)
                cursor?.use { cursorInstance ->
                    while (cursorInstance.moveToNext()) {
                        val id = cursorInstance.getLong(cursorInstance.getColumnIndexOrThrow(MediaStore.Images.Media._ID))
                        val uri = Uri.withAppendedPath(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id.toString())
                        val mimeType = contentResolver.getType(uri) ?: "application/octet-stream"
                        val url = "http://localhost:8080/files/$id"

                        fileInfoList.add(mapOf("url" to url, "mimeType" to mimeType))
                    }
                }
            }
            "WHATSAPP", "WHATSAPP4B" -> {
                val docUri = if (appType == "WHATSAPP") {
                    Common.whatsappMediaQuery(contentResolver)
                } else {
                    Common.whatsappBusinessMediaQuery(contentResolver)
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
                        val mimeType = cursorInstance.getString(cursorInstance.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_MIME_TYPE)) ?: "application/octet-stream"
                        val url = "http://localhost:8080/files/$documentId"

                        fileInfoList.add(mapOf("url" to url, "mimeType" to mimeType))
                    }
                }
            }
            else -> Log.d("FileQuery", "Invalid app type.")
        }

        return fileInfoList
    }

    private suspend fun downloadAndSaveFile(fileUrl: String): String {
        // Extract fileId from fileUrl
        val fileId = try {
            val pathSegments = Uri.parse(fileUrl).pathSegments
            if (pathSegments.isNotEmpty()) {
                pathSegments.last().toLongOrNull()
            } else {
                null
            }
        } catch (e: Exception) {
            null
        } ?: return "Invalid File ID"

        return withContext(Dispatchers.IO) {
            val client = OkHttpClient.Builder().readTimeout(60, TimeUnit.SECONDS).build()
            val request = Request.Builder()
                .url(fileUrl)
                .build()

            try {
                client.newCall(request).execute().use { response ->
                    if (!response.isSuccessful) {
                        return@withContext "Download Failed"
                    }

                    val mimeType = response.header("Content-Type")
                    val fileExtension = MimeTypeMap.getSingleton().getExtensionFromMimeType(mimeType)
                    val contentResolver = applicationContext.contentResolver

                    val fileName = "mediasaver_$fileId.$fileExtension"

                    // Check if file already exists in MediaStore
                    val cursor = Common.savedMediasQuery(contentResolver)
                    val fileExists = cursor?.use {
                        val displayNameColumn = it.getColumnIndex(MediaStore.Images.Media.DISPLAY_NAME)
                        while (it.moveToNext()) {
                            val existingFileName = it.getString(displayNameColumn)
                            if (existingFileName == fileName) {
                                return@withContext "File already exists"
                            }
                        }
                        false
                    } ?: false

                    if (fileExists) {
                        return@withContext "File already exists"
                    }

                    // Prepare ContentValues for MediaStore
                    val values = ContentValues().apply {
                        put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
                        put(MediaStore.Images.Media.MIME_TYPE, mimeType)
                        put(MediaStore.Images.Media.IS_PENDING, 1)
                    }

                    // Insert a new entry in MediaStore
                    val savedUri = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                        ?: return@withContext "Failed to create MediaStore entry"

                    // Open streams for downloading and writing to MediaStore
                    val inputStream: InputStream? = response.body?.byteStream()
                    val outputStream = contentResolver.openOutputStream(savedUri) ?: return@withContext "Failed to save file"

                    val buffer = ByteArray(2048)
                    var bytesRead: Int

                    inputStream.use { input ->
                        outputStream.use { output ->
                            while (input?.read(buffer).also { bytesRead = it ?: -1 } != -1) {
                                output.write(buffer, 0, bytesRead)
                            }
                        }
                    }

                    // Mark the file as ready by clearing IS_PENDING
                    values.clear()
                    values.put(MediaStore.Images.Media.IS_PENDING, 0)
                    contentResolver.update(savedUri, values, null, null)

                    return@withContext when {
                        mimeType?.startsWith("video/") == true -> "Video saved"
                        mimeType?.startsWith("image/") == true -> "Image saved"
                        else -> "File saved"
                    }
                }
            } catch (e: IOException) {
                e.printStackTrace()
                return@withContext "IO Exception, Try again!"
            } catch (e: Exception) {
                e.printStackTrace()
                return@withContext "Unexpected Error: ${e.message}"
            }
        }
    }

    // PERMISSION HANDLING

    private fun hasFolderAccess(): Boolean {
        val isPermit = Common.hasPermission(context)
        return isPermit
    }

    private fun requestAccessToFolder() {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
        startActivityForResult(intent, Common.REQUEST_CODE_WHATSAPP_FOLDER)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (resultCode == Activity.RESULT_OK) {
            val uri = data?.data ?: return
            Log.d("uri", " $uri")

            if (requestCode == Common.REQUEST_CODE_WHATSAPP_FOLDER && uri.toString() == "content://com.android.externalstorage.documents/tree/primary%3AAndroid%2Fmedia") {
                Common.updatePermission(true, context)
            } else {
                Toast.makeText(applicationContext, "Please select the Media folder", Toast.LENGTH_SHORT).show()
                requestAccessToFolder()
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

