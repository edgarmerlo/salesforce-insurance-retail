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
 * Escapes HTML characters to prevent XSS or broken tag structures.
 */
function escapeHtml(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

/**
 * Escapes characters for embedding safely inside single-quoted JavaScript strings.
 */
function escapeJs(str) {
  if (!str) return '';
  return String(str).replace(/\\/g, '\\\\').replace(/'/g, "\\'");
}

/**
 * Generates the complete, self-contained executive dashboard HTML document purely from data.
 * Does NOT require any template file to exist on disk.
 * @param {Object} result - Grounded data object from Agentforce or fallback snapshot
 * @returns {string} Fully rendered HTML string
 */
function generateDashboardHtml(result) {
  const isLive = Boolean(result.isLive);
  const pulseClass = isLive 
    ? 'w-2 h-2 rounded-full bg-emerald-500 animate-pulse' 
    : 'w-2 h-2 rounded-full bg-amber-500';
  const badgeText = isLive 
    ? '🟢 Agentforce AI Grounded' 
    : '🟡 Verified Offline Snapshot';
  const category = escapeHtml(result.topCategory || 'Retail Category');
  const bodyText = escapeHtml(result.aiAnalysis || 'Awaiting live Agentforce AI reasoning...');
  const promptContext = result.prompt ? `Prompt grounded: "${escapeHtml(result.prompt)}"` : '';
  const jsCategory = escapeJs(result.topCategory || '');

  return `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <script src="https://www.gstatic.com/antigravity/web/dev/tailwindcss.min.js"></script>
</head>
<body class="bg-transparent text-[var(--foreground)] antialiased p-2">
  <div class="bg-[var(--card)] text-[var(--foreground)] border border-[var(--border)] rounded-2xl p-5 shadow-lg max-w-2xl mx-auto space-y-4">
    
    <!-- Header -->
    <div class="flex items-center justify-between border-b border-[var(--border)] pb-3">
      <div class="flex items-center space-x-3">
        <div class="w-9 h-9 rounded-xl bg-blue-500/10 text-blue-500 flex items-center justify-center text-lg font-bold">
          📊
        </div>
        <div>
          <h2 class="text-base font-bold text-[var(--foreground)]">Executive Retail & Insurance Strategy</h2>
          <p class="text-xs text-[var(--muted-foreground)]">Salesforce Headless 360 • Agentforce AI Live Grounding</p>
        </div>
      </div>
      <div class="px-2.5 py-1 bg-emerald-500/10 text-emerald-500 text-xs font-semibold rounded-full border border-emerald-500/20 flex items-center gap-1.5">
        <span id="agent-pulse" class="${pulseClass}"></span>
        <span id="agent-badge-text">${badgeText}</span>
      </div>
    </div>

    <!-- AI Grounded Leading Category Banner -->
    <div class="bg-red-500/10 border border-red-500/20 rounded-xl p-3 flex items-center justify-between">
      <div class="flex items-center gap-2.5">
        <span class="text-base">🛡️</span>
        <div>
          <p class="text-[11px] uppercase tracking-wider text-red-400 font-bold">Uncovered Leading Category</p>
          <p id="top-category-name" class="text-lg font-black text-red-400">${category}</p>
        </div>
      </div>
      <span class="px-2.5 py-1 bg-red-500/20 text-red-400 text-xs font-semibold rounded-full border border-red-500/30">
        Active Coverage Gap
      </span>
    </div>

    <!-- Verbatim Strategic Analysis from Salesforce Agentforce -->
    <div class="bg-blue-500/5 border border-blue-500/20 rounded-xl p-4 space-y-2">
      <h4 class="text-xs font-bold text-blue-400 flex items-center gap-1.5">
        <span>💡</span> Strategic Recommendation from Agentforce
      </h4>
      <p id="strategic-body" class="text-xs text-[var(--muted-foreground)] mt-1 whitespace-pre-line leading-relaxed">${bodyText}</p>
      ${promptContext ? `<p id="prompt-context" class="text-[10px] text-[var(--muted-foreground)]/60 italic mt-2 border-t border-blue-500/10 pt-2">${promptContext}</p>` : ''}
    </div>

    <!-- Action Footer -->
    <div class="pt-1 flex items-center justify-between text-xs text-[var(--muted-foreground)]">
      <span>Agent: <strong>Retail_Insurance_Helper</strong></span>
      <button 
        id="approveBtn"
        onclick="initiateStrategy()" 
        class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg transition-colors cursor-pointer text-xs flex items-center gap-1.5"
      >
        <span>🤝</span> <span id="approveBtnText">Start working in insurance ${category} initiative</span>
      </button>
    </div>

  </div>

  <script id="dynamic-state-script">
    let currentCategory = '${jsCategory}';

    function initiateStrategy() {
      const btn = document.getElementById('approveBtn');
      const label = currentCategory ? \`\${currentCategory} protection\` : 'insurance';
      btn.innerHTML = '<span>✅</span> Strategy conversation for ' + label + ' initiated in CRM';
      btn.className = 'px-4 py-2 bg-emerald-600 text-white font-medium rounded-lg text-xs cursor-default';
    }
  </script>
</body>
</html>`;
}

/**
 * Dynamically queries the Agentforce AI agent in Salesforce (Retail_Insurance_Helper).
 * Extracts and surfaces ONLY what the AI agent returns in real time, with zero hardcoded metrics or categories.
 * @param {string} prompt - Prompt sent to the agent
 * @param {number} timeoutMs - Timeout in milliseconds
 * @param {boolean} forceFallback - Whether to directly use the offline snapshot
 */
async function queryAgentforceStoreTrends(prompt = DEFAULT_PROMPT, timeoutMs = 20000, forceFallback = false) {
  if (forceFallback) {
    console.log('🟡 [OFFLINE FALLBACK ACTIVATED] Forced offline fallback via --fallback flag.');
    const fallbackPath = path.join(__dirname, 'fallback_trends.json');
    const fallback = JSON.parse(fs.readFileSync(fallbackPath, 'utf8'));
    return {
      prompt: prompt || DEFAULT_PROMPT,
      aiAnalysis: fallback.coverageAnalysis,
      topCategory: fallback.topCategory,
      isLive: false
    };
  }

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
 * Dynamically generates and writes the interactive HTML dashboard.
 * Purely data-driven: does not require any HTML template file to pre-exist.
 * @param {string} prompt - Custom prompt for the Agent (optional)
 * @param {string} targetArtifactDir - Optional Antigravity artifact directory
 * @param {boolean} forceFallback - Whether to use verified offline snapshot directly
 */
async function syncDashboardWithAgentforce(prompt, targetArtifactDir, forceFallback = false) {
  const result = await queryAgentforceStoreTrends(prompt, 20000, forceFallback);

  // Generate complete HTML dynamically from scratch
  const html = generateDashboardHtml(result);

  // Write directly to local surface directory
  const htmlPath = path.join(__dirname, 'manager_dashboard.html');
  fs.writeFileSync(htmlPath, html, 'utf8');
  console.log(`🖼️  [GENERATE COMPLETE] manager_dashboard.html dynamically created with ${result.isLive ? 'LIVE Agentforce AI' : 'OFFLINE Fallback'} reasoning.`);

  // Write directly to conversation artifact directory if specified
  const resolvedArtifactDir = targetArtifactDir || process.env.ARTIFACT_DIR || process.env.ANTIGRAVITY_ARTIFACT_DIR;
  if (resolvedArtifactDir && fs.existsSync(resolvedArtifactDir)) {
    const artifactHtmlPath = path.join(resolvedArtifactDir, 'manager_dashboard.html');
    fs.writeFileSync(artifactHtmlPath, html, 'utf8');
    console.log(`📋 Copied dynamic dashboard to artifact: ${artifactHtmlPath}`);
  }
}

module.exports = {
  queryAgentforceStoreTrends,
  syncDashboardWithAgentforce,
  generateDashboardHtml,
  DEFAULT_PROMPT
};

// If executed directly from CLI or Antigravity
if (require.main === module) {
  const args = process.argv.slice(2);
  let customPrompt = undefined;
  let customArtifactDir = undefined;
  let forceFallback = false;

  for (const arg of args) {
    if (arg.startsWith('--artifact-dir=')) {
      customArtifactDir = arg.split('=')[1].replace(/^["']|["']$/g, '');
    } else if (arg === '--fallback') {
      forceFallback = true;
    } else if (!customPrompt) {
      customPrompt = arg;
    } else {
      customPrompt += ` ${arg}`;
    }
  }

  syncDashboardWithAgentforce(customPrompt || process.env.AGENTFORCE_PROMPT || undefined, customArtifactDir, forceFallback);
}
