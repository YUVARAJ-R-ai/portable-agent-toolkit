# PAT-2 Master Complexity Matrix & Twist Detection Guide

Comprehensive reference guide for DAA Lab PAT-2 (Design & Analysis of Algorithms): complexity comparison across all algorithms, 30-second keyword-to-twist translation table, and pre-flight zero-mark avoidance checklist. Category: Exam Reference.

---

## 1. Master Algorithm Complexity Comparison

| Algorithm | Best Time | Average Time | Worst Time | Space | Core Data Structure |
|---|---|---|---|---|---|
| **N-Queens (Backtracking)** | $O(N)$ | $O(N!)$ | $O(N!)$ | $O(N)$ | 1D Array + 3 Boolean vectors (`cols`, `diag1`, `diag2`) |
| **Job Selection (B&B)** | $O(n \log n)$ | $O(k^n), k<2$ | $O(2^n)$ | $O(n + D)$ | Sorted Vector + Boolean Slot Array + Recursion Stack |
| **Job Assignment (LCBB)** | $O(N^2)$ | $O(N!)$ pruned | $O(N!)$ | $O(N \cdot 2^N)$ | `priority_queue` (Min-Heap) + Assignment Bitmask |
| **Naïve String Matching** | $O(n)$ | $O(n + m)$ | $O((n-m+1)m)$ | $O(1)$ | None (Sliding pointer window) |
| **KMP Algorithm** | $O(n + m)$ | $O(n + m)$ | $O(n + m)$ | $O(m)$ | 1D Prefix Function ($\pi$ / LPS Array) |
| **Rabin-Karp Algorithm** | $O(n + m)$ | $O(n + m)$ | $O(n \cdot m)$ | $O(1)$ | Polynomial Rolling Hash with Modulo Math |
| **Suffix Structure / Array** | $O(n \log n)$ | $O(n \log n)$ | $O(n \log n)$ | $O(n)$ | Suffix Array + Kasai's $O(n)$ LCP Array |
| **Kruskal's Algorithm (MST)** | $O(E \log V)$ | $O(E \log V)$ | $O(E \log V)$ | $O(V + E)$ | Disjoint Set Union (DSU) with Path Compression & Rank |
| **Prim's Algorithm (MST)** | $O(E \log V)$ | $O(E \log V)$ | $O(E \log V)$ | $O(V + E)$ | `std::priority_queue` (Min-Heap) + Adjacency List |
| **Floyd-Warshall (APSP)** | $O(V^3)$ | $O(V^3)$ | $O(V^3)$ | $O(V^2)$ | 2D DP Distance Matrix + `nextNode` Path Matrix |
| **Johnson's Algorithm (APSP)** | $O(V^2 \log V + VE)$ | $O(V^2 \log V + VE)$ | $O(V^2 \log V + VE)$ | $O(V + E)$ | Bellman-Ford Potentials + Adjacency List + Min-Heap |

---

## 2. Exam Keyword Translation: "Spot the Twist in 30 Seconds"

