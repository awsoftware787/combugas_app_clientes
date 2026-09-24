package com.example.combugas_clientes

import android.os.Bundle
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val content = findViewById<android.view.View>(android.R.id.content)
        var keyboardWasVisible = false
        ViewCompat.setOnApplyWindowInsetsListener(content) { _, insets ->
            val keyboardVisible = insets.isVisible(WindowInsetsCompat.Type.ime())
            if (keyboardWasVisible && !keyboardVisible) {
                // Older Android versions delay system UI changes after closing the IME.
                content.postDelayed({ hideNavigationBar() }, 1100)
            }
            keyboardWasVisible = keyboardVisible
            insets
        }
        window.decorView.post { hideNavigationBar() }
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) hideNavigationBar()
    }

    private fun hideNavigationBar() {
        if (isFinishing || isDestroyed) return
        WindowCompat.getInsetsController(window, window.decorView).apply {
            systemBarsBehavior =
                WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            hide(WindowInsetsCompat.Type.navigationBars())
        }
    }
}
