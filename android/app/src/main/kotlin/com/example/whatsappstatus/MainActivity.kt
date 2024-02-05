package com.blackstackhub.whatsappstatus

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
import android.content.pm.PackageManager
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

import java.io.IOException
import java.io.FileInputStream
import java.io.FileOutputStream
import io.flutter.plugin.common.PluginRegistry.Registrar

object Common {
    val SAVEDSTATUSES = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES),"Status Saver")
    val WHATSAPP = File(Environment.getExternalStorageDirectory().toString() + "/Android/media/com.whatsapp/WhatsApp/Media/.Statuses")
    val WHATSAPP4B = File(Environment.getExternalStorageDirectory().toString() + "/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses")
}


class MainActivity : FlutterActivity() {
    private val FILE_PROVIDER_AUTHORITY = "com.blackstackhub.whatsappstatus.fileprovider"
    private val TAG = "MainActivity"
    private val APP_STORAGE_ACCESS_REQUEST_CODE = 501
    private val CHANNEL = "com.blackstackhub.whatsappstatus"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "shareApp" -> result.success(shareApp())
                "sendEmail" -> result.success(sendEmail())
                "launchDemo" -> result.success(launchDemo())
                "checkStoragePermission" -> result.success(checkStoragePermission())
                "requestStoragePermission" -> result.success(requestStoragePermission())
                "getStatusFilesInfo" -> {
                    val appType = call.argument<String>("appType")
                    if (appType != null) {
                        result.success(getStatusFilesInfo(appType))
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
                "saveStatus" -> {
                    val filePath = call.argument<String>("filePath")
                    // val folder = call.argument<String>("folder")
                    if (filePath != null) {
                        result.success(saveStatus(filePath))
                    } else {
                        result.error("INVALID_PARAMETERS", "Invalid parameters", null)
                    }
                }
                "deleteStatus" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        result.success(deleteStatus(filePath))
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
            e.printStackTrace()
        }
        return "Unknown"
    }

    private fun sendEmail(): Boolean{
        val emailIntent = Intent(Intent.ACTION_SENDTO)

        val locale = Locale.getDefault()
        val country = locale.displayCountry

        val email = "devfemibadmus@gmail.com"
        val subject = "Request a new feature for Whatsapp-status-saver"
        
        val preBody = "Version: ${getAppVersion(applicationContext)}\nCountry: $country\n\nI want to request for feature..."
        val mailtoLink = "mailto:$email?subject=$subject&body=$preBody"

        // Set the email address
        emailIntent.data = Uri.parse(mailtoLink)

        // Check if there is a package that can handle the intent
        try {
            startActivity(emailIntent)
        } catch (e: Exception) {
            // If no email app is available, open a web browser
            val webIntent = Intent(Intent.ACTION_VIEW)
            webIntent.data = Uri.parse("https://github.com/devfemibadmus/whatsapp-status-saver")
            startActivity(webIntent)
        }
        return true
    }

    private fun launchDemo(): Boolean{
        val webIntent = Intent(Intent.ACTION_VIEW)
        webIntent.data = Uri.parse("https://github.com/devfemibadmus/whatsapp-status-saver")
        startActivity(webIntent)
        return true
    }

