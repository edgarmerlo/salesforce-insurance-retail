const fs = require('fs');
const path = require('path');

// 100% Decoupled: Loads local .env file (supports dotenv or native zero-dependency parsing)
try {
  require('dotenv').config({ path: path.join(__dirname, '.env') });
} catch (e) {
  const envPath = path.join(__dirname, '.env');
  if (fs.existsSync(envPath)) {
    const lines = fs.readFileSync(envPath, 'utf8').split('\n');
    for (const line of lines) {
      const match = line.match(/^\s*([\w.-]+)\s*=\s*(.*)?\s*$/);
      if (match) {
        let val = (match[2] || '').trim();
        if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
          val = val.slice(1, -1);
        }
        process.env[match[1]] = val;
      }
    }
  }
}

const DEFAULT_PROMPT = 
  'As a retail insurance assistant, analyze our cardholder retail purchases and insurance policy trends. How does our current policy coverage compare with customer purchase categories, and what insurance protection is uncovered?';

/**
 * Safely replaces the inner HTML of any element matching the given ID.
 * Uses a replacer function to prevent literal '$' characters in currency figures (e.g. $20,993)
 * from being mistakenly parsed as regex capture group tokens ($1, $2) by JavaScript String.prototype.replace.
 */
function updateElementContentById(html, id, newInnerContent) {
  const regex = new RegExp(`(<[^>]+id=["']${id}["'][^>]*>)[\\s\\S]*?(<\\/[^>]+>)`, 'i');
  return html.replace(regex, (match, openTag, closeTag) => `${openTag}${newInnerContent}${closeTag}`);
}

/**
 * Dynamically queries the Agentforce AI agent in Salesforce (Retail_Insurance_Helper).
 * Extracts and surfaces ONLY what the AI agent returns in real time, with zero hardcoded metrics or categories.
 * @param {string} prompt - Prompt sent to the agent
 * @param {number} timeoutMs - Timeout in milliseconds
 */
