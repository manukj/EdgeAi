package com.example.edge_ai

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

internal class ToolPromptingTest {
    private val weatherTool =
        EdgeGenAIToolDefinition(
            name = "get_weather",
            descriptionText = "Gets the current weather for a city.",
            parameters =
                listOf(
                    EdgeGenAIToolParameterDefinition(
                        name = "city",
                        descriptionText = "The city to get the weather for.",
                        type = EdgeGenAIToolParameterType.STRING,
                        isRequired = true,
                    )
                ),
        )

    @Test
    fun buildToolPreamble_describesToolAndParameters() {
        val preamble = ToolPrompting.buildToolPreamble(listOf(weatherTool))

        assertTrue(preamble.contains("get_weather"))
        assertTrue(preamble.contains("Gets the current weather for a city."))
        assertTrue(preamble.contains("\"city\" (string)"))
        assertTrue(preamble.contains("{\"tool\":"))
    }

    @Test
    fun parseToolCall_plainAnswer_returnsNull() {
        assertNull(
            ToolPrompting.parseToolCall("The weather is sunny.", listOf(weatherTool))
        )
    }

    @Test
    fun parseToolCall_unknownTool_returnsNull() {
        assertNull(
            ToolPrompting.parseToolCall(
                "{\"tool\": \"send_email\", \"arguments\": {}}",
                listOf(weatherTool),
            )
        )
    }

    @Test
    fun parseToolCall_validCall_returnsNameAndArguments() {
        val call =
            ToolPrompting.parseToolCall(
                "{\"tool\": \"get_weather\", \"arguments\": {\"city\": \"Oslo\"}}",
                listOf(weatherTool),
            )

        assertEquals("get_weather", call?.toolName)
        assertTrue(call!!.argumentsJson.contains("Oslo"))
    }

    @Test
    fun parseToolCall_toleratesCodeFenceAndTrailingText() {
        val call =
            ToolPrompting.parseToolCall(
                "```json\n{\"tool\": \"get_weather\", \"arguments\": " +
                    "{\"city\": \"Oslo\"}}\n```\nI'll check that for you.",
                listOf(weatherTool),
            )

        assertEquals("get_weather", call?.toolName)
    }

    @Test
    fun parseToolCall_bracesInsideStrings_doNotConfuseParser() {
        val call =
            ToolPrompting.parseToolCall(
                "{\"tool\": \"get_weather\", \"arguments\": {\"city\": \"O{s}lo\"}} extra",
                listOf(weatherTool),
            )

        assertEquals("get_weather", call?.toolName)
        assertTrue(call!!.argumentsJson.contains("O{s}lo"))
    }

    @Test
    fun parseToolCall_missingArguments_defaultsToEmptyObject() {
        val call =
            ToolPrompting.parseToolCall(
                "{\"tool\": \"get_weather\"}",
                listOf(weatherTool),
            )

        assertEquals("{}", call?.argumentsJson)
    }
}
