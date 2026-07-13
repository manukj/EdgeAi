package com.example.edge_ai

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

internal class ConversationHistoryTest {
    @Test
    fun buildPrompt_withoutHistory_returnsPromptUnchanged() {
        assertEquals("Hello", ConversationHistory.buildPrompt(emptyList(), "Hello"))
    }

    @Test
    fun buildPrompt_withHistory_prependsTurns() {
        val history = listOf("Hi" to "Hello there")

        val prompt = ConversationHistory.buildPrompt(history, "How are you?")

        assertEquals("User: Hi\nModel: Hello there\nUser: How are you?", prompt)
    }

    @Test
    fun buildPrompt_overBudget_dropsOldestTurnsButKeepsMostRecent() {
        val longText = "x".repeat(6000)
        val history = listOf(
            "old prompt" to "old response",
            longText to longText,
        )

        val prompt = ConversationHistory.buildPrompt(history, "new prompt")

        assertTrue(prompt.contains(longText))
        assertTrue(!prompt.contains("old prompt"))
    }
}
