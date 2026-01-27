# Reflection: Agent vs Chat-Based ECG HRV Fatigue Assessment

**Group:** 2026-Fan-Lee-Liu  
**Authors:** Fan Cheng-Yu, Lee Po-Lin, Liu Wu-Jun  
**License:** CC-BY-4.0

## Tools

Custom Python-based AI agent system vs. ChatGPT-4 (chat-only interaction).

## Task Description

We compared two approaches for analyzing ECG data to compute basic heart rate
variability (HRV) metrics and generate a simple fatigue or stress-related
recommendation based on physiological indicators.

The task included ECG signal loading, R-peak detection, HRV metric computation,
and decision-making based on the extracted features.

## Agent Approach

Our AI agent system implemented a fixed, automated workflow:

1. Performed simplified R-peak detection using signal squaring and peak finding  
2. Computed RR intervals and removed abnormal values  
3. Calculated time-domain HRV metrics (BPM, SDNN, RMSSD)  
4. Used a DecisionAgent to classify physiological state (normal, fatigue, high stress)  
5. Used an ActionAgent to generate corresponding recommendations  

Once executed, the agent completed the entire pipeline automatically without
additional human intervention, producing both numerical results and a final
decision output in a single run.

## Chat Approach

Using a pure chat-based approach (ChatGPT-4):

1. We asked the model how to compute HRV from ECG data  
2. ChatGPT provided Python code snippets for each processing step  
3. We manually copied and executed the code in a local environment  
4. Errors and missing details required multiple clarification prompts  
5. The decision logic and recommendation generation were manually designed and integrated  

The overall process required repeated back-and-forth interactions and manual
assembly of results into a final interpretation.

## Performance Comparison

| Metric | Agent | Chat-based |
|------|------|-----------|
| Time to complete | ~30 sec | ~30–45 min |
| Manual steps required | 1 (run script) | 10+ |
| Error handling | Automatic | Manual debugging |
| Output consistency | High | Variable |

## Analysis

The performance difference arises from several factors:

1. **Workflow automation:**  
   The agent executes a predefined pipeline from data loading to decision output,
   while the chat-based approach requires manual coordination of each step.

2. **State encapsulation:**  
   The agent maintains internal state across signal processing, feature extraction,
   and decision-making. In contrast, chat interactions require repeated restatement
   of context.

3. **Decision modularity:**  
   Separating the DecisionAgent and ActionAgent enables clearer logic reuse, which
   is difficult to maintain consistently in chat-only workflows.

4. **Reduced cognitive load:**  
   Automation minimizes human error and attention fatigue, especially for repetitive
   signal-processing tasks.

## Lessons Learned

- Agent-based systems are well-suited for **structured, repeatable biomedical data pipelines**
- Chat-based AI is useful for **learning, prototyping, and debugging individual steps**
- Explicit agent design improves reproducibility and clarity of decision logic
- The benefit of an AI agent increases as task complexity and repetition grow
