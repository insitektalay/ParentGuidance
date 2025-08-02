import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { promptTemplates } from '../../prompts/promptTemplates.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

interface RequestBody {
  operation: 'guidance' | 'analyze' | 'framework' | 'context' | 'translate' | 'psychologists_note_context' | 'psychologists_note_traits' | 'transcribe' | 'validate_key' | 'coping_strategies' | 'extract_overall_recommendation' | 'generate_embedding' | 'check_similarity' | 'which_insights_matter'
  variables: Record<string, any>
  apiKey: string
  provider?: 'openai' | 'anthropic' | 'xai' | 'google' // Provider override
  audioData?: string // Base64 encoded audio data for transcribe operation
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

// Helper function to detect provider from API key
function detectProvider(apiKey: string): 'openai' | 'anthropic' | 'xai' | 'google' {
  if (apiKey.startsWith('sk-ant-')) return 'anthropic'
  if (apiKey.startsWith('xai-')) return 'xai'
  if (apiKey.startsWith('sk-')) return 'openai'
  // Google keys are typically just alphanumeric
  return 'google'
}

// Helper function to get API endpoint and model for each provider
function getProviderConfig(provider: string) {
  switch (provider) {
    case 'openai':
      return {
        endpoint: 'https://api.openai.com/v1/chat/completions',
        model: 'gpt-4-turbo-preview',
        headers: (apiKey: string) => ({
          'Authorization': `Bearer ${apiKey}`,
          'Content-Type': 'application/json'
        })
      }
    case 'anthropic':
      return {
        endpoint: 'https://api.anthropic.com/v1/messages',
        model: 'claude-3-sonnet-20240229',
        headers: (apiKey: string) => ({
          'x-api-key': apiKey,
          'Content-Type': 'application/json',
          'anthropic-version': '2023-06-01'
        })
      }
    case 'xai':
      return {
        endpoint: 'https://api.x.ai/v1/chat/completions',
        model: 'grok-beta',
        headers: (apiKey: string) => ({
          'Authorization': `Bearer ${apiKey}`,
          'Content-Type': 'application/json'
        })
      }
    case 'google':
      return {
        endpoint: 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent',
        model: 'gemini-pro',
        headers: (apiKey: string) => ({
          'Content-Type': 'application/json'
        }),
        // Google uses API key as query parameter
        keyParam: 'key'
      }
    default:
      throw new Error(`Unsupported provider: ${provider}`)
  }
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
    const { operation, variables, apiKey, provider } = body
    
    // Determine the AI provider to use
    const detectedProvider = provider || detectProvider(apiKey)
    console.log(`[DEBUG] Operation: ${operation}, provider: ${detectedProvider}, variables: [${Object.keys(variables || {}).join(', ')}]`)

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
        return await handleGuidanceOperation(apiKey, variables, detectedProvider)
      
      case 'analyze':
        return await handleAnalyzeOperation(apiKey, variables, detectedProvider)
      
      case 'framework':
        return await handleFrameworkOperation(apiKey, variables, detectedProvider)
      
      case 'context':
        return await handleContextOperation(apiKey, variables, detectedProvider)
      
      case 'translate':
        return await handleTranslateOperation(apiKey, variables, detectedProvider)
      
      case 'psychologists_note_context':
        return await handlePsychologistNoteContextOperation(apiKey, variables, detectedProvider)
      
      case 'psychologists_note_traits':
        return await handlePsychologistNoteTraitsOperation(apiKey, variables, detectedProvider)
      
      case 'transcribe':
        return await handleTranscribeOperation(apiKey, variables, body.audioData, detectedProvider)
      
      case 'validate_key':
        return await handleValidateKeyOperation(apiKey, detectedProvider)
      
      case 'coping_strategies':
        return await handleCopingStrategiesOperation(apiKey, variables, detectedProvider)
      
      case 'extract_overall_recommendation':
        return await handleExtractOverallRecommendationOperation(apiKey, variables, detectedProvider)
      
      case 'generate_embedding':
        return await handleGenerateEmbeddingOperation(apiKey, variables, detectedProvider)
      
      case 'check_similarity':
        return await handleCheckSimilarityOperation(apiKey, variables, detectedProvider)
      
      case 'which_insights_matter':
        return await handleWhichInsightsMatterOperation(apiKey, variables, detectedProvider)
      
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

// Handle API key validation
async function handleValidateKeyOperation(apiKey: string, provider: string) {
  console.log(`[DEBUG] Validating API key for provider: ${provider}`)
  
  try {
    const config = getProviderConfig(provider)
    
    // Prepare a minimal request body for validation
    let requestBody
    if (provider === 'anthropic') {
      requestBody = {
        model: config.model,
        max_tokens: 5,
        messages: [
          { role: 'user', content: 'Hello' }
        ]
      }
    } else if (provider === 'google') {
      requestBody = {
        contents: [{
          parts: [{ text: 'Hello' }]
        }],
        generationConfig: {
          maxOutputTokens: 5
        }
      }
    } else {
      // OpenAI and xAI use the same format
      requestBody = {
        model: config.model,
        messages: [
          { role: 'user', content: 'Hello' }
        ],
        max_tokens: 5
      }
    }
    
    // Make API request to validate key
    const url = config.keyParam ? `${config.endpoint}?${config.keyParam}=${apiKey}` : config.endpoint
    const response = await fetch(url, {
      method: 'POST',
      headers: config.headers(apiKey),
      body: JSON.stringify(requestBody)
    })
    
    if (response.ok) {
      console.log(`[DEBUG] API key validation successful for ${provider}`)
      return new Response(
        JSON.stringify({ success: true }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    } else {
      const errorText = await response.text()
      console.error(`[ERROR] API key validation failed for ${provider}: ${response.status} - ${errorText}`)
      return new Response(
        JSON.stringify({ success: false, error: `API key validation failed: ${response.status}` }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
  } catch (error) {
    console.error(`[ERROR] API key validation failed for ${provider}:`, error)
    
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}

// Handle coping strategies extraction
async function handleCopingStrategiesOperation(apiKey: string, variables: any, provider: string) {
  const { longtext } = variables
  console.log(`[DEBUG] Coping strategies operation - text length: ${longtext?.length || 0}`)

  try {
    // Prepare variables for interpolation
    const promptVariables = {
      longtext: longtext
    }

    // Get the system prompt and interpolate variables
    const systemPrompt = interpolatePrompt(promptTemplates.child_coping_strategies.systemPromptText, promptVariables)

    // Use direct API calls for multi-provider support
    const config = getProviderConfig(provider)
    
    console.log(`[DEBUG] Coping strategies using ${provider} with model: ${config.model}`)
    
    // Prepare request body based on provider
    let requestBody
    if (provider === 'anthropic') {
      requestBody = {
        model: config.model,
        max_tokens: 500,
        temperature: 0.3,
        messages: [
          { role: 'user', content: systemPrompt }
        ]
      }
    } else if (provider === 'google') {
      requestBody = {
        contents: [{
          parts: [{ text: systemPrompt }]
        }],
        generationConfig: {
          maxOutputTokens: 500,
          temperature: 0.3
        }
      }
    } else {
      // OpenAI and xAI use the same format
      requestBody = {
        model: config.model,
        messages: [
          { role: 'system', content: systemPrompt }
        ],
        temperature: 0.3,
        max_tokens: 500
      }
    }
    
    // Make API request
    const url = config.keyParam ? `${config.endpoint}?${config.keyParam}=${apiKey}` : config.endpoint
    const response = await fetch(url, {
      method: 'POST',
      headers: config.headers(apiKey),
      body: JSON.stringify(requestBody)
    })
    
    if (!response.ok) {
      const errorText = await response.text()
      console.error(`[ERROR] Coping strategies ${provider} API error: ${response.status}`)
      throw new Error(`${provider} API error: ${response.status} - ${errorText}`)
    }
    
    const data = await response.json()
    console.log(`[DEBUG] Coping strategies response received from ${provider}`)
    
    // Extract response text based on provider
    let responseText
    if (provider === 'anthropic') {
      responseText = data.content?.[0]?.text || ''
    } else if (provider === 'google') {
      responseText = data.candidates?.[0]?.content?.parts?.[0]?.text || ''
    } else {
      // OpenAI and xAI
      responseText = data.choices?.[0]?.message?.content || ''
    }
    
    console.log(`[DEBUG] Extracted coping strategies: ${responseText}`)
    
    return new Response(
      JSON.stringify({ success: true, data: responseText }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
    
  } catch (error) {
    console.error('[ERROR] Coping strategies operation failed:', error)
    return new Response(
      JSON.stringify({ error: 'Coping strategies extraction failed', details: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}

// Handle guidance generation (non-streaming for now)
  async function handleGuidanceOperation(apiKey: string, variables: any, provider: string) {
    const { current_situation, child_context, key_insights, active_foundation_tools, structure_mode, guidance_style, situation_type } = variables

    // Determine which prompt template to use
    const hasFramework = !!active_foundation_tools

    // Default to "Warm Practical + Fixed" if not specified
    const style = guidance_style || "Warm Practical"
    const mode = (structure_mode || "Fixed").charAt(0).toUpperCase() + (structure_mode || "Fixed").slice(1).toLowerCase()
    const configKey = `${style} + ${mode}`

    console.log(`[DEBUG] Guidance configuration: style="${style}", mode="${mode}", configKey="${configKey}", hasFramework=${hasFramework}`)
    console.log(`[DEBUG] Situation type: ${situation_type || 'not provided'}`) // NEW LINE ADDED
    console.log(`[DEBUG] Raw variables received:`, { guidance_style, structure_mode })

    try {
      // Map situation_type to guidance note
      const situationTypeToGuidanceNote: Record<string, string> = {
        'just_let_me_type': 'Respond naturally based on the situation text. No assumptions about urgency, tone, or structure.',
        'crisis_now': 'This is an urgent, emotionally intense moment. Provide fast, calming, practical guidance with empathy.',
        'what_just_happened': 'Reflect on the recent moment with insight. Help the parent understand what might have happened internally for the child and offer suggestions for next time.',
        'foundational_work': 'Address a deeper trait or pattern. Focus on long-term development, emotional growth, and internal change.',
        'teach_me_a_tactic': 'Give step-by-step, practical suggestions to resolve everyday struggles with warmth and realism.',
        'know_my_child': 'The user is offering background info. Focus on understanding the child better to inform future guidance.',
        'rebuild_connection': 'Help the parent repair emotional connection. Emphasize empathy, trust-building, and emotional safety.',
        'im_just_wondering': 'This is a non-urgent question. Offer thoughtful, curious, and informative guidance that supports reflective parenting.'
      }
      
      const situationTypeKey = situation_type || 'im_just_wondering'
      const guidanceNote = situationTypeToGuidanceNote[situationTypeKey] || situationTypeToGuidanceNote['im_just_wondering']
      
      console.log(`[DEBUG] Situation type '${situationTypeKey}' mapped to guidance note: "${guidanceNote}"`)

      // Select the appropriate prompt template
      let promptTemplate: any
      let promptVariables: Record<string, any> = {
        current_situation: current_situation,
        situation_type: situationTypeKey,
        situation_guidance_note: guidanceNote
      }

      if (hasFramework) {
        // With framework
        promptTemplate = promptTemplates.guidance.versions_with_framework[configKey]
        if (!promptTemplate) {
          throw new Error(`Unknown guidance configuration: ${configKey}`)
        }
        console.log(`[DEBUG] Selected WITH FRAMEWORK prompt: ${configKey}`)
        promptVariables.active_foundation_tools = active_foundation_tools
      } else {
        // Without framework
        promptTemplate = promptTemplates.guidance.versions_no_framework[configKey]
        if (!promptTemplate) {
          throw new Error(`Unknown guidance configuration: ${configKey}`)
        }
        console.log(`[DEBUG] Selected NO FRAMEWORK prompt: ${configKey}`)
        // Add psychologist notes variables if present
        if (child_context && promptTemplate.variables.includes("child_context")) {
          promptVariables.child_context = child_context
        }
        if (key_insights && promptTemplate.variables.includes("key_insights")) {
          promptVariables.key_insights = key_insights
        }
      }

      // Interpolate the system prompt with variables
      const systemPrompt = interpolatePrompt(promptTemplate.systemPromptText, promptVariables)

      // Log the complete final prompt for debugging
      console.log(`🚨🚨🚨 COMPLETE FINAL PROMPT STARTS HERE 🚨🚨🚨`)
      console.log(`Provider: ${provider} | Template: ${configKey}`)
      console.log(`Variables:`, promptVariables)
      console.log(`🚨🚨🚨 FULL PROMPT TEXT BELOW 🚨🚨🚨`)
      console.log(systemPrompt)
      console.log(`🚨🚨🚨 COMPLETE FINAL PROMPT ENDS HERE 🚨🚨🚨`)

      // Use direct API calls for multi-provider support
      const config = getProviderConfig(provider)
      
      console.log(`[DEBUG] Using ${provider} with model: ${config.model}`)
      
      // Prepare request body based on provider
      let requestBody
      if (provider === 'anthropic') {
        requestBody = {
          model: config.model,
          max_tokens: 2000,
          temperature: 0.7,
          messages: [
            { role: 'user', content: systemPrompt }
          ]
        }
      } else if (provider === 'google') {
        requestBody = {
          contents: [{
            parts: [{ text: systemPrompt }]
          }],
          generationConfig: {
            temperature: 0.7,
            maxOutputTokens: 2000
          }
        }
      } else {
        // OpenAI and xAI use the same format
        requestBody = {
          model: config.model,
          messages: [
            { role: 'system', content: systemPrompt }
          ],
          temperature: 0.7,
          max_tokens: 2000
        }
      }
      
      // Make API request
      const url = config.keyParam ? `${config.endpoint}?${config.keyParam}=${apiKey}` : config.endpoint
      const response = await fetch(url, {
        method: 'POST',
        headers: config.headers(apiKey),
        body: JSON.stringify(requestBody)
      })

      if (!response.ok) {
        const errorText = await response.text()
        console.error(`[ERROR] ${provider} API error: ${response.status} - ${errorText}`)
        throw new Error(`${provider} API error: ${response.status}`)
      }

      const data = await response.json()
      
      // Extract content based on provider response format
      let content
      if (provider === 'anthropic') {
        content = data.content?.[0]?.text
      } else if (provider === 'google') {
        content = data.candidates?.[0]?.content?.parts?.[0]?.text
      } else {
        // OpenAI and xAI
        content = data.choices?.[0]?.message?.content
      }

      if (!content) {
        console.error(`[ERROR] No content received from ${provider}`)
        throw new Error(`No content received from ${provider}`)
      }

      console.log(`[DEBUG] Guidance response received, length: ${content.length} characters`)

      // Return the content as SSE stream for iOS client compatibility
      const stream = new ReadableStream({
        async start(controller) {
          try {
            // Stream the content word by word to simulate streaming
            const words = content.split(' ')
            
            for (let i = 0; i < words.length; i++) {
              const chunk = words[i] + (i < words.length - 1 ? ' ' : '')
              const sseData = `data: ${JSON.stringify([{ type: 'text', value: chunk }])}\n\n`
              controller.enqueue(new TextEncoder().encode(sseData))
              
              // Small delay to simulate streaming
              if (i < words.length - 1) {
                await new Promise(resolve => setTimeout(resolve, 5))
              }
            }
            
            // Send completion signal
            controller.enqueue(new TextEncoder().encode('data: [DONE]\n\n'))
            controller.close()
          } catch (error) {
            console.error('[ERROR] Streaming error:', error)
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
async function handleAnalyzeOperation(apiKey: string, variables: any, provider: string) {
  const { situation_text } = variables
  console.log(`[DEBUG] Analyze operation - text length: ${situation_text?.length || 0}`)

  try {
    // Prepare variables for interpolation (map situation_text to situation_inputted)
    const promptVariables = {
      situation_inputted: situation_text
    }

    // Get the system prompt and interpolate variables
    const systemPrompt = interpolatePrompt(promptTemplates.analyze.systemPromptText, promptVariables)

    // Use direct API calls for multi-provider support
    const config = getProviderConfig(provider)
    
    console.log(`[DEBUG] Analyze using ${provider} with model: ${config.model}`)
    
    // Prepare request body based on provider
    let requestBody
    if (provider === 'anthropic') {
      requestBody = {
        model: config.model,
        max_tokens: 500,
        temperature: 0.3,
        messages: [
          { role: 'user', content: systemPrompt }
        ]
      }
    } else if (provider === 'google') {
      requestBody = {
        contents: [{
          parts: [{ text: systemPrompt }]
        }],
        generationConfig: {
          temperature: 0.3,
          maxOutputTokens: 500
        }
      }
    } else {
      // OpenAI and xAI use the same format
      requestBody = {
        model: config.model,
        messages: [
          { role: 'system', content: systemPrompt }
        ],
        temperature: 0.3,
        max_tokens: 500
      }
    }
    
    // Make API request
    const url = config.keyParam ? `${config.endpoint}?${config.keyParam}=${apiKey}` : config.endpoint
    const response = await fetch(url, {
      method: 'POST',
      headers: config.headers(apiKey),
      body: JSON.stringify(requestBody)
    })

    if (!response.ok) {
      const errorText = await response.text()
      console.error(`[ERROR] ${provider} API error: ${response.status} - ${errorText}`)
      throw new Error(`${provider} API error: ${response.status}`)
    }

    const data = await response.json()
    
    // Extract content based on provider response format
    let content
    if (provider === 'anthropic') {
      content = data.content?.[0]?.text
    } else if (provider === 'google') {
      content = data.candidates?.[0]?.content?.parts?.[0]?.text
    } else {
      // OpenAI and xAI
      content = data.choices?.[0]?.message?.content
    }

    if (!content) {
      throw new Error(`No content received from ${provider}`)
    }

    // Parse the analysis response (custom format from prompt template)
    console.log(`[DEBUG] Analyze response content: ${content}`)
    
    let analysisResult
    try {
      // First try JSON parsing
      const parsed = JSON.parse(content)
      // Convert field names to match iOS expectations
      analysisResult = {
        category: parsed.category || "general",
        isIncident: parsed.incident !== undefined ? parsed.incident : false
      }
    } catch (parseError) {
      console.log(`[DEBUG] JSON parsing failed, using regex fallback`)
      // Fallback: parse the specific format from prompt template
      const categoryMatch = content.match(/"category":\s*"([^"]+)"/i)
      const incidentMatch = content.match(/"incident":\s*(true|false)/i)
      
      analysisResult = {
        category: categoryMatch ? categoryMatch[1] : "general",
        isIncident: incidentMatch ? incidentMatch[1] === 'true' : false
      }
    }
    
    console.log(`[DEBUG] Analysis result: ${JSON.stringify(analysisResult)}`)

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
async function handleFrameworkOperation(apiKey: string, variables: any, provider: string) {
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
        model: 'gpt-4-turbo-preview',
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
async function handleContextOperation(apiKey: string, variables: any, provider: string) {
  const { situation_text, extraction_type } = variables
  console.log(`[DEBUG] Context operation - type: ${extraction_type}, text length: ${situation_text?.length || 0}`)

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

    // Use native fetch to call OpenAI API
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4-turbo-preview',
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
      console.error(`[ERROR] Context OpenAI API error: ${response.status}`)
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
async function handleTranslateOperation(apiKey: string, variables: any, provider: string) {
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
        model: 'gpt-4-turbo-preview',
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

// Handle psychologist note context generation (non-streaming)
async function handlePsychologistNoteContextOperation(apiKey: string, variables: any, provider: string) {
  const { structured_context_data_over_time } = variables
  console.log(`[DEBUG] Psychologist note context operation - data length: ${structured_context_data_over_time?.length || 0}`)

  try {
    // Prepare variables for interpolation
    const promptVariables = {
      structured_context_data_over_time: structured_context_data_over_time
    }

    // Get the system prompt and interpolate variables
    const systemPrompt = interpolatePrompt(promptTemplates.psychologists_note_context.systemPromptText, promptVariables)

    // Use native fetch to call OpenAI API
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4-turbo-preview',
        messages: [
          { role: 'system', content: systemPrompt }
        ],
        temperature: 0.6, // Balanced temperature for clinical insights
        max_tokens: 2000
      })
    })

    if (!response.ok) {
      const errorText = await response.text()
      console.error(`[ERROR] Psychologist note context OpenAI API error: ${response.status}`)
      throw new Error(`OpenAI API error: ${response.status} - ${errorText}`)
    }

    const data = await response.json()
    const content = data.choices?.[0]?.message?.content

    if (!content) {
      throw new Error('No content received from OpenAI')
    }

    console.log(`[DEBUG] Psychologist note context response: ${content.substring(0, 100)}...`)

    return new Response(
      JSON.stringify({ success: true, data: content }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Psychologist note context operation error:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to generate psychologist note context', details: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}

// Handle psychologist note traits generation (non-streaming)
async function handlePsychologistNoteTraitsOperation(apiKey: string, variables: any, provider: string) {
  const { bullet_point_pattern_data_over_time } = variables
  console.log(`[DEBUG] Psychologist note traits operation - data length: ${bullet_point_pattern_data_over_time?.length || 0}`)

  try {
    // Prepare variables for interpolation
    const promptVariables = {
      bullet_point_pattern_data_over_time: bullet_point_pattern_data_over_time
    }

    // Get the system prompt and interpolate variables
    const systemPrompt = interpolatePrompt(promptTemplates.psychologists_note_traits.systemPromptText, promptVariables)

    // Use native fetch to call OpenAI API
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4-turbo-preview',
        messages: [
          { role: 'system', content: systemPrompt }
        ],
        temperature: 0.6, // Balanced temperature for clinical insights
        max_tokens: 2000
      })
    })

    if (!response.ok) {
      const errorText = await response.text()
      console.error(`[ERROR] Psychologist note traits OpenAI API error: ${response.status}`)
      throw new Error(`OpenAI API error: ${response.status} - ${errorText}`)
    }

    const data = await response.json()
    const content = data.choices?.[0]?.message?.content

    if (!content) {
      throw new Error('No content received from OpenAI')
    }

    console.log(`[DEBUG] Psychologist note traits response: ${content.substring(0, 100)}...`)

    return new Response(
      JSON.stringify({ success: true, data: content }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Psychologist note traits operation error:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to generate psychologist note traits', details: error.message }),
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

// ================== AUDIO TRANSCRIPTION HANDLER ==================

// Handle overall recommendation extraction
async function handleExtractOverallRecommendationOperation(apiKey: string, variables: any, provider: string) {
  const { source_text } = variables
  console.log(`[DEBUG] Extract overall recommendation operation - text length: ${source_text?.length || 0}`)

  try {
    // Prepare variables for interpolation
    const promptVariables = {
      source_text: source_text
    }

    // Get the system prompt and interpolate variables
    const systemPrompt = interpolatePrompt(promptTemplates.extract_overall_recomendation.systemPromptText, promptVariables)

    // Use direct API calls for multi-provider support
    const config = getProviderConfig(provider)
    
    console.log(`[DEBUG] Extract overall recommendation using ${provider} with model: ${config.model}`)
    
    // Prepare request body based on provider
    let requestBody
    if (provider === 'anthropic') {
      requestBody = {
        model: config.model,
        max_tokens: 500,
        temperature: 0.3,
        messages: [
          { role: 'user', content: systemPrompt }
        ]
      }
    } else if (provider === 'google') {
      requestBody = {
        contents: [{
          parts: [{ text: systemPrompt }]
        }],
        generationConfig: {
          maxOutputTokens: 500,
          temperature: 0.3
        }
      }
    } else {
      // OpenAI and xAI use the same format
      requestBody = {
        model: config.model,
        messages: [
          { role: 'system', content: systemPrompt }
        ],
        temperature: 0.3,
        max_tokens: 500
      }
    }
    
    // Make API request
    const url = config.keyParam ? `${config.endpoint}?${config.keyParam}=${apiKey}` : config.endpoint
    const response = await fetch(url, {
      method: 'POST',
      headers: config.headers(apiKey),
      body: JSON.stringify(requestBody)
    })
    
    if (!response.ok) {
      const errorText = await response.text()
      console.error(`[ERROR] Extract overall recommendation ${provider} API error: ${response.status}`)
      throw new Error(`${provider} API error: ${response.status} - ${errorText}`)
    }
    
    const data = await response.json()
    console.log(`[DEBUG] Extract overall recommendation response received from ${provider}`)
    
    // Extract response text based on provider
    let responseText
    if (provider === 'anthropic') {
      responseText = data.content?.[0]?.text || ''
    } else if (provider === 'google') {
      responseText = data.candidates?.[0]?.content?.parts?.[0]?.text || ''
    } else {
      // OpenAI and xAI
      responseText = data.choices?.[0]?.message?.content || ''
    }
    
    console.log(`[DEBUG] Extracted overall recommendation: ${responseText}`)
    
    return new Response(
      JSON.stringify({ success: true, data: responseText }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
    
  } catch (error) {
    console.error('[ERROR] Extract overall recommendation operation failed:', error)
    return new Response(
      JSON.stringify({ error: 'Overall recommendation extraction failed', details: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}

async function handleTranscribeOperation(
  apiKey: string, 
  variables: Record<string, any>,
  audioData?: string,
  provider: string = 'openai'
): Promise<Response> {
  console.log('[DEBUG] Starting audio transcription operation')

  try {
    // Validate audio data
    if (!audioData) {
      throw new Error('No audio data provided')
    }

    // Decode base64 audio data
    const audioBuffer = Uint8Array.from(atob(audioData), c => c.charCodeAt(0))
    console.log(`[DEBUG] Audio buffer size: ${audioBuffer.length} bytes`)

    // Create a File object from the buffer
    const audioFile = new File([audioBuffer], 'audio.m4a', { type: 'audio/m4a' })

    // Use Vercel AI SDK for transcription
    console.log('[DEBUG] Calling OpenAI Whisper via Vercel AI SDK')
    
    // Note: The Vercel AI SDK doesn't have a direct transcription method yet,
    // so we'll make a direct API call with proper error handling
    const formData = new FormData()
    formData.append('file', audioFile)
    formData.append('model', 'whisper-1')
    formData.append('response_format', 'json')

    const response = await fetch('https://api.openai.com/v1/audio/transcriptions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
      },
      body: formData
    })

    if (!response.ok) {
      const errorText = await response.text()
      console.error(`[ERROR] Transcription API error: ${response.status} - ${errorText}`)
      throw new Error(`Transcription API error: ${response.status}`)
    }

    const data = await response.json()
    console.log('[DEBUG] Transcription successful')

    return new Response(
      JSON.stringify({ 
        transcription: data.text,
        duration: data.duration 
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('[ERROR] Transcription operation failed:', error)
    return new Response(
      JSON.stringify({ 
        error: error.message || 'Transcription failed',
        details: 'Failed to transcribe audio'
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
}

// ================== EMBEDDING GENERATION HANDLER ==================

// Handle embedding generation with multilingual support
async function handleGenerateEmbeddingOperation(apiKey: string, variables: any, provider: string) {
  const { text, source_language } = variables
  console.log(`[DEBUG] Generate embedding operation - text length: ${text?.length || 0}, source language: ${source_language || 'auto-detect'}`)

  try {
    const startTime = Date.now()
    
    // Step 1: Detect language if not provided
    let detectedLanguage = source_language || 'unknown'
    let textToEmbed = text
    let wasTranslated = false
    
    if (!source_language) {
      // Simple language detection - check for non-ASCII characters and common words
      detectedLanguage = detectLanguage(text)
      console.log(`[DEBUG] Detected language: ${detectedLanguage}`)
    }
    
    // Step 2: Translate to English if needed
    if (detectedLanguage !== 'en' && detectedLanguage !== 'unknown') {
      console.log(`[DEBUG] Translating from ${detectedLanguage} to English`)
      
      try {
        // Use the existing translate prompt template
        const translateVariables = {
          input_text: text,
          lang: 'English'
        }
        
        const translatePrompt = interpolatePrompt(promptTemplates.translate.systemPromptText, translateVariables)
        
        // Use OpenAI for translation (most reliable for embeddings)
        const translateResponse = await fetch('https://api.openai.com/v1/chat/completions', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${apiKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            model: 'gpt-4-turbo-preview',
            messages: [
              { role: 'system', content: translatePrompt }
            ],
            temperature: 0.3,
            max_tokens: 1000
          })
        })
        
        if (translateResponse.ok) {
          const translateData = await translateResponse.json()
          textToEmbed = translateData.choices?.[0]?.message?.content || text
          wasTranslated = true
          console.log(`[DEBUG] Translation successful: ${textToEmbed.substring(0, 100)}...`)
        } else {
          console.log(`[DEBUG] Translation failed, using original text`)
          textToEmbed = text
        }
      } catch (translateError) {
        console.log(`[DEBUG] Translation error, using original text: ${translateError}`)
        textToEmbed = text
      }
    }
    
    // Step 3: Generate embedding using OpenAI (always use OpenAI for consistency)
    console.log(`[DEBUG] Generating embedding for text: ${textToEmbed.substring(0, 100)}...`)
    
    const embeddingResponse = await fetch('https://api.openai.com/v1/embeddings', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'text-embedding-3-small',
        input: textToEmbed,
        encoding_format: 'float'
      })
    })
    
    if (!embeddingResponse.ok) {
      const errorText = await embeddingResponse.text()
      console.error(`[ERROR] Embedding API error: ${embeddingResponse.status} - ${errorText}`)
      throw new Error(`Embedding API error: ${embeddingResponse.status}`)
    }
    
    const embeddingData = await embeddingResponse.json()
    const embedding = embeddingData.data?.[0]?.embedding
    
    if (!embedding) {
      console.error(`[ERROR] No embedding data received`)
      throw new Error('No embedding data received')
    }
    
    const processingTime = Date.now() - startTime
    console.log(`[DEBUG] Embedding generated successfully in ${processingTime}ms`)
    
    return new Response(
      JSON.stringify({
        success: true,
        data: {
          embedding: embedding,
          detectedLanguage: detectedLanguage,
          wasTranslated: wasTranslated,
          originalText: text,
          embeddedText: textToEmbed,
          model: 'text-embedding-3-small',
          dimension: embedding.length,
          processingTimeMs: processingTime
        }
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
    
  } catch (error) {
    console.error('[ERROR] Generate embedding operation failed:', error)
    return new Response(
      JSON.stringify({ error: 'Embedding generation failed', details: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}

// Simple language detection function
function detectLanguage(text: string): string {
  if (!text || text.trim().length === 0) return 'unknown'
  
  // Simple heuristics for common languages
  const englishWords = ['the', 'and', 'is', 'in', 'to', 'of', 'a', 'that', 'it', 'with', 'for', 'as', 'was', 'on', 'are', 'you']
  const spanishWords = ['el', 'la', 'de', 'que', 'y', 'a', 'en', 'un', 'es', 'se', 'no', 'te', 'lo', 'le', 'da', 'su']
  const frenchWords = ['le', 'de', 'et', 'à', 'un', 'il', 'être', 'et', 'en', 'avoir', 'que', 'pour', 'dans', 'ce', 'son']
  
  const lowerText = text.toLowerCase()
  
  // Count matches for each language
  const englishMatches = englishWords.filter(word => lowerText.includes(` ${word} `) || lowerText.startsWith(`${word} `) || lowerText.endsWith(` ${word}`)).length
  const spanishMatches = spanishWords.filter(word => lowerText.includes(` ${word} `) || lowerText.startsWith(`${word} `) || lowerText.endsWith(` ${word}`)).length
  const frenchMatches = frenchWords.filter(word => lowerText.includes(` ${word} `) || lowerText.startsWith(`${word} `) || lowerText.endsWith(` ${word}`)).length
  
  // Check for non-ASCII characters (suggests non-English)
  const hasNonAscii = /[^\x00-\x7F]/.test(text)
  
  if (englishMatches > spanishMatches && englishMatches > frenchMatches && !hasNonAscii) {
    return 'en'
  } else if (spanishMatches > englishMatches && spanishMatches > frenchMatches) {
    return 'es'
  } else if (frenchMatches > englishMatches && frenchMatches > spanishMatches) {
    return 'fr'
  } else if (hasNonAscii) {
    return 'non-en' // Generic non-English
  }
  
  return 'en' // Default to English
}

// ================== SIMILARITY CHECK HANDLER ==================

// Handle similarity checking with deduplication policies
async function handleCheckSimilarityOperation(apiKey: string, variables: any, provider: string) {
  const { 
    embedding, 
    family_id, 
    category, 
    table_name, 
    similarity_threshold,
    subcategory,
    max_results = 20
  } = variables
  
  console.log(`[DEBUG] Check similarity operation - table: ${table_name}, category: ${category}, threshold: ${similarity_threshold}`)

  try {
    // Initialize Supabase client with service role for database operations
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const startTime = Date.now()
    
    // Validate inputs
    if (!embedding || !Array.isArray(embedding)) {
      throw new Error('Invalid embedding provided')
    }
    
    if (!family_id || !category || !table_name) {
      throw new Error('Missing required parameters: family_id, category, table_name')
    }
    
    // Use default thresholds from settings if not provided
    const threshold = similarity_threshold || (table_name === 'insight_bullet_points' ? 0.90 : 0.85)
    
    let similarInsights = []
    
    // Query for similar insights based on table
    if (table_name === 'insight_bullet_points') {
      console.log(`[DEBUG] Searching for similar bullet points in category: ${category}`)
      
      const { data, error } = await supabaseClient.rpc('find_similar_bullet_points', {
        target_embedding: `[${embedding.join(',')}]`,
        family_id_filter: family_id,
        category_filter: category,
        similarity_threshold: threshold,
        max_results: max_results
      })
      
      if (error) {
        console.error(`[ERROR] Database error in similarity search: ${error.message}`)
        throw new Error(`Database error: ${error.message}`)
      }
      
      similarInsights = data || []
      
    } else if (table_name === 'contextual_insights') {
      console.log(`[DEBUG] Searching for similar contextual insights in category: ${category}`)
      
      const { data, error } = await supabaseClient.rpc('find_similar_contextual_insights', {
        target_embedding: `[${embedding.join(',')}]`,
        family_id_filter: family_id,
        category_filter: category,
        similarity_threshold: threshold,
        max_results: max_results
      })
      
      if (error) {
        console.error(`[ERROR] Database error in similarity search: ${error.message}`)
        throw new Error(`Database error: ${error.message}`)
      }
      
      similarInsights = data || []
    } else {
      throw new Error(`Unsupported table: ${table_name}`)
    }
    
    // Apply category-specific deduplication policies
    const deduplicationPolicy = getDeduplicationPolicy(table_name, category, subcategory)
    
    const searchTime = Date.now() - startTime
    console.log(`[DEBUG] Found ${similarInsights.length} similar insights in ${searchTime}ms`)
    
    // Determine recommended action based on policy and similarity scores
    let recommendedAction = 'insert'
    let highestSimilarity = 0
    
    if (similarInsights.length > 0) {
      highestSimilarity = Math.max(...similarInsights.map(insight => insight.similarity_score))
      
      switch (deduplicationPolicy) {
        case 'DROP':
          recommendedAction = 'drop'
          break
        case 'REWRITE':
          recommendedAction = 'rewrite'
          break
        case 'FUSE':
          recommendedAction = 'fuse'
          break
        default:
          recommendedAction = 'insert'
      }
    }
    
    return new Response(
      JSON.stringify({
        success: true,
        data: {
          similarInsights: similarInsights,
          recommendedAction: recommendedAction,
          deduplicationPolicy: deduplicationPolicy,
          highestSimilarity: highestSimilarity,
          searchTimeMs: searchTime,
          threshold: threshold,
          totalFound: similarInsights.length
        }
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
    
  } catch (error) {
    console.error('[ERROR] Check similarity operation failed:', error)
    return new Response(
      JSON.stringify({ error: 'Similarity check failed', details: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}

// Get deduplication policy for a given category
function getDeduplicationPolicy(tableName: string, category: string, subcategory?: string): string {
  if (tableName === 'insight_bullet_points') {
    // Regulation insights policies
    switch (category.toLowerCase()) {
      case 'core':
      case 'emotional_regulation':
        return 'DROP'
      case 'adhd':
      case 'attention_focus':
        return 'DROP'
      case 'mildautism':
      case 'mild_autism':
      case 'flexibility_social':
        return 'DROP'
      case 'copingstrategies':
      case 'coping_strategies':
        return 'REWRITE'
      default:
        return 'DROP'
    }
  } else if (tableName === 'contextual_insights') {
    // Contextual insights policies
    switch (category.toLowerCase()) {
      case 'family_context':
        return 'DROP'
      case 'medical_health':
      case 'medical':
      case 'health':
        return 'DROP'
      case 'educational_academic':
      case 'educational':
      case 'academic':
        return 'DROP'
      case 'parenting_approaches':
      case 'parenting':
        return 'DROP'
      case 'sibling_dynamics':
      case 'sibling':
        return 'FUSE'
      default:
        return 'DROP'
    }
  }
  
  return 'DROP' // Default to dropping duplicates
}

// Handle which insights matter operation
async function handleWhichInsightsMatterOperation(apiKey: string, variables: any, provider: string) {
  const { GuidanceText, InsightList } = variables
  console.log(`[DEBUG] Which insights matter operation - guidance length: ${GuidanceText?.length || 0}, insights count: ${InsightList?.length || 0}`)

  try {
    // Prepare variables for interpolation
    const promptVariables = {
      GuidanceText: GuidanceText,
      InsightList: InsightList
    }

    // Get the system prompt and interpolate variables
    const systemPrompt = interpolatePrompt(promptTemplates.which_insights_matter.systemPromptText, promptVariables)

    // Use direct API calls for multi-provider support
    const config = getProviderConfig(provider)
    
    console.log(`[DEBUG] Which insights matter using ${provider} with model: ${config.model}`)
    
    // Prepare request body based on provider
    let requestBody
    if (provider === 'anthropic') {
      requestBody = {
        model: config.model,
        max_tokens: 2000,
        temperature: 0.3,
        messages: [
          { role: 'user', content: systemPrompt }
        ]
      }
    } else if (provider === 'google') {
      requestBody = {
        contents: [{
          parts: [{ text: systemPrompt }]
        }],
        generationConfig: {
          maxOutputTokens: 2000,
          temperature: 0.3
        }
      }
    } else {
      // OpenAI and xAI use the same format
      requestBody = {
        model: config.model,
        messages: [
          { role: 'system', content: systemPrompt }
        ],
        temperature: 0.3,
        max_tokens: 2000
      }
    }

    // Make API request
    const url = config.keyParam ? `${config.endpoint}?${config.keyParam}=${apiKey}` : config.endpoint
    const response = await fetch(url, {
      method: 'POST',
      headers: config.headers(apiKey),
      body: JSON.stringify(requestBody)
    })

    if (!response.ok) {
      const errorText = await response.text()
      console.error(`[ERROR] Which insights matter API call failed: ${response.status} - ${errorText}`)
      throw new Error(`API call failed: ${response.status}`)
    }

    // Parse response based on provider
    let content
    if (provider === 'anthropic') {
      const data = await response.json()
      content = data.content[0].text
    } else if (provider === 'google') {
      const data = await response.json()
      content = data.candidates[0].content.parts[0].text
    } else {
      // OpenAI and xAI format
      const data = await response.json()
      content = data.choices[0].message.content
    }

    console.log(`[DEBUG] Which insights matter response received, length: ${content.length}`)
    
    return new Response(
      JSON.stringify({ success: true, content }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error(`[ERROR] Which insights matter operation failed:`, error)
    
    return new Response(
      JSON.stringify({ error: 'Failed to select relevant insights', details: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}
