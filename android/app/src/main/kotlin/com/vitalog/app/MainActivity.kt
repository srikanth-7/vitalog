package com.vitalog.app

import android.app.Activity
import android.app.KeyguardManager
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.Rect
import android.graphics.pdf.PdfRenderer
import android.hardware.biometrics.BiometricManager.Authenticators
import android.hardware.biometrics.BiometricPrompt
import android.os.Build
import android.os.CancellationSignal
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.system.Os
import android.system.OsConstants
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyPermanentlyInvalidatedException
import android.security.keystore.KeyProperties
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
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import java.util.concurrent.Executors
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

class MainActivity : FlutterActivity() {
    private val scanner = DocumentScanner(this)

    // Hides health data from Recents (security audit #2). Android 13+ can
    // drop just the Recents thumbnail; older versions only have FLAG_SECURE,
    // which also blocks screenshots of the app.
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= 33) {
            setRecentsScreenshotEnabled(false)
        } else {
            window.addFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ReportOcr(cacheDir).register(flutterEngine)
        scanner.register(flutterEngine)
        VaultKey(this).register(flutterEngine)
        // "Open Settings" after a permission was refused: straight to this
        // app's page (its Notifications page when that's what is off).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "vitalog/app_settings")
            .setMethodCallHandler { call, result ->
                val intent = if (call.arguments == "notifications" && Build.VERSION.SDK_INT >= 26) {
                    Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                        .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                } else {
                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", packageName, null))
                }
                startActivity(intent)
                result.success(null)
            }
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

/**
 * The Android half of the vault (ReportCipher.vault on the Dart side; on
 * iOS the Keychain's userPresence does this). A Keystore AES key that only
 * works right after a fingerprint / face (strong) or the screen-lock PIN,
 * pattern or password, for each single use. It never leaves the security
 * chip; it only wraps and unwraps the app's own vault key.
 *
 * Unlike flutter_secure_storage's biometric mode, enrolling a new
 * fingerprint does NOT destroy it (that would lose every stored original).
 * Removing the screen lock does — Android's rule, same as the iPhone.
 *
 * Android 11+ only (CryptoObject with PIN fallback); older phones report
 * "unavailable" and keep the unprompted key.
 *
 * Channel "vitalog/vault_key": wrap / unwrap(data, title, subtitle) → bytes. Errors: "cancelled", "invalidated" (screen lock
 * was removed: the key is gone), "failed".
 */
class VaultKey(private val activity: Activity) {
    fun register(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, "vitalog/vault_key")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "wrap", "unwrap" -> {
                        val data = call.argument<ByteArray>("data")!!
                        val title = call.argument<String>("title")!!
                        val subtitle = call.argument<String>("subtitle")!!
                        if (!available()) {
                            result.error("failed", "No screen lock or Android < 11", null)
                        } else if (call.method == "wrap") {
                            wrap(data, title, subtitle, result)
                        } else {
                            unwrap(data, title, subtitle, result)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun available() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.R &&
        activity.getSystemService(KeyguardManager::class.java).isDeviceSecure

    /** Output: 12-byte GCM nonce, then ciphertext + tag. */
    private fun wrap(data: ByteArray, title: String, subtitle: String, result: MethodChannel.Result) {
        val cipher = Cipher.getInstance(TRANSFORM)
        try {
            cipher.init(Cipher.ENCRYPT_MODE, key(create = true))
        } catch (e: KeyPermanentlyInvalidatedException) {
            // Wrapping happens only when nothing is wrapped yet: start over.
            keyStore().deleteEntry(ALIAS)
            cipher.init(Cipher.ENCRYPT_MODE, key(create = true))
        }
        authenticate(cipher, title, subtitle, result) { it.iv + it.doFinal(data) }
    }

    private fun unwrap(data: ByteArray, title: String, subtitle: String, result: MethodChannel.Result) {
        val key = key(create = false)
            ?: return result.error("invalidated", "Vault key is gone", null)
        val cipher = Cipher.getInstance(TRANSFORM)
        try {
            cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(128, data, 0, 12))
        } catch (e: KeyPermanentlyInvalidatedException) {
            return result.error("invalidated", "Screen lock was removed", null)
        }
        authenticate(cipher, title, subtitle, result) { it.doFinal(data, 12, data.size - 12) }
    }

    private fun authenticate(
        cipher: Cipher, title: String, subtitle: String,
        result: MethodChannel.Result, use: (Cipher) -> ByteArray,
    ) {
        BiometricPrompt.Builder(activity)
            .setTitle(title)
            .setSubtitle(subtitle)
            .setAllowedAuthenticators(Authenticators.BIOMETRIC_STRONG or Authenticators.DEVICE_CREDENTIAL)
            .build()
            .authenticate(
                BiometricPrompt.CryptoObject(cipher), CancellationSignal(), activity.mainExecutor,
                object : BiometricPrompt.AuthenticationCallback() {
                    override fun onAuthenticationSucceeded(r: BiometricPrompt.AuthenticationResult) {
                        try {
                            result.success(use(r.cryptoObject!!.cipher!!))
                        } catch (e: Exception) {
                            result.error("failed", e.message, null)
                        }
                    }

                    // A wrong finger isn't final (onAuthenticationFailed); this is.
                    override fun onAuthenticationError(code: Int, message: CharSequence) {
                        val cancelled = code == BiometricPrompt.BIOMETRIC_ERROR_USER_CANCELED ||
                            code == BiometricPrompt.BIOMETRIC_ERROR_CANCELED
                        result.error(if (cancelled) "cancelled" else "failed", message.toString(), null)
                    }
                },
            )
    }

    private fun keyStore() = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }

    private fun key(create: Boolean): SecretKey? {
        (keyStore().getKey(ALIAS, null) as SecretKey?)?.let { return it }
        if (!create) return null
        val spec = KeyGenParameterSpec.Builder(
            ALIAS, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
            .setUserAuthenticationRequired(true)
            // 0 = every single use needs its own unlock.
            .setUserAuthenticationParameters(
                0, KeyProperties.AUTH_BIOMETRIC_STRONG or KeyProperties.AUTH_DEVICE_CREDENTIAL,
            )
            .setInvalidatedByBiometricEnrollment(false)
            .setUnlockedDeviceRequired(true)
            .build()
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
            .apply { init(spec) }
            .generateKey()
    }

    private companion object {
        // Named like the Keychain entries (fammo.*); never rename.
        const val ALIAS = "fammo.vault.wrap.v1"
        const val TRANSFORM = "AES/GCM/NoPadding"
    }
}
