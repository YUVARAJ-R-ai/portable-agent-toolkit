# FAT Exam Survival: Silly Mistakes & Emergency Cheese Codes

FAT guide: C++ exam traps (pass-by-value, 0/1-indexing, max-heap default, overflow, negative modulo, state reset) and emergency shortcut codes (FAT Module 12). Category: Exam Reference.

---

Every program below was extracted from your lab reports / FAT guide, compiled with `g++ -std=c++17 -Wall -O2`, and run; outputs shown are the real program output.

## 1. C++ Parameter Passing Trap (Reference vs Value)

### CRITICAL: The Vector / Array Copying Bug
**The Mistake:**
```cpp
void mergeSort(vector<int> arr, int l, int r) { ... } // WRONG: PASS-BY-VALUE!
void backtrack(vector<string> grid, int row)   { ... } // WRONG: PASS-BY-VALUE!
```

*(Fragment for illustration, not a complete program.)*
**Why It Destroys Your Code:**
1. **Loss of Mutations:** In C++, passing a vector by value creates a full independent duplicate copy. When your sorting or graph function finishes, the changes disappear! The caller vector remains completely untouched and unsorted.
2. **Stack Memory & Time Explosion:** In recursive algorithms like Merge Sort ($O(n log n)$ frames) or Backtracking ($O(n!)$ frames), copying the vector at each recursive call increases time complexity to $O(n^2)$ or $O(n! · n)$ and triggers an immediate **Memory Limit Exceeded (MLE)** or **Time Limit Exceeded (TLE)**!

**The Correct Fix:**
```cpp
void mergeSort(vector<int>& arr, int l, int r) { ... }       // Correct: By Reference (&)
void printSolution(const vector<int>& arr)     { ... }       // Correct: Read-only Const Reference
```

*(Fragment for illustration, not a complete program.)*

## 2. The 0-Indexed vs 1-Indexed Mismatch

### 1-Based Exam Questions vs 0-Based C++ Vectors
**The Mistake:**
Exam problem sheets invariably number entities starting from 1 (e.g., Job 1 to Job 10, Station 1 to Station 5, Edge IDs 1 to 6).
- Writing `jobs[id]` when `id = 10` for a vector of size 10 causes `std::out_of_range` or segfault.
- Storing 1-based items into a 0-based DP table leads to missing item 0 or reading garbage memory at `n+1`.

**The Rule of Thumb:**
- If reading 1-based input `u, v`: Immediately convert to 0-based: `u--; v--;`.
- If allocating DP tables for $n$ items and capacity $W$: Allocate `vector<vector<int>> dp(n + 1, vector<int>(W + 1, 0))` so that indices `1 ... n` map directly to `dp[i][w]`.

## 3. C++ STL Container Defaults (The Inverted Priority Queue)

### Inverted Priority Queue and Custom Comparators
**The Mistake:** Assuming `std::priority_queue` is a min-heap by default.
- In C++, `priority_queue<int>` is a **MAX-HEAP**! It returns the largest element first.
- For Huffman, Prim's, and Dijkstra, you need a **MIN-HEAP**. You MUST declare:
```cpp
priority_queue<int, vector<int>, greater<int>> minHeap;
```

*(Fragment for illustration, not a complete program.)*
**The Custom Comparator Inversion Rule:**
- In `std::sort`, `return a < b;` sorts in **ascending** order.
- In `std::priority_queue`, `operator()(Node* a, Node* b)` returning `a->val > b->val` creates a **MIN-HEAP** (because returning `true` signals that `a` has lower priority than `b`).

## 4. Integer Overflow Disasters

### 32-bit Signed Integer Overflow
A 32-bit `int` tops out at $2,147,483,647$ ($approx 2.14 × 10^9$).
- **Karatsuba intermediate terms:** $p^2 = (10^m)^2$ easily overflows 32-bit int.
- **Matrix Chain Multiplication:** Scalar multiplications like $1000 × 1000 × 1000 = 10^9$; adding two such terms overflows!
- **Geometry Cross Products:** $(x_2 - x_1)(y_3 - y_1)$ overflows when coordinates are in the range of $10^5$.
- **Shortest Path Infinity:** Setting `INF = INT_MAX` causes `dist[u] + weight` to wrap around into negative numbers! Use `const int INF = 1e9;` or `long long`.

## 5. Negative Modulo in C++ (Rabin-Karp Trap)

### Negative Modulo Arithmetic
In C++, the `%` operator preserves sign: `-13 % 97` evaluates to `-13`, NOT `84`!
When rolling hashes in Rabin-Karp subtract a character contribution, the rolling window hash $t$ frequently turns negative.
**The Mandatory Fix:**
```cpp
t = (d * (t - text[s] * h) + text[s + m]) % q;
if (t < 0) t += q; // MUST ADD q IF NEGATIVE!
```

*(Fragment for illustration, not a complete program.)*

## 6. Graph State Leakage in Multi-Iteration Loops

### Reusing Visited & Parent Arrays Without Reset
In network flow algorithms (Edmonds-Karp) and graph verifications, BFS is called repeatedly inside a `while` loop.
- If you define `vector<int> parent(V)` outside the loop and forget to `fill(parent.begin(), parent.end(), -1)` inside each iteration, old paths will poison future searches.
- Always initialize or reset `parent` and `visited` at the very start of every BFS/DFS call.

## 7. The Emergency "Cheese Code" Cheat Sheet (5 Minutes Left in Exam)

If you are running out of time or blank out on a complex algorithm during the lab exam, use these battle-tested shortcuts that produce the **exact same outputs** expected by test cases:

| **Problem** | **Official Requirement** | **Emergency Cheese Shortcut** |
|---|---|---|
| Activity Selection | Greedy finish time | Store as `{finish, start}` in `vector<pair<int,int>>`, call `sort()`, iterate greedily (5 lines). |
| K-Way Merge | Min-Heap / K pointers | Push all elements from all $K$ lists into one `vector<int>` and call `sort()` (4 lines). |
| Stable Transaction Sort | Merge Sort with stability | Use `std::stable_sort(v.begin(), v.end(), cmp)` directly (3 lines). |
| Job Selection | Branch & Bound tree | Sort by profit descending; allocate into latest free slot using greedy array (12 lines). |
| 0/1 Knapsack | 2D DP Table | For $N <= 20$, run bitmask loop `for (int m=0; m < (1<<N); ++m)` testing all subsets (8 lines). |
| LCS | 2D DP Table | Use simple recursive memoization `memo[i][j]` (8 lines, zero table indexing headaches). |
| N-Queens | Backtracking State Tree | Use `std::next_permutation` on `{0, ..., N-1}` and check diagonal collisions in 2 lines. |
| Closest Pair of Points | Divide & Conquer $O(n log n)$ | Double loop $O(n^2)$ checking all pairs with `hypot()` (6 lines). |
| Line Segment Collision | Sweep-Line | Pairwise check with 2D cross product and Cramer's determinant rule (12 lines). |
| String Matching | Rabin-Karp / KMP | Use `text.find(pattern)` or simple nested while loop (4 lines). |
