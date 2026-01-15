# System Design - Group Submission

This folder contains group system design diagrams following UML standards.

## Requirements

### File Format
- **Format:** draw.io XML (`.drawio`) and exported PDF (`.pdf`)
- **Naming:** `YYYY-FamilyName1-FamilyName2-FamilyName3.drawio` (alphabetical order, ASCII only)
- **Standard:** UML (Unified Modeling Language)
- **License:** Include license in diagram metadata or as text element (CC-BY-4.0 recommended)
- **Length:** Maximum 1 A4 page equivalent when exported

---

## Content Requirements

Your system design diagram must illustrate your AI agent architecture using UML notation. Include:

| Element | Description |
|---------|-------------|
| **Components** | Major system components (agents, tools, data stores) |
| **Interfaces** | How components communicate |
| **Data Flow** | Direction of data/control flow |
| **External Systems** | APIs, databases, or services your system uses |

### Recommended UML Diagram Types

Choose the most appropriate for your system:

1. **Component Diagram** - Shows system components and their relationships (most common)
2. **Sequence Diagram** - Shows interaction flow over time
3. **Activity Diagram** - Shows workflow/process steps
4. **Class Diagram** - Shows classes and their relationships (if OOP-based)

---

## Grading Criteria

Deliverable scored as passed (1) if handed in with acceptable quality before the end of the course.

---

## What is UML?

**UML (Unified Modeling Language)** is a standardized visual modeling language for software engineering. It provides a common vocabulary and notation for designing and documenting software systems.

### Why Use UML?

| Benefit | Description |
|---------|-------------|
| **Standardization** | Universal notation understood across the industry |
| **Communication** | Clear visual language for discussing architecture with team members, stakeholders, and future maintainers |
| **Documentation** | Self-documenting diagrams that remain useful long after code is written |
| **Design Clarity** | Forces you to think through system structure before implementation |
| **Tool Support** | Wide ecosystem of tools (draw.io, Lucidchart, PlantUML, etc.) |

### UML in AI/Agent Systems

For AI agent architectures, UML helps visualize:
- **Agent boundaries** - What is the agent vs. external systems
- **Tool orchestration** - How the orchestrator coordinates tools
- **Data flow** - How information moves through the pipeline
- **Interface contracts** - What each component expects and provides

---

## UML Reference

