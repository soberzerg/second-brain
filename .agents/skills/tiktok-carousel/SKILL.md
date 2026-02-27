---
name: tiktok-carousel
description: Automate TikTok slideshow (carousel) marketing for any app or product. Researches competitors, generates AI images, adds text overlays, and posts via Postiz. Use when setting up TikTok marketing automation, creating slideshow posts, or when a user mentions TikTok growth, slideshow ads, carousel posts, or social media marketing for their app. Covers competitor research (browser-based), image generation, text overlays, TikTok posting (Postiz API), hook testing, and CTA optimization.
---

# TikTok Carousel Marketing

Automate your TikTok slideshow marketing pipeline: generate → overlay → post.

Based on the proven Larry system (1M+ TikTok views, $670/month MRR).

## When to use this skill

**Automatic activation when:**
- User wants to create TikTok slideshows/carousels
- User mentions TikTok marketing or growth
- User wants to generate slideshow images with AI
- User asks about TikTok hooks, CTAs, or content strategy
- User wants to post slideshows via Postiz

**Pattern triggers:**
- "Create a TikTok carousel for..."
- "Generate TikTok slides..."
- "Set up TikTok marketing..."
- "Post to TikTok..."
- "What hooks work on TikTok?"

## Prerequisites

This skill does NOT bundle any dependencies. Your AI agent will need to research and install the following based on your setup.

