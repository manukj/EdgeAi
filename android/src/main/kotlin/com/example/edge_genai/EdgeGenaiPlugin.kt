package com.example.edge_genai

import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.prompt.Generation
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
}
