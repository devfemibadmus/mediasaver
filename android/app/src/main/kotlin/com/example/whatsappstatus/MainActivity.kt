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

import java.io.IOException
import java.io.FileInputStream
import java.io.FileOutputStream
import io.flutter.plugin.common.PluginRegistry.Registrar

object Common {
    val WHATSAPP = File(Environment.getExternalStorageDirectory().toString() + "/Android/media/com.whatsapp/WhatsApp/Media/.Statuses")
    val SAVEDWHATSAPP = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES),"Status Saver")
    val WHATSAPP4B = File(Environment.getExternalStorageDirectory().toString() + "/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses")
    val SAVEDWHATSAPP4B = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES),"Status Saver")
}


class MainActivity : FlutterActivity() {
    private val TAG = "MainActivity"
    private val APP_STORAGE_ACCESS_REQUEST_CODE = 501
    private val CHANNEL = "com.blackstackhub.whatsappstatus"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestStoragePermission" -> result.success(requestStoragePermission())
                "checkStoragePermission" -> result.success(checkStoragePermission())
                "getStatusFilesInfo" -> {
                    val appType = call.argument<String>("appType")
                    if (appType != null) {
                        result.success(getStatusFilesInfo(appType))
                    } else {
                        result.error("INVALID_PARAMETERS", "Invalid parameters", null)
                    }
                }
                "saveStatus" -> {
                    val imagePath = call.argument<String>("imagePath")
                    val folder = call.argument<String>("folder")
                    if (imagePath != null && folder != null) {
                        saveStatus(imagePath, folder)
                        result.success(null)
                    } else {
                        result.error("INVALID_PARAMETERS", "Invalid parameters", null)
                    }
                }
                else -> result.notImplemented()
            }
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

    private fun getStatusFilesInfo(appType: String): List<Map<String, Any>> {
        val statusFilesInfo = mutableListOf<Map<String, Any>>()

        fun getMediaByte(file: File, format: String): ByteArray {
            try {
                // Check if the file is an mp4 video
                // val format = getFileFormat(file.name)
                if (format == "mp4") {
                    val retriever = MediaMetadataRetriever()
                    retriever.setDataSource(file.absolutePath)
                    val thumbnailBitmap = retriever.getFrameAtTime()
                    val stream = ByteArrayOutputStream()
                    thumbnailBitmap?.compress(Bitmap.CompressFormat.PNG, 100, stream)
                    return stream.toByteArray()
                } else if (format == "jpg"){
                    /*
                    val byteArrayOutputStream = ByteArrayOutputStream()
                    val image = ImageIO.read(File(file.absolutePath))                    
                    ImageIO.write(image, "jpg", byteArrayOutputStream)
                    return byteArrayOutputStream.toByteArray()
                    */

                    /*
                    val options = BitmapFactory.Options()
                    options.inPreferredConfig = Bitmap.Config.ARGB_8888
                    val bitmap = BitmapFactory.decodeFile(file.absolutePath, options)
                    val byteArrayOutputStream = ByteArrayOutputStream()
                    bitmap?.compress(Bitmap.CompressFormat.JPEG, 100, byteArrayOutputStream)
                    return byteArrayOutputStream.toByteArray()
                    */
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
                fileInfo["mediaByte"] = getMediaByte(file, fileInfo["format"] as String)
                statusFilesInfo.add(fileInfo)
            }
        }

        if(appType == "SAVED"){
            Common.SAVEDWHATSAPP?.let { processFiles(it.listFiles(FileFilter { file -> file.isFile && file.canRead() }), "Whatsapp Status") }
            Common.SAVEDWHATSAPP4B?.let { processFiles(it.listFiles(FileFilter { file -> file.isFile && file.canRead() }), "Whatsapp4b Status") }
        }
        else if(appType == "WHATSAPP"){
            Common.WHATSAPP?.let { processFiles(it.listFiles(FileFilter { file -> file.isFile && file.canRead() }), "Whatsapp Status") }
        }
        else if(appType == "WHATSAPP4B"){
            Common.WHATSAPP4B?.let { processFiles(it.listFiles(FileFilter { file -> file.isFile && file.canRead() }), "Whatsapp4b Status") }
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
        statusFilesInfo.addAll(whatsapp)
        statusFilesInfo.addAll(whatsapp4b)
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

    private fun saveStatus(sourceImagePath: String, folder: String) {
        val imagePath = File(sourceImagePath)

        if (imagePath.exists()) {
                try {
                        val galleryDirectory = File(
                                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES),
                                folder
                        )

                        if (!galleryDirectory.exists()) {
                                galleryDirectory.mkdirs()
                        }

                        val timeStamp = System.currentTimeMillis()
                        val originalExtension = getExtension(imagePath)
                        val newImageFileName = "IMG_$timeStamp.$originalExtension"

                        val newImageFile = File(galleryDirectory, newImageFileName)

                        FileInputStream(imagePath).use { inputStream ->
                                FileOutputStream(newImageFile).use { outputStream ->
                                        val buffer = ByteArray(4 * 1024)
                                        var bytesRead: Int
                                        while (inputStream.read(buffer).also { bytesRead = it } >= 0) {
                                                outputStream.write(buffer, 0, bytesRead)
                                        }
                                }
                        }
                } catch (e: IOException) {
                        e.printStackTrace()
                }
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
// This is the wishful use, thoug need to update

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
