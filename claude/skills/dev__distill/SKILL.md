---
name: distill
description: "Convert any source material — YouTube video, blog post, PDF, DOCX, Markdown, or pasted text — into a well-structured project knowledge markdown file. Trigger when the user says 'distill this', 'distill this blog', 'distill this PDF', 'create knowledge doc from', 'convert this to knowledge', or provides a YouTube transcript (pasted or attached) and wants it organized into a structured knowledge document. Also trigger when the user provides a YouTube URL and asks to create a knowledge document from it. The skill auto-detects input type and produces a single .md file following strict diagram and documentation conventions, ready to be added as project knowledge."
effort: medium
---

# Distill — Source to Knowledge Skill

Convert any source material into structured, referenceable project knowledge files.

## Skill Contents

```
distill/
├── SKILL.md                              ← You are here
├── scripts/
│   └── yt-transcript.zsh                 ← Fetch transcript via yt-dlp (YouTube only)
└── references/
    ├── diagram-standard.md               ← Diagram conventions (MUST read before writing)
    ├── example-output.md                 ← Reference: YouTube source example
    └── example-output-blog.md            ← Reference: Blog post source example
```

**Before writing any output, you MUST read all three reference files.** They define the quality bar.

---

## Inputs

The user provides a source. Auto-detect the type:

| Input Pattern | Type | Extraction Method |
|---|---|---|
| URL containing `youtube.com` or `youtu.be` | YouTube | `scripts/yt-transcript.zsh` (Claude Code) or WebFetch + ask for transcript |
| URL starting with `http` (non-YouTube) | Web/Blog | WebFetch tool |
| File path ending in `.pdf` | PDF | Read tool (PDF support) |
| URL ending in `.pdf` | PDF (remote) | WebFetch to download, then Read tool |
| File path ending in `.docx` | DOCX | `pandoc -t markdown <file>` |
| File path ending in `.md` or `.txt` | Text/Markdown | Direct Read tool |
| None of the above | Pasted text | Parse structured headers or ask for metadata |

### Pasted Text Headers

When the user pastes text directly, check for these structured header formats:

**YouTube:**
```
YOUTUBE VIDEO TRANSCRIPT

CHANNEL: {channel name}
TITLE: {video title}
URL: {youtube url}

{transcript text}
```

**Blog Post:**
```
BLOG POST

AUTHOR: {author name}
SITE: {site name}
TITLE: {article title}
URL: {url}

{article text}
```

**Document:**
```
DOCUMENT

AUTHOR: {author name}
TITLE: {document title}
TYPE: {PDF|DOCX|other}

{document text}
```

If no recognized header is found, ask the user: _"What is the source of this text? I need: author/speaker, title, and optionally a URL."_

## Output

A single `.md` file. Where it's saved depends on the environment:

- **claude.ai**: Save to `/mnt/user-data/outputs/` and use `present_files` to deliver
- **Claude Code**: Save to the current working directory (or a path the user specifies)
- **Other**: Save to the current working directory

Filename is derived from the document title using kebab-case (e.g., `harness-design-for-long-running-apps.md`)

---

## Process

### Step 1 — Gather Metadata

Metadata varies by source type:

| Source | Required Metadata |
|---|---|
| YouTube | Speaker/Channel, Video Title, URL |
| Blog | Author, Site Name, Article Title, URL |
| PDF (local) | Author, Document Title |
| PDF (URL) | Author, Document Title, URL |
| DOCX | Author, Document Title |
| Markdown/Text | Author, Title, Path or URL |

**Resolution order per type:**

- **YouTube (Claude Code)**: Run `source <skill-dir>/scripts/yt-transcript.zsh && yt-transcript <url> -o /tmp/yt-transcript.txt` — the output file contains `CHANNEL:`, `TITLE:`, `URL:` headers followed by timestamped transcript lines. Read the file to extract metadata and transcript in one step, then skip to Step 2
- **YouTube (other environments)**: Use `web_fetch` to get the page title and channel name, then ask user to paste the transcript
- **Blog URL**: WebFetch the page. Extract author from byline/meta tags, site name from domain, title from `<title>` or `<h1>`
- **PDF (local)**: Read the file. Check first page for author/title. If ambiguous, ask the user
- **PDF (URL)**: Fetch the file first, then read. Check first page for author/title. If ambiguous, ask the user
- **DOCX**: Run `pandoc -t markdown <file>`. If pandoc is not installed, tell the user: _"pandoc is required for DOCX conversion. Install: `brew install pandoc`"_. Check YAML frontmatter or first heading for metadata. If ambiguous, ask the user
- **Markdown/Text file**: Read directly. Check YAML frontmatter or first heading. If ambiguous, ask the user
- **Pasted text**: Parse structured headers (see Pasted Text Headers above). If absent, ask the user
- **If fetching/reading fails**: Ask the user to provide the metadata

### Step 2 — Read Skill References

**Mandatory.** Read all three reference files before writing anything. Use the appropriate tool for your environment:

- **claude.ai**: `view` tool on the reference file paths
- **Claude Code**: `cat` the reference files from the skill directory

```
references/diagram-standard.md     ← How ALL diagrams must be formatted
references/example-output.md       ← Quality bar: YouTube source example
references/example-output-blog.md  ← Quality bar: Blog post source example
```

### Step 3 — Analyze the Source Content

Read the full source content and extract:

