# Minimum Spanning Tree: Kruskal's & Prim's Algorithms

A Minimum Spanning Tree (MST) of an undirected, connected, weighted graph $G = (V, E)$ is an acyclic subgraph spanning all $V$ vertices with exactly $V - 1$ edges that minimizes the total sum of edge weights. Category: Graph Algorithms.

---

## 1. Kruskal's Algorithm (Edge-Centric Greedy)

Kruskal's algorithm sorts all edges in non-decreasing order of weight and greedily selects edges using a **Disjoint Set Union (DSU)** data structure with **Path Compression** and **Union by Rank** to avoid cycle formation.

### Complexity
- **Time Complexity**: $O(E \log E) = O(E \log V)$ for edge sorting; DSU operations run in near-linear $O(E \cdot \alpha(V))$ where $\alpha$ is the inverse Ackermann function.
- **Space Complexity**: $O(V + E)$ for DSU structures and edge list.
- **Best Applied**: Sparse graphs where $E \ll V^2$. Operating on an edge list (`vector<Edge>`) is required.

### Canonical C++ Implementation (Kruskal)

```cpp
#include <iostream>
#include <vector>
#include <algorithm>
using namespace std;

struct Edge {
    int u, v, weight;
    bool operator<(const Edge& other) const { return weight < other.weight; }
};

class DSU {
public:
    vector<int> parent, rank;
    DSU(int n) : parent(n), rank(n, 0) {
        for (int i = 0; i < n; ++i) parent[i] = i;
    }
    int find(int i) {
        if (parent[i] == i) return i;
        return parent[i] = find(parent[i]); // Path compression
    }
    bool unite(int u, int v) {
        int rootU = find(u), rootV = find(v);
        if (rootU == rootV) return false; // Cycle detected
        if (rank[rootU] < rank[rootV]) swap(rootU, rootV);
        parent[rootV] = rootU;
        if (rank[rootU] == rank[rootV]) rank[rootU]++;
        return true;
    }
};

int kruskalMST(int V, vector<Edge>& edges, vector<Edge>& mstEdges) {
    sort(edges.begin(), edges.end());
    DSU dsu(V);
    int totalWeight = 0;

    for (const auto& e : edges) {
        if (dsu.unite(e.u, e.v)) {
            totalWeight += e.weight;
            mstEdges.push_back(e);
            if ((int)mstEdges.size() == V - 1) break;
        }
    }
    return totalWeight;
}
```

---

## 2. Prim's Algorithm (Vertex-Centric Greedy)

Prim's algorithm grows a single tree starting from an arbitrary root vertex (e.g. vertex 0). At each step, it extracts the minimum-weight cut edge connecting a tree vertex to an external vertex using a min-heap.

### Complexity
- **Time Complexity**: $O((V + E) \log V) = O(E \log V)$ using a binary min-heap (`std::priority_queue`).
- **Space Complexity**: $O(V + E)$ for adjacency list, visited array, and min-heap.
- **Best Applied**: Dense graphs where $E \approx V^2$. Operating on an adjacency list (`vector<vector<pair<int, int>>>>`) is required.

### Canonical C++ Implementation (Prim)

```cpp
#include <iostream>
#include <vector>
#include <queue>
using namespace std;

typedef pair<int, int> pii; // {weight, vertex}

int primMST(int V, const vector<vector<pii>>& adj, vector<pair<int, int>>& mstEdges) {
    priority_queue<pii, vector<pii>, greater<pii>> pq;
    vector<int> key(V, 1e9);
    vector<int> parent(V, -1);
    vector<bool> inMST(V, false);

    pq.push({0, 0});
    key[0] = 0;
    int totalWeight = 0;

    while (!pq.empty()) {
        int u = pq.top().second;
        int w = pq.top().first;
        pq.pop();

        if (inMST[u]) continue;
        inMST[u] = true;
        totalWeight += w;
        if (parent[u] != -1) mstEdges.push_back({parent[u], u});

        for (auto& edge : adj[u]) {
            int weight = edge.first;
            int v = edge.second;
            if (!inMST[v] && weight < key[v]) {
                key[v] = weight;
                parent[v] = u;
                pq.push({key[v], v});
            }
        }
    }
    return totalWeight;
}
```

