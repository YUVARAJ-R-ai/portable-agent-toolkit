# Tool-Call RAG for DAA Algorithms

A small, curated reference corpus (Design & Analysis of Algorithms) that
OpenCode/Goose fetch **on demand via a shell tool call**, not by having it
permanently stuffed into the system prompt. Built specifically to avoid a
common failure mode with local-model RAG setups: confidently returning the
wrong reference, which causes the model to hallucinate with unwarranted
confidence. This one is deliberately conservative — when in doubt, say "not
covered," never guess.

## Why tool-call retrieval instead of just stuffing context

All 38 topics together run to tens of thousands of tokens. Loading all of it on
every turn burns a large chunk of the (already tight, tool-schema-heavy)
context budget on irrelevant material for most questions. Instead, the
agent calls `rag-search.sh "<query>"` through its existing `shell` tool only
when the question is actually about one of these topics, and gets back just
that one topic's content (roughly 1-3K tokens).

## Corpus (38 topics, all C++, every complete program compiled and run)

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
| Bellman-Ford SSSP | Graph algorithms | Handles negative edge weights, $V-1$ relaxation passes, negative cycle detection, bounded hops |
| Ford-Fulkerson Method | Network flow | Residual graph $G_f$, augmenting path DFS, bottleneck capacity, Max-Flow Min-Cut theorem, min-cut extraction |
| Edmonds-Karp Algorithm | Network flow | BFS shortest augmenting paths in $O(V E^2)$, edge-disjoint paths (Menger's theorem), multi-source/sink |
| Line Segments & Sweeping Lines | Computational geometry | Cross-product turn test, CLRS intersection test, exact coordinates, Bentley-Ottmann, Shamos-Hoey, Orthogonal sweep line via BIT |
| Convex Hull (Graham & Jarvis) | Computational geometry | Andrew's Monotone Chain (Graham's Scan) $O(n \log n)$, Jarvis' March $O(nh)$, Chan's algorithm $O(n \log h)$, Rotating Calipers diameter, collinear points |
| PAT-2 Twist Detection & Complexity Matrix | Exam reference | Master complexity table, 30-second keyword translation table, and pre-flight zero-mark avoidance checklist |
| Activity Selection | Greedy | Earliest-finish-time greedy, Lab 1 program |
| Karatsuba Multiplication | Divide and conquer | 3 recursive products, $O(n^{1.585})$ |
| K-Way Merge | Divide and conquer | Min-heap $O(N \log K)$ vs K-pointer scan |
| Matrix Chain Multiplication | Dynamic programming | $O(n^3)$ table + parenthesization |
| 0/1 Knapsack (DP) | Dynamic programming | $O(nW)$ table with item reconstruction |
| Longest Common Subsequence | Dynamic programming | $O(mn)$ table + backtracking (token & char sequences) |
| 0/1 Knapsack (LCBB) | Branch and bound | Best-first search with fractional upper bound |
| Closest Pair of Points | Computational geometry | Divide & conquer strip check, AGV hazard variant |
| NP Certificate Verification | NP-completeness | Polynomial-time verifiers (job selection, spanning network + budget) |
| Greedy Set Cover | Approximation | Cost per newly covered element, $H_n$ factor |
| Vertex Cover 2-Approximation | Approximation | Maximal matching, both endpoints |
| Randomized Sampling | Randomized | Sampling without replacement, fixed seed, Monte Carlo vs Las Vegas |
| FAT Complexity Master Table | Exam reference | Best/avg/worst time + space for every lab algorithm |
| FAT Exam Traps & Cheese Codes | Exam reference | C++ pitfalls + emergency shortcut programs |

Every complete C++ program in the corpus was compiled with `g++ -std=c++17 -Wall
-O2` and run against known textbook and lab test cases before being written into the
corpus. The FAT-guide (Labs 1-11) material was merged into the matching topics, each with
a table of the user's lab questions and their verified answers. Shown outputs are real
program output, and the places where the guide's stated output was wrong are corrected inline.

**Deliberate categorization choices, made for correctness, not just
organization**: maximum subarray implements the actual divide-and-conquer
algorithm (recursive split + crossing-subarray combine), not Kadane's —
those are genuinely different algorithms, and Kadane's is included in the
same file as a clearly-labeled second method for comparison rather than
being conflated with the D&C one. Fractional knapsack's entry explicitly
states it is **not** the 0/1 knapsack problem (different problem, needs
dynamic programming, greedy doesn't give the optimal answer) and points to the
separate `knapsack_01_dp` / `knapsack_01_lcbb` topics. A bare `knapsack` query is
deliberately `AMBIGUOUS` so the agent has to pick the right one.

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

**Practical takeaway**: for the topics this corpus actually covers,
grounding is reliable. For anything adjacent but not in the corpus, there's
no hard guarantee the model checks first rather than answering from memory.
