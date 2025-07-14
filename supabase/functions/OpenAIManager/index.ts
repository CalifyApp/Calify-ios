// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts"

interface MealEstimateRequest {
  meal: string
}

interface MealEstimateResponse {
  calories: number
  protein: number
  carbs: number
  fat: number
  accuracyScore: number
  description: string
  accuracyTips: string[]
}

interface APIError {
  error: string
  message: string
}
Deno.serve(async (req: Request) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      }
    })
  }

  try {
    const { meal }: MealEstimateRequest = await req.json()
    
    if (!meal) {
      return new Response(
        JSON.stringify({ error: 'Bad Request', message: 'Meal description is required' }),
        { 
          status: 400,
          headers: { 
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          }
        }
      )
    }

    const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
    if (!openaiApiKey) {
      return new Response(
        JSON.stringify({ error: 'Server Error', message: 'OpenAI API key not configured' }),
        { 
          status: 500,
          headers: { 
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          }
        }
      )
    }

    // Run main estimation and accuracy tips concurrently
    const [mainResult, accuracyTips] = await Promise.all([
      processMainEstimation(meal, openaiApiKey),
      fetchAccuracyTips(meal, openaiApiKey)
    ])

    // Parse the main result JSON
    const parsedResult = JSON.parse(mainResult)
    
    // Combine results
    const response: MealEstimateResponse = {
      ...parsedResult,
      accuracyTips: JSON.parse(accuracyTips)
    }

    return new Response(
      JSON.stringify(response),
      {
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      }
    )

  } catch (error) {
    console.error('Error processing request:', error)
    
    const errorResponse: APIError = {
      error: 'Internal Server Error',
      message: error instanceof Error ? error.message : 'Unknown error occurred'
    }

    return new Response(
      JSON.stringify(errorResponse),
      {
        status: 500,
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      }
    )
  }
})

async function processMainEstimation(meal: string, apiKey: string): Promise<string> {
  const estimatePrompt = `You are a calorie tracking expert. Estimate total calories and macros (protein, carbs, fat in grams) for any food input. Be accurate and include specific numbers. Assume standard portion sizes if needed. Never skip any items mentioned. Output should be clear, factual, and not overly polite or vague.

If a user uses vague measurements like 'a cup,' 'a serving,' or 'an ounce,' standardize them to precise values like '1 cup,' '1 serving,' or '1 ounce.' Scale appropriately if the context implies more or less. The meal is:`

  const accuracyPrompt = `Based on this meal description: "${meal}"

Evaluate the precision of the information provided:

Assign a confidence score (accuracyScore) from 0-100 based on:
- Portion clarity (specific measurements vs vague amounts)
- Ingredient details (specific types/brands vs generic mentions)
- Preparation method information
- Comprehensive listing of components
- Overall descriptiveness

🔹 If the meal is simple, and does not require much detail (e.g a banana, or egg) because it does not vary in calories a lot, give a High accuracy score above 70. 

Higher scores mean more confident estimates. Lower scores indicate more assumptions were needed. For less descriptive, but branded meals, provide higher accuracy score for the user, since you know brand estimates.

Return only this in JSON Format, with NO BACKTICKS:
- accuracyScore: (int)`

  const structurePrompt = `Convert this text into JSON with keys: calories(int), protein(int), carbs(int), fat(int), accuracyScore(int), and description(string).
Add into the description field a short description of the meal based off the meals description. Only return JSON. Do not include backticks. Use average values of calorie/macro estimates.`

  try {
    // Run estimate request
    const estimateResponse = await makeOpenAIRequest(
      `${estimatePrompt} ${meal}`,
      apiKey,
      'gpt-4.1-2025-04-14'
    )

    // Run accuracy request
    const accuracyResponse = await makeOpenAIRequest(
      accuracyPrompt,
      apiKey,
      'gpt-4.1-2025-04-14'
    )

    // Run structure request
    const structureResponse = await makeOpenAIRequest(
      `${structurePrompt} ${estimateResponse} ${accuracyResponse}`,
      apiKey,
      'gpt-4.1-nano'
    )

    return structureResponse

  } catch (error) {
    throw new Error(`Main estimation failed: ${error instanceof Error ? error.message : 'Unknown error'}`)
  }
}

async function fetchAccuracyTips(meal: string, apiKey: string): Promise<string> {
  const accuracyTipsPrompt = `Check out this meal description: "${meal}"

Your job is to help the user write more accurate food descriptions for calorie estimation.

🔹 If the meal is already well-written, specific, and clear, respond only with:
["Looks great! No tips needed."]

🔹 If the meal is vague or missing important details, return **2–3 concise suggestions** in a JSON array.

Focus only on:
- Portion clarity
- Ingredient specificity (type/brand)
- Cooking method
- Completeness of all components
- Overall descriptiveness

❗️Avoid nitpicking. Do NOT give tips for things the user already clearly described. Do NOT suggest minor or unnecessary improvements.

Output format: a JSON array of 2–3 bullet points contained in strings or the exact phrase ["Looks great! No tips needed."] — no extra text, no backticks.`

  try {
    const tipsResponse = await makeOpenAIRequest(
      accuracyTipsPrompt,
      apiKey,
      'gpt-4o'
    )
    
    return tipsResponse

  } catch (error) {
    console.error('Error fetching accuracy tips:', error)
    return '["Unable to generate tips due to an error"]'
  }
}

async function makeOpenAIRequest(prompt: string, apiKey: string, model: string): Promise<string> {
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: model,
      messages: [
        {
          role: 'user',
          content: prompt
        }
      ],
      temperature: 0.0
    })
  })

  if (!response.ok) {
    throw new Error(`OpenAI API error: ${response.status} ${response.statusText}`)
  }

  const data = await response.json()
  
  if (!data.choices || !data.choices[0] || !data.choices[0].message || !data.choices[0].message.content) {
    throw new Error('Empty response from OpenAI API')
  }

  return data.choices[0].message.content
}

/* To invoke:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/OpenAIManager' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"meal":"2 eggs and toast"}'

*/
