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

import java.io.IOException
import java.io.FileInputStream
import java.io.FileOutputStream
import io.flutter.plugin.common.PluginRegistry.Registrar

object Common {
    val WHATSAPP = File(Environment.getExternalStorageDirectory().toString() + "/Android/media/com.whatsapp/WhatsApp/Media/.Statuses")
    val WHATSAPP4B = File(Environment.getExternalStorageDirectory().toString() + "/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses")
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
                "getStatusFilesInfo" -> result.success(getStatusFilesInfo())
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


}
