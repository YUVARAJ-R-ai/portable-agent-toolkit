# Greedy Algorithms — General Idea

A greedy algorithm builds up a solution step by step, at each step making the
choice that looks best *right now* (locally optimal), and never
reconsidering that choice later. It never looks ahead or backtracks.

## When greedy actually works (and when it doesn't)

Greedy only produces a *globally* optimal solution when the problem has
these two properties — always check for them before assuming greedy applies:

1. **Greedy-choice property**: a globally optimal solution can be reached by
   making a sequence of locally optimal (greedy) choices. Making the
   current best choice never rules out reaching the overall best answer.
2. **Optimal substructure**: an optimal solution to the problem contains
   optimal solutions to its subproblems (after the greedy choice is fixed,
   what remains is a smaller instance of the same problem).

If a problem lacks the greedy-choice property, a greedy algorithm will run
fast but can give a *wrong* (suboptimal) answer — it will not backtrack to
fix it. This is the single most common way people misuse greedy: applying it
to a problem (like 0/1 knapsack) where it simply doesn't guarantee
optimality, and getting a plausible-looking but wrong result.

## How to prove a greedy algorithm is correct

The standard technique is an **exchange argument**: take any optimal
solution that differs from the greedy one, show you can "exchange" one of
its choices for the greedy algorithm's choice without making the solution
worse. Repeating this shows the greedy solution is at least as good as any
optimal solution, hence optimal itself. This is how correctness is normally
argued for Huffman coding and fractional knapsack (see their own entries).

## Recognizing a greedy problem

Common signals a problem might be solvable greedily:
- An "optimal substructure" naturally falls out after one choice (e.g. after
  picking the two least-frequent symbols in Huffman coding, the rest is the
  same problem on a smaller alphabet).
- Sorting by some ratio/criterion, then processing in that order, seems to
  produce good answers on small examples (fractional knapsack: sort by
  value/weight ratio).
- The problem asks for "minimum/maximum X given a sequence of choices" and a
  natural local criterion exists (earliest deadline first, shortest job
  first, highest ratio first, etc.).

If none of these clearly apply, or a small counterexample can be found where
the "obviously best" local choice leads to a worse overall answer, greedy is
probably the wrong tool — consider dynamic programming instead (which
explores/compares multiple choices via subproblem reuse rather than
committing to one immediately).

## Two worked examples in this corpus

- **[Huffman Coding](huffman_coding.md)** — repeatedly merge the two
  least-frequent nodes; the greedy-choice property holds because the two
  least-frequent symbols can always be made siblings at the deepest level of
  an optimal tree.
- **[Fractional Knapsack](fractional_knapsack.md)** — sort by value/weight
  ratio, take as much of the best ratio as fits; provably optimal because
  items are divisible (this breaks down for **0/1 knapsack**, which is NOT
  in this corpus and needs dynamic programming instead — do not answer a 0/1
  knapsack question with the fractional greedy method).