    private fun shareApp(): Boolean{
        // Share intent
        val shareIntent = Intent(Intent.ACTION_SEND)
        shareIntent.type = "text/plain"
    
        // Set the subject and message
        val shareSubject = "Check out this amazing free status saver no-ads!"
        val shareMessage = "$shareSubject\n\nDownload the app: https://play.google.com/store/apps/details?id=com.blackstackhub.whatsapp"
    
        // shareIntent.putExtra(Intent.EXTRA_SUBJECT, shareSubject)
        shareIntent.putExtra(Intent.EXTRA_TEXT, shareMessage)

        try {
            startActivity(Intent.createChooser(shareIntent, "Share via"))
        } catch (e: Exception) {
            // Handle exceptions
            e.printStackTrace()
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
            val shareSubject = "https://play.google.com/store/apps/details?id=com.blackstackhub.whatsapp"
            val shareMessage = "i save this from free status saver no-ads!\n\n$shareSubject"
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
                e.printStackTrace()
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
            e.printStackTrace()
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
                e.printStackTrace()
            }
            return@withContext ByteArray(0)
        }
    }

    // the main issue that could lead to skipped frames and performance problems is the synchronous execution of createVideoThumbnail(videoPath) function on the main thread. The MediaMetadataRetriever and getFrameAtTime() methods perform I/O operations and may involve heavy computations, especially for large videos.
    
    /*
    private fun getVideoThumbnail(absolutePath: String): ByteArray {

        fun createVideoThumbnail(videoPath: String): Bitmap? {
            val retriever = MediaMetadataRetriever()

            try {
                retriever.setDataSource(videoPath)
                return retriever.getFrameAtTime()
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                retriever.release()
            }

            return null
        }
        try {
            val bitmap = createVideoThumbnail(absolutePath);
            if (bitmap != null){
                val stream = ByteArrayOutputStream();
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream);
                bitmap.recycle();
                return stream.toByteArray();
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return ByteArray(0)
    }
    */

    private fun getStatusFilesInfo(appType: String): List<Map<String, Any>> {
        val statusFilesInfo = mutableListOf<Map<String, Any>>()

        fun createVideoThumbnail(videoPath: String): Bitmap? {
            val retriever = MediaMetadataRetriever()

            try {
                retriever.setDataSource(videoPath)
                return retriever.getFrameAtTime()
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                retriever.release()
            }

            return null
        }


        fun getMediaByte(file: File, format: String): ByteArray {
            try {
                // Check if the file is an mp4 video
                // val format = getFileFormat(file.name)
                if (format == "mp4") {
                    // I/Choreographer(25094): Skipped 717 frames!  The application may be doing too much work on its main thread.
                    /*
                    val retriever = MediaMetadataRetriever()
                    retriever.setDataSource(file.absolutePath)
                    val thumbnailBitmap = retriever.getFrameAtTime()

                    thumbnailBitmap?.let {
                        val stream = ByteArrayOutputStream()
                        it.compress(Bitmap.CompressFormat.PNG, 100, stream)
                        it.recycle() // Release the bitmap resources
                        return stream.toByteArray()
                    }
                    */
                    val bitmap = createVideoThumbnail(file.absolutePath);
                    if (bitmap != null){
                        val stream = ByteArrayOutputStream();
                        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream);
                        bitmap.recycle();
                        return stream.toByteArray();
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
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
                /*
                fileInfo["mediaByte"] = getMediaByte(file, fileInfo["format"] as String)
                */

                statusFilesInfo.add(fileInfo)
            }
        }

        if(appType == "SAVED"){
            Common.SAVEDSTATUSES?.let { processFiles(it.listFiles(FileFilter { file -> file.isFile && file.canRead() }), "SAVED") }
        }
        else if(appType == "WHATSAPP"){
            Common.WHATSAPP?.let { processFiles(it.listFiles(FileFilter { file -> file.isFile && file.canRead() }), "WHATSAPP") }
        }
        else if(appType == "WHATSAPP4B"){
            Common.WHATSAPP4B?.let { processFiles(it.listFiles(FileFilter { file -> file.isFile && file.canRead() }), "WHATSAPP4B") }
        }
        else if(appType == "ALLWHATSAPP"){
            Common.WHATSAPP?.let { processFiles(it.listFiles(FileFilter { file -> file.isFile && file.canRead() }), "WHATSAPP") }
            Common.WHATSAPP4B?.let { processFiles(it.listFiles(FileFilter { file -> file.isFile && file.canRead() }), "WHATSAPP4B") }
        }
        /*
        else if(appType == "SAVEDWHATSAPP"){
            Common.SAVEDWHATSAPP?.let { processFiles(it.listFiles(FileFilter { file -> file.isFile && file.canRead() }), "whatsapp") }
        }
        else if(appType == "SAVEDWHATSAPP4B"){
            Common.SAVEDWHATSAPP4B?.let { processFiles(it.listFiles(FileFilter { file -> file.isFile && file.canRead() }), "whatsapp4b") }
        }
        */
        return statusFilesInfo
    }

    // ignore, let try the new one
    /*
    private fun getStatusFilesInfo(): List<Map<String, Any>> {
        val statusFilesInfo = mutableListOf<Map<String, Any>>()
        
        val whatsapp = mutableListOf<Map<String, Any>>()
        Common.WHATSAPP?.let {
            val files = it.listFiles(FileFilter { file ->
                file.isFile && file.canRead()
            })
            files?.forEach { file ->
                val fileInfo = mutableMapOf<String, Any>()
                fileInfo["name"] = file.name
                fileInfo["path"] = file.absolutePath
                fileInfo["size"] = file.length()
                fileInfo["format"] = getFileFormat(file.name)
                fileInfo["source"] = "whatsapp"
                whatsapp.add(fileInfo)
            }
        }
        val whatsapp4b = mutableListOf<Map<String, Any>>()
        Common.WHATSAPP4B?.let {
            val files = it.listFiles(FileFilter { file ->
                file.isFile && file.canRead()
            })
            files?.forEach { file ->
                val fileInfo = mutableMapOf<String, Any>()
                fileInfo["name"] = file.name
                fileInfo["path"] = file.absolutePath
                fileInfo["size"] = file.length()
                fileInfo["format"] = getFileFormat(file.name)
                fileInfo["source"] = "whatsapp4b"
                whatsapp4b.add(fileInfo)
            }
        }
        val whatsapp4b = mutableListOf<Map<String, Any>>()
        Common.WHATSAPP4B?.let {
            val files = it.listFiles(FileFilter { file ->
                file.isFile && file.canRead()
            })
            files?.forEach { file ->
                val fileInfo = mutableMapOf<String, Any>()
                fileInfo["name"] = file.name
                fileInfo["path"] = file.absolutePath
                fileInfo["size"] = file.length()
                fileInfo["format"] = getFileFormat(file.name)
                fileInfo["source"] = "whatsapp4b"
                whatsapp4b.add(fileInfo)
            }
        }
        val savedstatus = mutableListOf<Map<String, Any>>()
        Common.SAVEDSTATUSES?.let {
            val files = it.listFiles(FileFilter { file ->
                file.isFile && file.canRead()
            })
            files?.forEach { file ->
                val fileInfo = mutableMapOf<String, Any>()
                fileInfo["name"] = file.name
                fileInfo["path"] = file.absolutePath
                fileInfo["size"] = file.length()
                fileInfo["format"] = getFileFormat(file.name)
                fileInfo["source"] = "whatsapp4b"
                whatsapp4b.add(fileInfo)
            }
        }
        statusFilesInfo.addAll(whatsapp)
        statusFilesInfo.addAll(whatsapp4b)
        statusFilesInfo.addAll(savedstatus)
        return statusFilesInfo
    }
    */
    
    private fun checkStoragePermission(): Boolean {
        val hasPermission =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                Environment.isExternalStorageManager()
            } else {
                true
            }
        // Log.d(TAG, "Has storage permission: $hasPermission")
        return hasPermission
    }

    private fun requestStoragePermission(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION, Uri.parse("package:" + packageName))
            activity.startActivityForResult(intent, APP_STORAGE_ACCESS_REQUEST_CODE)
            return true
        }
        return false
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

    private fun saveStatus(sourceFilePath: String): String {
        val sourceFile = File(sourceFilePath)

        return if (sourceFile.exists()) {
            try {
                val galleryDirectory = Common.SAVEDSTATUSES

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

                // File saved successfully
                "Status Saved"
                } catch (e: IOException) {
                    e.printStackTrace()
                    // Error saving file
                    "Not Saved"
                }
        } else {
            // Source file doesn't exist
            "Not Saved"
        }
    }

    private fun deleteStatus(filePath: String): String {
        val folder = Common.SAVEDSTATUSES
        val file = File(filePath)

        return try {
            if (file.exists() && file.delete()) {
                "deleted"
            }else{
                "not deleted"
            }
        } catch (e: SecurityException) {
            e.printStackTrace()
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

/*
// This is the wishful one, thoug need to update

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

*/

}
