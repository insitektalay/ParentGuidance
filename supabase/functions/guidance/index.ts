// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts"

// Import Vercel AI SDK and OpenAI
import { streamText } from 'npm:ai@latest'
import { createOpenAI } from 'npm:@ai-sdk/openai@latest'

// Import prompt templates
import { getGuidancePrompt, formatFrameworkForPrompt } from '../prompts/guidancePrompt.ts'
import { getSituationAnalysisPrompt } from '../prompts/situationAnalysisPrompt.ts'
import { getFrameworkPrompt } from '../prompts/frameworkPrompt.ts'
import { getContextExtractionPrompt } from '../prompts/contextExtractionPrompt.ts'
import { getTranslationPrompt } from '../prompts/translationPrompt.ts'

// CORS headers for iOS app
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

Deno.serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Parse request body
    const { operation, variables, apiKey } = await req.json()

    if (!operation || !variables || !apiKey) {
      throw new Error('Missing required parameters: operation, variables, or apiKey')
    }

    // Initialize OpenAI client with user's API key
    const openai = createOpenAI({
      apiKey: apiKey,
    })

    // Get appropriate prompt based on operation
    let systemPrompt: string
    let userPrompt: string
    let model = 'gpt-4'
    let temperature = 0.7
    let responseFormat: 'text' | 'json' = 'text'

    switch (operation) {
      case 'guidance': {
        const prompt = getGuidancePrompt({
          current_situation: variables.current_situation,
          active_foundation_tools: variables.active_foundation_tools,
          family_context: variables.family_context,
          has_framework: !!variables.active_foundation_tools,
          structure_mode: variables.structure_mode || 'fixed'
        })
        systemPrompt = prompt.system
        userPrompt = prompt.user
        break
      }

      case 'analyze': {
        const prompt = getSituationAnalysisPrompt({
          situation_text: variables.situation_text
        })
        systemPrompt = prompt.system
        userPrompt = prompt.user
        responseFormat = 'json'
        temperature = 0.3 // Lower temperature for classification
        break
      }

      case 'framework': {
        const prompt = getFrameworkPrompt({
          recent_situations: variables.recent_situations
        })
        systemPrompt = prompt.system
        userPrompt = prompt.user
        responseFormat = 'json'
        break
      }

      case 'context': {
        const prompt = getContextExtractionPrompt({
          situation_text: variables.situation_text,
          extraction_type: variables.extraction_type || 'general'
        })
        systemPrompt = prompt.system
        userPrompt = prompt.user
        responseFormat = 'json'
        temperature = 0.5
        break
      }

      case 'translate': {
        const prompt = getTranslationPrompt({
          guidance_content: variables.guidance_content,
          target_language: variables.target_language
        })
        systemPrompt = prompt.system
        userPrompt = prompt.user
        break
      }

      default:
        throw new Error(`Unknown operation: ${operation}`)
    }

    // For non-streaming operations (JSON responses)
    if (responseFormat === 'json') {
      const result = await streamText({
        model: openai(model),
        system: systemPrompt,
        messages: [{ role: 'user', content: userPrompt }],
        temperature: temperature,
      })

      // Collect the full response
      let fullText = ''
      for await (const textPart of result.textStream) {
        fullText += textPart
      }

      return new Response(
        JSON.stringify({ 
          success: true, 
          data: fullText 
        }),
        { 
          headers: { 
            ...corsHeaders, 
            'Content-Type': 'application/json' 
          } 
        }
      )
    }

    // For streaming operations (guidance and translation)
    const result = streamText({
      model: openai(model),
      system: systemPrompt,
      messages: [{ role: 'user', content: userPrompt }],
      temperature: temperature,
    })

    // Create a TransformStream to handle the streaming response
    const stream = new TransformStream({
      async transform(chunk, controller) {
        // Forward the chunk as-is for SSE format
        controller.enqueue(chunk)
      },
    })

    // Pipe the AI stream through our transform
    const body = result.toDataStreamResponse().body
    if (!body) {
      throw new Error('No response body from AI')
    }

    return new Response(
      body.pipeThrough(stream),
      {
        headers: {
          ...corsHeaders,
          'Content-Type': 'text/event-stream',
          'Cache-Control': 'no-cache',
          'Connection': 'keep-alive',
        },
      }
    )

  } catch (error) {
    console.error('Error in guidance function:', error)
    
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error instanceof Error ? error.message : 'Unknown error occurred' 
      }),
      { 
        status: 500,
        headers: { 
          ...corsHeaders, 
          'Content-Type': 'application/json' 
        } 
      }
    )
  }
})

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  # For guidance generation:
  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/guidance' \
    --header 'Authorization: Bearer YOUR_ANON_KEY' \
    --header 'Content-Type: application/json' \
    --data '{
      "operation": "guidance",
      "variables": {
        "current_situation": "My 5-year-old is having tantrums at bedtime",
        "structure_mode": "fixed"
      },
      "apiKey": "YOUR_OPENAI_API_KEY"
    }'

  # For translation:
  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/guidance' \
    --header 'Authorization: Bearer YOUR_ANON_KEY' \
    --header 'Content-Type: application/json' \
    --data '{
      "operation": "translate",
      "variables": {
        "guidance_content": "[TITLE]\\nBedtime Battles\\n\\n[SITUATION]...",
        "target_language": "Spanish"
      },
      "apiKey": "YOUR_OPENAI_API_KEY"
    }'

*/