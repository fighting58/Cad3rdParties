import { chromium } from 'playwright';
import { GoogleGenerativeAI } from "@google/generative-ai";

export async function captureScreenshot(url) {
    console.log(`Capturing screenshot for: ${url}`);
    const browser = await chromium.launch({ headless: true });
    const context = await browser.newContext({
        viewport: { width: 1280, height: 800 }
    });
    const page = await context.newPage();
    
    try {
        await page.goto(url, { waitUntil: 'load', timeout: 30000 });
        await page.waitForTimeout(2000);
        
        const buffer = await page.screenshot({ fullPage: true });
        await browser.close();
        return buffer.toString('base64');
    } catch (error) {
        await browser.close();
        throw error;
    }
}

export async function evaluateDesign(imageBase64, apiKey) {
    if (!apiKey) throw new Error("Gemini API Key is required");

    const genAI = new GoogleGenerativeAI(apiKey);
    // Use the latest available model from our previous checks
    const model = genAI.getGenerativeModel({ model: "gemini-flash-latest" });

    const prompt = `
    You are a professional web design evaluator. 
    Analyze the provided screenshot of a website and evaluate it based on the following 25 criteria.
    For each criterion, provide a score from 1 to 5 (1: Poor, 5: Excellent) and a brief reason.
    
    Categories and Criteria:
    1. Aesthetics: Color Harmony, Typography Quality, Imagery & Graphics, Visual Impact, Modern Feel
    2. Layout & Structure: Visual Hierarchy, Use of White Space, Grid Consistency, Content Grouping, Eye Flow
    3. UX & Interaction: Navigation Clarity, CTA Visibility, Affordance, Ease of Access, User Journey Clarity
    4. Brand Identity: Logo Integration, Tone & Manner, Professionalism, Uniqueness, Emotional Connection
    5. Content & Readability: Readability, Clarity of Message, Headline Effectiveness, Visual-Text Balance, Content Density

    Also, provide the TOP 3 most critical actionable improvements to reach a score of 90+.

    Return the result ONLY in the following JSON format:
    {
        "totalScore": number (0-100),
        "categories": {
            "Aesthetics": { "score": number, "details": { "Color Harmony": 5, ... }, "summary": "string" },
            "Layout": { ... },
            "UX": { ... },
            "Brand": { ... },
            "Content": { ... }
        },
        "improvements": ["string", "string", "string"]
    }
    `;

    const result = await model.generateContent([
        prompt,
        {
            inlineData: {
                data: imageBase64,
                mimeType: "image/png"
            }
        }
    ]);

    const responseText = result.response.text();
    const jsonMatch = responseText.match(/\{[\s\S]*\}/);
    if (!jsonMatch) throw new Error("Failed to parse AI response as JSON");
    
    return JSON.parse(jsonMatch[0]);
}
