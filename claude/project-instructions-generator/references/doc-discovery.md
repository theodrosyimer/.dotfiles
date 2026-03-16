# Documentation Source Discovery Workflow

Finding and organizing the right doc sources is the most impactful part of project instructions. Follow this workflow for each topic in the user's priority stack.

## Step 1: Official Documentation

### If Context7 MCP is available (preferred)

1. Use `resolve-library-id` to find the library/framework
2. Use `query-docs` to verify the docs are comprehensive
3. Extract the base URL and key sections

### If Context7 is not available

1. `web_search` for `[topic] official documentation`
2. `web_fetch` the docs homepage to get the navigation/sidebar structure
3. Extract page URLs and category groupings

### For all official docs

- Get the **sidebar/navigation structure** — this gives Claude the full map of what's available
- Look for a **sitemap, docs map, or table of contents** page. If one exists, include it as a special entry:

```markdown
> When unsure which page covers the topic, fetch the docs map first:
> https://example.com/docs/sitemap
```

- Organize pages by the same categories the docs site uses
- Include both getting-started and reference/advanced pages

## Step 2: Expert Articles

Search for authoritative content beyond official docs:

1. `web_search` for `[topic] best practices expert blog`
2. `web_search` for `[topic] architecture patterns article`
3. `web_search` for `[topic] tutorial advanced guide`

**What to look for:**
- Blog posts from recognized practitioners (conference speakers, core contributors, authors)
- In-depth technical articles with practical examples
- Architecture decision guides and pattern comparisons
- Posts that are frequently referenced in the community

**What to avoid:**
- Generic "top 10" listicles
- Outdated articles (check publication date)
- SEO-optimized content farms
- Paywalled content the user can't access

**Present to user:** Show each article with title, author, and a one-line summary. Ask which to include.

## Step 3: Additional Resources

Look for supplementary sources:

- **Specifications** (e.g., MCP spec, OpenAPI spec)
- **Cookbooks/examples** (official recipe repos, quickstarts)
- **GitHub repos** (reference implementations, awesome lists)
- **API references** (separate from guides/tutorials)

## Organizing the Output

### Label hierarchy

- **PRIMARY** — The main source Claude should check first. Usually 1-2 sources max.
- **SECONDARY** — Supporting sources Claude checks when PRIMARY doesn't cover the topic.
- **Expert Articles** — Standalone section for blog posts and guides.
- **Additional Sources** — Specs, repos, cookbooks.

### Format

```markdown
### Source Name (`domain.com`) — PRIMARY

**Category Name**
- [Page title](https://full-url)
- [Page title](https://full-url)

**Another Category**
- [Page title](https://full-url)
```

### Keep it manageable

- Aim for 3-5 source groups total
- 5-15 pages per PRIMARY source (the most important ones)
- 3-10 pages per SECONDARY source
- 3-5 expert articles
- 2-5 additional resources

If a docs site has 50+ pages, curate — include the pages most relevant to the project's focus, not every single page.
