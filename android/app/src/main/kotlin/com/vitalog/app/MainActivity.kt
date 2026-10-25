package com.vitalog.app

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.Rect
import android.graphics.pdf.PdfRenderer
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.system.Os
import android.system.OsConstants
import androidx.exifinterface.media.ExifInterface
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning
import com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayInputStream
import java.io.File
import java.util.concurrent.Executors
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

class MainActivity : FlutterActivity() {
    private val scanner = DocumentScanner(this)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ReportOcr(cacheDir).register(flutterEngine)
        scanner.register(flutterEngine)
    }

    @Deprecated("Needed for the scanner's IntentSender result")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (!scanner.onResult(requestCode, resultCode, data)) {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }
}

/**
 * Google's document scanner (ML Kit, runs on the phone via Play services):
 * finds the page edges, flattens and crops each page. Same contract as
 * DocumentScannerPlugin on iOS: the path of a PDF in the cache folder
 * (removed once the report is stored encrypted), null if cancelled, error
 * "unavailable" when the scanner can't run, so the app uses the plain camera.
 */
class DocumentScanner(private val activity: Activity) {
    private var pending: MethodChannel.Result? = null

    fun register(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, "vitalog/document_scanner")
            .setMethodCallHandler { call, result ->
                if (call.method != "scan") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (pending != null) {
                    result.error("unavailable", "Scanner already open", null)
                    return@setMethodCallHandler
                }
                val options = GmsDocumentScannerOptions.Builder()
                    .setGalleryImportAllowed(false)
                    .setPageLimit(20)
                    .setResultFormats(GmsDocumentScannerOptions.RESULT_FORMAT_PDF)
                    .setScannerMode(GmsDocumentScannerOptions.SCANNER_MODE_FULL)
                    .build()
                GmsDocumentScanning.getClient(options).getStartScanIntent(activity)
                    .addOnSuccessListener { sender ->
                        pending = result
                        activity.startIntentSenderForResult(sender, REQUEST, null, 0, 0, 0)
                    }
                    .addOnFailureListener { result.error("unavailable", it.message, null) }
            }
    }

    /** True if [requestCode] was the scanner's. */
    fun onResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST) return false
        val result = pending ?: return true
        pending = null
        val uri = GmsDocumentScanningResult.fromActivityResultIntent(data)?.pdf?.uri
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return true
        }
        try {
            val out = File(activity.cacheDir, "scan-${System.currentTimeMillis()}.pdf")
            activity.contentResolver.openInputStream(uri)!!.use { input ->
                out.outputStream().use { input.copyTo(it) }
            }
            result.success(out.path)
        } catch (e: Exception) {
            result.error("scan_failed", e.message, null)
        }
        return true
    }

    private companion object {
        const val REQUEST = 7301
    }
}

/**
 * On-device text recognition for lab reports (ML Kit, Latin model bundled;
 * nothing leaves the phone). Same contract as ReportOcrPlugin in
 * ios/Runner/AppDelegate.swift: one string per printed row, top to bottom,
 * with the row's columns separated by two spaces.
 */
class ReportOcr(private val cacheDir: File) {
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val recognizer by lazy {
        TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
    }

    fun register(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, "vitalog/report_ocr")
            .setMethodCallHandler { call, result ->
                val data = call.argument<ByteArray>("data")
                if (call.method != "recognizeData" || data == null) {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val isPdf = call.argument<Boolean>("pdf") ?: false
                worker.execute {
                    try {
                        val lines = if (isPdf) recognizePdf(data) else rows(decodeUpright(data))
                        main.post { result.success(lines) }
                    } catch (e: Exception) {
                        main.post { result.error("ocr_failed", e.message, null) }
                    }
                }
            }
    }

    /** Decodes any image Android can read (JPEG, PNG, WebP, HEIC on 9+) and
     *  applies the photo's EXIF rotation so sideways shots read correctly. */
    private fun decodeUpright(data: ByteArray): Bitmap {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(data, 0, data.size, bounds)
        // Very large photos are halved until they fit; text stays legible.
        var sample = 1
        while (max(bounds.outWidth, bounds.outHeight) / sample > 4000) sample *= 2
        val bitmap = BitmapFactory.decodeByteArray(
            data, 0, data.size, BitmapFactory.Options().apply { inSampleSize = sample })
            ?: throw IllegalArgumentException("Unsupported image")
        val degrees = ExifInterface(ByteArrayInputStream(data)).rotationDegrees
        if (degrees == 0) return bitmap
        val matrix = Matrix().apply { postRotate(degrees.toFloat()) }
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    }

    /** Renders each page at ~3x (capped to keep memory bounded) and reads it. */
    private fun recognizePdf(data: ByteArray): List<String> {
        val lines = mutableListOf<String>()
        PdfRenderer(pdfDescriptor(data)).use { pdf ->
            for (index in 0 until pdf.pageCount) {
                pdf.openPage(index).use { page ->
                    val scale = min(3f, 4000f / max(page.width, page.height))
                    val bitmap = Bitmap.createBitmap(
                        (page.width * scale).toInt(), (page.height * scale).toInt(),
                        Bitmap.Config.ARGB_8888)
                    bitmap.eraseColor(Color.WHITE)
                    page.render(bitmap, null, Matrix().apply { setScale(scale, scale) },
                        PdfRenderer.Page.RENDER_MODE_FOR_PRINT)
                    lines += rows(bitmap)
                    bitmap.recycle()
                }
            }
        }
        return lines
    }

    /** PdfRenderer needs a seekable file descriptor. On Android 11+ that's an
     *  in-memory file, so the decrypted report never touches storage; older
     *  versions use a private cache file that's unlinked as soon as it's open. */
    private fun pdfDescriptor(data: ByteArray): ParcelFileDescriptor {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val fd = Os.memfd_create("report", 0)
            try {
                var written = 0
                while (written < data.size) written += Os.write(fd, data, written, data.size - written)
                Os.lseek(fd, 0, OsConstants.SEEK_SET)
                return ParcelFileDescriptor.dup(fd)
            } finally {
                Os.close(fd)
            }
        }
        val file = File.createTempFile("report", ".pdf", cacheDir)
        try {
            file.writeBytes(data)
            return ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
        } finally {
            file.delete()
        }
    }

    /** Groups recognised lines whose vertical centres line up into one printed
     *  row (left to right), rows top to bottom — same rule as the iOS plugin. */
    private fun rows(bitmap: Bitmap): List<String> {
        val text = Tasks.await(recognizer.process(InputImage.fromBitmap(bitmap, 0)))
        val pieces = text.textBlocks.flatMap { block ->
            block.lines.mapNotNull { line -> line.boundingBox?.let { it to line.text } }
        }.sortedBy { it.first.exactCenterY() }
        val grouped = mutableListOf<MutableList<Pair<Rect, String>>>()
        for (piece in pieces) {
            val first = grouped.lastOrNull()?.first()?.first
            if (first != null &&
                abs(first.exactCenterY() - piece.first.exactCenterY()) <
                min(first.height(), piece.first.height()) * 0.6f) {
                grouped.last() += piece
            } else {
                grouped += mutableListOf(piece)
            }
        }
        return grouped.map { row -> row.sortedBy { it.first.left }.joinToString("  ") { it.second } }
    }
}
