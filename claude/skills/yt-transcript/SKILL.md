---
name: yt-transcript
description: "Convert a YouTube video transcript into a well-structured project knowledge markdown file. Trigger when the user provides a YouTube transcript (pasted text or attached) and wants it organized into a structured knowledge document. Also trigger when the user provides a YouTube URL and asks to create a knowledge document from it. The skill produces a single .md file following strict diagram and documentation conventions, ready to be added as project knowledge."
---

# Transcript to Knowledge — Skill

Convert YouTube video transcripts into structured, referenceable project knowledge files.

## Skill Contents

```
yt-transcript/
├── SKILL.md                              ← You are here
├── scripts/
│   └── yt-transcript.zsh                 ← Fetch transcript via yt-dlp (copy of ~/.dotfiles/zsh/custom/yt-transcript.zsh)
└── references/
    ├── diagram-standard.md               ← Diagram conventions (MUST read before writing)
    └── example-output.md                 ← Reference example of expected output
```

**Before writing any output, you MUST read both reference files.** They define the quality bar.

---

## Inputs

The user provides ONE of:

1. **A YouTube URL (Claude Code)** — use the bundled `scripts/yt-transcript.zsh` to fetch the transcript, title, channel, and URL automatically via `yt-dlp`. Execute: `source <skill-dir>/scripts/yt-transcript.zsh && yt-transcript <url> -o /tmp/yt-transcript.txt`. This provides everything needed — skip straight to Step 2
2. **A YouTube URL (other environments)** — fetch the page to extract the video title and channel, then ask the user to paste the transcript
3. **A transcript file** — an attached `.txt` or `.md` file containing the transcript, plus the URL and/or title in the message
4. **A pasted transcript** — raw text from a YouTube video, plus the URL and/or title

If the user provides only a transcript without URL/title, ask for both before proceeding.

## Output

A single `.md` file. Where it's saved depends on the environment:

- **claude.ai**: Save to `/mnt/user-data/outputs/` and use `present_files` to deliver
- **Claude Code**: Save to the current working directory (or a path the user specifies)
- **Other**: Save to the current working directory

Filename is derived from the title using kebab-case (e.g., `event-driven-architecture-top-patterns.md`)

---

## Process

### Step 1 — Gather Metadata

Collect all three:

- **Video title** (exact)
- **Video URL** (full YouTube URL)
- **Speaker/Channel name**

How to resolve metadata from a URL:

- **Claude Code**: Run `source <skill-dir>/scripts/yt-transcript.zsh && yt-transcript <url> -o /tmp/yt-transcript.txt` — the output file contains `CHANNEL:`, `TITLE:`, `URL:` headers followed by timestamped transcript lines. Read the file to extract metadata and transcript in one step, then skip to Step 2
- **claude.ai**: Use `web_fetch` to get the page title and channel name
- **If fetching fails**: Ask the user to provide the title and channel name

### Step 2 — Read Skill References

**Mandatory.** Read both files before writing anything. Use the appropriate tool for your environment:

- **claude.ai**: `view` tool on the reference file paths
- **Claude Code**: `cat` the reference files from the skill directory

```
references/diagram-standard.md   ← How ALL diagrams must be formatted
references/example-output.md     ← The quality bar and structure to match
```

### Step 3 — Analyze the Transcript

Read the full transcript and extract:

1. **The core thesis** — the single main argument or insight of the video (1-2 sentences)
2. **Key concepts** — distinct ideas, patterns, or principles discussed
3. **Relationships between concepts** — how they build on or relate to each other
4. **Concrete examples** — specific technologies, libraries, demos mentioned
5. **Practical recommendations** — what the speaker says to do or avoid

Do NOT include:

- Sponsor mentions, channel promotion, like/subscribe requests
- Repetition from the speaker restating the same point
- Step-by-step demo narration (capture the _concept_ the demo illustrates, not the steps)

### Step 4 — Gather Architecture Context

The "Relevance to Our Architecture" section MUST be grounded in the user's actual project context. Follow this resolution order:

