# 0/1 Knapsack with Least-Cost Branch and Bound (LCBB / Best-First Search)

0/1 knapsack solved by LCBB best-first branch and bound with a fractional-knapsack upper bound (FAT Module 6). Category: Branch And Bound.

---

Every program below was extracted from your lab reports / FAT guide, compiled with `g++ -std=c++17 -Wall -O2`, and run; outputs shown are the real program output.

## Lab questions & verified answers

| Lab question | Scenario & input data | Verified answer |
|---|---|---|
| FAT Module 6 example | W = 10; items (w,v): (2,40) (3,50) (5,100) (5,95) | **195** = items 3 + 4 (weight 10) |

## 0/1 Knapsack with Least-Cost Branch and Bound (LCBB)

### 0/1 Knapsack via LCBB (Best-First Search)
**Lab scenario:** Selecting High-Value Cargo with Fractional Upper Bound Pruning

Instead of Depth-First Search, Least-Cost Branch & Bound (LCBB) maintains a **Max-Priority Queue** of active search nodes.
- Each node represents a partial assignment of items `{level, profit, weight, bound}`.
- The upper bound is computed using the greedy **Fractional Knapsack** strategy (take whole items by value/weight ratio, then fractional part of next item).
- Always expand the node with the highest optimistic bound!

### Algorithm: LCBBKnapsack
```python
LCBBKnapsack(items, W, n):
    SORT items by value/weight ratio descending
    pq = MaxPriorityQueue()           # Ordered by upper bound descending
    root = Node(level = -1, profit = 0, weight = 0)
    root.bound = FractionalBound(root, W, items)
    pq.push(root)
    max_profit = 0

    WHILE NOT pq.empty():
        u = pq.pop()
        IF u.bound <= max_profit: CONTINUE   # Prune node

        # Branch 1: Include item (u.level + 1)
        v_inc = Node(level = u.level + 1)
        v_inc.weight = u.weight + items[v_inc.level].weight
        v_inc.profit = u.profit + items[v_inc.level].value
        IF v_inc.weight <= W:
            IF v_inc.profit > max_profit: max_profit = v_inc.profit
            v_inc.bound = FractionalBound(v_inc, W, items)
            IF v_inc.bound > max_profit: pq.push(v_inc)

        # Branch 2: Exclude item (u.level + 1)
        v_exc = Node(level = u.level + 1, weight = u.weight, profit = u.profit)
        v_exc.bound = FractionalBound(v_exc, W, items)
        IF v_exc.bound > max_profit: pq.push(v_exc)

    RETURN max_profit
```

### Step-by-Step LCBB Priority Queue Execution Trace
**Items Sorted by Ratio ($v/w$ descending):**
- Item 1: $w=2, v=40$ (ratio 20.0)
- Item 3: $w=5, v=100$ (ratio 20.0)
- Item 4: $w=5, v=95$ (ratio 19.0)
- Item 2: $w=3, v=50$ (ratio 16.67)

**Priority Queue Node Expansion Table:**

| **Node / Step** | **Weight** | **Profit** | **Upper Bound** | **Action & Justification** |
|---|---|---|---|---|
| N1 (Root) | 0 | 0 | 197.00 | Pop & Expand: Bound $40 + 100 + 95 · (3/5) = 197.00$ |
| N2 (+Item 1) | 2 | 40 | 197.00 | Best Profit = 40. Pushed with bound 197.00 |
| N3 (-Item 1) | 0 | 0 | 195.00 | Pushed with bound $100 + 95 = 195.00$ |
| N4 (+Item 3) | 7 | 140 | 197.00 | Best Profit = 140. Pop & Expand (highest bound 197.00) |
| N8 (+Item 3) | 5 | 100 | 195.00 | From N3. Best Profit = 140. Next highest bound 195.00 |
| N8 branch | 10 | 195 | 195.00 | **Include Item 4:** Weight = 10, **New Best Profit = 195!** |
| N7 (+Item 4) | 7 | 140 | 190.00 | **PRUNED:** Bound 190.00 $<= 195$ best profit |
| N5 (-Item 3) | 2 | 40 | 185.00 | **PRUNED:** Bound 185.00 $<= 195$ best profit |
| N9 (-Item 3) | 0 | 0 | 145.00 | **PRUNED:** Bound 145.00 $<= 195$ best profit |

