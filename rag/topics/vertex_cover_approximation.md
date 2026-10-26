# 2-Approximation for Vertex Cover (Maximal Matching)

Vertex cover 2-approximation: take both endpoints of each uncovered edge (FAT Module 10). Category: Approximation.

---

Every program below was extracted from your lab reports / FAT guide, compiled with `g++ -std=c++17 -Wall -O2`, and run; outputs shown are the real program output.

## Lab questions & verified answers

| Lab question | Scenario & input data | Verified answer |
|---|---|---|
| FAT Module 10 | 5 vertices; edges (0,1) (0,2) (1,3) (3,4) (1,4) (2,4) | cover **{0, 1, 3, 4}** (≤ 2 × OPT) |

## 2-Approximation for Vertex Cover (Maximal Matching)

### 2-Approximation for Vertex Cover
**Lab scenario:** Network Security Guard Placement at Intersections

Given an undirected graph $G = (V, E)$, find a minimum set of vertices such that every edge is incident to at least one vertex in the set.
**Greedy Edge Matching Rule:** While there are uncovered edges, pick an arbitrary uncovered edge $(u, v)$, add **both** $u$ and $v$ to the vertex cover, and remove all edges incident to $u$ or $v$.
**Guaranteed Approximation Factor:** $|C| <= 2 · |C^*|$.

### Algorithm: ApproxVertexCover
```python
ApproxVertexCover(V, edges):
    inCover = [FALSE for _ in range(V)]

    FOR (u, v) in edges:
        IF NOT inCover[u] AND NOT inCover[v]:
            inCover[u] = TRUE
            inCover[v] = TRUE            # Take BOTH endpoints for 2-approx!

    RETURN inCover
```

### Concise C++ Implementation (2-Approximation)

```cpp
#include <iostream>
#include <vector>
using namespace std;

void approxVertexCover(int V, const vector<pair<int, int>>& edges) {
    vector<bool> inCover(V, false);
    vector<bool> edgeCovered(edges.size(), false);

    for (size_t i = 0; i < edges.size(); ++i) {
        if (!edgeCovered[i]) {
            int u = edges[i].first, v = edges[i].second;
            if (!inCover[u] && !inCover[v]) {
                inCover[u] = true;
                inCover[v] = true; // Add both endpoints!
            }
        }
    }

    cout << "Approximate Vertex Cover: ";
    for (int i = 0; i < V; ++i) if (inCover[i]) cout << i << " ";
    cout << "\n";
}

int main() {
    vector<pair<int, int>> edges = {{0, 1}, {0, 2}, {1, 3}, {3, 4}, {1, 4}, {2, 4}};
    approxVertexCover(5, edges);
    return 0;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
Approximate Vertex Cover: 0 1 3 4
```
