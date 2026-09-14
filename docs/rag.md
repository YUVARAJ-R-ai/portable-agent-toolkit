# Tool-Call RAG for DAA Algorithms

A small, curated reference corpus (Design & Analysis of Algorithms) that
OpenCode/Goose fetch **on demand via a shell tool call**, not by having it
permanently stuffed into the system prompt. Built specifically to avoid a
common failure mode with local-model RAG setups: confidently returning the
wrong reference, which causes the model to hallucinate with unwarranted
confidence. This one is deliberately conservative — when in doubt, say "not
covered," never guess.

## Why tool-call retrieval instead of just stuffing context

All 19 topics together run to tens of thousands of tokens. Loading all of it on
every turn burns a large chunk of the (already tight, tool-schema-heavy)
context budget on irrelevant material for most questions. Instead, the
agent calls `rag-search.sh "<query>"` through its existing `shell` tool only
when the question is actually about one of these topics, and gets back just
that one topic's content (roughly 1-3K tokens).

## Corpus (19 topics, all C++, every concrete algorithm compiled and run)

| Topic | Category | Key Elements & Twists |
|---|---|---|
| Greedy algorithms — general idea | Concept overview | Greedy-choice property, optimal substructure, exchange argument |
| Huffman coding | Greedy | Optimal prefix codes, min-heap tree merging |
| Fractional knapsack | Greedy | Value/weight ratio sorting (divisible items) |
| Divide and conquer — general idea | Concept overview | Recurrences, Master theorem, split/combine |
| Maximum subarray sum | Divide and conquer | Crossing subarray recursive split (+ Kadane's for comparison) |
| QuickSort | Divide and conquer | Lomuto partition scheme, in-place sort |
| MergeSort | Divide and conquer | Stable divide-and-conquer sort with guaranteed O(n log n) |
| Assembly line scheduling | Dynamic programming | Two parallel lines with transfer costs and path reconstruction |
| N-Queens Backtracking | Backtracking | $O(1)$ diagonal lookups (`cols`, `d1`, `d2`), Obstacles, Amazon/Super-Queens, Max-Weight B&B, Pre-Fixed Queens, No 3 Collinear, K-Queens |
| Job Selection with Deadlines & Profits | Branch and bound | Canonical single-machine, optimistic upper bound, Variable Duration knapsack bound, Rejection Penalties, Release Times $[r_i, d_i]$ |
| Job Assignment (LCBB) | Branch and bound | Cost matrix, row-reduction lower bound, min-heap priority queue |
| Naïve String Matching | String matching | Sliding window, wildcard `?` matching, no adjacent duplicate matched characters |
| Knuth-Morris-Pratt (KMP) | String matching | LPS array $\pi$, linear $O(n+m)$ search, periodic string detection, non-overlapping matches, cyclic shift $A+A$ |
| Rabin-Karp Algorithm | String matching | Polynomial rolling hash base 256 mod $10^9+7$, non-negative modulo, multiple pattern dictionary search |
| Suffix Structures (Suffix Array + LCP) | String matching | Suffix Array + Kasai's $O(n)$ LCP array, Longest Repeated Substring, Longest Common Substring of 2 strings, distinct substring count |
| Minimum Spanning Tree (Kruskal & Prim) | Graph algorithms | Kruskal with DSU (path compression & rank), Prim with min-heap, Mandatory & Forbidden cables, Strictly Second Best MST |
| Floyd-Warshall APSP | Graph algorithms | $O(V^3)$ DP (outermost $k$ loop), path reconstruction matrix, negative cycle detection (-INF marking), widest path / bottleneck capacity, transitive closure |
| Johnson's Algorithm (Sparse APSP) | Graph algorithms | 5 execution steps: synthetic source $s$, Bellman-Ford potential $h[v]$, non-negative reweighting $\hat{w}(u, v)$, $V \times$ Dijkstra |
| PAT-2 Twist Detection & Complexity Matrix | Exam reference | Master complexity table, 30-second keyword translation table, and pre-flight zero-mark avoidance checklist |

Every concrete algorithm's C++ code was compiled with `g++ -std=c++17 -Wall
-O2` and run against known textbook and lab test cases before being written into the
corpus.

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
comes back. It explicitly does **not** hardcode a brittle list of covered topics as the
trigger condition — the rule applies to *any* algorithm question, letting
the tool's own `NO MATCH` response decide scope, rather than asking the
model to correctly pre-judge in advance whether a topic is covered (an
earlier version of the instruction that named topics explicitly let
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

**Practical takeaway**: for the 19 topics this corpus actually covers,
grounding is reliable. For anything adjacent but not in the corpus, there's
no hard guarantee the model checks first rather than answering from memory.