| Exam Problem Keywords / Scenario | Base Algorithm | Required Implementation Twist |
|---|---|---|
| **Non-interfering satellites / drones / engines**, "radar line of sight" | **N-Queens** | Map to grid rows and columns; check $O(1)$ diagonal formulas. |
| **Damaged tiles / broken solar panels / restricted zones** | **N-Queens** | Skip column if `grid[r][c] == 'X'` before testing safety. |
| **Hybrid moves: radar + L-shaped knight hop** | **N-Queens** | Add knight offset checks `(r-1, c±2)` and `(r-2, c±1)`. |
| **Grid cell radiation values / maximize harvested solar power** | **N-Queens** | Add Branch-and-Bound upper bound pruning to Backtracking. |
| **Pre-installed cryptographic engines / fixed hardware positions** | **N-Queens** | Pre-mark vectors; skip column loop if `fixedPlacement[row] != -1`. |
| **No three queens collinear / linear independence at any slope** | **N-Queens** | Check cross-product: `(c2 - c1)*(r3 - r1) == (c3 - c1)*(r2 - r1)`. |
| **Emergency medical drop-offs / satellite missions / unit deadlines** | **Job Selection (B&B)** | Sort by profit; use greedy slot checking from $d_i$ down to 1. |
| **Variable processing times / multi-unit duration** | **Job Selection (B&B)** | Sort by $p_i/t_i$; use Fractional Knapsack relaxation for bound. |
| **Uncompleted tasks incur financial penalty / delay fine** | **Job Selection (B&B)** | Set effective profit $P'_i = p_i + c_i$; subtract total penalty at end. |
| **Release times $[r_i, d_i]$** | **Job Selection (B&B)** | Restrict slot search to $[r_i, d_i]$. |
| **N workers assigned to N jobs with cost matrix** | **Job Assignment** | Implement LCBB with `priority_queue` and row-reduction lower bounds. |
| **Pattern contains '?' or wildcard characters** | **Naïve Matching** | Allow `pattern[j] == '?'` to match any character. |
| **No two adjacent matched characters identical** (PAT-1 style) | **Naïve / KMP** | Add post-match filter: verify `text[k] != text[k+1]` for all $k \in [s, s+m-2]$. |
| **Smallest repeating telemetry packet / periodic signal** | **KMP** | Compute LPS; check if $L \% (L - \text{lps}[L-1]) == 0$. |
| **Check if string B is a circular / cyclic shift of A** | **KMP** | Run KMP search for $B$ inside the doubled text $A + A$. |
| **Detect multiple signatures of same length simultaneously** | **Rabin-Karp** | Hash all patterns into an `unordered_set`; scan text with rolling hash. |
| **Deepest repeated signature / longest common substring between 2 files** | **Suffix Tree / Array** | Build Suffix Array + Kasai's LCP array; find maximum LCP value. |
| **Mandatory fiber links + forbidden hazardous conduits** | **Kruskal's MST** | Pre-unite mandatory edges in DSU; discard forbidden edges; complete MST. |
| **Redundant backup network with second lowest installation cost** | **2nd MST** | Remove each MST edge one by one and find cheapest alternative spanning tree. |
| **Maximize bottleneck bandwidth / widest path between all nodes** | **Floyd-Warshall** | Maximin DP: `cap[i][j] = max(cap[i][j], min(cap[i][k], cap[k][j]))`. |
| **Negative communication delays / detect infinite gain loops** | **Floyd-Warshall** | Check if `dist[k][k] < 0`; mark affected node pairs as `-INF`. |

---

## 3. Pre-Flight Exam Checklist: Zero-Mark Avoidance

1. **Integer Overflow Protection**:
   For Floyd-Warshall and Johnson's, never set $\text{INF} = \text{INT\_MAX}$ because $\text{dist}[i][k] + \text{dist}[k][j]$ wraps around to negative numbers! Always use `const long long INF = 1e15;` and `long long` for distance matrices.
2. **Floyd-Warshall Outer Loop**:
   The $k$ loop (intermediate vertex) **MUST** be the outermost loop. If $i$ or $j$ is outermost, the DP state does not compute intermediate paths correctly and will fail tests.
3. **Rabin-Karp Modulo Arithmetic**:
   In C++, `%` can return negative values. Always use:
   `hash = (hash % MOD + MOD) % MOD;`
4. **KMP LPS Pointer Reset**:
   When pattern is matched, remember to set `j = lps[j - 1]` (or `j = 0` for non-overlapping matches). Never leave $j$ unreset, or you will enter an infinite loop or access out-of-bounds memory.
5. **Edge List Representation for Kruskal**:
   Kruskal operates on an edge list (`vector<Edge>`), *not* an adjacency matrix. Prim operates on an adjacency list (`vector<vector<pair<int, int>>>`). Using the wrong data representation wastes 15 minutes of lab time.
6. **1-Based vs 0-Based Indexing**:
   Watch deadline indexing! In Lab 6, time slots run from $t = 1$ to $t = \text{deadline}$. Ensure your slot vector size is $\text{maxDeadline} + 1$.
