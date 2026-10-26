# NP-Completeness: Polynomial-Time Certificate Verification

Verifying NP certificates in polynomial time: job-selection certificate and spanning network + budget check (Lab 11, FAT Module 10). Category: Np Completeness.

---

Every program below was extracted from your lab reports / FAT guide, compiled with `g++ -std=c++17 -Wall -O2`, and run; outputs shown are the real program output.

## Lab questions & verified answers

| Lab question | Scenario & input data | Verified answer |
|---|---|---|
| Lab 11 Q1 | Times [2,3,5,4,6], values [4,6,10,7,12], T=10, K=18, certificate [1,1,1,0,0] | time 10 ≤ 10, value 20 ≥ 18 → **ACCEPTED** |
| Lab 11 Q2 | V=5, edges (1-2,3) (2-3,2) (3-4,4) (4-5,2) (1-5,8) (2-4,5), budget 12, selected IDs 1 2 3 4 | cost 11, connected, within budget → **ACCEPTED** |

## Polynomial-Time Certificate Verification (NPC Problems)

### Polynomial-Time Verification of NP Certificates
**Lab scenario:** Industrial Job Selection & Communication Network Feasibility Check

A decision problem belongs to class **NP** if a candidate solution ("certificate") can be verified by a deterministic algorithm in polynomial time ($O(n^k)$).

**Certificate Verification Concept:** We do **not** have to find the optimal solution from scratch (which might take exponential time $O(2^n)$). We only need to check in linear/polynomial time whether the proposed certificate satisfies all given constraints.

### Algorithm: VerifyJobSelection
```python
VerifyJobSelection(processingTime, productionValue, selection, T, K, N):
    totalTime = 0; totalValue = 0

    FOR i = 0 TO N - 1:
        IF selection[i] == 1:
            totalTime = totalTime + processingTime[i]
            totalValue = totalValue + productionValue[i]

    timeOK = (totalTime <= T)
    valueOK = (totalValue >= K)

    IF timeOK AND valueOK: RETURN "ACCEPTED"
    ELSE: RETURN "REJECTED"
```

### Problem 1: Verification of Industrial Job Selection

```cpp
#include <iostream>
#include <vector>
using namespace std;

int main() {
    // Lab Example: N=5, Deadline T=10, Target Value K=18
    const int N = 5, T = 10, K = 18;
    vector<int> processingTime = {2, 3, 5, 4, 6};
    vector<int> productionValue = {4, 6, 10, 7, 12};
    vector<int> selection = {1, 1, 1, 0, 0}; // Certificate: Choose jobs 1, 2, 3

    int totalTime = 0, totalValue = 0;
    for (int i = 0; i < N; ++i) {
        if (selection[i] == 1) {
            totalTime += processingTime[i];
            totalValue += productionValue[i];
        }
    }

    bool timeOK = (totalTime <= T);
    bool valueOK = (totalValue >= K);

    cout << "Total Processing Time: " << totalTime << " (Limit <= " << T << ")\n";
    cout << "Total Production Value: " << totalValue << " (Requirement >= " << K << ")\n";
    cout << "Time Constraint: " << (timeOK ? "Satisfied" : "Violated") << "\n";
    cout << "Value Constraint: " << (valueOK ? "Satisfied" : "Violated") << "\n";
    cout << "Certificate Verification: " << (timeOK && valueOK ? "ACCEPTED" : "REJECTED") << "\n";
    return 0;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
Total Processing Time: 10 (Limit <= 10)
Total Production Value: 20 (Requirement >= 18)
Time Constraint: Satisfied
Value Constraint: Satisfied
Certificate Verification: ACCEPTED
```

### Problem 2: Verification of Communication Network (Spanning & Budget)

```cpp
#include <iostream>
#include <vector>
#include <queue>
using namespace std;

struct Edge { int u, v, cost; };

int main() {
    // Lab Example: V=5, Budget B=12
    const int V = 5, B = 12;
    vector<Edge> edges = {
        {0, 1, 3}, {1, 2, 2}, {2, 3, 4},
        {3, 4, 2}, {0, 4, 8}, {1, 3, 5}
    };
    vector<int> chosenEdgeIDs = {1, 2, 3, 4}; // 1-based edge IDs

    vector<vector<int>> adj(V);
    int totalCost = 0;
    for (int id : chosenEdgeIDs) {
        Edge e = edges[id - 1];
        adj[e.u].push_back(e.v);
        adj[e.v].push_back(e.u);
        totalCost += e.cost;
    }

    // Verify Connectivity using BFS
    vector<bool> visited(V, false);
    queue<int> q;
    q.push(0);
    visited[0] = true;
    int visitedCount = 0;

    while (!q.empty()) {
        int u = q.front(); q.pop();
        visitedCount++;
        for (int v : adj[u]) {
            if (!visited[v]) {
                visited[v] = true;
                q.push(v);
            }
        }
    }

    bool isConnected = (visitedCount == V);
    bool withinBudget = (totalCost <= B);

    cout << "Total Network Cost: " << totalCost << " / Budget: " << B << "\n";
    cout << "Connectivity: " << (isConnected ? "Connected (All V stations reached)" : "Disconnected") << "\n";
    cout << "Budget Status: " << (withinBudget ? "Within Budget" : "Exceeded") << "\n";
    cout << "Certificate Status: " << (isConnected && withinBudget ? "ACCEPTED" : "REJECTED") << "\n";
    return 0;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
Total Network Cost: 11 / Budget: 12
Connectivity: Connected (All V stations reached)
Budget Status: Within Budget
Certificate Status: ACCEPTED
```

**Complexity:** best O(V + E) · average O(V + E) · worst O(V + E) · auxiliary space O(V + E)  
**Recurrence:** Linear polynomial-time verification
