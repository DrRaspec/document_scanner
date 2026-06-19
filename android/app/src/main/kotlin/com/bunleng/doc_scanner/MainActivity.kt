package com.bunleng.doc_scanner

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.pdf.PdfRenderer
import android.media.ExifInterface
import android.os.Build
import android.os.ParcelFileDescriptor
import com.googlecode.tesseract.android.TessBaseAPI
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "doc_scanner/ocr"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "recognizeText" -> recognizeImageText(call, result)
                "recognizePdfText" -> recognizePdfText(call, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun recognizeImageText(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        val imagePath = call.argument<String>("imagePath")
        val dataPath = call.argument<String>("dataPath")
        val language = call.argument<String>("language") ?: "khm+eng"

        if (imagePath.isNullOrBlank() || dataPath.isNullOrBlank()) {
            result.error("INVALID_ARGS", "Missing image path or OCR data path.", null)
            return
        }

        Thread {
            val tessBaseApi = TessBaseAPI()
            try {
                val imageFile = File(imagePath)
                if (!imageFile.exists()) {
                    runOnUiThread {
                        result.error("FILE_MISSING", "The selected image file does not exist.", null)
                    }
                    return@Thread
                }

                if (!initializeTesseract(tessBaseApi, dataPath, language, result)) {
                    return@Thread
                }

                val bitmap = prepareImageForOcr(imageFile)
                val text = try {
                    tessBaseApi.setImage(bitmap)
                    tessBaseApi.getUTF8Text() ?: ""
                } finally {
                    bitmap.recycle()
                }

                runOnUiThread {
                    result.success(text)
                }
            } catch (error: Exception) {
                runOnUiThread {
                    result.error("OCR_FAILED", error.localizedMessage ?: "OCR failed.", null)
                }
            } finally {
                tessBaseApi.recycle()
            }
        }.start()
    }

    /**
     * Camera photos need more preparation than PDF pages. This method:
     * - applies the JPEG EXIF rotation;
     * - limits very large camera images to an OCR-friendly size;
     * - upscales unusually small images;
     * - removes colour and increases contrast so Khmer character marks remain clear.
     */
    private fun prepareImageForOcr(imageFile: File): Bitmap {
        val bounds = BitmapFactory.Options().apply {
            inJustDecodeBounds = true
        }
        BitmapFactory.decodeFile(imageFile.absolutePath, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) {
            throw IllegalArgumentException("The selected image could not be decoded.")
        }

        var sampleSize = 1
        val longestSourceEdge = maxOf(bounds.outWidth, bounds.outHeight)
        while (longestSourceEdge / (sampleSize * 2) >= MAX_OCR_EDGE) {
            sampleSize *= 2
        }

        val decoded = BitmapFactory.decodeFile(
            imageFile.absolutePath,
            BitmapFactory.Options().apply {
                inSampleSize = sampleSize
                inPreferredConfig = Bitmap.Config.ARGB_8888
            }
        ) ?: throw IllegalArgumentException("The selected image could not be decoded.")

        var working = rotateFromExif(decoded, imageFile)
        if (working !== decoded) {
            decoded.recycle()
        }

        val longestEdge = maxOf(working.width, working.height)
        val targetEdge = longestEdge.coerceIn(MIN_OCR_EDGE, MAX_OCR_EDGE)
        if (targetEdge != longestEdge) {
            val scale = targetEdge.toFloat() / longestEdge
            val scaled = Bitmap.createScaledBitmap(
                working,
                (working.width * scale).toInt().coerceAtLeast(1),
                (working.height * scale).toInt().coerceAtLeast(1),
                true
            )
            if (scaled !== working) {
                working.recycle()
                working = scaled
            }
        }

        val enhanced = Bitmap.createBitmap(
            working.width,
            working.height,
            Bitmap.Config.ARGB_8888
        )
        Canvas(enhanced).apply {
            drawColor(Color.WHITE)
            val contrast = 1.45f
            val offset = 128f * (1f - contrast)
            val filterMatrix = ColorMatrix().apply {
                setSaturation(0f)
                postConcat(
                    ColorMatrix(
                        floatArrayOf(
                            contrast, 0f, 0f, 0f, offset,
                            0f, contrast, 0f, 0f, offset,
                            0f, 0f, contrast, 0f, offset,
                            0f, 0f, 0f, 1f, 0f
                        )
                    )
                )
            }
            drawBitmap(
                working,
                0f,
                0f,
                Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG).apply {
                    colorFilter = ColorMatrixColorFilter(filterMatrix)
                }
            )
        }
        working.recycle()
        return enhanced
    }

    private fun rotateFromExif(bitmap: Bitmap, imageFile: File): Bitmap {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            return bitmap
        }

        val orientation = ExifInterface(imageFile.absolutePath).getAttributeInt(
            ExifInterface.TAG_ORIENTATION,
            ExifInterface.ORIENTATION_NORMAL
        )
        val matrix = Matrix()
        when (orientation) {
            ExifInterface.ORIENTATION_ROTATE_90 -> matrix.postRotate(90f)
            ExifInterface.ORIENTATION_ROTATE_180 -> matrix.postRotate(180f)
            ExifInterface.ORIENTATION_ROTATE_270 -> matrix.postRotate(270f)
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.postScale(-1f, 1f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> matrix.postScale(1f, -1f)
            ExifInterface.ORIENTATION_TRANSPOSE -> {
                matrix.postScale(-1f, 1f)
                matrix.postRotate(270f)
            }
            ExifInterface.ORIENTATION_TRANSVERSE -> {
                matrix.postScale(-1f, 1f)
                matrix.postRotate(90f)
            }
            else -> return bitmap
        }

        return Bitmap.createBitmap(
            bitmap,
            0,
            0,
            bitmap.width,
            bitmap.height,
            matrix,
            true
        )
    }

    private fun recognizePdfText(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        val pdfPath = call.argument<String>("pdfPath")
        val dataPath = call.argument<String>("dataPath")
        val language = call.argument<String>("language") ?: "khm+eng"

        if (pdfPath.isNullOrBlank() || dataPath.isNullOrBlank()) {
            result.error("INVALID_ARGS", "Missing PDF path or OCR data path.", null)
            return
        }

        Thread {
            val tessBaseApi = TessBaseAPI()
            var descriptor: ParcelFileDescriptor? = null
            var renderer: PdfRenderer? = null
            try {
                val pdfFile = File(pdfPath)
                if (!pdfFile.exists()) {
                    runOnUiThread {
                        result.error("FILE_MISSING", "The selected PDF file does not exist.", null)
                    }
                    return@Thread
                }

                if (!initializeTesseract(tessBaseApi, dataPath, language, result)) {
                    return@Thread
                }

                descriptor = ParcelFileDescriptor.open(pdfFile, ParcelFileDescriptor.MODE_READ_ONLY)
                renderer = PdfRenderer(descriptor)
                val text = StringBuilder()

                for (index in 0 until renderer.pageCount) {
                    val page = renderer.openPage(index)
                    try {
                        val scale = 4
                        val bitmap = Bitmap.createBitmap(
                            page.width * scale,
                            page.height * scale,
                            Bitmap.Config.ARGB_8888
                        )
                        Canvas(bitmap).drawColor(Color.WHITE)
                        page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                        tessBaseApi.setImage(bitmap)
                        val pageText = tessBaseApi.getUTF8Text()?.trim().orEmpty()
                        if (pageText.isNotEmpty()) {
                            if (text.isNotEmpty()) {
                                text.append("\n\n")
                            }
                            text.append(pageText)
                        }
                        bitmap.recycle()
                    } finally {
                        page.close()
                    }
                }

                runOnUiThread {
                    result.success(text.toString())
                }
            } catch (error: Exception) {
                runOnUiThread {
                    result.error("OCR_FAILED", error.localizedMessage ?: "PDF OCR failed.", null)
                }
            } finally {
                renderer?.close()
                descriptor?.close()
                tessBaseApi.recycle()
            }
        }.start()
    }

    private fun initializeTesseract(
        tessBaseApi: TessBaseAPI,
        dataPath: String,
        language: String,
        result: MethodChannel.Result
    ): Boolean {
        val initialized = tessBaseApi.init(dataPath, language, TessBaseAPI.OEM_LSTM_ONLY)
        if (!initialized) {
            runOnUiThread {
                result.error("OCR_INIT_FAILED", "OCR language data could not be initialized.", null)
            }
            return false
        }

        tessBaseApi.setPageSegMode(TessBaseAPI.PageSegMode.PSM_AUTO)
        return true
    }

    companion object {
        private const val MIN_OCR_EDGE = 2200
        private const val MAX_OCR_EDGE = 3600
    }
}
