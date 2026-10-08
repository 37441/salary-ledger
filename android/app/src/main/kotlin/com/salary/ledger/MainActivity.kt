package com.salary.ledger

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.salary.ledger/legacy")
            .setMethodCallHandler { call, result ->
                if (call.method == "readLegacyData") {
                    val prefs = getSharedPreferences("salary_ledger_data", Context.MODE_PRIVATE)
                    result.success(
                        mapOf(
                            "baseSalary" to Double.fromBits(prefs.getLong("baseSalary", 0)),
                            "performanceRate" to Double.fromBits(prefs.getLong("performanceRate", 0)),
                            "theme" to prefs.getInt("theme", 0),
                            "records" to (prefs.getString("records", "") ?: ""),
                            "deductions" to (prefs.getString("deductions", "") ?: ""),
                            "subsidies" to (prefs.getString("subsidies", "") ?: ""),
                        )
                    )
                } else {
                    result.notImplemented()
                }
            }
    }
}
