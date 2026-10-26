# Floyd-Warshall All-Pairs Shortest Path (APSP)

The Floyd-Warshall algorithm is a Dynamic Programming formulation that computes the shortest paths between all pairs of vertices in a weighted, directed graph (supporting positive and negative edge weights). Category: Graph Algorithms.

---

## 1. Algorithmic Invariants & Critical Pitfalls

### DP Recurrence Relation
Let $D^{(k)}[i][j]$ be the shortest path from vertex $i$ to vertex $j$ using only intermediate vertices from $\{0, 1, \dots, k\}$:
$$D^{(k)}[i][j] = \min\left(D^{(k-1)}[i][j], D^{(k-1)}[i][k] + D^{(k-1)}[k][j]\right)$$

### Critical Implementation Rules
1. **The $k$ Loop Must Be Outermost**:
   The intermediate vertex $k$ must iterate from $0$ to $V-1$ as the outermost loop. If $i$ or $j$ is outermost, subproblem results from previous stages are not properly populated, causing incorrect distances.
2. **Integer Overflow Prevention**:
   Never use `INF = INT_MAX`! In C++, `INT_MAX + weight` causes signed integer overflow (wrapping to negative values). Always use `const long long INF = 1e15;` and `long long` distance matrices.

### Complexity
- **Time Complexity**: Strictly $O(V^3)$ across all inputs (triply nested loops of size $V$).
- **Space Complexity**: $O(V^2)$ matrix storage for distances and path reconstruction pointers.
- **Negative Edge Handling**: Supports negative edge weights; detects negative cycles.

---

## 2. Canonical C++ Implementation with Path Reconstruction

```cpp
#include <iostream>
#include <vector>
using namespace std;

const long long INF = 1e15;

void floydWarshall(int V, vector<vector<long long>>& dist, vector<vector<int>>& nextNode) {
    // 1. Initialize nextNode for path reconstruction
    for (int i = 0; i < V; ++i) {
        for (int j = 0; j < V; ++j) {
            if (dist[i][j] < INF && i != j) nextNode[i][j] = j;
            else nextNode[i][j] = -1;
        }
    }

    // 2. Outermost loop MUST be intermediate vertex k!
    for (int k = 0; k < V; ++k) {
        for (int i = 0; i < V; ++i) {
            for (int j = 0; j < V; ++j) {
                if (dist[i][k] < INF && dist[k][j] < INF) {
                    if (dist[i][k] + dist[k][j] < dist[i][j]) {
                        dist[i][j] = dist[i][k] + dist[k][j];
                        nextNode[i][j] = nextNode[i][k];
                    }
                }
            }
        }
    }
}

vector<int> reconstructPath(int u, int v, const vector<vector<int>>& nextNode) {
    if (nextNode[u][v] == -1) return {};
    vector<int> path = {u};
    while (u != v) {
        u = nextNode[u][v];
        path.push_back(u);
    }
    return path;
}

int main() {
    int V = 4;
    vector<vector<long long>> dist = {
        {0, 3, INF, 7},
        {8, 0, 2, INF},
        {5, INF, 0, 1},
        {2, INF, INF, 0}
    };
    vector<vector<int>> nextNode(V, vector<int>(V, -1));

    floydWarshall(V, dist, nextNode);

    cout << "Shortest distance from 0 to 3: " << dist[0][3] << "\n";
    vector<int> path = reconstructPath(0, 3, nextNode);
    cout << "Path: ";
    for (int node : path) cout << node << " ";
    cout << "\n";
    return 0;
}
```

---

## 3. Twisted Exam Variations & Implementations

### Variation 1: Negative Cycle Detection & Marking Infinite Loop Nodes (-INF)
- **Scenario Keywords**: "Negative communication delays", "detect infinite gain loops", "mark paths of negative infinity".
- **Detection**: If after $V$ iterations any diagonal entry $\text{dist}[k][k] < 0$, vertex $k$ is on a negative weight cycle.
- **Propagation**: Run a second pass. Any path that passes through any negative-cycle node $k$ has distance $-\infty$.

```cpp
void detectNegativeCycles(int V, vector<vector<long long>>& dist) {
    for (int k = 0; k < V; ++k) {
        if (dist[k][k] < 0) { // Vertex k lies on a negative cycle
            for (int i = 0; i < V; ++i) {
                for (int j = 0; j < V; ++j) {
                    if (dist[i][k] < INF && dist[k][j] < INF) {
                        dist[i][j] = -INF; // Path corrupted by negative cycle!
                    }
                }
            }
        }
    }
}
```

---

### Variation 2: Widest Path / Maximum Bottleneck Capacity (Maximin DP)
- **Scenario Keywords**: "Maximize bottleneck bandwidth", "widest path between all pairs", "network channel capacity".
- **Core Concept**: The bottleneck capacity of a path is the minimum edge weight along that path. Find the path that maximizes this minimum capacity.
- **Adaptation**: Replace sum-of-weights with the maximin recurrence:
  $$\text{cap}[i][j] = \max(\text{cap}[i][j], \min(\text{cap}[i][k], \text{cap}[k][j]))$$

