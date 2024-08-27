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
import kotlinx.coroutines.launch
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.InputStream
import android.app.Service
import android.os.IBinder
import android.os.Handler
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager



import android.content.ContentValues
import android.provider.MediaStore
import java.io.OutputStream


import androidx.documentfile.provider.DocumentFile
import android.provider.DocumentsContract
import android.content.ContentResolver
import android.provider.DocumentsContract.Document

import android.widget.Toast



class MainActivity : FlutterActivity() {
    private val FILE_PROVIDER_AUTHORITY = "com.blackstackhub.mediasaver.fileprovider"
    private val TAG = "MainActivity"
    private val APP_STORAGE_ACCESS_REQUEST_CODE = 501
    private val REQUEST_CODE_MEDIA = 1001
    private val CHANNEL = "com.blackstackhub.mediasaver"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "shareApp" -> result.success(shareApp())
                "sendEmail" -> result.success(sendEmail())
                "launchDemo" -> result.success(launchDemo())
                "launchUpdate" -> result.success(launchUpdate())
                "launchPrivacyPolicy" -> result.success(launchPrivacyPolicy())
                "getClipboardContent" -> result.success(getClipboardContent())
                "checkStoragePermission" -> result.success(checkStoragePermission())
                "requestStoragePermission" -> result.success(requestStoragePermission())
                "startService" -> {
                    startBackgroundService()
                    result.success("Service started")
                }
                "downloadFile" -> {
                    val fileUrl = call.argument<String>("fileUrl")
                    val fileId = call.argument<String>("fileId")
                    if (fileUrl != null && fileId !=null) {
                        CoroutineScope(Dispatchers.Main).launch {
                            val filePath = downloadAndSaveFile(fileUrl, fileId)
                            result.success(filePath)
                        }
                    } else {
                        result.error("INVALID_PARAMETERS", "Invalid parameters", null)
                    }
                }
                "getMediaFilesInfo" -> {
                    val appType = call.argument<String>("appType")
                    if (appType != null) {
                        result.success(getMediaFilesInfo(appType))
                    } else {
                        result.error("INVALID_PARAMETERS", "Invalid parameters", null)
                    }
                }
                "getVideoThumbnailAsync" -> {
                    val absolutePath = call.argument<String>("absolutePath")
                    if (absolutePath != null) {
                        lifecycleScope.launch {
                            try {
                                val thumbnail = getVideoThumbnailAsync(absolutePath)
                                result.success(thumbnail)
                            } catch (e: Exception) {
                                result.error("EXCEPTION", "Error during thumbnail retrieval", null)
                            }
                        }
                    } else {
                        result.error("INVALID_PARAMETERS", "Invalid parameters", null)
                    }
                }
                "saveMedia" -> {
                    val filePath = call.argument<String>("filePath")
                    // val folder = call.argument<String>("folder")
                    if (filePath != null) {
                        result.success(saveMedia(filePath))
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
                "shareMedia" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        result.success(shareMedia(filePath))
                    } else {
                        result.error("INVALID_PARAMETERS", "Invalid parameters", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    fun getAppVersion(context: Context): String {
        try {
            val packageInfo = context.packageManager.getPackageInfo(context.packageName, 0)
            return packageInfo.versionName
        } catch (e: PackageManager.NameNotFoundException) {
            // e.printStackTrace()
        }
        return "Unknown"
    }

    private fun startBackgroundService() {
        val intent = Intent(this, MyBackgroundService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

class MyBackgroundService : Service() {

    private val handler = Handler()

    private val syncRunnable = object : Runnable {
        override fun run() {
            // Log.d("MyBackgroundService", "Sync task running...")
            syncAllDirectories()
            handler.postDelayed(this, 5000)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Log.d("MyBackgroundService", "Service started")

        // Immediately call startForeground
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "background_service_channel"
            val channel = NotificationChannel(
                channelId,
                "Background Service Channel",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)

            val notification: Notification = Notification.Builder(this, channelId)
                .setContentTitle("Background Task Running")
                .setContentText("This task is running in the background")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .build()

            startForeground(1, notification)
        }

        // Start the sync task
        handler.post(syncRunnable)

        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacks(syncRunnable)
        // Log.d("MyBackgroundService", "Service stopped")
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun getLastModified(directoryUri: Uri): Long {
        var lastModified = 0L
        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_LAST_MODIFIED
        )

        val cursor = contentResolver.query(directoryUri, projection, null, null, null)
        cursor?.use { cursorInstance ->
            val lastModifiedIndex = cursorInstance.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_LAST_MODIFIED)
            while (cursorInstance.moveToNext()) {
                val currentLastModified = cursorInstance.getLong(lastModifiedIndex)
                if (currentLastModified > lastModified) {
                    lastModified = currentLastModified
                }
            }
        }

        return lastModified
    }

    private fun syncAllDirectories() {
        val sharedPreferences = getSharedPreferences("MyPreferences", Context.MODE_PRIVATE)
        val isProcessing = sharedPreferences.getBoolean("isProcessing", false)
        if (isProcessing) {
            return
        }

        sharedPreferences.edit().putBoolean("isProcessing", true).apply()

        try{
            try{
                syncSavedMedia(contentResolver)
            } catch(e: Exception){
                // Log.d("syncSavedMedia", "Caught an exception: ${e.message}")
            }
            try{
            syncDirectory(
                contentResolver,
                Uri.parse("content://com.android.externalstorage.documents/tree/primary%3AAndroid%2Fmedia/document/primary%3AAndroid%2Fmedia%2Fcom.whatsapp%2FWhatsApp%2FMedia%2F.Statuses/children"),
                File(getExternalFilesDir(null), "whatsapp"),
                "lastModifiedWhatsapp"
            )
            } catch(e: Exception){
                // Log.d("syncDirectory", "Caught an exception: ${e.message}")
            }
            try{
            syncDirectory(
                contentResolver,
                Uri.parse("content://com.android.externalstorage.documents/tree/primary%3AAndroid%2Fmedia/document/primary%3AAndroid%2Fmedia%2Fcom.whatsapp.w4b%2FWhatsApp%20Business%2FMedia%2F.Statuses/children"),
                File(getExternalFilesDir(null), "whatsapp4b"),
                "lastModifiedWhatsapp4b"
            )
            } catch(e: Exception){
                // Log.d("syncDirectoryW4B", "Caught an exception: ${e.message}")
            }
        } finally{
            sharedPreferences.edit().putBoolean("isProcessing", false).apply()
        }
    }

    private fun syncSavedMedia(contentResolver: ContentResolver) {
        val sharedPreferences = getSharedPreferences("MyPreferences", Context.MODE_PRIVATE)
        val editor = sharedPreferences.edit()

        val sourceDir = File(applicationContext.getExternalFilesDir(null), "saved")
        val currentLastModified = sourceDir.lastModified()

        // Retrieve the last stored last modified timestamp
        val storedLastModified = sharedPreferences.getLong("lastModified", -1)

        // If the directory has not been modified since the last check, return early
        if (currentLastModified == storedLastModified) {
            return
        }
        // Log.d("syncSavedMedia", "currentLastModified: $currentLastModified, storedLastModified: $storedLastModified")

        // Update the stored last modified timestamp
        editor.putLong("lastModified", currentLastModified)
        editor.apply()

        // Iterate over files in the source directory
        val files = sourceDir.listFiles() ?: return
        for (file in files) {
            val displayName = file.name
            val mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(file.extension) ?: "application/octet-stream"

            val contentUri = when {
                mimeType.startsWith("image/") -> MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                mimeType.startsWith("video/") -> MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                else -> continue // Skip unsupported file types
            }

            // Query the MediaStore for files with the same display name
            val selection = "${MediaStore.MediaColumns.DISPLAY_NAME} = ?"
            val selectionArgs = arrayOf(displayName)
            val cursor = contentResolver.query(contentUri, null, selection, selectionArgs, null)

            if (cursor?.count == 0) {
                // File does not exist in the MediaStore, insert it
                try {
                    val contentValues = ContentValues().apply {
                        put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
                        put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                        put(MediaStore.MediaColumns.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/Media Saver")
                    }

                    val newUri = contentResolver.insert(contentUri, contentValues)
                    newUri?.let { uri ->
                        contentResolver.openOutputStream(uri)?.use { outputStream ->
                            file.inputStream().use { inputStream ->
                                inputStream.copyTo(outputStream)
                            }
                        }
                    }
                } catch (e: IOException) {
                    Log.e("syncSavedMedia", "Error writing file: ${e.message}")
                    // Pass and continue with the next file
                }
            }
            cursor?.close()
        }
    }

    private fun syncDirectory(contentResolver: ContentResolver, sourceUri: Uri, destinationDir: File, preferenceKey: String) {
        val sharedPreferences = getSharedPreferences("MyPreferences", Context.MODE_PRIVATE)
        val editor = sharedPreferences.edit()

        // Get the last modified timestamp for the directory
        val currentLastModified = getLastModified(sourceUri)

        // Retrieve the last stored last modified timestamp for the given directory
        val storedLastModified = sharedPreferences.getLong(preferenceKey, -1)

        // If the directory has not been modified since the last check, return early
        if (currentLastModified == storedLastModified) {
            return
        }
        // Log.d("syncDirectory", "currentLastModified: $currentLastModified, storedLastModified: $storedLastModified")

        // Update the stored last modified timestamp
        editor.putLong(preferenceKey, currentLastModified)
        editor.apply()

        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME
        )

        if (!destinationDir.exists()) {
            destinationDir.mkdirs()
        }

        // Get the list of files in the destination directory
        val existingFiles = destinationDir.listFiles()?.associateBy { it.name } ?: emptyMap()

        val cursor = contentResolver.query(sourceUri, projection, null, null, null)
        cursor?.use { cursorInstance ->
            val sourceFiles = mutableSetOf<String>()

            while (cursorInstance.moveToNext()) {
                val documentId = cursorInstance.getString(cursorInstance.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID))
                val displayName = cursorInstance.getString(cursorInstance.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME))
                val documentUri = DocumentsContract.buildDocumentUriUsingTree(sourceUri, documentId)

                sourceFiles.add(displayName)
                val destFile = File(destinationDir, displayName)

                try {
                    if (!destFile.exists() || contentResolver.openInputStream(documentUri)?.available() ?: 0 > destFile.length()) {
                        contentResolver.openInputStream(documentUri)?.use { input ->
                            destFile.outputStream().use { output ->
                                input.copyTo(output)
                            }
                        }
                    }
                } catch (e: IOException) {
                    Log.e("syncDirectory", "Error syncing file ${displayName}: ${e.message}")
                    // Pass and continue with the next file
                }
            }

            // Delete files in destination that are no longer present in source
            existingFiles.forEach { (fileName, file) ->
                if (fileName !in sourceFiles) {
                    try {
                        file.delete()
                    } catch (e: IOException) {
                        Log.e("syncDirectory", "Error deleting file ${fileName}: ${e.message}")
                        // Pass and continue with the next file
                    }
                }
            }
        }
    }
}

    private fun sendEmail(): Boolean{
        val emailIntent = Intent(Intent.ACTION_SENDTO)

        val locale = Locale.getDefault()
        val country = locale.displayCountry

        val email = "devfemibadmus@gmail.com"
        val subject = "Request a new feature for Media-Saver"
        
        val preBody = "Version: ${getAppVersion(applicationContext)}\nCountry: $country\n\nI want to request feature for..."
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

    private fun launchDemo(): Boolean{
        val webIntent = Intent(Intent.ACTION_VIEW)
        webIntent.data = Uri.parse("https://github.com/devfemibadmus/mediasaver")
        startActivity(webIntent)
        return true
    }

    private fun launchPrivacyPolicy(): Boolean{
        val webIntent = Intent(Intent.ACTION_VIEW)
        webIntent.data = Uri.parse("https://devfemibadmus.blackstackhub.com/webmedia#privacy")
        startActivity(webIntent)
        return true
    }

    private fun getClipboardContent(): String{
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
    
    private fun launchUpdate(): Boolean{
        val webIntent = Intent(Intent.ACTION_VIEW)
        webIntent.data = Uri.parse("https://play.google.com/store/apps/details?id=com.blackstackhub.mediasaver")
        startActivity(webIntent)
        return true
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

    private fun shareMedia(filePath: String): String {
        val file = File(filePath)

        return if (file.exists()) {
            val mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(
                MimeTypeMap.getFileExtensionFromUrl(file.absolutePath)
            )
            val uri: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                // Use FileProvider on Android N and above
                val fileUri = FileProvider.getUriForFile(
                    applicationContext,
                    FILE_PROVIDER_AUTHORITY,
                    file
                )
                fileUri
            } else {
                Uri.fromFile(file)
            }

            // Share intent
            val shareIntent = Intent(Intent.ACTION_SEND)
            val shareSubject = "Saved with Media Saver—no cost, no ads!"
            val shareMessage = "$shareSubject\n\nDownload it: https://play.google.com/store/apps/details?id=com.blackstackhub.mediasaver"
            //shareIntent.type = mimeType
            shareIntent.type = mimeType
            // shareIntent.putExtra(Intent.EXTRA_SUBJECT, shareSubject)
            shareIntent.putExtra(Intent.EXTRA_TEXT, shareMessage)
            shareIntent.putExtra(Intent.EXTRA_STREAM, uri)

            // Grant temporary read permission to the content URI
            shareIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

            try {
                startActivity(Intent.createChooser(shareIntent, "Share Media"))
                "sharing..."
            } catch (e: Exception) {
                // Handle exceptions
                // e.printStackTrace()
                "can't share"
            }
        } else {
            "can't share"
        }
    }

    private fun getFileFormat(fileName: String): String {
        val lastDotIndex = fileName.lastIndexOf('.')
        return if (lastDotIndex != -1 && lastDotIndex < fileName.length - 1) {
            fileName.substring(lastDotIndex + 1).toLowerCase()
        } else {
            "unknown"
        }
    }

    private suspend fun createVideoThumbnailAsync(videoPath: String): Bitmap? = withContext(Dispatchers.IO) {
        val retriever = MediaMetadataRetriever()
        return@withContext try {
            retriever.setDataSource(videoPath)
            retriever.getFrameAtTime()
        } catch (e: Exception) {
            // e.printStackTrace()
            null
        } finally {
            retriever.release()
        }
    }

    private suspend fun getVideoThumbnailAsync(absolutePath: String): ByteArray {
        return withContext(Dispatchers.Default) {
            try {
                val bitmap = createVideoThumbnailAsync(absolutePath)
                if (bitmap != null) {
                    val stream = ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                    bitmap.recycle()
                    return@withContext stream.toByteArray()
                }
            } catch (e: Exception) {
                // e.printStackTrace()
            }
            return@withContext ByteArray(0)
        }
    }

    private fun getMediaFilesInfo(appType: String): List<Map<String, Any>> {
        val mediaFilesInfo = mutableListOf<Map<String, Any>>()

        fun createVideoThumbnail(videoPath: String): Bitmap? {
            val retriever = MediaMetadataRetriever()

            try {
                retriever.setDataSource(videoPath)
                return retriever.getFrameAtTime()
            } catch (e: Exception) {
                // e.printStackTrace()
            } finally {
                retriever.release()
            }

            return null
        }


        fun getMediaByte(file: File, format: String): ByteArray {
            try {
                if (format == "mp4") {
                    val bitmap = createVideoThumbnail(file.absolutePath);
                    if (bitmap != null){
                        val stream = ByteArrayOutputStream();
                        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream);
                        bitmap.recycle();
                        return stream.toByteArray();
                    }
                }
            } catch (e: Exception) {
                // e.printStackTrace()
            }
            return ByteArray(0)
        }

        fun processFiles(files: Array<File>?, source: String) {
            files?.forEach { file ->
                val fileInfo = mutableMapOf<String, Any>()
                fileInfo["name"] = file.name
                fileInfo["path"] = file.absolutePath
                fileInfo["size"] = file.length()
                fileInfo["format"] = getFileFormat(file.name)
                fileInfo["source"] = source
                fileInfo["mediaByte"] = ByteArray(0)

                mediaFilesInfo.add(fileInfo)
            }
        }

        if(appType == "SAVED"){
            File(applicationContext.getExternalFilesDir(null), "saved")?.let { processFiles(it.listFiles(FileFilter { file -> file.isFile && file.canRead() }), "SAVED") }
        }
        else if(appType == "WHATSAPP"){
            File(applicationContext.getExternalFilesDir(null), "whatsapp")?.let { processFiles(it.listFiles(FileFilter { file -> file.isFile && file.canRead() }), "WHATSAPP") }
        }
        else if(appType == "WHATSAPP4B"){
            File(applicationContext.getExternalFilesDir(null), "whatsapp4b")?.let { processFiles(it.listFiles(FileFilter { file -> file.isFile && file.canRead() }), "WHATSAPP4B") }
        }
        else if(appType == "ALLWHATSAPP"){
            File(applicationContext.getExternalFilesDir(null), "whatsapp")?.let { processFiles(it.listFiles(FileFilter { file -> file.isFile && file.canRead() }), "WHATSAPP") }
            File(applicationContext.getExternalFilesDir(null), "whatsapp4b")?.let { processFiles(it.listFiles(FileFilter { file -> file.isFile && file.canRead() }), "WHATSAPP4B") }
        }
        return mediaFilesInfo
    }
    
    /*
    private fun checkStoragePermission(): Boolean {
        val hasPermission =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                Environment.isExternalStorageManager()
            } else {
                ContextCompat.checkSelfPermission(this,Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
            }
        return hasPermission
    }

    private fun requestStoragePermission(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION, Uri.parse("package:" + packageName))
            activity.startActivityForResult(intent, APP_STORAGE_ACCESS_REQUEST_CODE)
            return true
        } else {
            ActivityCompat.requestPermissions(this.activity,arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),APP_STORAGE_ACCESS_REQUEST_CODE)
            return true
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == APP_STORAGE_ACCESS_REQUEST_CODE) {
            if (resultCode == RESULT_OK && Environment.isExternalStorageManager()) {
                // Log.d(TAG, "Storage permission granted")
            } else {
                // Log.d(TAG, "Storage permission denied")
            }
        }
    }
    */

    private fun checkStoragePermission(): Boolean {
        val documentFile = DocumentFile.fromTreeUri(context, Uri.parse("content://com.android.externalstorage.documents/tree/primary%3AAndroid%2Fmedia"))
        return documentFile?.exists() == true
    }

    private fun requestStoragePermission(): Boolean {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
        startActivityForResult(intent, REQUEST_CODE_MEDIA)
        return true
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (resultCode == RESULT_OK) {
            val uri = data?.data ?: return
            // Log.d("uri", " $uri")
            if(requestCode == REQUEST_CODE_MEDIA){
                contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                if(uri.toString() != "content://com.android.externalstorage.documents/tree/primary%3AAndroid%2Fmedia"){
                    Toast.makeText(applicationContext, "Please select the Media folder", Toast.LENGTH_SHORT).show()
                    requestStoragePermission()
                }
            }
        }
    }


    private fun saveMedia(sourceFilePath: String): String {
        val sourceFile = File(sourceFilePath)
        val intent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE)
        intent.data = Uri.fromFile(File(applicationContext.getExternalFilesDir(null), "saved"))

        return if (sourceFile.exists()) {
            try {
                val galleryDirectory = File(applicationContext.getExternalFilesDir(null), "saved")

                if (!galleryDirectory.exists()) {
                    galleryDirectory.mkdirs()
                }

                val originalFileName = sourceFile.name
                val originalExtension = getExtension(sourceFile)

                val newImageFile = File(galleryDirectory, originalFileName)

                // If a file with the same name already exists, return "Already Saved"
                if (newImageFile.exists()) {
                     return "Already Saved"
                }

                FileInputStream(sourceFile).use { inputStream ->
                    FileOutputStream(newImageFile).use { outputStream ->
                        val buffer = ByteArray(4 * 1024)
                        var bytesRead: Int
                        while (inputStream.read(buffer).also { bytesRead = it } >= 0) {
                            outputStream.write(buffer, 0, bytesRead)
                        }
                    }
                }
                applicationContext.sendBroadcast(intent)


                // File saved successfully
                val fileName = sourceFilePath.toLowerCase()
                return when {
                    fileName.endsWith(".jpg") || fileName.endsWith(".jpeg") || fileName.endsWith(".png") -> "Image saved"
                    else -> "Video saved"
                }
                } catch (e: IOException) {
                    // e.printStackTrace()
                    // Error saving file
                    "Not Saved"
                }
        } else {
            // Source file doesn't exist
            "Not Saved"
        }
    }

    private fun deleteMedia(filePath: String): String {
        val folder = File(applicationContext.getExternalFilesDir(null), "saved")
        val file = File(filePath)

        return try {
            if (file.exists() && file.delete()) {
                "deleted"
            }else{
                "not deleted"
            }
        } catch (e: SecurityException) {
            // e.printStackTrace()
            "not deleted"
        }
    }

    private fun getExtension(file: File): String {
        val name = file.name
        val lastDotIndex = name.lastIndexOf('.')
        return if (lastDotIndex == -1) {
                "jpg"
        } else {
                name.substring(lastDotIndex + 1).toLowerCase()
        }
    }

    private suspend fun downloadAndSaveFile(fileUrl: String, fileId: String): String {
            return withContext(Dispatchers.IO) {
                val intent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE)
                intent.data = Uri.fromFile(File(applicationContext.getExternalFilesDir(null), "saved"))
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

                        val galleryDirectory = File(applicationContext.getExternalFilesDir(null), "saved")
                        if (!galleryDirectory.exists()) {
                            galleryDirectory.mkdirs()
                        }

                        val fileName = "mediasaver_$fileId.$fileExtension"
                        val saveFile = File(galleryDirectory, fileName)

                        if (saveFile.exists()) {
                            return@withContext "Already Saved"
                        }

                        val inputStream: InputStream? = response.body?.byteStream()
                        val outputStream = FileOutputStream(saveFile)
                        val buffer = ByteArray(2048)
                        var bytesRead: Int

                        inputStream.use { input ->
                            outputStream.use { output ->
                                while (input?.read(buffer).also { bytesRead = it ?: -1 } != -1) {
                                    output.write(buffer, 0, bytesRead)
                                }
                            }
                        }
                        applicationContext.sendBroadcast(intent)

                        return@withContext when {
                            mimeType?.startsWith("video/") == true -> "Video saved"
                            mimeType?.startsWith("image/") == true -> "Image saved"
                            else -> "File saved"
                        }
                    }
                } catch (e: SecurityException) {
                    // e.printStackTrace()
                    return@withContext "Restart app and give permission."
                } catch (e: IOException) {
                    // e.printStackTrace()
                    return@withContext "IO Exception, Try again!"
                }
            }
    }
}

