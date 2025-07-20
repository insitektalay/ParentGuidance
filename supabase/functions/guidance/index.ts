import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { promptTemplates } from '../../prompts/promptTemplates.ts'

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
  console.log(`[DEBUG] Request received: ${req.method} ${req.url}`)
  
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
    
    console.log(`[DEBUG] Parsed request - operation: "${operation}", variables keys: [${Object.keys(variables || {}).join(', ')}]`)
    console.log(`[DEBUG] Variables content: ${JSON.stringify(variables, null, 2)}`)

    if (!apiKey) {
      return new Response(
        JSON.stringify({ error: 'Missing API key' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Route to appropriate operation handler
    console.log(`[DEBUG] Routing to operation: "${operation}"`)
    switch (operation) {
      case 'guidance':
        return await handleGuidanceOperation(apiKey, variables)
      
      case 'analyze':
        return await handleAnalyzeOperation(apiKey, variables)
      
      case 'framework':
        return await handleFrameworkOperation(apiKey, variables)
      
      case 'context':
        return await handleContextOperation(apiKey, variables)
      
      case 'translate':
        return await handleTranslateOperation(apiKey, variables)
      
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

// Handle guidance generation (non-streaming for now)
async function handleGuidanceOperation(apiKey: string, variables: any) {
  const { current_situation, family_context, active_foundation_tools, structure_mode, guidance_style } = variables

  // Determine which prompt template to use
  const hasFramework = !!active_foundation_tools
  
  // Default to "Warm Practical + Fixed" if not specified
  const style = guidance_style || "Warm Practical"
  const mode = (structure_mode || "Fixed").charAt(0).toUpperCase() + (structure_mode || "Fixed").slice(1).toLowerCase()
  const configKey = `${style} + ${mode}`
  
  console.log(`[DEBUG] Guidance configuration: style="${style}", mode="${mode}", configKey="${configKey}", hasFramework=${hasFramework}`)

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

    // Use native fetch to call OpenAI API
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4',
        messages: [
          { role: 'system', content: systemPrompt }
        ],
        temperature: 0.7,
        max_tokens: 2000
      })
    })

    if (!response.ok) {
      throw new Error(`OpenAI API error: ${response.status}`)
    }

    const data = await response.json()
    const content = data.choices?.[0]?.message?.content

    if (!content) {
      throw new Error('No content received from OpenAI')
    }

    // For now, return the full response as JSON (we can add streaming later)
    // The iOS EdgeFunctionService expects streaming format, so we'll simulate it
    const stream = new ReadableStream({
      start(controller) {
        // Send the content as chunks to match expected format
        const words = content.split(' ')
        let index = 0
        
        const sendChunk = () => {
          if (index < words.length) {
            const chunk = words[index] + (index < words.length - 1 ? ' ' : '')
            const sseData = `data: ${JSON.stringify([{ type: 'text', value: chunk }])}\n\n`
            controller.enqueue(new TextEncoder().encode(sseData))
            index++
            setTimeout(sendChunk, 10) // Small delay to simulate streaming
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
async function handleAnalyzeOperation(apiKey: string, variables: any) {
  const { situation_text } = variables
  console.log(`[DEBUG] Analyze operation - situation_text: "${situation_text?.substring(0, 100)}..."`)
  console.log(`[DEBUG] Analyze - promptTemplates.analyze exists: ${!!promptTemplates.analyze}`)

  try {
    // Prepare variables for interpolation (map situation_text to situation_inputted)
    const promptVariables = {
      situation_inputted: situation_text
    }

    // Get the system prompt and interpolate variables
    const systemPrompt = interpolatePrompt(promptTemplates.analyze.systemPromptText, promptVariables)

    // Use native fetch to call OpenAI API
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4',
        messages: [
          { role: 'system', content: systemPrompt }
        ],
        temperature: 0.3, // Lower temperature for more consistent categorization
        max_tokens: 500
        // Removed JSON response format - causing 400 errors
      })
    })

    if (!response.ok) {
      const errorText = await response.text()
      console.error(`[DEBUG] Analyze operation OpenAI API error: Status ${response.status}, Body: ${errorText}`)
      throw new Error(`OpenAI API error: ${response.status} - ${errorText}`)
    }

    const data = await response.json()
    const content = data.choices?.[0]?.message?.content

    if (!content) {
      throw new Error('No content received from OpenAI')
    }

    // Parse the analysis response (custom format from prompt template)
    console.log(`[DEBUG] Analyze response content: ${content}`)
    console.log(`[DEBUG] Content length: ${content.length}`)
    console.log(`[DEBUG] Content type: ${typeof content}`)
    
    let analysisResult
    try {
      // First try JSON parsing
      console.log(`[DEBUG] Attempting JSON.parse...`)
      const parsed = JSON.parse(content)
      console.log(`[DEBUG] JSON parsing successful. Parsed object:`, JSON.stringify(parsed, null, 2))
      
      // Convert field names to match iOS expectations
      analysisResult = {
        category: parsed.category || "general",
        isIncident: parsed.incident !== undefined ? parsed.incident : false
      }
      console.log(`[DEBUG] Field conversion completed. Final result:`, JSON.stringify(analysisResult, null, 2))
    } catch (parseError) {
      console.log(`[DEBUG] JSON parsing failed with error:`, parseError.message)
      console.log(`[DEBUG] Falling back to regex parsing...`)
      
      // Fallback: parse the specific format from prompt template
      // Expected format: "category": "Label", "incident": true/false
      const categoryMatch = content.match(/"category":\s*"([^"]+)"/i)
      const incidentMatch = content.match(/"incident":\s*(true|false)/i)
      
      console.log(`[DEBUG] Category match:`, categoryMatch ? categoryMatch[1] : 'not found')
      console.log(`[DEBUG] Incident match:`, incidentMatch ? incidentMatch[1] : 'not found')
      
      analysisResult = {
        category: categoryMatch ? categoryMatch[1] : "general",
        isIncident: incidentMatch ? incidentMatch[1] === 'true' : false
      }
      console.log(`[DEBUG] Regex parsing result:`, JSON.stringify(analysisResult, null, 2))
    }
    
    console.log(`[DEBUG] Final analysis result that will be returned: ${JSON.stringify(analysisResult)}`)
    console.log(`[DEBUG] About to return HTTP response with this data...`)

    return new Response(
      JSON.stringify({ success: true, data: JSON.stringify(analysisResult) }),
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
async function handleFrameworkOperation(apiKey: string, variables: any) {
  const { recent_situations } = variables

  try {
    // Prepare variables for interpolation (map recent_situations to situation_summary)
    const promptVariables = {
      situation_summary: recent_situations
    }

    // Get the system prompt and interpolate variables
    const systemPrompt = interpolatePrompt(promptTemplates.framework.systemPromptText, promptVariables)

    // Use native fetch to call OpenAI API
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4',
        messages: [
          { role: 'system', content: systemPrompt }
        ],
        temperature: 0.7,
        max_tokens: 1000
      })
    })

    if (!response.ok) {
      throw new Error(`OpenAI API error: ${response.status}`)
    }

    const data = await response.json()
    const content = data.choices?.[0]?.message?.content

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
async function handleContextOperation(apiKey: string, variables: any) {
  const { situation_text, extraction_type } = variables
  console.log(`[DEBUG] Context operation - extraction_type: "${extraction_type}", situation_text: "${situation_text?.substring(0, 100)}..."`)

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
    
    console.log(`[DEBUG] Context - isRegulation: ${isRegulation}`)
    console.log(`[DEBUG] Context - template exists: ${!!systemPromptTemplate}`)
    console.log(`[DEBUG] Context - template length: ${systemPromptTemplate?.length || 0}`)

    // Interpolate the system prompt with variables
    const systemPrompt = interpolatePrompt(systemPromptTemplate, promptVariables)

    // Use native fetch to call OpenAI API
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4',
        messages: [
          { role: 'system', content: systemPrompt }
        ],
        temperature: 0.5,
        max_tokens: 1500
        // Removed JSON response format - causing 400 errors
      })
    })

    if (!response.ok) {
      const errorText = await response.text()
      console.error(`[DEBUG] Context operation OpenAI API error: Status ${response.status}, Body: ${errorText}`)
      throw new Error(`OpenAI API error: ${response.status} - ${errorText}`)
    }

    const data = await response.json()
    const content = data.choices?.[0]?.message?.content

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