```cpp
void widestPathAllPairs(int V, vector<vector<int>>& capacity) {
    for (int k = 0; k < V; ++k) {
        for (int i = 0; i < V; ++i) {
            for (int j = 0; j < V; ++j) {
                capacity[i][j] = max(capacity[i][j], min(capacity[i][k], capacity[k][j]));
            }
        }
    }
}
```

---

### Variation 3: Transitive Closure (Warshall's Reachability Matrix)
- **Scenario Keywords**: "Transitive closure", "reachability matrix", "determine directed path existence".
- **Adaptation**: Boolean values with bitwise OR/AND:
  $$\text{reach}[i][j] = \text{reach}[i][j] \lor (\text{reach}[i][k] \land \text{reach}[k][j])$$

---

# FAT Lab-Exam Version & Your Lab Programs (BCSE204P, Dr. Sakthivel R)

Every program below was extracted from your lab reports / FAT guide, compiled with `g++ -std=c++17 -Wall -O2`, and run; outputs shown are the real program output.

## Lab questions & verified answers

| Lab question | Scenario & input data | Verified answer |
|---|---|---|
| FAT Module 7 | 4×4 matrix [0,3,∞,7] [8,0,2,∞] [5,∞,0,1] [2,∞,∞,0] | [0,3,5,6] [5,0,2,3] [3,6,0,1] [2,5,7,0] |

## All-Pairs Shortest Path: Floyd-Warshall Algorithm

### Floyd-Warshall Algorithm
**Lab scenario:** All-Pairs Route Optimization in Dense Transit Networks

Given a weighted graph with no negative cycles, compute the shortest path between every pair of vertices $(i, j)$ using dynamic programming.
- $D[i][j] = min(D[i][j], D[i][k] + D[k][j])$
- **Critical Rule:** The intermediate vertex $k$ MUST be the **outermost** loop!

### Algorithm: FloydWarshall
```python
FloydWarshall(V, W):
    D = copy(W)   # Adjacency matrix of edge weights

    FOR k = 0 TO V - 1:            # Intermediate vertex MUST be outermost!
        FOR i = 0 TO V - 1:
            FOR j = 0 TO V - 1:
                IF D[i][k] + D[k][j] < D[i][j]:
                    D[i][j] = D[i][k] + D[k][j]

    RETURN D
```

### Concise C++ Implementation (O(V^3))

```cpp
#include <iostream>
#include <vector>
#include <algorithm>
using namespace std;

const int INF = 1e9;

int main() {
    int V = 4;
    vector<vector<int>> dist = {
        {0, 3, INF, 7},
        {8, 0, 2, INF},
        {5, INF, 0, 1},
        {2, INF, INF, 0}
    };

    // k MUST be the outermost loop!
    for (int k = 0; k < V; ++k)
        for (int i = 0; i < V; ++i)
            for (int j = 0; j < V; ++j)
                if (dist[i][k] < INF && dist[k][j] < INF)
                    dist[i][j] = min(dist[i][j], dist[i][k] + dist[k][j]);

    cout << "All-Pairs Shortest Distance Matrix:\n";
    for (int i = 0; i < V; ++i) {
        for (int j = 0; j < V; ++j) {
            if (dist[i][j] == INF) cout << "INF\t";
            else cout << dist[i][j] << "\t";
        }
        cout << "\n";
    }
    return 0;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
All-Pairs Shortest Distance Matrix:
0	3	5	6	
5	0	2	3	
3	6	0	1	
2	5	7	0
```

### Cheese Code: Barebones 6-Line Triple Loop
**Why it works in the exam:** Floyd-Warshall is the easiest DP algorithm to code: 3 nested for loops with one min statement!

```cpp
#include <bits/stdc++.h>
using namespace std;
int d[4][4] = {{0,3,1000,7},{8,0,2,1000},{5,1000,0,1},{2,1000,1000,0}};
int main() {
    for (int k = 0; k < 4; ++k)
        for (int i = 0; i < 4; ++i)
            for (int j = 0; j < 4; ++j)
                d[i][j] = min(d[i][j], d[i][k] + d[k][j]);
    for (int i = 0; i < 4; ++i) { for (int j = 0; j < 4; ++j) cout << d[i][j] << " "; cout << "\n"; }
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
0 3 5 6 
5 0 2 3 
3 6 0 1 
2 5 7 0
```

### Silly Mistakes & Traps: Floyd-Warshall
1. **Incorrect Loop Nesting:** Putting `k` as the inner loop completely destroys the DP invariant! $k$ represents the maximum allowed intermediate vertex index and MUST be the outermost loop.
2. **Addition Overflow:** If `INF = INT_MAX`, `dist[i][k] + dist[k][j]` overflows into negative numbers. Always use `INF = 1e9` or guard with `dist[i][k] < INF && dist[k][j] < INF`.
3. **Self-Loop Diagonal:** Ensure $D[i][i] = 0$ at the start. If $D[i][i] < 0$ after execution, a negative-weight cycle exists.

**Complexity:** best O(V^3) · average O(V^3) · worst O(V^3) · auxiliary space O(V^2) matrix  
**Recurrence:** D^(k)[i][j] = min(D^(k-1)[i][j], D^(k-1)[i][k] + D^(k-1)[k][j])
