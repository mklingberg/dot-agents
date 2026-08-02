<overview>
Atlassian Document Format — the JSON document shape used for every rich-text
field in Jira REST v3: `description`, `comment.body`, `environment`, and
custom fields of type `doc`.

**Markdown does not work.** `"description": "As a user..."` returns 400
`INVALID_INPUT`. Build the document, or convert.
</overview>

<envelope>
Every ADF document is wrapped the same way. Only `content` varies.

```json
{
  "type": "doc",
  "version": 1,
  "content": [ ...block nodes... ]
}
```
</envelope>

<blocks>
Copy these. They cover ~95% of story and comment bodies.

**Paragraph**
```json
{"type":"paragraph","content":[{"type":"text","text":"Plain sentence."}]}
```

**Empty line** — a paragraph with no content. Needed for spacing; ADF has no `\n`.
```json
{"type":"paragraph","content":[]}
```

**Heading** (`level` 1–6)
```json
{"type":"heading","attrs":{"level":3},"content":[{"type":"text","text":"Acceptance criteria"}]}
```

**Bullet list** — every item wraps its text in a paragraph. Skipping the
paragraph is the single most common ADF mistake.
```json
{"type":"bulletList","content":[
  {"type":"listItem","content":[
    {"type":"paragraph","content":[{"type":"text","text":"First item"}]}]},
  {"type":"listItem","content":[
    {"type":"paragraph","content":[{"type":"text","text":"Second item"}]}]}
]}
```
`orderedList` is identical with the outer type swapped.

**Bold / italic / code** — marks on a text node:
```json
{"type":"text","text":"must","marks":[{"type":"strong"}]}
{"type":"text","text":"GET /foo","marks":[{"type":"code"}]}
```

**Link**
```json
{"type":"text","text":"Figma design",
 "marks":[{"type":"link","attrs":{"href":"https://figma.com/file/..."}}]}
```

**Code block**
```json
{"type":"codeBlock","attrs":{"language":"csharp"},
 "content":[{"type":"text","text":"var x = 1;"}]}
```

**Panel** — for a callout, e.g. a note about scope.
`panelType`: `info` | `note` | `warning` | `success` | `error`
```json
{"type":"panel","attrs":{"panelType":"info"},
 "content":[{"type":"paragraph","content":[{"type":"text","text":"Blocked on design."}]}]}
```

**Issue mention** — renders as a live ticket link:
```json
{"type":"inlineCard","attrs":{"url":"https://norionbank.atlassian.net/browse/MS-6545"}}
```
</blocks>

<building>
Do not hand-assemble ADF in a shell heredoc. Write a small Python helper to a
temp file, generate the payload, and post the file — errors become readable and
the story text stays editable.

```python
# /tmp/adf.py
def p(text): return {"type":"paragraph","content":[{"type":"text","text":text}] if text else []}
def h(text, level=3): return {"type":"heading","attrs":{"level":level},
                              "content":[{"type":"text","text":text}]}
def ul(items): return {"type":"bulletList","content":[
    {"type":"listItem","content":[p(i)]} for i in items]}
def link(text, href): return {"type":"paragraph","content":[
    {"type":"text","text":text,"marks":[{"type":"link","attrs":{"href":href}}]}]}
def doc(*blocks): return {"type":"doc","version":1,"content":list(blocks)}
```

Then:
```python
import json
body = doc(
    p("As a customer"), p("I want to see my invoices"), p("So that I can pay them"),
    h("Acceptance criteria"),
    ul(["Invoice list loads under 1s", "Empty state shown when no invoices"]),
    h("Links"),
    link("Figma design", "https://figma.com/file/..."),
)
json.dump({"fields": {"project": {"key": "MS"}, "issuetype": {"id": "10001"},
                      "summary": "See my invoices", "description": body,
                      "reporter": {"id": "613779557eb35f006928eb06"},
                      "customfield_12035": {"value": "Magica"}}},
          open("/tmp/issue.json", "w"))
```
</building>

<reading_adf>
Coming back the other way — when summarising an existing issue for the user,
flatten instead of dumping the JSON:

```python
def flatten(node):
    if isinstance(node, dict):
        if node.get("type") == "text": return node["text"]
        return "".join(flatten(c) for c in node.get("content", []))
    return "".join(flatten(c) for c in node)
```
Good enough for reading. It loses list bullets and headings — fine for a
summary, not for round-tripping an edit. **Never** flatten, edit the string, and
write it back; that destroys formatting. Rebuild the document instead.
</reading_adf>

<gotchas>
- **`listItem` content must be block nodes.** `{"type":"listItem","content":[{"type":"text",...}]}` 400s.
- **No newlines in text nodes.** `\n` is either stripped or rejected; use separate paragraphs, or `hardBreak` inside one.
- **`version` is `1`, always**, and it is required.
- **Empty paragraph is `"content": []`, not `"content": [{"type":"text","text":""}]`** — an empty text node is invalid.
- **A 400 from `/issue` names the field but not the offending node.** Bisect by posting the description alone via `PUT /issue/KEY`.
</gotchas>
