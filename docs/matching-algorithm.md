# TeamUp — Matching Algorithm (v0)

> Detailed explanation of the ranking algorithm implemented in
> [`backend/src/services/matching.js`](../backend/src/services/matching.js).

## 1. The problem

We have two entities:

- **Students** with declared **skills** (proficiency level `1..5`) and **interests**.
- **Projects** with declared **required skills** (importance weight `1..5`) and **interest tags**.

The matcher answers two symmetric questions:

1. *Given a project, which students should we recommend?*
2. *Given a student, which projects should we suggest?*

The output is a **ranked list** (most relevant first), with a `score ∈ [0, 1]`
that is fully interpretable.

## 2. The formula

```
score = 0.7 · skill_match  +  0.3 · interest_match              ∈ [0, 1]
```

Two components, computed independently and then combined.

### 2.1 `skill_match` — weighted, normalized overlap

```
                Σ_{s ∈ P.skills}  weight_p(s) · level_u(s)
skill_match = ─────────────────────────────────────────────
                Σ_{s ∈ P.skills}  weight_p(s) · 5
```

- We sum over the **project's required skills** (not the user's full set).
- For each required skill, the user contributes `weight × level` if they have it,
  `0` otherwise.
- We divide by the maximum theoretical score (every skill at the max level `5`)
  to get a number in `[0, 1]`.

**Why weighted?** A project can say *"Flutter is critical (weight 5), Figma is a
plus (weight 2)"*. The weight reflects priority.

**Why does the user's level matter?** An expert (level 5) brings more value than
a beginner (level 1) for the same skill.

**Why normalize?** Without dividing by the maximum, projects that require many
skills would have larger raw sums and unfair advantages. Normalization makes
scores comparable across projects.

### 2.2 `interest_match` — Jaccard similarity

```
interest_match = |I_u ∩ I_p|  /  |I_u ∪ I_p|
```

This is the standard **Jaccard index**, the canonical similarity measure for
two sets.

**Why Jaccard?** Interests don't have proficiency levels (you either have an
interest or you don't — binary). Jaccard is symmetric, in `[0, 1]`, and
trivial to explain.

### 2.3 The 70/30 split

- **Skills** are *technical prerequisites*: without them the team can't build
  the project. They are the dominant signal.
- **Interests** are *fit / motivation*: nice-to-have, not blocking.

Hence: skills weighted `0.7`, interests weighted `0.3`.

## 3. Worked example — Chloé Lefèvre for "StudyMate"

This reproduces the actual response in
[`backend/demo-output/04-matching-algorithm.json`](../backend/demo-output/04-matching-algorithm.json).

### The project: *StudyMate* (owner: Alice)

| Required skill   | Weight |
|------------------|--------|
| Flutter          | 5      |
| Node.js          | 4      |
| UI/UX Design     | 3      |

Tagged interests: `{Mobile Apps, EdTech}`.

### The candidate: Chloé

| Skill            | Level  |
|------------------|--------|
| Figma            | 5      |
| UI/UX Design     | 5      |
| Flutter          | 3      |

Interests: `{Mobile Apps, Design, EdTech}`.

### Step 1 — Compute `skill_match`

Walk over the project's required skills and check Chloé's profile:

| Required        | Chloé's level | Contribution (`weight × level`) |
|-----------------|---------------|---------------------------------|
| Flutter         | 3             | 5 × 3 = **15**                  |
| Node.js         | —             | **0**                           |
| UI/UX Design    | 5             | 3 × 5 = **15**                  |

- Raw sum: `15 + 0 + 15 = 30`
- Max possible: `5×5 + 4×5 + 3×5 = 25 + 20 + 15 = 60`
- **`skill_match = 30 / 60 = 0.5`**

> Note: Chloé's Figma skill is **not** counted — StudyMate doesn't require it.
> We score the candidate against the project's needs, not against everything
> they happen to know.

### Step 2 — Compute `interest_match`

