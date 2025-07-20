export interface ContextExtractionPromptVariables {
  situation_text: string;
  extraction_type: 'general' | 'child_regulation';
}

export function getContextExtractionPrompt(variables: ContextExtractionPromptVariables) {
  const { situation_text, extraction_type } = variables;

  if (extraction_type === 'child_regulation') {
    return getChildRegulationPrompt(situation_text);
  } else {
    return getGeneralContextPrompt(situation_text);
  }
}

function getChildRegulationPrompt(situation_text: string) {
  const systemPrompt = `You are an expert in child development and emotional regulation. Extract insights about emotional regulation tools and strategies from parenting situations.

Analyze the situation and identify which regulation tools subcategories apply:
- Sensory Tools: Items or activities that provide sensory input (weighted blankets, fidgets, noise machines)
- Breathing Techniques: Specific breathing exercises or patterns mentioned
- Movement Activities: Physical activities for regulation (jumping, running, yoga)
- Calming Strategies: Techniques for calming down (quiet spaces, routines, visual aids)
- Connection Methods: Ways of connecting with the child for co-regulation

For each applicable subcategory, provide specific insights found in the situation.

Respond with a JSON object in this format:
{
  "insights": [
    {
      "subcategory": "Subcategory Name",
      "value": "Specific insight extracted from the situation"
    }
  ]
}

Only include subcategories that are explicitly mentioned or clearly implied in the situation.`;

  const userPrompt = `Extract emotional regulation insights from this parenting situation:

${situation_text}`;

  return {
    system: systemPrompt,
    user: userPrompt
  };
}

function getGeneralContextPrompt(situation_text: string) {
  const systemPrompt = `You are an expert in understanding family dynamics and child development. Extract contextual insights from parenting situations across these categories:

1. Family Context: Family structure, relationships, dynamics
2. Child Characteristics: Age, personality traits, preferences, strengths
3. Environmental Factors: Home, school, community settings
4. Medical/Health: Health conditions, medications, diagnoses
5. Communication Patterns: How family members communicate
6. Triggers: What sets off challenging behaviors
7. Successful Strategies: What has worked in the past
8. Daily Routines: Schedule, activities, transitions
9. Support Systems: Extended family, friends, professionals
10. Cultural Background: Cultural values, traditions, languages

For each category where you find relevant information, extract specific insights.

Respond with a JSON object in this format:
{
  "insights": [
    {
      "category": "Category Name",
      "insights": ["insight 1", "insight 2", ...]
    }
  ]
}

Only include categories that have explicit information in the situation.`;

  const userPrompt = `Extract contextual insights from this parenting situation:

${situation_text}`;

  return {
    system: systemPrompt,
    user: userPrompt
  };
}