---

## 3. Twisted Exam Variations & Implementations

### Variation 1: Mandatory and Forbidden Network Cables (Constrained MST)
- **Scenario Keywords**: "Mandatory fiber links", "forbidden hazardous conduits", "compulsory network cables".
- **Core Concept**: Specified edges must be forced into the tree; other forbidden edges cannot be touched.
- **Algorithm**:
  1. Filter out all forbidden edges immediately.
  2. Pre-process mandatory edges: unite them in DSU first. If a cycle forms among mandatory edges, output impossible (`-1`).
  3. Sort the remaining valid edges and continue standard Kruskal until $V - 1$ edges are selected.

```cpp
int constrainedMST(int V, const vector<Edge>& allEdges,
                   const vector<Edge>& mandatory, const vector<Edge>& forbidden,
                   vector<Edge>& mstEdges) {
    DSU dsu(V);
    int totalWeight = 0;

    // 1. Process Mandatory Edges first
    for (const auto& e : mandatory) {
        if (!dsu.unite(e.u, e.v)) return -1; // Mandatory edges form a cycle!
        totalWeight += e.weight;
        mstEdges.push_back(e);
    }

    // 2. Discard forbidden edges
    vector<Edge> candidateEdges;
    for (const auto& e : allEdges) {
        bool isForb = false;
        for (const auto& f : forbidden) {
            if ((e.u == f.u && e.v == f.v) || (e.u == f.v && e.v == f.u)) {
                isForb = true; break;
            }
        }
        if (!isForb) candidateEdges.push_back(e);
    }

    sort(candidateEdges.begin(), candidateEdges.end());

    // 3. Complete MST with remaining valid edges
    for (const auto& e : candidateEdges) {
        if (dsu.unite(e.u, e.v)) {
            totalWeight += e.weight;
            mstEdges.push_back(e);
            if ((int)mstEdges.size() == V - 1) break;
        }
    }
    return (int)mstEdges.size() == V - 1 ? totalWeight : -1;
}
```

---

### Variation 2: Strictly Second Best Minimum Spanning Tree (2nd MST)
- **Scenario Keywords**: "Redundant backup network", "strictly second minimum spanning tree", "2nd MST".
- **Core Concept**: Find the spanning tree with the smallest total weight that is strictly greater than the base MST weight.
- **Algorithm**:
  1. Compute the base MST and record the indices of its $V - 1$ edges.
  2. For each edge in the base MST: temporarily exclude it, and run Kruskal on the remaining $E - 1$ edges.
  3. If a valid spanning tree forms with $V - 1$ edges and $\text{weight} > \text{baseWeight}$, record it.
  4. The minimum among these candidate weights gives the strictly second best MST!
- **Complexity**: $O(V \cdot E \cdot \alpha(V))$.

```cpp
int secondMST(int V, vector<Edge>& edges) {
    sort(edges.begin(), edges.end());
    DSU dsu(V);
    vector<int> mstEdgeIndices;
    int baseWeight = 0;

    for (int i = 0; i < (int)edges.size(); ++i) {
        if (dsu.unite(edges[i].u, edges[i].v)) {
            baseWeight += edges[i].weight;
            mstEdgeIndices.push_back(i);
        }
    }
    if ((int)mstEdgeIndices.size() != V - 1) return -1; // Graph disconnected

    int secondBest = 1e9;

    // Remove each base MST edge one by one and find cheapest alternative
    for (int excludedIdx : mstEdgeIndices) {
        DSU tempDsu(V);
        int currentWeight = 0, edgeCount = 0;
        for (int i = 0; i < (int)edges.size(); ++i) {
            if (i == excludedIdx) continue;
            if (tempDsu.unite(edges[i].u, edges[i].v)) {
                currentWeight += edges[i].weight;
                edgeCount++;
            }
        }
        if (edgeCount == V - 1 && currentWeight > baseWeight) {
            secondBest = min(secondBest, currentWeight);
        }
    }
    return secondBest == 1e9 ? -1 : secondBest;
}
```

