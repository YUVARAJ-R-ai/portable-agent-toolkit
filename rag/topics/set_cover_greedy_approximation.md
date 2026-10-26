# Greedy Set Cover Approximation (Sensor Placement)

Greedy weighted set cover approximation by cost per newly covered element, H_n factor (Lab 11, FAT Module 10). Category: Approximation.

---

Every program below was extracted from your lab reports / FAT guide, compiled with `g++ -std=c++17 -Wall -O2`, and run; outputs shown are the real program output.

## Lab questions & verified answers

| Lab question | Scenario & input data | Verified answer |
|---|---|---|
| Lab 11 Q3 | 6 machines. Sensor 1 cost 4 {1,2,3}; sensor 2 cost 3 {3,4}; sensor 3 cost 5 {4,5,6}; sensor 4 cost 2 {1,5} | Greedy picks 4, 2, 1, 3 → 6/6 covered, cost **14** |

**Guide correction:** the FAT guide's sample output claims the greedy picks sensors 1 and 3 (cost 9). It does not. The first ratios are 4/3, 3/2, 5/3, 2/2, so sensor 4 (ratio 1.0) goes first, then 2, 1, 3, for a total cost of **14** (what both programs print). Cost 9 is the *optimal* cover. The gap shows greedy is only an approximation (14 ≤ H₆·9 ≈ 22.05).

## Greedy Approximation Algorithms (Set Cover & Vertex Cover)

### Greedy Set Cover Approximation
**Lab scenario:** Industrial Plant Sensor Placement (Monitoring all N machines with M candidate sensors)

Given a universe $U$ of $n$ elements and a collection of subsets $S_1, S_2, …, S_m$ with costs $c_i$, find a minimum-cost subcollection that covers all elements.
**Greedy Rule:** Repeatedly select the subset that minimizes the cost-effectiveness ratio:
$ Ratio = Cost of candidate sensor / Number of newly covered machines $
Approximation Factor: $H_n = sum_(i=1)^n 1/i <= ln n + 1$.

### Algorithm: GreedySetCover
```python
GreedySetCover(N, M, sensors):
    covered = [FALSE for _ in range(N)]
    used = [FALSE for _ in range(M)]
    totalCost = 0; coveredCount = 0

    WHILE coveredCount < N:
        bestSensor = -1; bestRatio = INF
        FOR i = 0 TO M - 1:
            IF NOT used[i]:
                newCovered = COUNT(m in sensors[i].machines if not covered[m])
                IF newCovered > 0:
                    ratio = sensors[i].cost / newCovered
                    IF ratio < bestRatio:
                        bestRatio = ratio; bestSensor = i

        used[bestSensor] = TRUE
        totalCost = totalCost + sensors[bestSensor].cost
        FOR m in sensors[bestSensor].machines:
            IF NOT covered[m]: covered[m] = TRUE; coveredCount++

    RETURN totalCost
```

### Concise C++ Implementation (Greedy Sensor Placement)

```cpp
#include <iostream>
#include <vector>
#include <iomanip>
using namespace std;

struct Sensor {
    int id, cost;
    vector<int> machines;
};

int main() {
    int N = 6, M = 4;
    vector<Sensor> sensors = {
        {1, 4, {1, 2, 3}},
        {2, 3, {3, 4}},
        {3, 5, {4, 5, 6}},
        {4, 2, {1, 5}}
    };

    vector<bool> covered(N + 1, false);
    vector<bool> used(M, false);
    int totalCost = 0, coveredCount = 0;

    cout << "--- Greedy Sensor Placement Steps ---\n";
    while (coveredCount < N) {
        int bestSensor = -1, bestNewCovered = 0;
        double bestRatio = 1e9;

        for (int i = 0; i < M; ++i) {
            if (used[i]) continue;
            int newCovered = 0;
            for (int m : sensors[i].machines)
                if (!covered[m]) newCovered++;

            if (newCovered > 0) {
                double ratio = (double)sensors[i].cost / newCovered;
                if (ratio < bestRatio) {
                    bestRatio = ratio;
                    bestSensor = i;
                    bestNewCovered = newCovered;
                }
            }
        }

        if (bestSensor == -1) { cout << "Cannot cover all machines!\n"; break; }

        used[bestSensor] = true;
        totalCost += sensors[bestSensor].cost;
        cout << "Selected Sensor " << sensors[bestSensor].id
             << " (Cost: " << sensors[bestSensor].cost << ", Covers " << bestNewCovered << " new machines)\n";

        for (int m : sensors[bestSensor].machines) {
            if (!covered[m]) { covered[m] = true; coveredCount++; }
        }
    }

    cout << "Machines Covered: " << coveredCount << "/" << N << "\n";
    cout << "Total Approximate Cost: " << totalCost << "\n";
    return 0;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
--- Greedy Sensor Placement Steps ---
Selected Sensor 4 (Cost: 2, Covers 2 new machines)
Selected Sensor 2 (Cost: 3, Covers 2 new machines)
Selected Sensor 1 (Cost: 4, Covers 1 new machines)
Selected Sensor 3 (Cost: 5, Covers 1 new machines)
Machines Covered: 6/6
Total Approximate Cost: 14
```
