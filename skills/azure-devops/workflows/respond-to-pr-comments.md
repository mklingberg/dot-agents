# Workflow — Respond to PR comments

Read `references/rest-api.md` sections B5 and B7 before posting anything.

<objective>
Turn open reviewer comments on a pull request into drafted replies, posted only
after the operator approves each one. Replies only — no code changes, no thread resolution.
</objective>

## Step 1 — Locate the PR

From a PR URL, from `git branch --show-current` + the active-PR list, or from an id
the user gave. Confirm the PR before reading further:

```bash
curl -s -u ":$AZURE_DEVOPS_PAT" \
  "https://dev.azure.com/$ORG/$PROJ/_apis/git/repositories/$REPO/pullrequests/$PR?api-version=7.1" \
  | jq '{pullRequestId, title, status, sourceRefName, targetRefName, isDraft}'
```

## Step 2 — Fetch and filter threads

```bash
curl -s -u ":$AZURE_DEVOPS_PAT" \
  "https://dev.azure.com/$ORG/$PROJ/_apis/git/repositories/$REPO/pullrequests/$PR/threads?api-version=7.1" \
  | jq '[.value[]
      | select(.comments[0].commentType != "system")
      | select(.comments[0].author.displayName
               | test("Azure Pipelines|Microsoft\\.VisualStudio|Test Service|\\[.*\\]\\\\") | not)
      | select(.status == "active" or .status == "pending")
      | {id, status,
         file: .threadContext.filePath,
         line: .threadContext.rightFileStart.line,
         comments: [.comments[] | {id, parentCommentId, author: .author.displayName, content}]}]'
```

Two independent filters are needed, and **both** matter:

- `commentType != "system"` drops branch-updated and policy notices.
- The author check drops bots that post as ordinary text. Verified case: the diff-coverage
  bot posts with `commentType: "text"` and author `Azure Pipelines Test Service`, so the
  commentType filter alone lets it through. Replying to it is embarrassing and public.

Then drop already-settled threads (`fixed`, `wontFix`, `closed`). What remains is what
actually needs an answer.

If nothing remains, say so and stop. Do not manufacture work.

## Step 3 — Read the code the comment refers to

For each thread with a `threadContext`, open the file at that line on the PR's source
branch. A reply written without looking at the code is a guess, and it will read like one.

For threads without file context, read the PR description and diff summary.

## Step 4 — Classify each thread

| Kind | Response |
|---|---|
| Question about intent or approach | Answer it directly |
| Suggestion you agree with | Say so, state what will change — but do **not** make the change |
| Suggestion you disagree with | State the reason concretely; disagreement is normal in review |
| Already addressed in a later commit | Point at the commit |
| Out of scope for this PR | Say so and where it belongs |

## Step 5 — Draft replies

Apply the global "Writing in my name" rules. Concretely, for review replies:

- **Same language as the comment.** Swedish question → Swedish answer. This is the
  single most common failure — the "reply to the operator in English" rule does not apply to
  text written for other people.
- Short. One to three sentences answers most threads.
- No apology unless something was actually broken. "Missed that, fixed in `abc1234`"
  is fine. "Sorry for the confusion!" on a neutral question is not.
- No filler ("Great catch!", "Absolutely!"). Answer the question.
- Concrete over hedged: name the file, the commit, the reason.
- Dry humour is allowed where it lands naturally. Never at the reviewer's expense.

Present all drafts together:

```
Thread 617735 — Sofia L. — PaymentService.cs:412
  > Behålla som standard? Känns som att det borde vara opt-in.
  Draft reply (Swedish):
  Håller med, opt-in är rimligare. Ändrar defaultvärdet till false.

Thread 617740 — ...
```

Ask: post all / edit one / skip one.

## Step 6 — Post approved replies

One POST per approved reply. `parentCommentId` is the `id` of the comment being
answered — normally `1` for the thread's opening comment.

```bash
curl -s -u ":$AZURE_DEVOPS_PAT" -X POST \
  "https://dev.azure.com/$ORG/$PROJ/_apis/git/repositories/$REPO/pullrequests/$PR/threads/$THREAD/comments?api-version=7.1" \
  -H "Content-Type: application/json" \
  -d '{"parentCommentId": 1, "content": "...", "commentType": "text"}'
```

Do **not** PATCH thread status afterwards. Leaving threads open is intentional.

## Step 7 — Report

List each thread, the reply posted, and its new comment id. Note any thread that was
skipped and why. If a reply promised a code change, state plainly that the change has
not been made yet.

<success_criteria>
- [ ] System/bot threads excluded by **both** commentType and author, settled threads excluded
- [ ] Code at the referenced line actually read before drafting
- [ ] Each reply in the same language as the comment it answers
- [ ] No unwarranted apology, no filler praise
- [ ] Every reply approved by the operator before posting
- [ ] No thread status changed
- [ ] No code modified
</success_criteria>