### Required
- **Node.js** (v18+) — all scripts run on Node
- **node-canvas** (`npm install canvas`) — used for adding text overlays to slide images. May need build tools on some systems.
- **Postiz** — handles posting to TikTok and provides analytics. Sign up at [postiz.com](https://postiz.com).

### Image Generation (pick one)
- **OpenAI** — `gpt-image-1.5` **(ALWAYS 1.5, never 1)**. Best for realistic photo-style images. Strongly recommended.
- **Stability AI** — Stable Diffusion XL. Good for stylized/artistic images.
- **Replicate** — any open-source model (Flux, SDXL, etc.). Most flexible.
- **Local** — bring your own images. No API needed.

## First Run — Onboarding

When this skill is first loaded, IMMEDIATELY start a conversation with the user. Don't dump a checklist — talk to them like a human marketing partner would. Ask one or two things at a time. React to what they say.

**Important:** Use `scripts/onboarding.js --validate` at the end to confirm the config is complete.

### Phase 0: TikTok Account Warmup (CRITICAL — Don't Skip This)

Before anything else, check if the user already has a TikTok account with posting history. If they're creating a fresh account, they MUST warm it up first.

Explain naturally:

> "Quick question — do you already have a TikTok account you've been using, or are we starting fresh? If it's new, we need to warm it up first. TikTok's algorithm watches how new accounts behave, and if you go straight from creating an account to posting AI slideshows, it flags you as a bot and kills your reach."

**If the account is new or barely used, walk them through this:**

Use TikTok like a normal person for **7-14 days** before posting. Spend **30-60 minutes a day**:

- **Scroll the For You page naturally.** Watch some videos all the way through. Skip others halfway.
- **Like sparingly.** Maybe 1 in 10 videos. Don't like everything — that's bot behaviour.
- **Follow accounts in your niche.** This trains the algorithm.
- **Watch niche content intentionally.** TikTok learns what you engage with.
- **Leave a few genuine comments.** Not spam. Real reactions.
- **Maybe post 1-2 casual videos.** Nothing promotional.

**The signal:** When their For You page is dominated by niche content, the account is warmed up.

Tell the user: "I know two weeks feels like wasted time, but accounts that skip warmup consistently get 80-90% less reach on their first posts."

**If the account is already active and established,** skip this entirely.

### Phase 1: Get to Know Their Product (Conversational)

Start casual:

> "Hey! Let's get your TikTok marketing set up. First — tell me about your product. What's it called, what does it do?"

Then FOLLOW UP based on what they say:

- They mention what it does → ask who it's for ("Who's your ideal user?")
- They describe the audience → ask about the pain point ("What's the main problem it solves?")
- They explain the problem → ask what makes them different ("What makes yours stand out?")
- Get the website/store link naturally ("Can you drop me the link?")
- Determine category (home/beauty/fitness/productivity/food/other) — often inferable

**Don't ask for "brand guidelines" robotically.** Instead: "Do you have any existing content or a vibe you're going for? Or are we starting fresh?"

Store everything in `tiktok-marketing/app-profile.json`.

### Phase 2: Competitor Research (Requires Browser Permission)

Before building any content strategy, research what competitors are doing on TikTok.

Ask the user:

> "Before we start creating content, I want to research what your competitors are doing on TikTok — what's getting views, what hooks they use, what's working. Can I use the browser to look around TikTok?"

**Wait for permission.** Then:

1. **Search TikTok** for the product's niche
2. **Find 3-5 competitor accounts** posting similar content
3. **Analyze their top-performing content:**
   - What hooks are they using?
   - What slide format? (before/after, listicle, POV, tutorial)
   - How many views on best vs average posts?
   - What's their posting frequency?
   - What CTAs are they using?
   - What music/sounds are trending?
4. **Compile findings** into `tiktok-marketing/competitor-research.json`
5. **Share findings conversationally:**

> "So I looked at what's out there. [Competitor A] is doing well with [format] — their best post got [X] views. But I noticed nobody's really doing [gap]. That's our angle."

See [resources/competitor-research.md](resources/competitor-research.md) for the full research guide.

### Phase 3: Content Format & Image Generation

Ask about format:

> "Do you want to do slideshows (photo carousels) or video? Slideshows are what this skill is built around — TikTok's data shows they get 2.9x more comments and 2.6x more shares than video, and they're much easier for AI to generate consistently."

**For slideshows (recommended):**

> "For the slideshows, we need images. I'd strongly recommend OpenAI's gpt-image-1.5 — it produces images that genuinely look like someone took them on their phone. You can also use Stability AI, Replicate, or bring your own images."

**If they pick OpenAI, make sure the model is set to `gpt-image-1.5` — NEVER `gpt-image-1`.** The quality difference is massive.

**Then work through the image style with them:**

> "Now let's figure out what these images should actually look like. Do you want them to look like real photos someone took on their phone, or more like polished graphics?"

Dig deeper:

- **What's the subject?** "What are we showing? Rooms? Faces? Products?"
- **What vibe?** "Cozy? Clean? Luxurious?"
- **Consistency:** "Should all 6 slides look like the same place or person?"
- **Must-have elements?** "Anything that HAS to be in every image?"

Build the base prompt WITH them. A good base prompt:

```
iPhone photo of a [specific room/scene], [specific style], [specific details].
Realistic lighting, natural colors, taken on iPhone 15 Pro.
No text, no watermarks, no logos.
[Consistency anchors: "same window on left wall", "same grey sofa"]
```

**Save the agreed prompt style to config as `imageGen.basePrompt`.**

**Key prompt rules:**
- "iPhone photo" + "realistic lighting" = looks real
- Lock architecture/layout in EVERY slide prompt
- Include everyday objects for lived-in feel
- Portrait orientation (1024x1536) always — this is TikTok
- Extremely specific > vague

**NEVER use generic prompts** like "a nice living room" — they produce generic images that get scrolled past.

### Phase 4: Postiz Setup

Postiz handles posting to TikTok via API.

> "We need Postiz to handle posting. It lets me create slideshows and post them to your TikTok as drafts."

Walk them through:

1. **Sign up at [postiz.com](https://postiz.com)** — create an account
2. **Connect TikTok** — Integrations → Add TikTok → Authorize
3. **Note the TikTok integration ID** — visible in URL or integration settings
4. **Get the API key** — Settings → API → copy the key

Explain the draft workflow:

> "Posts go to your TikTok inbox as drafts, not straight to your feed. Before you publish each one, add a trending sound from TikTok's sound library. Music is the single biggest factor in TikTok reach — silent slideshows get buried. It takes 30 seconds per post."

**Don't move on until Postiz is connected and the API key works.**

### Phase 5: Content Strategy (Built from Research)

Using the competitor research AND the product profile, build an initial content strategy:

> "Based on what I found and what your product does, here's my plan for the first week..."

Present:
1. **3-5 hook ideas** tailored to their niche + competitor gaps
2. **Posting schedule** recommendation (default: 7:30am, 4:30pm, 9pm — their timezone)
3. **Which hook categories to test first** (reference what worked for competitors)

Save the strategy to `tiktok-marketing/strategy.json`.

### Phase 6: Save Config & First Post

Store everything in `tiktok-marketing/config.json`:

```json
{
  "app": {
    "name": "ProductName",
    "description": "Detailed description",
    "audience": "Target demographic",
    "problem": "Pain point it solves",
    "differentiator": "What makes it unique",
    "url": "https://...",
    "category": "home|beauty|fitness|productivity|food|other"
  },
  "imageGen": {
    "provider": "openai",
    "apiKey": "sk-...",
    "model": "gpt-image-1.5",
    "basePrompt": "..."
  },
  "postiz": {
    "apiKey": "your-postiz-key",
    "integrationId": "tiktok-integration-id"
  },
  "posting": {
    "privacyLevel": "SELF_ONLY",
    "schedule": ["07:30", "16:30", "21:00"]
  }
}
```

Then generate the **first test slideshow** — set expectations:

> "Let's create our first slideshow. This is a TEST — we're dialing in the image style, not posting yet. I'll generate 6 slides and we'll look at them together."

**The refinement process:**

1. **Generate a test set of 6 images** using the prompts you built together
2. **Show them the results:** "How do these look? Too polished? Too dark? Wrong vibe?"
3. **Tweak based on feedback** — adjust the base prompt, regenerate
4. **Repeat until they're happy** — 2-5 rounds is normal
5. **Lock the prompt style** once it looks right

Things to ask:
- "Are these realistic enough or do they look AI-generated?"
- "Is the lighting right?"
- "Does this match what your users would actually relate to?"

Once the style is locked, start the posting schedule using hook strategy from competitor research and the category templates (see [resources/slide-structure.md](resources/slide-structure.md)).

---

## Core Workflow

### 1. Generate Slideshow Images

Use `scripts/generate-slides.js`:

```bash
node scripts/generate-slides.js --config tiktok-marketing/config.json --output tiktok-marketing/posts/YYYY-MM-DD-HHmm/ --prompts prompts.json
```

The script auto-routes to the correct provider based on `config.imageGen.provider`.

**Timeout warning:** Generating 6 images takes 3-9 minutes total. Set exec timeout to at least **600 seconds (10 minutes)**. The script supports resume — if it fails partway, re-run it and completed slides will be skipped.

**Critical image rules:**
- ALWAYS portrait aspect ratio (1024x1536 or 9:16 equivalent)
- Include "iPhone photo" and "realistic lighting" in prompts
- ALL 6 slides share the EXACT same base description (only style/feature changes)
- Lock key elements across all slides
- See [resources/slide-structure.md](resources/slide-structure.md) for the 6-slide formula

### 2. Add Text Overlays

Uses `node-canvas` to render text directly onto slide images.

#### Setting Up node-canvas

Prompt the user:

> "To add text overlays, I need node-canvas. Can you run this?"
>
> ```bash
> npm install canvas
> ```
>
> **macOS:** `brew install pkg-config cairo pango libpng jpeg giflib librsvg && npm install canvas`
> **Ubuntu/Debian:** `sudo apt-get install build-essential libcairo2-dev libpango1.0-dev libjpeg-dev libgif-dev librsvg2-dev && npm install canvas`

Use `scripts/add-text-overlay.js`:

```bash
node scripts/add-text-overlay.js --input tiktok-marketing/posts/YYYY-MM-DD-HHmm/ --texts texts.json
```

**Text content rules:**
- **REACTIONS not labels** — "Wait... this is actually nice??" not "Modern minimalist"
- **4-6 words per line** — short lines scannable at a glance
- **3-4 lines per slide is ideal**
- **No emoji** — canvas can't render them reliably
- **Safe zones:** No text in bottom 20% (TikTok controls) or top 10% (status bar)
- **Use `\n` for manual line breaks** — gives you control over rhythm

**Good (manual breaks):**
```json
[
  "I showed my landlord\nwhat AI thinks our\nkitchen should look like",
  "She said you can't\nchange anything\nchallenge accepted",
  "So I downloaded\nthis app and\ntook one photo",
  "Wait... is this\nactually the same\nkitchen??",
  "Okay I'm literally\nobsessed with\nthis one",
  "[AppName] showed me\nwhat's possible\nlink in bio"
]
```

**Key overlay details:**
- **Dynamic font sizing** — short text gets bigger (75px), long text gets smaller (51px)
- **Word wrap** — respects manual `\n` breaks, auto-wraps lines exceeding 75% width
- **Centered at ~28-30% from top** — stays in safe zone
- **Thick outline** — 15% of font size, readable on ANY background

### 3. Post to TikTok

Use `scripts/post-to-tiktok.js`:

```bash
node scripts/post-to-tiktok.js --config tiktok-marketing/config.json --dir tiktok-marketing/posts/YYYY-MM-DD-HHmm/ --caption "caption" --title "title"
```

### Why We Post as Drafts (SELF_ONLY)

Posts go to your TikTok inbox as drafts, NOT published directly:

1. **Music is everything on TikTok.** Trending sounds massively boost reach.
2. **You add the music manually**, then publish. Takes 30 seconds.
3. **Posts without music get buried.**
4. **Creative control** — preview before going live.

**Caption rules:** Long storytelling captions (3x more views). Structure: Hook → Problem → Discovery → Result → max 5 hashtags. Conversational tone.

**Caption template:**
```
[hook matching slide 1] [2-3 sentences of relatable struggle].
So I found this app called [APP NAME] that [what it does] -
you just [simple action] and it [result]. I tried [style 1] and [style 2]
and honestly?? [emotional reaction]. [funny/relatable closer]
#[niche1] #[niche2] #[niche3] #fyp
```

---

## Posting Schedule

Optimal times (adjust for audience timezone):
- **7:30 AM** — catch early scrollers
- **4:30 PM** — afternoon break
- **9:00 PM** — evening wind-down

3x/day minimum. Consistency beats sporadic viral hits.

## Hook Performance Tracking (Manual)

After posts are live, track performance in `tiktok-marketing/hook-performance.json`:

```json
{
  "posts": [
    {
      "date": "2026-02-26",
      "hook": "boyfriend said flat looks like catalogue",
      "hookCategory": "person-conflict-ai",
      "views": 15000,
      "likes": 450,
      "comments": 23,
      "saves": 89
    }
  ]
}
```

**Decision rules:**
- 50K+ views → DOUBLE DOWN — make 3 variations immediately
- 10K-50K → Good — keep in rotation, test tweaks
- 1K-10K → Try 1 more variation before dropping
- <1K twice → DROP — radically different approach

**What to vary when iterating:**
- **Same hook, different person:** "landlord" → "mum" → "boyfriend"
- **Same structure, different subject:** bedroom → kitchen → bathroom
- **Same images, different text:** proven images reused with new hooks
- **Same hook, different time:** morning vs evening posting

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| 1536x1024 (landscape) | Use 1024x1536 (portrait) |
| Font at 5% | Use 6.5% of width |
| Text at bottom | Position at 30% from top |
| Different rooms per slide | Lock architecture in EVERY prompt |
| Labels not reactions | "Wait this is nice??" not "Modern style" |
| No music | Always add trending sound before publishing |
| `spawnSync ETIMEDOUT` | Exec timeout too short — use 10-minute timeout or generate one at a time |

## Resources

- [Slide Structure & Hook Writing](resources/slide-structure.md) — the 6-slide formula, hook tiers, category adaptation
- [App Category Templates](resources/app-categories.md) — category-specific slide prompts
- [Competitor Research Guide](resources/competitor-research.md) — how to research the landscape

## Integration with other skills

- **social-content**: For writing captions and cross-platform content strategy
- **brainstorming**: For ideating hook categories and content angles
- **content-strategy**: For planning content calendar and topic clusters
- **web-research**: For researching competitors and trending content

## Examples

### Example 1: Interior Design App

**User:** "I want to promote my room design app on TikTok"

**Claude:**
1. Runs onboarding — learns it's a home/interior app
2. Researches competitors on TikTok (before/after room redesigns)
3. Sets up OpenAI gpt-image-1.5 with base prompt: "iPhone photo of a small London flat living room..."
4. Generates 6 slides: before (tired magnolia) → 5 style transforms
5. Adds text overlays: "I showed my landlord what AI thinks our flat should look like"
6. Posts to TikTok via Postiz as draft
7. User adds trending sound and publishes

### Example 2: Beauty App

**User:** "Set up TikTok carousel marketing for my lip filler preview app"

**Claude:**
1. Onboarding — beauty/cosmetics category
2. Competitor research — finds "what would I look like with..." hooks work
3. Image gen: Close-up portrait, same face, progressive enhancement
4. 6 slides: natural → subtle → medium → bold → dramatic → CTA
5. Text: "Everyone's getting lip filler but would it suit MY face?"
6. Posts as draft, user adds sound

### Example 3: Quick Post Generation

**User:** "Generate a new TikTok carousel with hook 'My nan wouldn't believe this is the same kitchen'"

**Claude:**
1. Uses existing config and base prompt
2. Generates 6 kitchen slides with style transforms
3. Writes overlay texts following the hook narrative
4. Adds overlays and posts to TikTok
