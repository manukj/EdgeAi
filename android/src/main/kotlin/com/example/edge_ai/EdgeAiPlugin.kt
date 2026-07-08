package com.example.edge_ai

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

/** EdgeAiPlugin */
class EdgeAiPlugin :
    FlutterPlugin,
    EdgeAiHostApi {
    private var pluginBinding: FlutterPlugin.FlutterPluginBinding? = null
    private val scope = CoroutineScope(Dispatchers.Main)
    private val generativeModel by lazy { Generation.getClient() }
    private var pendingPrompt: String? = null
    private var pendingOptions: EdgeAiGenerationOptions? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        pluginBinding = flutterPluginBinding
        EdgeAiHostApi.setUp(flutterPluginBinding.binaryMessenger, this)
        DownloadProgressStreamHandler.register(
            flutterPluginBinding.binaryMessenger,
            EdgeAiDownloadProgressStreamHandler(scope, generativeModel),
        )
        GenerateContentChunkStreamHandler.register(
            flutterPluginBinding.binaryMessenger,
            EdgeAiGenerateContentStreamHandler(scope, generativeModel) {
                pendingPrompt?.let { it to pendingOptions }
            },
        )
    }

    override fun checkAvailability(callback: (Result<EdgeAiAvailability>) -> Unit) {
        scope.launch {
            val availability =
                try {
                    when (generativeModel.checkStatus()) {
                        FeatureStatus.AVAILABLE -> EdgeAiAvailability.AVAILABLE
                        FeatureStatus.DOWNLOADABLE, FeatureStatus.DOWNLOADING ->
                            EdgeAiAvailability.DOWNLOADABLE
                        else -> EdgeAiAvailability.UNAVAILABLE
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
        options: EdgeAiGenerationOptions?
    ) {
        pendingPrompt = prompt
        pendingOptions = options
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        pluginBinding?.let { EdgeAiHostApi.setUp(it.binaryMessenger, null) }
        pluginBinding = null
    }
}

/** Triggers the Gemini Nano download when Flutter starts listening, and streams its progress. */
private class EdgeAiDownloadProgressStreamHandler(
    private val scope: CoroutineScope,
    private val generativeModel: GenerativeModel
) : DownloadProgressStreamHandler() {
    override fun onListen(
        p0: Any?,
        sink: PigeonEventSink<EdgeAiDownloadProgress>
    ) {
        scope.launch {
            generativeModel.download().collect { status ->
                when (status) {
                    is DownloadStatus.DownloadStarted ->
                        sink.success(
                            EdgeAiDownloadProgress(EdgeAiDownloadStatus.STARTED, null)
                        )
                    is DownloadStatus.DownloadProgress ->
                        sink.success(
                            EdgeAiDownloadProgress(
                                EdgeAiDownloadStatus.IN_PROGRESS,
                                status.totalBytesDownloaded
                            )
                        )
                    is DownloadStatus.DownloadCompleted -> {
                        sink.success(
                            EdgeAiDownloadProgress(EdgeAiDownloadStatus.COMPLETED, null)
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
private class EdgeAiGenerateContentStreamHandler(
    private val scope: CoroutineScope,
    private val generativeModel: GenerativeModel,
    private val takePendingRequest: () -> Pair<String, EdgeAiGenerationOptions?>?
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
