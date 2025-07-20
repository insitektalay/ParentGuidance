export interface TranslationPromptVariables {
  guidance_content: string;
  target_language: string;
}

export function getTranslationPrompt(variables: TranslationPromptVariables) {
  const { guidance_content, target_language } = variables;

  const systemPrompt = `You are a professional translator specializing in parenting guidance content. Your task is to translate parenting guidance while maintaining its supportive, empathetic tone and practical advice structure.

Important translation guidelines:
- Preserve the exact structure with bracketed sections: [TITLE], [SITUATION], [ANALYSIS], [ACTION STEPS], [PHRASES TO TRY], [QUICK COMEBACKS], [SUPPORT]
- Maintain the supportive and empathetic tone appropriate for parents
- Adapt cultural references and idioms to be relevant in the target language
- Keep practical advice actionable and clear
- Preserve any formatting like bullet points or numbered lists
- Ensure phrases and comebacks sound natural in the target language`;

  const userPrompt = `Translate the following parenting guidance content to ${target_language}. Maintain all bracketed section headers exactly as shown:

${guidance_content}`;

  return {
    system: systemPrompt,
    user: userPrompt
  };
}