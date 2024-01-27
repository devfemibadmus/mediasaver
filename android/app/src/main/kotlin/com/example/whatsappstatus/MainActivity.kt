package com.blackstackhub.whatsapp

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



    // private val PICK_DIRECTORY_REQUEST_CODE = 123
    // private var STATUS_DIRECTORY: DocumentFile? = null
    // private var BASE_DIRECTORY: Uri = Uri.parse("/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/")

/*
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