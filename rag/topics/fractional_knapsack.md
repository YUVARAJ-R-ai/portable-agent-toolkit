# Fractional Knapsack (Greedy)

Given items with a weight and a value, and a knapsack of limited capacity,
maximize total value when items **can be split** (take any fraction of an
item). Category: [Greedy algorithm](greedy_overview.md).

> **This is NOT the 0/1 knapsack problem.** 0/1 knapsack (items must be
> taken whole or not at all) is a *different* problem that needs dynamic
> programming — greedy does **not** give the optimal answer for 0/1
> knapsack. If a question is actually about 0/1 knapsack, do NOT use this
> greedy solution: look up `knapsack_01_dp` (DP table) or `knapsack_01_lcbb`
> (branch and bound) instead.

## Idea

1. Compute each item's value/weight ratio.
2. Sort items by that ratio, descending.
3. Walk the sorted list, taking as much of each item as fits in the
   remaining capacity — the whole item if it fits, otherwise exactly enough
   of it to fill the remaining capacity (fractional), then stop.

**Why this is correct**: because items are divisible, taking the highest
value/weight ratio first is always at least as good as any other order — an
exchange argument shows that swapping any fraction of a lower-ratio item
already taken for an equal weight of a higher-ratio item never decreases
total value. This exchange argument is exactly what breaks down for 0/1
knapsack, where you can't take an arbitrary weight of an item.

## Complexity

`O(n log n)`, dominated by the sort.

## Verified C++ implementation

Compiled with `g++ -std=c++17 -Wall -O2` and run against the classic
textbook example (weights `{10,20,30}`, values `{60,100,120}`, capacity
`50`) — output matches the known correct answer of `240` exactly.

```cpp
#include <bits/stdc++.h>
using namespace std;

struct Item {
    int weight, value;
    double ratio() const { return (double)value / weight; }
};

double fractionalKnapsack(vector<Item> items, int capacity) {
    // Greedy choice: always take as much as possible of the item with the
    // highest value/weight ratio first.
    sort(items.begin(), items.end(),
         [](const Item& a, const Item& b) { return a.ratio() > b.ratio(); });

    double totalValue = 0.0;
    int remaining = capacity;

    for (const auto& item : items) {
        if (remaining <= 0) break;
        if (item.weight <= remaining) {
            totalValue += item.value;
            remaining -= item.weight;
        } else {
            double fraction = (double)remaining / item.weight;
            totalValue += item.value * fraction;
            remaining = 0;
        }
    }
    return totalValue;
}

int main() {
    // (weight, value)
    vector<Item> items = {{10, 60}, {20, 100}, {30, 120}};
    int capacity = 50;

    double result = fractionalKnapsack(items, capacity);
    cout << "Capacity: " << capacity << "\n";
    cout << "Maximum value obtainable: " << result << "\n";
    return 0;
}
```

### Verified output

```
Capacity: 50
Maximum value obtainable: 240
```
(Ratios: item1 = 6.0, item2 = 5.0, item3 = 4.0. Greedy takes all of item1
(w10,v60) and item2 (w20,v100) — 30 capacity used, 30 value+100 value=160 so
far — then 20/30 of item3: 20 weight, value = 120*(20/30) = 80. Total =
60+100+80 = 240.)
