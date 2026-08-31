package ua.org.sovic.xsilent

import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import java.io.File

/**
 * Зберігає озвучені сповіщення у спільному сховищі MediaStore
 * (`Notifications/xSilent`), щоб системний `NotificationManager` міг їх програти
 * як звук каналу. Працює лише з власними записами застосунку — на Android 10+
 * додаткових дозволів не потрібно.
 */
class SoundStore(private val context: Context) {

    private val collection: Uri
        get() = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q)
            MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        else
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI

    private val relativePath = "${Environment.DIRECTORY_NOTIFICATIONS}/xSilent"

    /** Записує файл; повертає його `content://` URI. Перезаписує однойменний. */
    fun put(name: String, sourcePath: String): String {
        deleteWhere("${MediaStore.MediaColumns.DISPLAY_NAME} = ?", arrayOf(name))

        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, name)
            put(MediaStore.MediaColumns.MIME_TYPE, "audio/x-wav")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            put(MediaStore.Audio.Media.IS_NOTIFICATION, 1)
            put(MediaStore.Audio.Media.IS_MUSIC, 0)
            put(MediaStore.Audio.Media.IS_ALARM, 0)
            put(MediaStore.Audio.Media.IS_RINGTONE, 0)
        }

        val resolver = context.contentResolver
        val uri = resolver.insert(collection, values)
            ?: throw IllegalStateException("MediaStore.insert повернув null")

        resolver.openOutputStream(uri, "w").use { out ->
            File(sourcePath).inputStream().use { it.copyTo(out!!) }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val done = ContentValues().apply {
                put(MediaStore.MediaColumns.IS_PENDING, 0)
            }
            resolver.update(uri, done, null, null)
        }
        return uri.toString()
    }

    /** Видаляє всі власні записи `prefix*`, окрім `keep`. */
    fun pruneExcept(prefix: String, keep: String?) {
        val selection = StringBuilder("${MediaStore.MediaColumns.DISPLAY_NAME} LIKE ?")
        val args = mutableListOf("$prefix%")
        if (keep != null) {
            selection.append(" AND ${MediaStore.MediaColumns.DISPLAY_NAME} <> ?")
            args.add(keep)
        }
        deleteWhere(selection.toString(), args.toTypedArray())
    }

    fun deleteAll(prefix: String) {
        deleteWhere("${MediaStore.MediaColumns.DISPLAY_NAME} LIKE ?", arrayOf("$prefix%"))
    }

    private fun deleteWhere(selection: String, args: Array<String>) {
        val resolver = context.contentResolver
        resolver.query(collection, arrayOf(MediaStore.MediaColumns._ID), selection, args, null)
            ?.use { cursor ->
                val idCol = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
                while (cursor.moveToNext()) {
                    val itemUri = ContentUris.withAppendedId(collection, cursor.getLong(idCol))
                    try {
                        resolver.delete(itemUri, null, null)
                    } catch (_: Exception) {
                        // Запис міг зникнути — ігноруємо.
                    }
                }
            }
    }
}
