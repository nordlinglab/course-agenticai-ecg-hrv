# Case Brief: Agentic Urban Water Leak Monitoring Assistant

**Author:** 2026-Li-Po-Ling  
**License:** CC-BY-4.0  

## Problem Statement

- Aging urban water pipelines cause frequent underground leaks that are difficult to detect in real time.
- Long-term leakage leads to water loss, soil erosion, road subsidence, and public safety risks.
- Current practices rely on citizen reports or periodic manual inspections, resulting in delayed and reactive responses.
- There is no continuous, proactive decision-support mechanism for early intervention.

## Context / Background

- Industry Context: Smart city infrastructure emphasizes real-time sensing and preventive maintenance, yet underground pipelines remain hard to monitor.
- Current Solutions: Manual acoustic inspections, periodic patrols, and single-point sensors are passive and low-frequency.
- Stakeholders: Municipal governments, water utilities, road management authorities, and the general public.
- The Gap: Lack of an intelligent system that integrates sensing data, spatial information, and maintenance workflows to guide timely intervention.

## Analysis

### Root Causes

- Subsurface Invisibility: Leaks occur underground and cannot be directly observed, requiring indirect signal interpretation.
- Fragmented Data: Pressure, flow, acoustic, and GIS pipeline data exist in separate systems without unified analysis.
- Delayed Response: Anomalies are logged but not translated into actionable decisions.

### Constraints

- Non-Intrusive Monitoring: Detection methods must avoid frequent excavation or disruption of existing pipelines.
- False Alarm Risk: The system must differentiate transient fluctuations from true leakage events.
- Data Quality Issues: Sensor noise and aging hardware reduce classification reliability.

### Requirements

- Multi-Source Data Integration: Combine pressure, flow, acoustic sensing, and GIS pipeline information.
- Anomaly Detection Model: Distinguish normal consumption patterns from abnormal leakage behavior.
- Decision-Support Interface: Convert technical results into understandable maintenance priorities.

## Proposed Approach (Chat-based)

- Manual Data Review: Engineers periodically inspect sensor reports.
- Human Judgment: Experts infer whether anomalies indicate leaks or peak demand.
- Cross-Referencing: GIS maps and historical maintenance records are checked manually.
- Action Decision: Maintenance dispatch decisions are made by human operators.
- Limitation: The workflow is labor-intensive, slow, and difficult to scale.

## Proposed Approach (Agentic)

### Perceive (Sense)

- Continuously collect multi-point pressure, flow, and acoustic sensor data.
- Synchronize with GIS pipeline locations and historical leakage records.

### Reason (Think)

- Analyze temporal trends and spatial correlations across data sources.
- Logic: Localized pressure anomalies + flow imbalance + high-risk history indicate potential leakage.
- Decision: Assign severity levels and determine intervention necessity.

### Act (Execute)

- Proactively notify authorities and maintenance teams.
- Automatically generate repair recommendations and prioritized task lists.
- Visualize suspected leakage locations within the GIS interface.

### Adapt

- Incorporate feedback from completed repairs.
- Continuously reduce false positives and improve detection accuracy.

## Expected Outcomes

- Reduce Water Loss: Enable early detection to minimize non-revenue water.
- Prevent Infrastructure Failure: Provide early warnings before surface damage occurs.
- Improve Maintenance Efficiency: Optimize resource allocation and response time.
- Enable Preventive Management: Shift from reactive repairs to proactive infrastructure management.

## References

- World Bank: Non-Revenue Water Management Reports.
- ISO 24516: Guidelines for Water Utility Asset Management.
- Smart City GIS and IoT Integration Studies.
