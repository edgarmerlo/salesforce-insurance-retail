---
name: insurance-trends
description: >-
  Fetches live store sales volume, category revenues, and policy coverage gaps directly from Salesforce Agentforce,
  and renders the Executive Retail & Insurance Strategy interactive dashboard. Use when the user types /insurance-trends
  or asks to analyze retail insurance store trends.
---

# Insurance Trends Executive Surface

This skill queries Salesforce Agentforce (`Retail_Insurance_Helper`) in real-time, extracts storewide sales volume, order counts, and insurance coverage gaps across retail purchases, and renders an interactive Tailwind CSS executive dashboard.

## When to Run
- Triggered by the slash command `/insurance-trends`
- Triggered when the user asks for store manager analytics, sales vs. policy coverage trends, or retail insurance cross-sell strategy.

## Workflow Execution

1. **Invoke Agentforce and Sync Dashboard**:
   Execute the decoupled launcher script:
   ```bash
   ./store-manager-surface/run.sh "$PROMPT" --artifact-dir="<appDataDir>/brain/<conversation-id>"
   ```
   *(If `$PROMPT` is omitted, the default retail insurance analysis prompt is sent. Add `--fallback` to explicitly force the offline verified snapshot without querying the live Agentforce endpoint).*

2. **Render Inline Directly in Session (No Sidebar)**:
   - The updated dashboard is saved to `store-manager-surface/manager_dashboard.html` and automatically copied to `<appDataDir>/brain/<conversation-id>/manager_dashboard.html`.
   - Do **NOT** create or trigger markdown side-panel artifacts (`UserFacing: true`).
   - Render the interactive widget directly inside the active chat timeline using `<agent-embed>`:
     ```html
     <agent-embed src="file:///<artifact_path>/manager_dashboard.html"></agent-embed>
     ```
   - Accompany the embedded widget with a concise executive summary directly in chat.

## Components
- [`fetch_trends.js`](../../../store-manager-surface/fetch_trends.js): Standalone runner that queries the Salesforce Agentforce REST API (`/services/data/v68.0/actions/custom/generateAiAgentResponse/Retail_Insurance_Helper`) and safely updates the HTML dashboard.
- [`manager_dashboard.html`](../../../store-manager-surface/manager_dashboard.html): Dynamically generated interactive dashboard using Tailwind CSS and semantic theme variables.
- [`fallback_trends.json`](../../../store-manager-surface/fallback_trends.json): Pre-grounded offline snapshot for resilient degradation.
