export interface GuidancePromptVariables {
  current_situation: string;
  active_foundation_tools?: string;
  family_context?: string;
  has_framework: boolean;
  structure_mode: 'fixed' | 'flexible';
}

export function getGuidancePrompt(variables: GuidancePromptVariables) {
  const { 
    current_situation, 
    active_foundation_tools, 
    family_context, 
    has_framework, 
    structure_mode 
  } = variables;

  // Base system prompt for all guidance
  let systemPrompt = `You are a supportive parenting guide providing evidence-based guidance for challenging parenting situations. Your responses should be empathetic, practical, and actionable.`;

  // Add framework-specific instructions if applicable
  if (has_framework && active_foundation_tools) {
    systemPrompt += `\n\nThe parent is using a specific parenting framework. Incorporate these tools and principles into your guidance:
${active_foundation_tools}`;
  }

  // Add structure-specific instructions
  if (structure_mode === 'fixed') {
    systemPrompt += `\n\nProvide your response in EXACTLY this format with these bracketed sections:

[TITLE]
A brief, descriptive title for the situation

[SITUATION]
Summarize the key aspects of what's happening

[ANALYSIS]
Analyze what might be going on from the child's perspective and underlying needs

[ACTION STEPS]
Provide 3-5 concrete steps the parent can take right now

[PHRASES TO TRY]
Suggest 3-5 specific phrases the parent can use with their child

[QUICK COMEBACKS]
Provide 2-3 quick responses for in-the-moment situations

[SUPPORT]
Offer encouragement and remind the parent they're doing their best`;

    // Add family context for fixed mode
    if (family_context) {
      systemPrompt += `\n\nFamily Context to consider:
${family_context}`;
    }
  } else {
    // Flexible mode
    systemPrompt += `\n\nProvide helpful parenting guidance that addresses the situation. Be conversational and supportive. Focus on:
- Understanding the child's perspective
- Practical strategies the parent can use
- Specific phrases or scripts when helpful
- Encouragement for the parent

You may organize your response naturally based on what would be most helpful for this specific situation.`;
  }

  const userPrompt = `Please provide guidance for this parenting situation:

${current_situation}`;

  return {
    system: systemPrompt,
    user: userPrompt
  };
}

// Helper function to format framework information consistently
export function formatFrameworkForPrompt(framework: {
  frameworkName: string;
  description?: string;
  keyPrinciples?: string[];
  tools?: string[];
}): string {
  let formatted = `Framework: ${framework.frameworkName}`;
  
  if (framework.description) {
    formatted += `\nDescription: ${framework.description}`;
  }
  
  if (framework.keyPrinciples && framework.keyPrinciples.length > 0) {
    formatted += `\nKey Principles:\n${framework.keyPrinciples.map(p => `- ${p}`).join('\n')}`;
  }
  
  if (framework.tools && framework.tools.length > 0) {
    formatted += `\nTools to Apply:\n${framework.tools.map(t => `- ${t}`).join('\n')}`;
  }
  
  return formatted;
}