import { captureScreenshot, evaluateDesign } from './lib/evaluator.js';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

// Setup environment from current or parent directories
dotenv.config();

const __dirname = path.dirname(fileURLToPath(import.meta.url));

async function main() {
    const url = process.argv[2];
    if (!url) {
        console.error("Usage: node run.js <URL>");
        process.exit(1);
    }

    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
        console.error("Error: GEMINI_API_KEY not found in environment.");
        process.exit(1);
    }

    try {
        const imageBase64 = await captureScreenshot(url);
        const results = await evaluateDesign(imageBase64, apiKey);
        console.log(JSON.stringify(results, null, 2));
    } catch (error) {
        console.error("Evaluation Failed:", error.message);
        process.exit(1);
    }
}

main();