1. **The core thesis** — the single main argument or insight (1-2 sentences)
2. **Key concepts** — distinct ideas, patterns, or principles discussed
3. **Relationships between concepts** — how they build on or relate to each other
4. **Concrete examples** — specific technologies, libraries, demos mentioned
5. **Practical recommendations** — what the author/speaker says to do or avoid

Do NOT include:

- Repetition where the author/speaker restates the same point
- Step-by-step demo narration (capture the _concept_ the demo illustrates, not the steps)

**Source-specific exclusions:**

- **YouTube**: Sponsor mentions, channel promotion, like/subscribe requests
- **Blog posts**: Author bios, related article links, newsletter signup CTAs
- **PDF/DOCX**: Table of contents, indexes, appendices of raw data (unless conceptually relevant)

### Step 4 — Gather Work Context

The "Relevance to Our Work" section MUST be grounded in the user's actual project context. Follow this resolution order:

1. **Search project knowledge** — if `project_knowledge_search` is available (claude.ai with project knowledge), search for terms related to the source concepts
2. **Search the codebase** — if in Claude Code, look for architecture docs, ADRs, README files, or a docs/ directory that describes the project's architecture and stack
3. **Ask the user** — if neither of the above yields context, ask: _"Do you have project documentation or conventions I should reference for the 'Relevance to Our Work' section? If not, I can skip it."_
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

Every output document MUST follow this structure. Sections can be added between sections 2-N based on content, but the header, the final two sections ("Relevance to Our Work" and "Summary"), and the footnote are mandatory.

### Header Block (mandatory)

```markdown
# {Document Title}

> **Source**: {source line — format varies by type}
>
> **Key Insight**: {1-2 sentence core thesis}
```

**Source line format per type:**

- **YouTube**: `{Speaker} ({Channel}) — [{Video Title}]({URL})`
- **Blog**: `{Author} ({Site Name}) — [{Article Title}]({URL})`
- **PDF/DOCX (local)**: `{Author} — {Document Title}`
- **PDF/DOCX (URL)**: `{Author} — [{Document Title}]({URL})`
- **Markdown (local)**: `{Author} — {Document Title}`
- **Markdown (URL)**: `{Author} — [{Title}]({URL})`

Rules:

- The `# title` should be a descriptive knowledge title, not necessarily the source title verbatim
- When a URL is available, the link text MUST be the source title, linking to the full URL
- **Key Insight** summarizes the author/speaker's main thesis in 1-2 sentences

### Content Sections

Organize concepts into numbered sections (`## 1. Section Name`). Guidelines:

- **One concept per section** — don't merge unrelated ideas
- **Use subsections** (`### 3.1 Subsection`) when a concept has distinct sub-points
- **Lead with the problem**, then the solution — mirror how the author/speaker motivates each concept
- **Include structured text diagrams** following `references/diagram-standard.md` when the concept involves flows, comparisons, or architecture
- **Use ✅/❌ markers** for rules, recommendations, and trade-offs
- **Use comparison tables** when the author/speaker contrasts approaches
- **Capture specific named technologies** (libraries, tools, frameworks) mentioned
- **Keep the author/speaker's terminology** — don't rename their concepts

### Relevance to Our Work (mandatory unless user says to skip)

```markdown
## N. Relevance to Our Work
```

Connect the source's concepts to the user's actual project context using a structured text block:

```
APPLICATION TO {PROJECT CONTEXT}

{CONCEPT FROM SOURCE}:
  ✅ {How it applies to the user's work}
  ❌ {What to avoid, with rationale}
```

Include specific tool/library recommendations matching the user's stack (gathered in Step 4). This section must reference real project conventions, not generic advice.

### Summary (mandatory)

A concise paragraph (3-5 sentences) restating the key takeaways. No bullet points. Should stand alone as a TL;DR.

### Footnote (mandatory)

Format per type:

- **YouTube**: `[^1]: {Speaker} — [{Video Title}]({URL})`
- **Blog**: `[^1]: {Author} — [{Article Title}]({URL})`
- **PDF/DOCX (local)**: `[^1]: {Author} — {Document Title}`
- **PDF/DOCX (URL)**: `[^1]: {Author} — [{Document Title}]({URL})`

---

## Style Rules

1. **Prose over bullets** — use paragraphs for explanations, structured text diagrams for architecture, tables for comparisons. Avoid bullet-point-heavy sections.
2. **No Mermaid** — all diagrams use structured text per `references/diagram-standard.md`
3. **Author/Speaker attribution** — use "{Author/Speaker} explains..." or "In the demo/article..." when referencing specific points. Don't use "the video/article says..."
4. **Concepts not narration** — capture what the author/speaker teaches, not what they show step by step
5. **English only** — all content and code comments in English
6. **Footnotes for sources** — use markdown footnotes `[^N]` with full URLs

---

## Quality Checklist

Before delivering, verify:

- [ ] Input type was correctly auto-detected
- [ ] Header has Source in correct format for source type (link when URL available) + Key Insight
- [ ] All three reference files were read before writing
- [ ] Diagram standard followed (structured text, ✅/❌, ASCII boxes, no Mermaid)
- [ ] No irrelevant content (sponsors, CTAs, self-promotion, boilerplate) included
- [ ] Specific technologies and libraries from the source are captured
- [ ] "Relevance to Our Work" is grounded in real project context (or explicitly skipped by user)
- [ ] Summary is a concise standalone paragraph
- [ ] Footnote matches source type format
- [ ] Filename matches the document title (kebab-case, no spaces)
- [ ] Output matches the quality and structure of the reference examples
