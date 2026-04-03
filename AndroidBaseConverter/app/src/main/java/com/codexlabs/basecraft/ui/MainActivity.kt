package com.codexlabs.basecraft.ui

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.codexlabs.basecraft.R
import com.codexlabs.basecraft.core.BaseConverter
import com.codexlabs.basecraft.core.BaseType
import com.codexlabs.basecraft.databinding.ActivityMainBinding
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding
    private val history = mutableListOf<ConversionRecord>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        binding.fromGroup.check(binding.fromDecimal.id)
        binding.toGroup.check(binding.toBinary.id)

        binding.swapButton.setOnClickListener {
            val from = checkedBase(isFrom = true)
            val to = checkedBase(isFrom = false)
            binding.fromGroup.check(idForBase(to, isFrom = true))
            binding.toGroup.check(idForBase(from, isFrom = false))
        }

        binding.clearButton.setOnClickListener {
            binding.inputEdit.setText("")
            binding.errorText.text = ""
        }

        binding.convertButton.setOnClickListener {
            val source = checkedBase(isFrom = true)
            val target = checkedBase(isFrom = false)
            val input = binding.inputEdit.text.toString()
            val result = BaseConverter.convert(input, source, target)

            if (result == null) {
                binding.errorText.text = "Invalid value for ${source.label}"
                return@setOnClickListener
            }

            binding.errorText.text = ""
            history.add(0, ConversionRecord(input, result, source, target, Date()))
            renderHistory()

            startActivity(
                Intent(this, ResultActivity::class.java)
                    .putExtra(ResultActivity.EXTRA_INPUT, input)
                    .putExtra(ResultActivity.EXTRA_OUTPUT, result)
                    .putExtra(ResultActivity.EXTRA_SOURCE, source.label)
                    .putExtra(ResultActivity.EXTRA_TARGET, target.label)
            )
        }

        renderHistory()
    }

    private fun renderHistory() {
        binding.historyContainer.removeAllViews()

        if (history.isEmpty()) {
            binding.emptyHistory.visibility = View.VISIBLE
            return
        }

        binding.emptyHistory.visibility = View.GONE
        val formatter = SimpleDateFormat("HH:mm", Locale.getDefault())

        history.take(5).forEach { record ->
            val item = layoutInflater.inflate(R.layout.item_history, binding.historyContainer, false)
            item.findViewById<TextView>(R.id.historyLine1).text =
                "${record.input} ${record.source.label} → ${record.target.label}"
            item.findViewById<TextView>(R.id.historyLine2).text = record.output
            item.findViewById<TextView>(R.id.historyTime).text = formatter.format(record.time)

            item.setOnClickListener {
                binding.inputEdit.setText(record.input)
                binding.fromGroup.check(idForBase(record.source, isFrom = true))
                binding.toGroup.check(idForBase(record.target, isFrom = false))
            }
            binding.historyContainer.addView(item)
        }
    }

    private fun checkedBase(isFrom: Boolean): BaseType {
        val checkedId = if (isFrom) binding.fromGroup.checkedRadioButtonId else binding.toGroup.checkedRadioButtonId
        return when (checkedId) {
            binding.fromBinary.id, binding.toBinary.id -> BaseType.BINARY
            binding.fromOctal.id, binding.toOctal.id -> BaseType.OCTAL
            binding.fromDecimal.id, binding.toDecimal.id -> BaseType.DECIMAL
            else -> BaseType.HEX
        }
    }

    private fun idForBase(base: BaseType, isFrom: Boolean): Int {
        return when (base) {
            BaseType.BINARY -> if (isFrom) binding.fromBinary.id else binding.toBinary.id
            BaseType.OCTAL -> if (isFrom) binding.fromOctal.id else binding.toOctal.id
            BaseType.DECIMAL -> if (isFrom) binding.fromDecimal.id else binding.toDecimal.id
            BaseType.HEX -> if (isFrom) binding.fromHex.id else binding.toHex.id
        }
    }
}

data class ConversionRecord(
    val input: String,
    val output: String,
    val source: BaseType,
    val target: BaseType,
    val time: Date
)
