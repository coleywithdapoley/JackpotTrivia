# Question standards — Jackpot Trivia

Human-authored questions in `JackpotTrivia/Resources/QuestionCatalog.json` must meet these rules before `status` is set to `approved`.

## Required fields

| Field | Rule |
|-------|------|
| `id` | Unique slug, lowercase with hyphens (e.g. `sci-gold-symbol`) |
| `category` | Must match a name in `AppConfig.defaultCategories` |
| `question` | Clear stem; one correct interpretation |
| `answers` | MCQ: 4 options; T/F: exactly `["True", "False"]` |
| `correctIndex` | 0-based index into `answers` |
| `questionType` | `multipleChoice` or `trueFalse` |
| `difficulty` | `easy`, `medium`, or `hard` |
| `status` | `approved` for live play; `draft` for work in progress |
| `source` | e.g. `human` (future: `ai-draft`) |
| `verifiedAt` | ISO date when a human verified the answer |

## Content quality

- **One unambiguous correct answer** — if experts disagree, reword or retire.
- **Plausible distractors** — wrong answers should be believable, not jokes (unless mood calls for it).
- **Length** — aim for ≤ 140 characters on the question stem for timed play.
- **Reading level** — target general audience unless category implies otherwise.
- **Mature content** — set `allowsMatureTopics`, `isFamilySafe`, and `isEducational` explicitly; default is family-safe.

## Difficulty and timing

| Difficulty | Default timer | Base points (in app) |
|------------|---------------|----------------------|
| easy | 20s | 100 |
| medium | 15s | 150 |
| hard | 10s | 200 |

Override with `timeLimitSeconds` only when needed.

## Lifecycle

- **draft** — not shown in play
- **approved** — eligible for daily jackpot and practice
- **retired** — removed from JSON or marked retired; use admin “Retire” for interim local hide

## Improvement flywheel

1. Ship only `approved` questions.
2. Monitor **player reports** and **miss rate** in Admin → Question Review.
3. Retire or edit weak items in JSON using the question `id`.
4. Re-run catalog validation tests before release.

Automated validation lives in `QuestionCatalogValidator` and `QuestionCatalogValidationTests`.
