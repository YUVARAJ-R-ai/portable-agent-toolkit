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