// Handle translation (simulated streaming for compatibility)
async function handleTranslateOperation(apiKey: string, variables: any) {
  const { guidance_content, target_language } = variables

  try {
    // Prepare variables for interpolation
    const promptVariables = {
      input_text: guidance_content,
      lang: target_language
    }

    // Get the system prompt and interpolate variables
    const systemPrompt = interpolatePrompt(promptTemplates.translate.systemPromptText, promptVariables)

    // Use native fetch to call OpenAI API
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4',
        messages: [
          { role: 'system', content: systemPrompt }
        ],
        temperature: 0.3, // Lower temperature for more accurate translation
        max_tokens: 2000
      })
    })

    if (!response.ok) {
      throw new Error(`OpenAI API error: ${response.status}`)
    }

    const data = await response.json()
    const content = data.choices?.[0]?.message?.content

    if (!content) {
      throw new Error('No content received from OpenAI')
    }

    // Simulate streaming for iOS compatibility
    const stream = new ReadableStream({
      start(controller) {
        // Send the content as chunks to match expected format
        const words = content.split(' ')
        let index = 0
        
        const sendChunk = () => {
          if (index < words.length) {
            const chunk = words[index] + (index < words.length - 1 ? ' ' : '')
            const sseData = `data: ${JSON.stringify([{ type: 'text', value: chunk }])}\n\n`
            controller.enqueue(new TextEncoder().encode(sseData))
            index++
            setTimeout(sendChunk, 10) // Small delay to simulate streaming
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
