# Tool-Call RAG for DAA Algorithms

A small, curated reference corpus (Design & Analysis of Algorithms) that
OpenCode/Goose fetch **on demand via a shell tool call**, not by having it
permanently stuffed into the system prompt. Built specifically to avoid a
common failure mode with local-model RAG setups: confidently returning the
wrong reference, which causes the model to hallucinate with unwarranted
confidence. This one is deliberately conservative — when in doubt, say "not
covered," never guess.

## Why tool-call retrieval instead of just stuffing context

All 8 topics together run to several thousand tokens. Loading all of it on
every turn burns a large chunk of the (already tight, tool-schema-heavy)
context budget on irrelevant material for most questions. Instead, the
agent calls `rag-search.sh "<query>"` through its existing `shell` tool only
when the question is actually about one of these topics, and gets back just
that one topic's content (roughly 1-3K tokens).

## Corpus (8 topics, all C++, every concrete algorithm compiled and run)

| Topic | Category |
|---|---|
| Greedy algorithms — general idea | Concept overview |
| Huffman coding | Greedy |
| Fractional knapsack | Greedy |
| Divide and conquer — general idea | Concept overview |
| Maximum subarray sum | Divide and conquer (+ Kadane's for comparison) |
| QuickSort | Divide and conquer |
| MergeSort | Divide and conquer |
| Assembly line scheduling | Dynamic programming |

Every concrete algorithm's C++ code was compiled with `g++ -std=c++17 -Wall
-O2` and run against a known textbook example before being written into the
corpus — including the assembly-line scheduling DP, where independently
hand-tracing the backtrack step caught that a fuzzy memory of the textbook
path was actually wrong, confirming the code (not the memory) was right.

**Deliberate categorization choices, made for correctness, not just
organization**: maximum subarray implements the actual divide-and-conquer
algorithm (recursive split + crossing-subarray combine), not Kadane's —
those are genuinely different algorithms, and Kadane's is included in the
same file as a clearly-labeled second method for comparison rather than
being conflated with the D&C one. Fractional knapsack's entry explicitly
states it is **not** the 0/1 knapsack problem (different problem, needs
dynamic programming, greedy doesn't give the optimal answer) — and
`rag-search.sh` has an explicit guard so a `0/1 knapsack` query gets a
direct "not covered" response instead of the (wrong) fractional solution.

## Retrieval: deterministic keyword/alias matching, not embeddings

For a small, fixed, well-known corpus, a full embedding-model + vector-DB
stack is the wrong tool — it adds a second source of retrieval imprecision
on top of generation imprecision. Instead, `rag-search.sh` scores each
topic by substring-matching a curated alias list against the query
(case-insensitive, weighted by alias length so more specific matches
outscore generic ones) — deterministic, near-instant, zero extra
dependencies beyond `jq`.

**Conservative on ambiguity, on purpose**: no confident match → `NO MATCH`
+ a list of what *is* covered. A tie between two topics → `AMBIGUOUS` + both
candidates. Never a silent guess.

**A real precision bug found and fixed via testing**: a query like
`"divide and conquer maximum subarray"` initially matched the generic
overview topic instead of the specific one, because the overview's own
broad alias out-scored the more specific one on raw substring length. Fixed
with a specificity rule — an `*_overview` topic's score is demoted to 0
whenever a more specific topic in the same category also matched.

## Wiring into the agents

`workspace/AGENTS.md` (auto-loaded by both OpenCode and Goose) has a
mandatory-tone rule: for any algorithm-explanation question, call
`rag-search.sh` first, before answering, and ground the answer in whatever
comes back. It explicitly does **not** name the 8 covered topics as the
trigger condition — the rule applies to *any* algorithm question, letting
the tool's own `NO MATCH` response decide scope, rather than asking the
model to correctly pre-judge in advance whether a topic is covered (an
earlier version of the instruction that named the 8 topics explicitly let
the model skip the tool entirely for out-of-scope questions).

## A known, honestly-reported limitation

A small local model does not 100% reliably call the tool, even with an
explicit "always check first" instruction — confirmed by testing, not
assumed: for topics *actually in the corpus*, the tool was called correctly
in every test run; for a deliberately out-of-scope question (an algorithm
not in this corpus), the model sometimes answered directly from its own
memory without disclosing it wasn't grounded. This was confirmed to be a
genuine model-instruction-following gap, not a wiring bug, by inspecting
the model's raw system prompt with the local server's debug logging and
verifying the instruction text was actually present. No amount of
`AGENTS.md` prompt tuning fully closes this gap on small (3B-30B-class)
local models — it's a real characteristic of the model, not a to-do item.

**Practical takeaway**: for the 8 topics this corpus actually covers,
grounding is reliable. For anything adjacent but not in the corpus, there's
no hard guarantee the model checks first rather than answering from memory.
