# Inbox Processor

Help organize and process items in the 000_Inbox folder according to the PARA
method.

## Task

Review all notes in `000_Inbox/` and help categorize them:

1. **Scan the Inbox**
   - List all files currently in 000_Inbox
   - Exclude README.md and Welcome.md

2. **Analyze Each Item**
   - Read the content
   - Identify the type of note
   - Suggest appropriate destination

3. **Categorization Rules**
   - **→ 200_Projects**: Has deadline, specific outcome
   - **→ 100_Tasks**: Actionable task with clear outcome
   - **→ 500_Research**: Reference material, knowledge
   - **→ 300_Blog**: Content ideas, drafts, research for blog
   - **→ 400_Planning**: Plans, syntheses, daily notes
   - **→ Delete**: No value, redundant, or temporary

4. **Suggest Actions**

   ```
   File: [filename]
   Type: [detected type]
   Destination: [suggested folder]
   Reason: [why this categorization]
   Related to: [any existing notes it connects to]
   ```

5. **Identify Patterns**
   - Common themes across multiple notes
   - Notes that could be combined
   - Missing connections between items

## Output Format

Provide a clear action plan:

1. Items to move (with destinations)
2. Items to combine or link
3. Items to delete
4. Items needing more context

## Remember

- Some items legitimately belong in the Inbox (daily notes, quick captures)
- Don't over-organize - sometimes "good enough" is perfect
- Look for opportunities to connect ideas, not just file them