---

# FAT Lab-Exam Version & Your Lab Programs (BCSE204P, Dr. Sakthivel R)

Every program below was extracted from your lab reports / FAT guide, compiled with `g++ -std=c++17 -Wall -O2`, and run; outputs shown are the real program output.

## Lab questions & verified answers

| Lab question | Scenario & input data | Verified answer |
|---|---|---|
| Lab 8 Q4 / Lab 9 Q6 / FAT | A−B 4, A−C 3, B−C 2, B−D 5, B−E 6, C−D 7, C−E 8, D−E 3, D−F 4 | B−C 2, A−C 3, D−E 3, D−F 4, B−D 5 → **17** |
| Lab 9 Q2 | Substations: A−B 6, A−C 4, B−C 3, B−D 7, B−E 8, C−D 5, C−E 9, D−E 2, D−F 5 | D−E 2, B−C 3, A−C 4, C−D 5, D−F 5 → **19** |

Your Lab 8 report pasted this same MST program under Q5 as well. Q5 is the Bellman-Ford question; see `bellman_ford`.

## Minimum Spanning Tree: Kruskal’s Algorithm (Disjoint Set Union)

### Kruskal’s Minimum Spanning Tree
**Lab scenario:** Regional Power Substation Grid & University Fiber-Optic Communication Infrastructure

Given a connected, undirected weighted graph $G = (V, E)$, find a subset of edges that connects all vertices without any cycles with minimum total weight.

**Greedy DSU Mechanics:**
1. Sort all edges in non-decreasing order of weight.
2. Process edges one by one: if endpoints $u$ and $v$ belong to different connected components, add $(u, v)$ to the MST and merge their components using **Disjoint Set Union (DSU)** with path compression.

### Algorithm: KruskalMST
```python
KruskalMST(V, edges):
    SORT edges by weight ascending: w1 <= w2 <= ... <= wE
    dsu = MakeSet(V)
    mst = []
    total_cost = 0

    FOR (u, v, weight) in edges:
        IF dsu.find(u) != dsu.find(v):
            dsu.unite(u, v)
            mst.append((u, v, weight))
            total_cost = total_cost + weight

    RETURN mst, total_cost
```

### Step-by-Step DSU Edge Selection Trace (Kruskal)
| **Edge** | **Weight** | **DSU Root Comparison** | **Status** | **Cumulative Cost** |
|---|---|---|---|---|
| B - C | 2 | `find(B) != find(C)` | **ACCEPTED** | Cost = 2 |
| A - C | 3 | `find(A) != find(C)` | **ACCEPTED** | Cost = 5 |
| D - E | 3 | `find(D) != find(E)` | **ACCEPTED** | Cost = 8 |
| A - B | 4 | `find(A) == find(B)` {A, B, C} | CYCLE! Rejected | Cost = 8 |
| D - F | 4 | `find(D) != find(F)` | **ACCEPTED** | Cost = 12 |
| B - D | 5 | `find(B) != find(D)` {A,B,C} vs {D,E,F} | **ACCEPTED** | Cost = 17 |
| B - E | 6 | `find(B) == find(E)` | CYCLE! Rejected | Cost = 17 |
| C - D | 7 | `find(C) == find(D)` | CYCLE! Rejected | Cost = 17 |
| C - E | 8 | `find(C) == find(E)` | CYCLE! Rejected | Cost = 17 |

**Termination:** Exactly $|V| - 1 = 5$ edges added to MST. Graph is fully connected with minimum possible total weight **17**.

### Concise C++ Implementation