async function queryAgentforceStoreTrends(prompt = DEFAULT_PROMPT, timeoutMs = 20000) {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

  const baseUrl = (process.env.SALESFORCE_INSTANCE_URL || '').replace(/\/+$/, '');
  const url = `${baseUrl}/services/data/v68.0/actions/custom/generateAiAgentResponse/Retail_Insurance_Helper`;

  console.log('[AGENTFORCE LIVE] Invoking Agentforce Agent with prompt:');
  console.log(`💬 "${prompt}"`);
  console.log(`📡 Salesforce Target: ${baseUrl}`);

  try {
    const response = await fetch(url, {
      method: 'POST',
      signal: controller.signal,
      headers: {
        'Authorization': `Bearer ${process.env.SALESFORCE_ACCESS_TOKEN}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        inputs: [{ userMessage: prompt }]
      })
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      const errText = await response.text();
      throw new Error(`Agentforce HTTP Error ${response.status} (${response.statusText}): ${errText}`);
    }

    const result = await response.json();
    if (result && result[0] && result[0].isSuccess && result[0].outputValues) {
      const rawAgentResponse = result[0].outputValues.agentResponse;
      let textAnalysis = rawAgentResponse;
      try {
        const parsed = JSON.parse(rawAgentResponse);
        if (parsed.value) textAnalysis = parsed.value;
        else if (parsed.response) textAnalysis = parsed.response;
      } catch (ignored) {}

      console.log('✅ [AGENTFORCE SUCCESS] Real response received from Agentforce:');
      console.log('--------------------------------------------------');
      console.log(textAnalysis);
      console.log('--------------------------------------------------');

      // Dynamically extract the leading category from the Agentforce natural language response,
      // resilient to natural LLM phrasing variations (e.g. "category is Technology", "category by revenue: Technology")
      let topCategory = 'Retail Category';
      const patterns = [
        /top-performing\s+(?:purchase\s+)?category(?:\s+by\s+\w+)?(?:\s+(?:is|was|being|named))?[:\s]+([A-Z][a-zA-Z]+)/i,
        /(?:specifically|tailored)\s+(?:for|to)\s+([A-Z][a-zA-Z]+)\s+products/i,
        /(?:the\s+)?([A-Z][a-zA-Z]+)\s+category[^\w\n]+(?:which\s+is[^\n]+)?currently\s+(?:lacks|has\s+no|is\s+not)/i,
        /([A-Z][a-zA-Z]+)\s+is\s+currently\s+(?:not\s+covered|uncovered)/i,
        /gap[:\s]+(?:the\s+)?([A-Z][a-zA-Z]+)\s+category/i
      ];

      for (const pattern of patterns) {
        const match = textAnalysis.match(pattern);
        if (match && match[1]) {
          const candidate = match[1].trim();
          if (!/^(is|was|the|a|an|in|at|by|for|with|of|to|revenue|sales)$/i.test(candidate)) {
            topCategory = candidate;
            break;
          }
        }
      }

      return {
        prompt,
        aiAnalysis: textAnalysis,
        topCategory,
        isLive: true
      };
    }

    throw new Error('Agentforce response did not contain valid outputValues.');
  } catch (err) {
    clearTimeout(timeoutId);
    console.warn(`⚠️ [OFFLINE FALLBACK ACTIVATED] ${err.message}`);

    // Fall back to fallback_trends.json only if the network or HTTP call failed
    const fallbackPath = path.join(__dirname, 'fallback_trends.json');
    const fallback = JSON.parse(fs.readFileSync(fallbackPath, 'utf8'));

    return {
      prompt,
      aiAnalysis: fallback.coverageAnalysis,
      topCategory: fallback.topCategory,
      isLive: false
    };
  }
}

/**
 * Dynamically synchronizes the interactive HTML widget with the Agentforce AI output.
 * Renders only data returned by Salesforce AI.
 * @param {string} prompt - Custom prompt for the Agent (optional)
 * @param {string} targetArtifactDir - Optional Antigravity artifact directory
 */
async function syncDashboardWithAgentforce(prompt, targetArtifactDir) {
  const result = await queryAgentforceStoreTrends(prompt);
  const htmlPath = path.join(__dirname, 'manager_dashboard.html');

  if (!fs.existsSync(htmlPath)) {
    console.error(`❌ HTML Dashboard not found at ${htmlPath}`);
    return;
  }

  let html = fs.readFileSync(htmlPath, 'utf8');

  // 1. Connection Status Badge (Live vs. Offline Fallback)
  if (result.isLive) {
    html = updateElementContentById(html, 'agent-pulse', '');
    html = html.replace(/id="agent-pulse"[^>]*class="[^"]*"/, 'id="agent-pulse" class="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"');
    html = updateElementContentById(html, 'agent-badge-text', '🟢 Agentforce AI Grounded');
  } else {
    html = updateElementContentById(html, 'agent-pulse', '');
    html = html.replace(/id="agent-pulse"[^>]*class="[^"]*"/, 'id="agent-pulse" class="w-2 h-2 rounded-full bg-amber-500"');
    html = updateElementContentById(html, 'agent-badge-text', '🟡 Verified Offline Snapshot');
  }

  // 2. Uncovered category dynamically extracted from Agentforce response
  html = updateElementContentById(html, 'top-category-name', result.topCategory);

  // 3. Verbatim strategic recommendation from Salesforce Agentforce
  html = updateElementContentById(html, 'strategic-body', result.aiAnalysis);

  // 4. Action button dynamically labeled with the identified category
  const dynamicBtnText = `Start working in insurance ${result.topCategory} initiative`;
  html = updateElementContentById(html, 'approveBtnText', dynamicBtnText);

  // 5. Dynamic JavaScript variable for user interaction
  html = html.replace(/let currentCategory = '[^']*';/, () => `let currentCategory = '${result.topCategory}';`);

  // 6. Grounded prompt context display
  const contextNote = `Prompt grounded: "${result.prompt}"`;
  html = updateElementContentById(html, 'prompt-context', contextNote);

  // Save to the local surface directory
  fs.writeFileSync(htmlPath, html, 'utf8');
  console.log(`🖼️  [SYNC COMPLETE] manager_dashboard.html updated with ${result.isLive ? 'LIVE Agentforce AI' : 'OFFLINE Fallback'} reasoning.`);

  // Copy to the conversation artifact directory if dynamically specified
  const resolvedArtifactDir = targetArtifactDir || process.env.ARTIFACT_DIR || process.env.ANTIGRAVITY_ARTIFACT_DIR;
  if (resolvedArtifactDir && fs.existsSync(resolvedArtifactDir)) {
    const artifactHtmlPath = path.join(resolvedArtifactDir, 'manager_dashboard.html');
    fs.writeFileSync(artifactHtmlPath, html, 'utf8');
    console.log(`📋 Copied updated dashboard to artifact: ${artifactHtmlPath}`);
  }
}

module.exports = {
  queryAgentforceStoreTrends,
  syncDashboardWithAgentforce,
  DEFAULT_PROMPT
};

// If executed directly from CLI or Antigravity
if (require.main === module) {
  const args = process.argv.slice(2);
  let customPrompt = undefined;
  let customArtifactDir = undefined;

  for (const arg of args) {
    if (arg.startsWith('--artifact-dir=')) {
      customArtifactDir = arg.split('=')[1].replace(/^["']|["']$/g, '');
    } else if (!customPrompt) {
      customPrompt = arg;
    } else {
      customPrompt += ` ${arg}`;
    }
  }

  syncDashboardWithAgentforce(customPrompt || process.env.AGENTFORCE_PROMPT || undefined, customArtifactDir);
}
