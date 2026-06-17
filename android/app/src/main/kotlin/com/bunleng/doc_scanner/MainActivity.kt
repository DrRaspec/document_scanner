package com.bunleng.doc_scanner

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
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

                tessBaseApi.setImage(imageFile)
                val text = tessBaseApi.getUTF8Text() ?: ""

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
}
