# 0/1 Knapsack (Dynamic Programming)

0/1 knapsack (items indivisible) via O(nW) DP table with item reconstruction (Lab 4, FAT Module 4). Category: Dynamic Programming.

---

Every program below was extracted from your lab reports / FAT guide, compiled with `g++ -std=c++17 -Wall -O2`, and run; outputs shown are the real program output.

## Lab questions & verified answers

| Lab question | Scenario & input data | Verified answer |
|---|---|---|
| Lab 4 Q1 | Backup drive 10 TB; database sizes {2,3,4,5} TB, risk-reduction values {30,40,50,70} | **140** = databases 1 + 2 + 4 |
| Lab 4 Q3 | Space probe 8 kg. Weights {3,4,2,5}, values {25,32,15,40} | **65** = items 1 + 4 |
| Lab 4 Q4 | VC budget $12M. Costs {3,5,6,4}, ROI {14,25,28,18} | **57** = startups 1 + 2 + 4 |

Not the same problem as **fractional knapsack** (greedy by value/weight). For 0/1 items greedy is NOT optimal; use this DP, or the LCBB topic (`knapsack_01_lcbb`) for branch and bound.

## 0/1 Knapsack Problem (Optimization & Item Reconstruction)

### 0/1 Knapsack Problem
**Lab scenario:** Cybersecurity Backup (10 TB Drive), Aerospace Probe (8 kg Payload), and VC Startup Budget ($12M)

Given $n$ items, each with weight $w_i$ and value $v_i$, select a subset of items to pack into a knapsack of maximum capacity $W$ such that total value is maximized and total weight does not exceed $W$. Items cannot be divided (0/1 constraint).

### Algorithm: Knapsack01
```python
Knapsack01(wt, val, W, n):
    FOR w = 0 TO W: dp[0][w] = 0

    FOR i = 1 TO n:
        FOR w = 0 TO W:
            IF wt[i - 1] <= w:
                dp[i][w] = max(dp[i - 1][w], val[i - 1] + dp[i - 1][w - wt[i - 1]])
            ELSE:
                dp[i][w] = dp[i - 1][w]

    # Backtrack to identify selected items
    selected = []; w = W
    FOR i = n DOWNTO 1:
        IF dp[i][w] != dp[i - 1][w]:
            selected.append(i)
            w = w - wt[i - 1]

    RETURN dp[n][W], selected
```

### Concise C++ Implementation (With Item Reconstruction)

```cpp
#include <iostream>
#include <vector>
#include <algorithm>
using namespace std;

int main() {
    // Lab Example: Aerospace Probe (Capacity = 8 kg)
    int n = 4, capacity = 8;
    vector<int> wt = {3, 4, 2, 5};
    vector<int> val = {25, 32, 15, 40};

    vector<vector<int>> dp(n + 1, vector<int>(capacity + 1, 0));

    for (int i = 1; i <= n; ++i) {
        for (int w = 0; w <= capacity; ++w) {
            if (wt[i - 1] <= w)
                dp[i][w] = max(dp[i - 1][w], val[i - 1] + dp[i - 1][w - wt[i - 1]]);
            else
                dp[i][w] = dp[i - 1][w];
        }
    }

    cout << "Maximum Utility = " << dp[n][capacity] << "\n";

    // Backtracking to identify selected items
    cout << "Selected Items:\n";
    int w = capacity;
    for (int i = n; i > 0; --i) {
        if (dp[i][w] != dp[i - 1][w]) {
            cout << "  Item " << i << " (Weight: " << wt[i - 1] << ", Value: " << val[i - 1] << ")\n";
            w -= wt[i - 1];
        }
    }
    return 0;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
Maximum Utility = 65
Selected Items:
  Item 4 (Weight: 5, Value: 40)
  Item 1 (Weight: 3, Value: 25)
```

### Cheese Code: Bitmask Power Set (8 Lines)
**Why it works in the exam:** For n <= 20 in lab exams, iterating through all 2^n binary subsets guarantees the optimal selection in 8 lines without any DP tables!

```cpp
#include <bits/stdc++.h>
using namespace std;
int main() {
    vector<int> wt = {3, 4, 2, 5}, val = {25, 32, 15, 40};
    int n = 4, cap = 8, bestV = 0, bestMask = 0;
    for (int mask = 0; mask < (1 << n); ++mask) {
        int w = 0, v = 0;
        for (int i = 0; i < n; ++i) if (mask & (1 << i)) { w += wt[i]; v += val[i]; }
        if (w <= cap && v > bestV) { bestV = v; bestMask = mask; }
    }
    cout << "Max Utility = " << bestV << "\nSelected Items: ";
    for (int i = 0; i < n; ++i) if (bestMask & (1 << i)) cout << (i + 1) << " ";
    cout << "\n";
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
Max Utility = 65
Selected Items: 1 4
```

### Silly Mistakes & Traps: 0/1 Knapsack
1. **0-Indexed vs 1-Indexed Mismatch:** When populating `dp[i][w]`, the current item's weight is `wt[i-1]`, NOT `wt[i]`. Using `wt[i]` causes out-of-bounds or skips the first item!
2. **Space-Optimized 1D DP Direction:** If writing 1D DP `dp[w]`, you MUST iterate capacity backwards: `for (int w = W; w >= wt[i]; w--)`. Iterating forward allows items to be selected multiple times, turning it into Unbounded Knapsack!
3. **Reconstruction Weight Decrement:** When backtracking, you must write `w -= wt[i-1]`. Forgetting this keeps checking against the full capacity.

**Complexity:** best O(n W) · average O(n W) · worst O(n W) · auxiliary space O(n W) [O(W) if 1D]  
**Recurrence:** Pseudo-polynomial time O(n W)
