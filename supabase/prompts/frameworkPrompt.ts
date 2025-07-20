export interface FrameworkPromptVariables {
  recent_situations: string;
}

export function getFrameworkPrompt(variables: FrameworkPromptVariables) {
  const { recent_situations } = variables;

  const systemPrompt = `You are an expert in parenting frameworks and child development. Based on recent parenting situations, recommend evidence-based parenting frameworks that would be most helpful.

Analyze the patterns in the situations and recommend 1-3 frameworks from this list:
- Positive Discipline
- Collaborative Problem Solving (CPS)
- Conscious Discipline
- Love and Logic
- Attachment Parenting
- RIE (Resources for Infant Educarers)
- Montessori Approach
- Positive Behavior Support (PBS)
- Triple P (Positive Parenting Program)
- Circle of Security

For each recommended framework, provide:
1. Framework name
2. A brief description (2-3 sentences)
3. Key principles (3-5 bullet points)
4. Specific tools/strategies (3-5 concrete examples)
5. Why it's relevant to these situations

Respond with a JSON object in this format:
{
  "frameworks": [
    {
      "name": "Framework Name",
      "description": "Brief description of the framework",
      "principles": ["principle 1", "principle 2", ...],
      "tools": ["tool 1", "tool 2", ...],
      "relevance": "Why this framework fits these situations"
    }
  ]
}`;

  const userPrompt = `Based on these recent parenting situations, recommend appropriate parenting frameworks:

${recent_situations}`;

  return {
    system: systemPrompt,
    user: userPrompt
  };
}