```cpp
#include <iostream>
#include <vector>
#include <algorithm>
using namespace std;

struct Edge {
    char u, v;
    int weight;
};

struct DSU {
    vector<int> parent, rank;
    DSU(int n) : parent(n), rank(n, 0) {
        for (int i = 0; i < n; ++i) parent[i] = i;
    }
    int find(int i) {
        if (parent[i] == i) return i;
        return parent[i] = find(parent[i]); // Path compression
    }
    bool unite(int i, int j) {
        int root_i = find(i), root_j = find(j);
        if (root_i == root_j) return false;
        if (rank[root_i] < rank[root_j]) parent[root_i] = root_j;
        else if (rank[root_i] > rank[root_j]) parent[root_j] = root_i;
        else { parent[root_j] = root_i; rank[root_i]++; }
        return true;
    }
};

int main() {
    // Lab Example: Regional Power Substations {A, B, C, D, E, F}
    vector<Edge> edges = {
        {'A', 'B', 4}, {'A', 'C', 3}, {'B', 'C', 2}, {'B', 'D', 5},
        {'B', 'E', 6}, {'C', 'D', 7}, {'C', 'E', 8}, {'D', 'E', 3}, {'D', 'F', 4}
    };

    sort(edges.begin(), edges.end(), [](const Edge& a, const Edge& b) {
        return a.weight < b.weight;
    });

    DSU dsu(6);
    int totalCost = 0;
    vector<Edge> mst;

    cout << "Selected MST Edges:\n";
    for (const auto& e : edges) {
        if (dsu.unite(e.u - 'A', e.v - 'A')) {
            mst.push_back(e);
            totalCost += e.weight;
            cout << "  " << e.u << " - " << e.v << " (Cost: " << e.weight << ")\n";
        }
    }
    cout << "Total Minimum Cost: " << totalCost << "\n";
    return 0;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
Selected MST Edges:
  B - C (Cost: 2)
  A - C (Cost: 3)
  D - E (Cost: 3)
  D - F (Cost: 4)
  B - D (Cost: 5)
Total Minimum Cost: 17
```

### Cheese Code: Minimal 6-Line DSU Kruskal
**Why it works in the exam:** A barebones parent array with recursive find is only 5 lines of code and needs zero complex classes!

```cpp
#include <bits/stdc++.h>
using namespace std;
int p[100];
int find(int x) { return p[x] == x ? x : p[x] = find(p[x]); }
int main() {
    for (int i = 0; i < 26; ++i) p[i] = i;
    vector<tuple<int,char,char>> edges = {{4,'A','B'},{3,'A','C'},{2,'B','C'},{5,'B','D'},{6,'B','E'},{7,'C','D'},{8,'C','E'},{3,'D','E'},{4,'D','F'}};
    sort(edges.begin(), edges.end());
    int cost = 0;
    for (auto [w, u, v] : edges) {
        if (find(u - 'A') != find(v - 'A')) {
            p[find(u - 'A')] = find(v - 'A');
            cost += w;
            cout << u << "-" << v << " ";
        }
    }
    cout << "\nTotal Cost: " << cost << endl;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
B-C A-C D-E D-F B-D 
Total Cost: 17
```

### Silly Mistakes & Traps: Kruskal's MST
1. **Forgetting Character to Integer Mapping:** Graph nodes often appear as chars (`'A'`, `'B'`). Writing `dsu.unite(e.u, e.v)` looks up index 65 (ASCII for 'A') which causes out-of-bounds segfaults! ALWAYS subtract base: `e.u - 'A'`.
2. **Undirected Edge Duplication:** When defining the edge list for Kruskal, insert each undirected edge once. Inserting both $(u, v)$ and $(v, u)$ wastes sorting time.

**Complexity:** best O(E log E) · average O(E log E) · worst O(E log E) · auxiliary space O(V) for DSU  
**Recurrence:** O(E log E) sorting dominates DSU alpha(V) operations
