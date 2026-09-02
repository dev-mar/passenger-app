package com.taxitexi.texi_passenger_app

import android.accounts.AccountManager
import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val emailChannel = "texi_passenger/device_email"
    private val reqPickAccount = 4402
    private var pendingEmailResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, emailChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "pickEmail") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (pendingEmailResult != null) {
                    result.success(null)
                    return@setMethodCallHandler
                }
                pendingEmailResult = result
                try {
                    val intent = AccountManager.newChooseAccountIntent(
                        null,
                        null,
                        arrayOf("com.google"),
                        false,
                        null,
                        null,
                        null,
                        null
                    )
                    startActivityForResult(intent, reqPickAccount)
                } catch (_: Exception) {
                    pendingEmailResult = null
                    result.success(null)
                }
            }
    }

    @Deprecated("Used for Google account email picker")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != reqPickAccount) return
        val pending = pendingEmailResult
        pendingEmailResult = null
        if (resultCode != Activity.RESULT_OK || data == null) {
            pending?.success(null)
            return
        }
        pending?.success(data.getStringExtra(AccountManager.KEY_ACCOUNT_NAME))
    }
}
