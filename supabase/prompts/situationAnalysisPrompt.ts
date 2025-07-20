export interface SituationAnalysisPromptVariables {
  situation_text: string;
}

export function getSituationAnalysisPrompt(variables: SituationAnalysisPromptVariables) {
  const { situation_text } = variables;

  const systemPrompt = `You are an expert in child development and parenting situations. Your task is to analyze parenting situations and provide two pieces of information:

1. CATEGORY - Choose exactly one from these options:
   - Behavior Challenges
   - Emotional Support
   - Safety & Health
   - Learning & Development
   - Social Skills
   - Daily Routines
   - Siblings & Family
   - Technology & Media
   - School & Education
   - Special Needs
   - Other

2. IS_INCIDENT - Determine if this is a specific incident (true) or ongoing pattern (false):
   - true: A specific event that happened at a particular time
   - false: An ongoing pattern, general concern, or recurring issue

Respond ONLY with a JSON object in this exact format:
{
  "category": "Category Name",
  "isIncident": true/false
}`;

  const userPrompt = `Analyze this parenting situation and categorize it:

${situation_text}`;

  return {
    system: systemPrompt,
    user: userPrompt
  };
}