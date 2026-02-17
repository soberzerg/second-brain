---
description: Create viral 10-slide carousels (карусель) using the 'Nano Banana' methodology (high-contrast visuals + punchy copywriting). Use when the user asks to create a carousel or mentions 'Nano Banana'.
---

# Nano Banana Carousel Skill

This skill guides you through creating high-impact, 10-slide carousels designed for social media (LinkedIn, Instagram). It combines the "Nano Banana" visual aesthetic (bold, high-contrast, often yellow/black) with a structured copywriting framework.

## Workflow

### Phase 1: The "Nano Hook" Concept

**Goal:** Define a counter-intuitive or highly specific topic.

1.  **Ask the User:** "What is the core transformation or 'aha!' moment you want to deliver?"
2.  **Refine Topic:** Convert a generic topic (e.g., "Productivity Tips") into a specific, "Nano" angle (e.g., "Why 5am Clubs Fail: The 10am Advantage").

### Phase 2: Copywriting Framework (10 Slides)

**Goal:** Draft the text for each slide using the following structure.
**General Rules:**

- **Word Count:** Body text should be 15-25 words max to ensure readability.
- **Layout:** Always leave significant negative space for imagery and visual hierarchy.

- **Slide 1: The Hook**
  - **Headline:** Short, punchy, < 7 words. Use "How to...", "Stop...", or specific numbers.
  - **Sub-headline:** Clarifies the promise.
  - **Visual Goal:** Dominant text, intriguing icon/image.

- **Slide 2: The Banana Peel (The Problem/Shift)**
  - **Content:** Expose a common mistake, a myth, or a surprising stat. "Most people think X, but actually Y."
  - **Visual Goal:** A visual representation of a "slip" or error.

- **Slides 3-8: The Meat (The Steps/Insights)**
  - **Structure:** One key point per slide.
  - **Headline:** The outcome of this step.
  - **Body:** 1-2 short sentences or bullet points explaining _how_.
  - **Visual Goal:** Numbered lists, process diagrams, or "this vs that" comparisons.

- **Slide 9: The Dessert (The Summary)**
  - **Content:** A "Cheat Sheet" or summary list of all points.
  - **Visual Goal:** A clean checklist or infographic style.

- **Slide 10: The Bunch (The CTA)**
  - **Headline:** "Want more?" or "Join the Bunch".
  - **Body:** Specific Call to Action (Newsletter, Follow, Comment).
  - **Visual Goal:** Profile picture, arrow pointing to follow/link.

### Phase 3: "Nano Banana" Visuals

**Goal:** Generate prompts for consistent, high-contrast images.
**Style:** Minimalist, Bold, 3D render style, "Plastic" or "Toy" aesthetic, bright Yellow and Black (or user's brand colors).

**Prompt Structure for `generate_image`:**
"A minimalist 3D render of [SUBJECT], smooth plastic texture, bright yellow and matte black color scheme, studio lighting, high contrast, clean background, ensuring space for text on the [TOP/BOTTOM/LEFT/RIGHT], 4k, octane render."

**Action:**

1.  For each slide, suggest a visual concept.
2.  Create the image generation prompt based on the concept.
3.  (Optional) Generate the images if the user requests. Ensure format is 1080x1350 (4:5 portrait aspect ratio).

## Deliverable

Output the full carousel plan in Markdown:

```markdown
## [Carousel Title]

| Slide | Visual Prompt | Text Overlay (Headline + Body) |
| :---- | :------------ | :----------------------------- |
| 1     | [Prompt]      | **[Headline]**<br>[Subtext]    |
| 2     | [Prompt]      | **[Headline]**<br>[Body]       |

...
```
