import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { streamText } from 'https://esm.sh/ai@3.4.7'
import { openai } from 'https://esm.sh/ai@3.4.7/openai'

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
  const { current_situation, family_context, active_foundation_tools, structure_mode } = variables

  // Determine prompt template based on framework presence
  const hasFramework = !!active_foundation_tools
  const promptId = hasFramework 
    ? "pmpt_68516f961dc08190aceb4f591ee010050a454989b0581453"
    : "pmpt_68515280423c8193aaa00a07235b7cf206c51d869f9526ba"

  // Build prompt variables
  let promptVariables: any = {
    current_situation: current_situation
  }

  // Add framework if present
  if (hasFramework) {
    promptVariables.active_foundation_tools = active_foundation_tools
  }

  // Add family context for fixed structure mode
  if (structure_mode === "fixed") {
    promptVariables.family_context = family_context || "none"
  }

  try {
    // Use OpenAI Prompts API for streaming
    const response = await fetch('https://api.openai.com/v1/responses', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiClient.apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        prompt: {
          id: promptId,
          version: "12", // Latest version
          variables: promptVariables
        }
      })
    })

    if (!response.ok) {
      throw new Error(`OpenAI API error: ${response.status}`)
    }

    const data = await response.json()
    const content = data.output?.[0]?.content?.[0]?.text

    if (!content) {
      throw new Error('No content received from OpenAI')
    }

    // Stream the content using Vercel AI SDK format
    const stream = new ReadableStream({
      start(controller) {
        // Split content into chunks for streaming simulation
        const chunks = content.split(' ')
        let index = 0

        const sendChunk = () => {
          if (index < chunks.length) {
            const chunk = chunks[index] + ' '
            const sseData = `data: ${JSON.stringify([{ type: 'text', value: chunk }])}\n\n`
            controller.enqueue(new TextEncoder().encode(sseData))
            index++
            setTimeout(sendChunk, 50) // Simulate streaming delay
          } else {
            controller.enqueue(new TextEncoder().encode('data: [DONE]\n\n'))
            controller.close()
          }
        }

        sendChunk()
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
    // Use OpenAI Prompts API for situation analysis
    const response = await fetch('https://api.openai.com/v1/responses', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiClient.apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        prompt: {
          id: "pmpt_686b988bf0ac8196a69e972f08842b9a05893c8e8a5153c7",
          version: "1",
          variables: {
            long_prompt: situation_text
          }
        }
      })
    })

    if (!response.ok) {
      throw new Error(`OpenAI API error: ${response.status}`)
    }

    const data = await response.json()
    const content = data.output?.[0]?.content?.[0]?.text

    if (!content) {
      throw new Error('No content received from OpenAI')
    }

    // Parse the analysis response (expecting JSON format)
    let analysisResult
    try {
      analysisResult = JSON.parse(content)
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
    // Use OpenAI Prompts API for framework generation
    const response = await fetch('https://api.openai.com/v1/responses', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiClient.apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        prompt: {
          id: "pmpt_68511f82ba448193a1af0dc01215706f0d3d3fe75d5db0f1",
          version: "3",
          variables: {
            recent_situations: recent_situations
          }
        }
      })
    })

    if (!response.ok) {
      throw new Error(`OpenAI API error: ${response.status}`)
    }

    const data = await response.json()
    const content = data.output?.[0]?.content?.[0]?.text

    if (!content) {
      throw new Error('No content received from OpenAI')
    }

    return new Response(
      JSON.stringify({ success: true, data: content }),
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

  // Choose prompt based on extraction type
  const promptId = extraction_type === "regulation" 
    ? "pmpt_6877c15da6388196a389c79feeefd4e30cccdbe5ba3909fb"
    : "pmpt_68778827e310819792876a9f5a844c050059609da32e4637"

  const version = extraction_type === "regulation" ? "5" : "4"

  try {
    // Use OpenAI Prompts API for context extraction
    const response = await fetch('https://api.openai.com/v1/responses', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiClient.apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        prompt: {
          id: promptId,
          version: version,
          variables: {
            long_prompt: situation_text
          }
        }
      })
    })

    if (!response.ok) {
      throw new Error(`OpenAI API error: ${response.status}`)
    }

    const data = await response.json()
    const content = data.output?.[0]?.content?.[0]?.text

    if (!content) {
      throw new Error('No content received from OpenAI')
    }

    return new Response(
      JSON.stringify({ success: true, data: content }),
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
    // Use Vercel AI SDK for streaming translation
    const result = await streamText({
      model: openaiClient('gpt-4'),
      prompt: `Translate the following parenting guidance content to ${target_language}. Maintain the same structure and formatting, especially any bracket-delimited sections like [TITLE], [SITUATION], etc.:\n\n${guidance_content}`,
      maxTokens: 2000,
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