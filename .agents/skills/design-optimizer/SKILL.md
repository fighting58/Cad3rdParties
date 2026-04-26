---
name: design-optimizer
description: "Iteratively evaluates and improves web page designs until they reach a target score of 90+. Use this whenever a user wants to beautify a page, improve its UX, or achieve a high professional design standard."
---

# Design Optimizer Skill

This skill enables the autonomous improvement of web designs using an iterative "Evaluate -> Analyze -> Fix -> Verify" loop.

## Mode 1: Optimization Loop (Self-Improvement)
- **Trigger**: "Improve this page until it reaches 90+", "Optimize the design".
- **Workflow**: 
    1. **Initial Evaluation**: Run `node .agents/skills/design-optimizer/run.js <LocalURL>` to get the current design score.
    2. **Goal Check**: If `totalScore` >= 90, stop.
    3. **Gap Analysis**: Review improvements from JSON output.
    4. **Code Modification**: Fix source files.
    5. **Verification**: Re-run `node .agents/skills/design-optimizer/run.js <LocalURL>`.

## Mode 2: Analysis & Benchmarking (Insight Generation)
- **Trigger**: "Evaluate [URL]", "Analyze [URL] and tell me what we can learn".
- **Workflow**:
    1. **External Scanning**: Run `node .agents/skills/design-optimizer/run.js <URL>`.
    2. **Insight Extraction**: Identify high-scoring elements (Score 4-5) of the target site.
    3. **Comparative Report**: Compare target site with current project.
    4. **Actionable Benchmarking**: Suggest specific design patterns from target site.

## Guidelines for Design Improvement
- **Typography**: Use professional fonts (Outfit, Inter, Roboto). Ensure clear hierarchy (H1 > H2 > p).
- **Color**: Use harmonious HSL-based palettes. Avoid generic colors.
- **Spacing**: Use generous white space (margin/padding) to prevent clutter.
- **Modern Effects**: Use subtle box-shadows, blurs, and gradients to create a premium feel.
- **Benchmarking**: When analyzing high-quality sites (Apple, Stripe), pay attention to their grid systems and micro-interactions.

## Termination
- When the score reaches 90+, provide a summary of the improvements made and the final score.
- For analysis requests, provide a structured report with scores and benchmarking suggestions.
- If 5 iterations are reached without hitting 90, stop and explain the progress and remaining bottlenecks.
