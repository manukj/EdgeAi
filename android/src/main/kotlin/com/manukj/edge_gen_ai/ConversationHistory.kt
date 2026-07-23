package com.manukj.edge_gen_ai

/**
 * Formats prior conversation turns and a new prompt into a single text
 * prompt for ML Kit's GenAI Prompt API, which has no native session/history
 * concept of its own — this is how Android fakes conversation memory.
 *
 * ponytail: trims oldest turns using a rough chars-per-token estimate (~4
 * chars/token) rather than exact counts, to avoid an extra `countTokens()`
 * round trip per turn. Ceiling: the real prompt may occasionally run a bit
 * over or under the intended budget. Upgrade path: use
 * `GenerativeModel.countTokens()` to trim precisely if that turns out to
 * matter in practice.
 */
object ConversationHistory {
    private const val CHARS_PER_TOKEN_ESTIMATE = 4
    private const val HISTORY_TOKEN_BUDGET = 2500
    private const val HISTORY_CHAR_BUDGET = HISTORY_TOKEN_BUDGET * CHARS_PER_TOKEN_ESTIMATE

    /**
     * Builds the prompt to send to the model: as many of the most recent
     * [history] turns (prompt to response pairs) as fit within the
     * character budget, followed by [newPrompt].
     */
    fun buildPrompt(
        history: List<Pair<String, String>>,
        newPrompt: String
    ): String {
        if (history.isEmpty()) return newPrompt

        val includedTurns = mutableListOf<Pair<String, String>>()
        var remainingBudget = HISTORY_CHAR_BUDGET
        for (turn in history.asReversed()) {
            val turnLength = turn.first.length + turn.second.length
            // Always keep at least the most recent turn, even if it alone
            // exceeds the budget.
            if (turnLength > remainingBudget && includedTurns.isNotEmpty()) break
            includedTurns.add(0, turn)
            remainingBudget -= turnLength
        }

        val historyText =
            includedTurns.joinToString(separator = "\n") { (prompt, response) ->
                "User: $prompt\nModel: $response"
            }
        return "$historyText\nUser: $newPrompt"
    }
}
