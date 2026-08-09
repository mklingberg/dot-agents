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

**Empty line** — **not possible.** Both `{"type":"paragraph","content":[]}` and
`{"type":"paragraph"}` return 400 `INVALID_INPUT`. Separate paragraphs already
render with spacing; for a hard separator use `{"type":"rule"}`.

**Line break inside a paragraph**
```json
{"type":"paragraph","content":[
  {"type":"text","text":"first"},{"type":"hardBreak"},{"type":"text","text":"second"}]}
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

**Issue mention** — renders as a live ticket link. Must sit **inside a
paragraph**; as a top-level block node it returns 400.
```json
{"type":"paragraph","content":[
  {"type":"inlineCard","attrs":{"url":"https://norionbank.atlassian.net/browse/MS-6545"}}]}
```
</blocks>

<building>
Do not hand-assemble ADF in a shell heredoc. Write a small Python helper to a
temp file, generate the payload, and post the file — errors become readable and
the story text stays editable.

```python
# /tmp/adf.py
def p(text): return {"type":"paragraph","content":[{"type":"text","text":text}]}
def h(text, level=3): return {"type":"heading","attrs":{"level":level},
                              "content":[{"type":"text","text":text}]}
def ul(items): return {"type":"bulletList","content":[
    {"type":"listItem","content":[p(i)]} for i in items]}
def link(text, href): return {"type":"paragraph","content":[
    {"type":"text","text":text,"marks":[{"type":"link","attrs":{"href":href}}]}]}
def card(key): return {"type":"paragraph","content":[{"type":"inlineCard",
    "attrs":{"url":f"https://norionbank.atlassian.net/browse/{key}"}}]}
def doc(*blocks): return {"type":"doc","version":1,"content":list(blocks)}
```

`p()` never takes an empty string — an empty paragraph is invalid ADF.

Then:
```python
import json, os
body = doc(
    p("As a customer"), p("I want to see my invoices"), p("So that I can pay them"),
    h("Acceptance criteria"),
    ul(["Invoice list loads under 1s", "Empty state shown when no invoices"]),
    h("Links"),
    link("Figma design", "https://figma.com/file/..."),
)
json.dump({"fields": {"project": {"key": "MS"}, "issuetype": {"id": "10001"},
                      "summary": "See my invoices", "description": body,
                      "reporter": {"id": os.environ["ATLASSIAN_ACCOUNT_ID"]},
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
All verified against MS-6548 by posting and deleting real comments.

- **`listItem` content must be block nodes.** `{"type":"listItem","content":[{"type":"text",...}]}` 400s.
- **There is no empty paragraph.** Both `"content": []` and an omitted `content` key 400.
- **`inlineCard` is inline-only.** Wrap it in a paragraph or it 400s.
- **`\n` inside a text node is accepted (201) but is not a line break** — it round-trips verbatim and renders as whitespace. Use `hardBreak`.
- **`version` is `1`, always**, and it is required.
- **A 400 from `/issue` names the field but not the offending node.** Bisect by posting one block at a time as a comment on a scratch issue — `DELETE $B/issue/KEY/comment/ID` cleans up and returns 204.

Confirmed working: `heading`, `paragraph`, `bulletList`, `strong`/`code` marks,
`codeBlock`, `panel`, `link`, `hardBreak`, `rule`, inline `inlineCard`.
</gotchas>
