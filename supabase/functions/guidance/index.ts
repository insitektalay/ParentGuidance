import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { streamText } from 'https://esm.sh/ai@3.4.7'
import { openai } from 'https://esm.sh/ai@3.4.7/openai'
import { promptTemplates } from '../prompts/promptTemplates.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

interface RequestBody {
  operation: 'guidance' | 'analyze' | 'framework' | 'context' | 'translate'
  variables: Record<string, any>
  apiKey: string
}

// Helper function to interpolate variables in prompt templates
function interpolatePrompt(template: string, variables: Record<string, any>): string {
  let interpolated = template
  for (const [key, value] of Object.entries(variables)) {
    const placeholder = `{{${key}}}`
    interpolated = interpolated.replace(new RegExp(placeholder, 'g'), value || '')
  }
  return interpolated
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Validate authorization
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Initialize Supabase client for auth validation
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: authHeader },
        },
      }
    )

    // Verify the user session
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser()
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Invalid authorization' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Parse request body
    const body: RequestBody = await req.json()
    const { operation, variables, apiKey } = body

    if (!apiKey) {
      return new Response(
        JSON.stringify({ error: 'Missing API key' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Initialize OpenAI client
    const openaiClient = openai({
      apiKey: apiKey,
    })

    // Route to appropriate operation handler
    switch (operation) {
      case 'guidance':
        return await handleGuidanceOperation(openaiClient, variables)
      
      case 'analyze':
        return await handleAnalyzeOperation(openaiClient, variables)
      
      case 'framework':
        return await handleFrameworkOperation(openaiClient, variables)
      
      case 'context':
        return await handleContextOperation(openaiClient, variables)
      
      case 'translate':
        return await handleTranslateOperation(openaiClient, variables)
      
      default:
        return new Response(
          JSON.stringify({ error: `Unknown operation: ${operation}` }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    }

  } catch (error) {
    console.error('Edge function error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

// Handle guidance generation with streaming
async function handleGuidanceOperation(openaiClient: any, variables: any) {
  const { current_situation, family_context, active_foundation_tools, structure_mode, guidance_style } = variables

  // Determine which prompt template to use
  const hasFramework = !!active_foundation_tools
  
  // Default to "Warm Practical + Fixed" if not specified
  const style = guidance_style || "Warm Practical"
  const mode = structure_mode || "Fixed"
  const configKey = `${style} + ${mode}`

  try {
    // Select the appropriate prompt template
    let promptTemplate: any
    let promptVariables: Record<string, any> = {
      current_situation: current_situation
    }

    if (hasFramework) {
      // With framework
      promptTemplate = promptTemplates.guidance.versions_with_framework[configKey]
      if (!promptTemplate) {
        throw new Error(`Unknown guidance configuration: ${configKey}`)
      }
      promptVariables.active_foundation_tools = active_foundation_tools
    } else {
      // Without framework
      promptTemplate = promptTemplates.guidance.versions_no_framework[configKey]
      if (!promptTemplate) {
        throw new Error(`Unknown guidance configuration: ${configKey}`)
      }
      // Only add family_context for Fixed mode
      if (mode === "Fixed" && promptTemplate.variables.includes("family_context")) {
        promptVariables.family_context = family_context || "none"
      }
    }

    // Interpolate the system prompt with variables
    const systemPrompt = interpolatePrompt(promptTemplate.systemPromptText, promptVariables)

    // Use Vercel AI SDK for streaming
    const result = await streamText({
      model: openaiClient('gpt-4'),
      prompt: systemPrompt,
      maxTokens: 2000,
      temperature: 0.7,
    })

    // Convert AI SDK stream to SSE format
    const stream = new ReadableStream({
      async start(controller) {
        try {
          for await (const chunk of result.textStream) {
            const sseData = `data: ${JSON.stringify([{ type: 'text', value: chunk }])}\n\n`
            controller.enqueue(new TextEncoder().encode(sseData))
          }
          controller.enqueue(new TextEncoder().encode('data: [DONE]\n\n'))
          controller.close()
        } catch (error) {
          controller.error(error)
        }
      }
    })

    return new Response(stream, {
      headers: {
        ...corsHeaders,
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      }
    })

  } catch (error) {
    console.error('Guidance operation error:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to generate guidance', details: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}

// Handle situation analysis (non-streaming)
async function handleAnalyzeOperation(openaiClient: any, variables: any) {
  const { situation_text } = variables

  try {
    // Prepare variables for interpolation (map situation_text to situation_inputted)
    const promptVariables = {
      situation_inputted: situation_text
    }

    // Get the system prompt and interpolate variables
    const systemPrompt = interpolatePrompt(promptTemplates.analyze.systemPromptText, promptVariables)

    // Use Vercel AI SDK for the analysis
    const result = await streamText({
      model: openaiClient('gpt-4'),
      prompt: systemPrompt,
      maxTokens: 500,
      temperature: 0.3, // Lower temperature for more consistent categorization
    })

    // Collect the full response
    let fullText = ''
    for await (const chunk of result.textStream) {
      fullText += chunk
    }

    // Parse the analysis response (expecting JSON format)
    let analysisResult
    try {
      analysisResult = JSON.parse(fullText)
    } catch {
      // Fallback parsing if not valid JSON
      analysisResult = {
        category: "general",
        isIncident: false
      }
    }

    return new Response(
      JSON.stringify(analysisResult),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Analyze operation error:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to analyze situation', details: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}

// Handle framework generation (non-streaming)
async function handleFrameworkOperation(openaiClient: any, variables: any) {
  const { recent_situations } = variables

  try {
    // Prepare variables for interpolation (map recent_situations to situation_summary)
    const promptVariables = {
      situation_summary: recent_situations
    }

    // Get the system prompt and interpolate variables
    const systemPrompt = interpolatePrompt(promptTemplates.framework.systemPromptText, promptVariables)

    // Use Vercel AI SDK for framework generation
    const result = await streamText({
      model: openaiClient('gpt-4'),
      prompt: systemPrompt,
      maxTokens: 1000,
      temperature: 0.7,
    })

    // Collect the full response
    let fullText = ''
    for await (const chunk of result.textStream) {
      fullText += chunk
    }

    return new Response(
      JSON.stringify({ success: true, data: fullText }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Framework operation error:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to generate framework', details: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}

// Handle context extraction (non-streaming)
async function handleContextOperation(openaiClient: any, variables: any) {
  const { situation_text, extraction_type } = variables

  try {
    // Prepare variables for interpolation (map situation_text to long_prompt)
    const promptVariables = {
      long_prompt: situation_text
    }

    // Select the appropriate prompt template based on extraction type
    const isRegulation = extraction_type === "regulation"
    const systemPromptTemplate = isRegulation
      ? promptTemplates.context.systemPromptText_regulation
      : promptTemplates.context.systemPromptText_general

    // Interpolate the system prompt with variables
    const systemPrompt = interpolatePrompt(systemPromptTemplate, promptVariables)

    // Use Vercel AI SDK for context extraction
    const result = await streamText({
      model: openaiClient('gpt-4'),
      prompt: systemPrompt,
      maxTokens: 1500,
      temperature: 0.5,
    })

    // Collect the full response
    let fullText = ''
    for await (const chunk of result.textStream) {
      fullText += chunk
    }

    return new Response(
      JSON.stringify({ success: true, data: fullText }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Context operation error:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to extract context', details: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}

// Handle translation with streaming
async function handleTranslateOperation(openaiClient: any, variables: any) {
  const { guidance_content, target_language } = variables

  try {
    // Prepare variables for interpolation
    const promptVariables = {
      input_text: guidance_content,
      lang: target_language
    }

    // Get the system prompt and interpolate variables
    const systemPrompt = interpolatePrompt(promptTemplates.translate.systemPromptText, promptVariables)

    // Use Vercel AI SDK for streaming translation
    const result = await streamText({
      model: openaiClient('gpt-4'),
      prompt: systemPrompt,
      maxTokens: 2000,
      temperature: 0.3, // Lower temperature for more accurate translation
    })

    // Convert AI SDK stream to SSE format
    const stream = new ReadableStream({
      async start(controller) {
        try {
          for await (const chunk of result.textStream) {
            const sseData = `data: ${JSON.stringify([{ type: 'text', value: chunk }])}\n\n`
            controller.enqueue(new TextEncoder().encode(sseData))
          }
          controller.enqueue(new TextEncoder().encode('data: [DONE]\n\n'))
          controller.close()
        } catch (error) {
          controller.error(error)
        }
      }
    })

    return new Response(stream, {
      headers: {
        ...corsHeaders,
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      }
    })

  } catch (error) {
    console.error('Translate operation error:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to translate content', details: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}

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