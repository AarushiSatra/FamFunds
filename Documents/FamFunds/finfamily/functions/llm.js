const Anthropic = require('@anthropic-ai/sdk');

/**
 * Converts rule-engine output (structured, numeric "slots") into
 * plain-language suggestions. The LLM never invents or recomputes
 * any figure — it only explains numbers the rule engine already produced.
 */
async function explainInvestmentSlots(client, slots) {
  if (!slots.length) return [];

  const prompt = `You are FinFamily's financial explanation assistant. You will be given
a JSON array of investment suggestion "slots". Each slot already contains
every number you're allowed to use — do NOT invent, estimate, or recompute
any figure. Your only job is to write, for each slot:
- "title": a short action-oriented title (under 8 words)
- "description": 1 sentence, plain language, using the exact numbers given
- "aiRationale": 1-2 sentences explaining WHY this makes sense, referencing
  the specific facts provided

Respond with ONLY a JSON array, same length and order as the input, each
element shaped exactly like:
{"title": "...", "description": "...", "riskLevel": "...", "aiRationale": "..."}

Copy "riskLevel" directly from the input slot unchanged.

Input slots:
${JSON.stringify(slots, null, 2)}`;

  const response = await client.messages.create({
    model: 'claude-sonnet-4-6',
    max_tokens: 1000,
    messages: [{ role: 'user', content: prompt }],
  });

  const text = response.content
    .filter((block) => block.type === 'text')
    .map((block) => block.text)
    .join('\n');

  const cleaned = text.replace(/```json|```/g, '').trim();

  try {
    const parsed = JSON.parse(cleaned);
    if (!Array.isArray(parsed)) throw new Error('LLM response was not an array');
    return parsed;
  } catch (err) {
    console.error('Failed to parse LLM response:', err, text);
    return slots.map((slot) => ({
      title: slot.type.replace(/_/g, ' '),
      description: `Based on your linked account data: ${JSON.stringify(slot.facts)}`,
      riskLevel: slot.riskLevel,
      aiRationale: 'Generated from your financial data.',
    }));
  }
}

module.exports = { explainInvestmentSlots };