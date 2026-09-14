# Job Assignment Problem via Least Cost Branch and Bound (LCBB)

Given $N$ workers and $N$ jobs, and an $N \times N$ cost matrix where $C[i][j]$ represents the cost of assigning worker $i$ to job $j$. Each worker must be assigned to exactly one unique job. The objective is to find a 1-to-1 assignment that minimizes total assignment cost using Least Cost Branch and Bound (LCBB). Category: Branch and Bound.

---

## 1. Algorithmic Invariants

1. **State-Space Representation**: A state node represents an assignment of the first `workerID` workers to distinct jobs.
2. **Min-Heap Exploration**: A `std::priority_queue` configured as a min-heap orders states by `lowerBound`. The node with the most promising (lowest) lower bound is expanded first.
3. **Row-Reduction Lower Bound**: For unassigned workers from `workerID` to $N-1$, find the minimum cost among currently available (unassigned) jobs:
   $$\text{LB}(\text{node}) = \text{costSoFar} + \sum_{i = \text{nextWorker}}^{N - 1} \min_{j \text{ unassigned}} C[i][j]$$
4. **Guaranteed Optimality**: Because the priority queue expands nodes in non-decreasing order of lower bound, the **first complete assignment (leaf node where `workerID == N`) popped from the priority queue is guaranteed to be optimal**. No further exploration is required!

### Complexity
- **Time Complexity**: Best $O(N^2)$ (when lower bound guides straight to optimal), Average $O(N!)$ heavily pruned, Worst case $O(N!)$ (all branches evaluated).
- **Space Complexity**: $O(N \cdot 2^N)$ worst case for active nodes in the priority queue.

---

## 2. Complete C++ Implementation (LCBB with Min-Heap)

```cpp
#include <iostream>
#include <vector>
#include <queue>
#include <algorithm>
using namespace std;

const int INF = 1e9;

struct Node {
    int workerID;
    int costSoFar;
    int lowerBound;
    vector<int> assignment; // assignment[worker] = job
    vector<bool> jobAssigned;

    // Min-heap comparator: smallest lowerBound has highest priority
    bool operator>(const Node& other) const {
        return lowerBound > other.lowerBound;
    }
};

int calculateAssignmentLB(int nextWorker, int N, const vector<vector<int>>& cost,
                          const vector<bool>& jobAssigned) {
    int lb = 0;
    for (int i = nextWorker; i < N; ++i) {
        int minRowCost = INF;
        for (int j = 0; j < N; ++j) {
            if (!jobAssigned[j]) {
                minRowCost = min(minRowCost, cost[i][j]);
            }
        }
        if (minRowCost != INF) lb += minRowCost;
    }
    return lb;
}

int solveJobAssignment(int N, const vector<vector<int>>& cost, vector<int>& bestAssignment) {
    priority_queue<Node, vector<Node>, greater<Node>> pq;

    Node root;
    root.workerID = 0;
    root.costSoFar = 0;
    root.assignment.assign(N, -1);
    root.jobAssigned.assign(N, false);
    root.lowerBound = calculateAssignmentLB(0, N, cost, root.jobAssigned);

    pq.push(root);

    while (!pq.empty()) {
        Node curr = pq.top();
        pq.pop();

        // Optimality criterion: First complete assignment popped is optimal
        if (curr.workerID == N) {
            bestAssignment = curr.assignment;
            return curr.costSoFar;
        }

        int w = curr.workerID;
        for (int j = 0; j < N; ++j) {
            if (!curr.jobAssigned[j]) {
                Node child = curr;
                child.workerID = w + 1;
                child.assignment[w] = j;
                child.jobAssigned[j] = true;
                child.costSoFar = curr.costSoFar + cost[w][j];
                child.lowerBound = child.costSoFar +
                    calculateAssignmentLB(w + 1, N, cost, child.jobAssigned);

                pq.push(child);
            }
        }
    }
    return -1;
}

int main() {
    int N = 4;
    vector<vector<int>> cost = {
        {9, 2, 7, 8},
        {6, 4, 3, 7},
        {5, 8, 1, 8},
        {7, 6, 9, 4}
    };

    vector<int> assignment;
    int minCost = solveJobAssignment(N, cost, assignment);

    cout << "Optimal Minimum Cost = " << minCost << "\n";
    for (int i = 0; i < N; ++i) {
        cout << "Worker " << i << " -> Job " << assignment[i]
             << " (Cost: " << cost[i][assignment[i]] << ")\n";
    }
    return 0;
}
```

### Verified Output
```
Optimal Minimum Cost = 13
Worker 0 -> Job 1 (Cost: 2)
Worker 1 -> Job 0 (Cost: 6)
Worker 2 -> Job 2 (Cost: 1)
Worker 3 -> Job 3 (Cost: 4)
```
