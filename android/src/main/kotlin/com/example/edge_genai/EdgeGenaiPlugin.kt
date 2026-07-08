package com.example.edge_genai

import com.google.mlkit.genai.common.DownloadStatus
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.prompt.Generation
import com.google.mlkit.genai.prompt.GenerativeModel
import com.google.mlkit.genai.prompt.TextPart
import com.google.mlkit.genai.prompt.generateContentRequest
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
    private var pendingPrompt: String? = null
    private var pendingOptions: EdgeGenaiGenerationOptions? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        pluginBinding = flutterPluginBinding
        EdgeGenaiHostApi.setUp(flutterPluginBinding.binaryMessenger, this)
        DownloadProgressStreamHandler.register(
            flutterPluginBinding.binaryMessenger,
            EdgeGenaiDownloadProgressStreamHandler(scope, generativeModel),
        )
        GenerateContentChunkStreamHandler.register(
            flutterPluginBinding.binaryMessenger,
            EdgeGenaiGenerateContentStreamHandler(scope, generativeModel) {
                pendingPrompt?.let { it to pendingOptions }
            },
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

    override fun startGenerateContent(
        prompt: String,
        options: EdgeGenaiGenerationOptions?
    ) {
        pendingPrompt = prompt
        pendingOptions = options
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        pluginBinding?.let { EdgeGenaiHostApi.setUp(it.binaryMessenger, null) }
        pluginBinding = null
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

/**
 * Starts generation for the prompt/options stashed via `startGenerateContent` when Flutter
 * starts listening, and streams the cumulative response text as it's generated.
 */
private class EdgeGenaiGenerateContentStreamHandler(
    private val scope: CoroutineScope,
    private val generativeModel: GenerativeModel,
    private val takePendingRequest: () -> Pair<String, EdgeGenaiGenerationOptions?>?
) : GenerateContentChunkStreamHandler() {
    override fun onListen(
        p0: Any?,
        sink: PigeonEventSink<String>
    ) {
        val (prompt, options) =
            takePendingRequest() ?: run {
                sink.error(
                    "no_prompt",
                    "startGenerateContent must be called before listening.",
                    null
                )
                return
            }
        val request =
            generateContentRequest(TextPart(prompt)) {
                options?.temperature?.let { temperature = it.toFloat() }
                options?.maxOutputTokens?.let { maxOutputTokens = it.toInt() }
            }
        scope.launch {
            try {
                var cumulativeText = ""
                generativeModel.generateContentStream(request).collect { response ->
                    cumulativeText += response.candidates.first().text
                    sink.success(cumulativeText)
                }
                sink.endOfStream()
            } catch (e: Exception) {
                sink.error("generate_content_failed", e.message, null)
            }
        }
    }
}
