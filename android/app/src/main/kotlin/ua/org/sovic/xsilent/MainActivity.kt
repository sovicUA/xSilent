package ua.org.sovic.xsilent

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val store = SoundStore(applicationContext)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "xsilent/sound_store")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "put" -> result.success(
                            store.put(call.argument("name")!!, call.argument("path")!!)
                        )
                        "pruneExcept" -> {
                            store.pruneExcept(call.argument("prefix")!!, call.argument("keep"))
                            result.success(null)
                        }
                        "deleteAll" -> {
                            store.deleteAll(call.argument("prefix")!!)
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("sound_store_error", e.message, null)
                }
            }
    }
}
