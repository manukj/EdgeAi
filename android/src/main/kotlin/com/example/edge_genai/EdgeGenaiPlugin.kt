package com.example.edge_genai

import com.google.mlkit.genai.common.DownloadStatus
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.prompt.Generation
import com.google.mlkit.genai.prompt.GenerativeModel
import io.flutter.embedding.engine.plugins.FlutterPlugin
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/** EdgeGenaiPlugin */
class EdgeGenaiPlugin :
    FlutterPlugin,
    EdgeGenaiHostApi {
    private var pluginBinding: FlutterPlugin.FlutterPluginBinding? = null
    private val scope = CoroutineScope(Dispatchers.Main)
    private val generativeModel by lazy { Generation.getClient() }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        pluginBinding = flutterPluginBinding
        EdgeGenaiHostApi.setUp(flutterPluginBinding.binaryMessenger, this)
        DownloadProgressStreamHandler.register(
            flutterPluginBinding.binaryMessenger,
            EdgeGenaiDownloadProgressStreamHandler(scope, generativeModel),
        )
    }

    override fun checkAvailability(callback: (Result<EdgeGenaiAvailability>) -> Unit) {
        scope.launch {
            val availability =
                try {
                    when (generativeModel.checkStatus()) {
                        FeatureStatus.AVAILABLE -> EdgeGenaiAvailability.AVAILABLE
                        FeatureStatus.DOWNLOADABLE, FeatureStatus.DOWNLOADING ->
                            EdgeGenaiAvailability.DOWNLOADABLE
                        else -> EdgeGenaiAvailability.UNAVAILABLE
                    }
                } catch (e: Exception) {
                    callback(Result.failure(e))
                    return@launch
                }
            callback(Result.success(availability))
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        pluginBinding?.let { EdgeGenaiHostApi.setUp(it.binaryMessenger, null) }
        pluginBinding = null
    }

    override fun generateContent(
        prompt: String,
        callback: (Result<String>) -> Unit
    ) {
        scope.launch {
            try {
                val response = generativeModel.generateContent(prompt)
                callback(Result.success(response.candidates.first().text))
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
    }
}

/** Triggers the Gemini Nano download when Flutter starts listening, and streams its progress. */
private class EdgeGenaiDownloadProgressStreamHandler(
    private val scope: CoroutineScope,
    private val generativeModel: GenerativeModel
) : DownloadProgressStreamHandler() {
    override fun onListen(
        p0: Any?,
        sink: PigeonEventSink<EdgeGenaiDownloadProgress>
    ) {
        scope.launch {
            generativeModel.download().collect { status ->
                when (status) {
                    is DownloadStatus.DownloadStarted ->
                        sink.success(
                            EdgeGenaiDownloadProgress(EdgeGenaiDownloadStatus.STARTED, null)
                        )
                    is DownloadStatus.DownloadProgress ->
                        sink.success(
                            EdgeGenaiDownloadProgress(
                                EdgeGenaiDownloadStatus.IN_PROGRESS,
                                status.totalBytesDownloaded
                            )
                        )
                    is DownloadStatus.DownloadCompleted -> {
                        sink.success(
                            EdgeGenaiDownloadProgress(EdgeGenaiDownloadStatus.COMPLETED, null)
                        )
                        sink.endOfStream()
                    }
                    is DownloadStatus.DownloadFailed ->
                        sink.error("download_failed", status.e.message, null)
                }
            }
        }
    }
}