1. **Search project knowledge** — if `project_knowledge_search` is available (claude.ai with project knowledge), search for terms related to the transcript concepts
2. **Search the codebase** — if in Claude Code, look for architecture docs, ADRs, README files, or a docs/ directory that describes the project's architecture and stack
3. **Ask the user** — if neither of the above yields architecture context, ask: _"Do you have architecture documentation or conventions I should reference for the 'Relevance to Our Architecture' section? If not, I can skip it."_
4. **Skip only if the user says so** — never skip silently, never fall back to generic advice without asking first

### Step 5 — Write the Document

Follow the structure defined in the **Document Template** section below. Write the full document, then save it.

### Step 6 — Deliver

Deliver the file based on the environment:

- **claude.ai**: Copy to `/mnt/user-data/outputs/` and use `present_files`
- **Claude Code**: The file is already in the working directory — confirm the path to the user
- **Other**: Provide the file path or content to the user

---

## Document Template

Every output document MUST follow this structure. Sections can be added between sections 2-N based on content, but the header, the final two sections ("Relevance to Our Architecture" and "Summary"), and the footnote are mandatory.

### Header Block (mandatory)

```markdown
# {Document Title}

> **Source**: {Speaker Name} ({Channel Name}) — [{Video Title}]({YouTube URL})
>
> **Key Insight**: {1-2 sentence core thesis of the video}
```

Rules:

- The `# title` should be a descriptive knowledge title, not necessarily the video title verbatim
- The link text in Source MUST be the video title, linking to the full URL
- **Key Insight** summarizes the speaker's main thesis in 1-2 sentences

### Content Sections

Organize concepts into numbered sections (`## 1. Section Name`). Guidelines:

- **One concept per section** — don't merge unrelated ideas
- **Use subsections** (`### 3.1 Subsection`) when a concept has distinct sub-points
- **Lead with the problem**, then the solution — mirror how the speaker motivates each concept
- **Include structured text diagrams** following `references/diagram-standard.md` when the concept involves flows, comparisons, or architecture
- **Use ✅/❌ markers** for rules, recommendations, and trade-offs
- **Use comparison tables** when the speaker contrasts approaches
- **Capture specific named technologies** (libraries, tools, frameworks) mentioned by the speaker
- **Keep the speaker's terminology** — don't rename their concepts

### Relevance to Our Architecture (mandatory unless user says to skip)

```markdown
## N. Relevance to Our Architecture
```

Connect the video's concepts to the user's actual project architecture using a structured text block:

```
APPLICATION TO {PROJECT CONTEXT}

{CONCEPT FROM VIDEO}:
  ✅ {How it applies to the user's architecture}
  ❌ {What to avoid, with rationale}
```

Include specific tool/library recommendations matching the user's stack (gathered in Step 4). This section must reference real project conventions, not generic advice.

### Summary (mandatory)

A concise paragraph (3-5 sentences) restating the key takeaways. No bullet points. Should stand alone as a TL;DR.

### Footnote (mandatory)

```markdown
[^1]: {Speaker Name} — [{Video Title}]({YouTube URL})
```

---

## Style Rules

1. **Prose over bullets** — use paragraphs for explanations, structured text diagrams for architecture, tables for comparisons. Avoid bullet-point-heavy sections.
2. **No Mermaid** — all diagrams use structured text per `references/diagram-standard.md`
3. **Speaker attribution** — use "{Speaker} demonstrates..." or "In the demo..." when referencing specific examples. Don't use "the video says..."
4. **Concepts not narration** — capture what the speaker teaches, not what they show step by step
5. **English only** — all content and code comments in English
6. **Footnotes for sources** — use markdown footnotes `[^N]` with full URLs

---

## Quality Checklist

Before delivering, verify:

- [ ] Header has Source with clickable video title link + Key Insight
- [ ] Both reference files were read before writing
- [ ] Diagram standard followed (structured text, ✅/❌, ASCII boxes, no Mermaid)
- [ ] No sponsor/promotion content included
- [ ] Specific technologies and libraries from the transcript are captured
- [ ] "Relevance to Our Architecture" is grounded in real project context (or explicitly skipped by user)
- [ ] Summary is a concise standalone paragraph
- [ ] Footnote has speaker name + video title as link text
- [ ] Filename matches the document title (underscores, no spaces)
- [ ] Output matches the quality and structure of `references/example-output.md`
