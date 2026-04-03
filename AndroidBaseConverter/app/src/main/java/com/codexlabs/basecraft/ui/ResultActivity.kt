package com.codexlabs.basecraft.ui

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.codexlabs.basecraft.databinding.ActivityResultBinding

class ResultActivity : AppCompatActivity() {

    private lateinit var binding: ActivityResultBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityResultBinding.inflate(layoutInflater)
        setContentView(binding.root)

        val input = intent.getStringExtra(EXTRA_INPUT).orEmpty()
        val output = intent.getStringExtra(EXTRA_OUTPUT).orEmpty()
        val source = intent.getStringExtra(EXTRA_SOURCE).orEmpty()
        val target = intent.getStringExtra(EXTRA_TARGET).orEmpty()

        binding.backButton.setOnClickListener { finish() }
        binding.mapText.text = "$source → $target"
        binding.inputValue.text = input
        binding.outputValue.text = output

        binding.copyButton.setOnClickListener {
            val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            clipboard.setPrimaryClip(ClipData.newPlainText("converted_result", output))
            Toast.makeText(this, "Result copied", Toast.LENGTH_SHORT).show()
        }
    }

    companion object {
        const val EXTRA_INPUT = "extra_input"
        const val EXTRA_OUTPUT = "extra_output"
        const val EXTRA_SOURCE = "extra_source"
        const val EXTRA_TARGET = "extra_target"
    }
}
