package com.bunleng.doc_scanner

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
            if (call.method != "recognizeText") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val imagePath = call.argument<String>("imagePath")
            val dataPath = call.argument<String>("dataPath")
            val language = call.argument<String>("language") ?: "khm+eng"

            if (imagePath.isNullOrBlank() || dataPath.isNullOrBlank()) {
                result.error("INVALID_ARGS", "Missing image path or OCR data path.", null)
                return@setMethodCallHandler
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

                    val initialized = tessBaseApi.init(dataPath, language, TessBaseAPI.OEM_LSTM_ONLY)
                    if (!initialized) {
                        runOnUiThread {
                            result.error("OCR_INIT_FAILED", "OCR language data could not be initialized.", null)
                        }
                        return@Thread
                    }

                    tessBaseApi.setPageSegMode(TessBaseAPI.PageSegMode.PSM_AUTO)
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
    }
}