**Key Insight:** Notice how the max-priority queue ordered by optimistic fractional bound greedily jumps directly to the high-yield branch and instantly prunes all three remaining nodes (N7, N5, N9) as soon as the optimal solution 195 is reached!

### Concise C++ Implementation (Best-First Search Knapsack)

```cpp
#include <iostream>
#include <vector>
#include <queue>
#include <algorithm>
using namespace std;

struct Item { int weight, value; double ratio; };

struct Node {
    int level, profit, weight;
    double bound;
};

struct CompareNode {
    bool operator()(const Node& a, const Node& b) { return a.bound < b.bound; } // Max-heap by bound
};

double getBound(Node u, int n, int W, const vector<Item>& items) {
    if (u.weight >= W) return 0;
    double profit_bound = u.profit;
    int j = u.level + 1;
    int total_weight = u.weight;
    while (j < n && total_weight + items[j].weight <= W) {
        total_weight += items[j].weight;
        profit_bound += items[j].value;
        j++;
    }
    if (j < n) profit_bound += (W - total_weight) * items[j].ratio;
    return profit_bound;
}

int main() {
    int W = 10;
    vector<Item> items = {{2, 40, 20.0}, {3, 50, 16.67}, {5, 100, 20.0}, {5, 95, 19.0}};
    int n = items.size();
    sort(items.begin(), items.end(), [](Item a, Item b) { return a.ratio > b.ratio; });

    priority_queue<Node, vector<Node>, CompareNode> pq;
    Node u, v;
    u.level = -1; u.profit = 0; u.weight = 0;
    u.bound = getBound(u, n, W, items);
    pq.push(u);

    int maxProfit = 0;
    while (!pq.empty()) {
        u = pq.top(); pq.pop();
        if (u.bound <= maxProfit) continue;

        v.level = u.level + 1;
        // Branch 1: Include item v.level
        v.weight = u.weight + items[v.level].weight;
        v.profit = u.profit + items[v.level].value;
        if (v.weight <= W && v.profit > maxProfit) maxProfit = v.profit;
        v.bound = getBound(v, n, W, items);
        if (v.bound > maxProfit) pq.push(v);

        // Branch 2: Exclude item v.level
        v.weight = u.weight;
        v.profit = u.profit;
        v.bound = getBound(v, n, W, items);
        if (v.bound > maxProfit) pq.push(v);
    }
    cout << "LCBB 0/1 Knapsack Max Profit: " << maxProfit << "\n";
    return 0;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
LCBB 0/1 Knapsack Max Profit: 195
```

### Cheese Code: 1D Array 0/1 Knapsack DP (8 Lines)
**Why it works in the exam:** If LCBB priority queue comparator is hard to remember in the exam, standard 1D DP knapsack produces the exact identical optimal profit of 195 in O(N*W) time!

```cpp
#include <bits/stdc++.h>
using namespace std;
int main() {
    int W = 10, wt[] = {2, 3, 5, 5}, val[] = {40, 50, 100, 95};
    vector<int> dp(W + 1, 0);
    for (int i = 0; i < 4; ++i)
        for (int w = W; w >= wt[i]; --w)
            dp[w] = max(dp[w], dp[w - wt[i]] + val[i]);
    cout << "Optimal Max Profit: " << dp[W] << endl; // Outputs: 195
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
Optimal Max Profit: 195
```

### Silly Mistakes & Traps: 0/1 Knapsack LCBB
1. **Inverted Priority Queue Comparator:** In C++ `std::priority_queue`, `bool operator<(a, b) { return a.bound < b.bound; }` creates a MAX-heap. Returning `a.bound > b.bound` creates a min-heap that pops worst bounds first and destroys the algorithm!
2. **Fractional Part Calculation:** If remaining capacity is smaller than the next item's weight, only add $(W - total_weight) × ratio$, NOT the entire item value.
3. **Pruning Check Placement:** Check `if (u.bound <= maxProfit) continue;` BOTH before popping children AND before pushing to queue to avoid allocating dead search nodes.

**Complexity:** best O(n log n) · average O(2^n) pruned · worst O(2^n) · auxiliary space O(2^n) priority queue nodes  
**Recurrence:** Branching factor 2, pruned via fractional knapsack dual bound