**Official Specification:** [OMG UML 2.5.1](https://www.omg.org/spec/UML/2.5.1/) (December 2017)

**Quick References:**
- [UML Diagrams Overview](https://www.uml-diagrams.org/) - Comprehensive guide with examples
- [PlantUML Reference](https://plantuml.com/) - Text-based UML (alternative to draw.io)
- [UML Cheat Sheet (PDF)](https://loufranco.com/wp-content/uploads/2012/11/cheatsheet.pdf) - Quick reference card

---


### Component Diagram Elements (UML 2.5.1)

```
┌───────────────────────────┐
│                    ┌───┐  │  Component with compartments
│                  ┌─┴─┐ │  │  (icon in upper-right corner)
│  ComponentName   └─┬─┘ │  │
│                  ┌─┴─┐ │  │
│                  └─┬─┘ │  │
│                    └───┘  │
├───────────────────────────┤
│ provided interfaces       │
│   Interface1              │
├───────────────────────────┤
│ required interfaces       │
│   Interface2              │
└───────────────────────────┘

    ┌───┐
  ┌─┴─┐ │      Component icon (UML 2.5.1)
  └─┬─┘ │      Two rectangles protruding
  ┌─┴─┐ │      from left side
  └─┬─┘ │
    └───┘
```

### Notation Guidelines

| Element | Symbol | When to Use |
|---------|--------|-------------|
| **Component** | Rectangle + «component» or icon | Always - represents a modular unit |
| **Activity** | Solid arrow (───►) | Activity showing information flow direction |

Note: Connectors should be used in a component diagram, but they are too challenging to make using pure text. To keep a simple conceptual illustration this deviation from the specification in UML 2.5.1 is done.

### Common Stereotypes for AI Agents

| Stereotype | Use for |
|------------|---------|
| `<<agent>>` | AI agent components |
| `<<tool>>` | Agent tools/capabilities |
| `<<model>>` | ML models |
| `<<database>>` | Data storage |
| `<<api>>` | External API interfaces |
| `<<service>>` | External services |

---

## Example System Design

### Component Diagram for HRV Analysis Agent

```
┌────────────────────────────────────────────────────────────────────────────────┐
│  «component»                                                          ┌───┐    │
│                                                                     ┌─┴─┐ │    │
│                                           HRV Analysis Agent        └─┬─┘ │    │
│                                                                     ┌─┴─┐ │    │
│                                                                     └─┬─┘ │    │
│                                                                       └───┘    │
├────────────────────────────────────────────────────────────────────────────────┤
│                                                                                │
│  ┌──────────────┐        ┌──────────────┐        ┌──────────────┐             │
│  │ «agent»      │        │ «tool»       │        │ «tool»       │             │
│  │              │───────>│              │───────>│              │             │
│  │ Orchestrator │        │ ECG Loader   │        │ Signal       │             │
│  │              │        │              │        │ Processor    │             │
│  └──────┬───────┘        └──────────────┘        └──────┬───────┘             │
│         │                                               │                      │
│         │                                               ▼                      │
│         │                ┌──────────────┐        ┌──────────────┐             │
│         │                │ «model»      │        │ «tool»       │             │
│         │                │              │<───────│              │             │
│         │                │ Classifier   │        │ Feature      │             │
│         │                │              │        │ Extractor    │             │
│         │                └──────┬───────┘        └──────┬───────┘             │
│         │                       │                       │                      │
│         │                       │       ┌───────────────┘                      │
│         │                       │       │                                      │
│         │                       ▼       ▼                                      │
│         │                ┌──────────────┐        ┌──────────────┐             │
│         │                │ «tool»       │        │ «artifact»   │             │
│         └───────────────>│              │───────>│              │             │
│                          │ Report       │        │ PDF Report   │             │
│                          │ Generator    │        │              │             │
│                          └──────────────┘        └──────────────┘             │
│                                                                                │
└────────────────────────────────────────────────────────────────────────────────┘

External:
┌──────────────┐
│ «database»   │
│              │  ECG Data Files (.txt)
│ File System  │
└──────────────┘
```

---

## How to Use draw.io

### Option 1: Online (Recommended)

1. Go to https://app.diagrams.net (draw.io)
2. Choose "Create New Diagram"
3. Select storage location (Device for local file)
4. Choose "UML" from template categories or start blank
5. Use the UML shape library from the left panel
6. Save as `.drawio` file

### Option 2: Desktop Application

Download from: https://www.drawio.com/

### Creating Your Diagram

1. **Open draw.io**
2. **Enable UML shapes:**
   - Click "More Shapes" at bottom of left panel
   - Check "UML" category
   - Click "Apply"
3. **Add components:**
   - Drag shapes from left panel
   - Double-click to edit labels
4. **Add connections:**
   - Hover over shape edge until blue arrows appear
   - Drag to target shape
5. **Add stereotypes:**
   - Add text `<<stereotype>>` above component name
6. **Save:**
   - File → Save As
   - Name: `YYYY-FamilyName1-FamilyName2-FamilyName3.drawio`

---

## Best Practices

### Layout
- Arrange components logically (input → processing → output)
- Use consistent spacing
- Align components in a grid
- Keep the diagram on a single page

### Labels
- Use clear, descriptive names
- Include stereotypes for clarity
- Label all connections/interfaces

### Style
- Use consistent colors (or keep default)
- Make text large enough to read
- Use standard UML notation

---

## Including License in draw.io

Add a text element to your diagram:

```
License: CC-BY-4.0
Authors: Chen Wei, Lin MeiLing, Wang XiaoMing
```

Or set in File → Properties → Description.

---

## Exporting for Review

To share a visual preview:

1. File → Export as → PNG or PDF
2. Name: `YYYY-FamilyName1-FamilyName2-FamilyName3.pdf`
3. Include both `.drawio` (source) and `.pdf` (preview) in submission

---

## Submission Checklist

Before submitting, verify:

- [ ] File named correctly: `YYYY-Name1-Name2-Name3.drawio` (alphabetical)
- [ ] Only ASCII characters in filename
- [ ] License declaration included
- [ ] Uses standard UML notation
- [ ] All major components represented
- [ ] Connections and data flow clearly shown
- [ ] Labels are readable
- [ ] Fits on approximately 1 A4 page
- [ ] No personally identifiable information (PII)
- [ ] All group members listed
- [ ] Verified to follow UML 2.5.1 by LLM
