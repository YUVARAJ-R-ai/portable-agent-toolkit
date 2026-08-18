# Divide and Conquer — General Idea

Divide and conquer solves a problem by breaking it into smaller subproblems
of the *same type*, solving each subproblem recursively, then combining
their solutions into the answer for the original problem. Three steps,
every time:

1. **Divide** the problem into smaller subproblems (usually by splitting the
   input, e.g. an array, roughly in half).
2. **Conquer** by solving each subproblem recursively. The recursion bottoms
   out at a **base case** small enough to solve directly (e.g. a single
   element, or an empty range).
3. **Combine** the subproblem solutions into a solution for the original
   problem. This combine step is often where the real algorithmic work
   happens (e.g. the `merge` step in mergesort, or the "crossing subarray"
   check in the divide-and-conquer maximum subarray algorithm).

## Analyzing the running time: recurrences

A divide-and-conquer algorithm's running time is naturally expressed as a
recurrence. For an algorithm that splits a size-`n` problem into `a`
subproblems of size `n/b`, doing `f(n)` work to divide+combine:

```
T(n) = a * T(n/b) + f(n)
```

The **Master Theorem** gives the closed-form answer for most cases you'll
meet in a first algorithms course, comparing `f(n)` against `n^(log_b a)`:

- If `f(n)` grows slower than `n^(log_b a)`: `T(n) = Θ(n^(log_b a))`.
- If `f(n)` grows at the same rate: `T(n) = Θ(n^(log_b a) * log n)`.
- If `f(n)` grows faster (and a regularity condition holds): `T(n) = Θ(f(n))`.

Example: mergesort splits into `a=2` subproblems of size `n/2` (`b=2`), and
the combine (merge) step is `f(n) = Θ(n)`. `n^(log_2 2) = n^1 = n`, which
matches `f(n)`'s growth rate, so `T(n) = Θ(n log n)` — the middle case.

## Three worked examples in this corpus

- **[Maximum Subarray (Divide & Conquer)](maximum_subarray_dc.md)** — split
  the array in half; the answer is either entirely in the left half, entirely
  in the right half, or crosses the midpoint (the combine step finds the
  best crossing subarray in linear time). `T(n) = 2T(n/2) + Θ(n)` →
  `Θ(n log n)`.
- **[QuickSort](quicksort.md)** — the *divide* step (partitioning around a
  pivot) does the real work; the two recursive calls are the conquer step,
  and there's nothing left to do for combine (the array is already sorted
  once both halves are). Average case `Θ(n log n)`, worst case `Θ(n²)` if
  the pivot is consistently a bad choice (e.g. already-sorted input with a
  last-element pivot).
- **[MergeSort](mergesort.md)** — split the array in half (divide), sort each
  half recursively (conquer), merge the two sorted halves in linear time
  (combine — this is where the real work is, unlike quicksort). Always
  `Θ(n log n)`, at the cost of `Θ(n)` extra space for the merge buffers.