- `I_p ∩ I_u = {Mobile Apps, EdTech}` → **2** elements
- `I_p ∪ I_u = {Mobile Apps, Design, EdTech}` → **3** elements
- **`interest_match = 2 / 3 ≈ 0.667`**

### Step 3 — Combine

```
score = 0.7 × 0.5 + 0.3 × 0.667
      = 0.35    + 0.200
      = 0.550
```

This is exactly the value returned by the API.

## 4. Why Chloé wins (intuitively)

Compared to the other top candidates for StudyMate:

| #   | Candidate    | `skill_match` | `interest_match` | `score` |
|-----|--------------|---------------|------------------|---------|
| 1   | Chloé        | 0.500         | 0.667            | **0.550** |
| 2   | Erwan        | 0.417         | 0.333            | 0.392   |
| 3   | Bob          | 0.333         | 0.000            | 0.233   |

- **Erwan** is a Flutter expert (level 5), but lacks UI/UX Design and shares
  fewer interests with StudyMate.
- **Bob** has Node.js but no Flutter and no shared interests.
- **Chloé** brings *both* Flutter and UI/UX Design (the latter at the max level)
  and shares more interests — her balance wins.

This matches what a human recruiter would intuitively pick for a mobile + UX
education project.

## 5. Performance

A naive implementation would score every user against every project: `O(N × M)`
where `N` is the user count and `M` the average skills per user.

We avoid this by **pre-filtering candidates in SQL**:

```sql
SELECT DISTINCT u.id, ...
  FROM users u
  JOIN user_skills us ON us.user_id = u.id
 WHERE us.skill_id IN (?)        -- the project's required skills
   AND u.id NOT IN (?)           -- exclude owner + existing members
```

Only users with **at least one** of the required skills are loaded into
memory. The fine-grained scoring is then done in JavaScript on this small
candidate set.

The MariaDB foreign-key index on `user_skills.skill_id` (auto-created) makes
the join fast.

**Final complexity:** `O(C · R)` where `C` is the filtered candidate count
(typically much smaller than `N`) and `R` is the number of required skills
(typically `< 10`).

## 6. Edge cases & known limits

- **Cold-start users** (no skills declared) are absent from the candidate set.
  Accepted limitation in v0 — they need to fill their profile to be matched.
- **Profile text is ignored.** Free-form bio / project description is not
  used yet.
- **No history.** Past project participations or successes don't influence
  the score.
- **No team-diversity awareness.** The algorithm ranks individual candidates;
  it doesn't try to assemble a complementary team.

## 7. Planned (v1)

- **TF-IDF** over `bio` and `description` to capture semantic match beyond
  declared skills.
- **Cold-start fallback** using bio text as a proxy when skills are missing.
- **Collaborative filtering** once we have enough historical participation
  data.
- **Team-diversity bonus** that down-weights candidates whose skills are
  already covered by current team members.

## 8. Anticipated questions

> **Why 70/30 and not 50/50?**

Empirical for v0. Skills are technical prerequisites; without them the team
can't ship. Interests are about motivation and fit. We made skills the
dominant signal without ignoring fit. In production these coefficients
would be tuned via A/B testing.

> **Why not cosine similarity?**

Cosine fits dense normalized vectors. Here features are sparse (a user has
~5 skills out of ~18 in the catalog). The weighted overlap we use is more
explainable directly to the user (*"you have X% of the required skills"*),
which matters for a UX-driven product.

> **Won't a user with 50 skills always rank first?**

No. We score a user **only** on the project's required skills. Off-topic
skills don't help. A user who has exactly the 3 required skills at max level
beats a user who has 50 skills, none of which are required.

> **How are ties broken?**

By SQL row order after the score sort. Future v1 plans to tie-break by
recency of activity or profile completeness.

> **Why does the user level cap at 5?**

Five-point Likert scales are a UX standard for self-rating; users intuit them
without instructions, and the granularity is sufficient for ranking
(higher granularity adds noise without signal).
