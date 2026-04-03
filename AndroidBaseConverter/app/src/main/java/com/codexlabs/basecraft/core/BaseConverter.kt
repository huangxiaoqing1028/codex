package com.codexlabs.basecraft.core

enum class BaseType(val radix: Int, val label: String) {
    BINARY(2, "Binary"),
    OCTAL(8, "Octal"),
    DECIMAL(10, "Decimal"),
    HEX(16, "Hex")
}

object BaseConverter {
    fun convert(input: String, source: BaseType, target: BaseType): String? {
        val value = input.trim()
        if (value.isEmpty()) return null

        val regex = when (source) {
            BaseType.BINARY -> Regex("^[01]+$")
            BaseType.OCTAL -> Regex("^[0-7]+$")
            BaseType.DECIMAL -> Regex("^[0-9]+$")
            BaseType.HEX -> Regex("^[0-9a-fA-F]+$")
        }

        if (!regex.matches(value)) return null

        val decimal = value.toLongOrNull(source.radix) ?: return null
        return decimal.toString(target.radix).uppercase()
    }
}
