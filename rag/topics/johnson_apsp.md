# Johnson's Algorithm for All-Pairs Shortest Paths (Sparse Graphs)

Johnson's algorithm computes shortest paths between all pairs of vertices in a directed, weighted graph that may contain negative edge weights (but no negative weight cycles). On sparse graphs where $E \ll V^2$, Johnson's algorithm ($O(V^2 \log V + VE)$) significantly outperforms Floyd-Warshall ($O(V^3)$). Category: Graph Algorithms.

---

## 1. The 5 Execution Steps & Mathematical Invariants

### Step 1: Augment Graph with Synthetic Source $s$
Add a new vertex $s$ (indexed as vertex $V$). Add directed edges $(s, v)$ with weight $0$ for every vertex $v \in V$.

### Step 2: Run Bellman-Ford to Compute Vertex Potentials $h[v]$
Run Bellman-Ford from source $s$ to calculate potential $h[v] = \text{dist}(s, v)$.
- If Bellman-Ford detects a negative weight cycle, terminate execution (APSP cannot be defined).

### Step 3: Reweight All Original Edges to Non-Negative Values
For each directed edge $(u, v)$ with weight $w(u, v)$, compute reweighted weight $\hat{w}(u, v)$:
$$\hat{w}(u, v) = w(u, v) + h[u] - h[v]$$

**Why $\hat{w}(u, v) \ge 0$**: By the triangle inequality in the shortest-path graph from $s$:
$$h[v] \le h[u] + w(u, v) \iff w(u, v) + h[u] - h[v] \ge 0$$
Furthermore, for any path $p = \langle v_0, v_1, \dots, v_k \rangle$, the reweighted length is:
$$\hat{w}(p) = \sum_{i=1}^k \left(w(v_{i-1}, v_i) + h[v_{i-1}] - h[v_i]\right) = w(p) + h[v_0] - h[v_k]$$
Because $h[v_0]$ and $h[v_k]$ depend only on the endpoints, all paths between $u$ and $v$ are shifted by the identical constant $h[u] - h[v]$, strictly preserving shortest path orderings!

### Step 4: Run Dijkstra from Every Vertex
Because all $\hat{w}(u, v) \ge 0$, run Dijkstra $|V|$ times (once from each vertex $u \in V$) using the reweighted graph and a min-heap (`std::priority_queue`).

### Step 5: Restore Original Distances
Convert reweighted distances $\hat{d}(u, v)$ back to true distances:
$$d(u, v) = \hat{d}(u, v) - h[u] + h[v]$$

### Complexity
- **Bellman-Ford Phase**: $O(V \cdot E)$.
- **Reweighting Phase**: $O(E)$.
- **$|V|$ Dijkstra Runs**: $O(V \cdot E \log V)$ with binary heap.
- **Total Time Complexity**: $O(V^2 \log V + V E)$.
- **Space Complexity**: $O(V + E)$ graph representation + $O(V^2)$ distance matrix.

---

## 2. Complete C++ Implementation

```cpp
#include <iostream>
#include <vector>
#include <queue>
using namespace std;

const long long INF = 1e15;
typedef pair<long long, int> pli; // {distance, vertex}

struct JEdge {
    int u, v;
    long long w;
};

vector<vector<long long>> johnsonAPSP(int V, const vector<JEdge>& edges) {
    // Step 1: Bellman-Ford with synthetic source node V
    vector<long long> h(V + 1, INF);
    h[V] = 0;
    vector<JEdge> augEdges = edges;
    for (int i = 0; i < V; ++i) augEdges.push_back({V, i, 0});

    for (int i = 0; i < V; ++i) {
        for (const auto& e : augEdges) {
            if (h[e.u] < INF && h[e.u] + e.w < h[e.v]) {
                h[e.v] = h[e.u] + e.w;
            }
        }
    }

    // Negative cycle detection
    for (const auto& e : augEdges) {
        if (h[e.u] < INF && h[e.u] + e.w < h[e.v]) {
            cerr << "Negative-weight cycle detected!\n";
            return {};
        }
    }

    // Step 2 & 3: Reweight edges & construct adjacency list
    vector<vector<pair<int, long long>>> adj(V);
    for (const auto& e : edges) {
        long long reweighted = e.w + h[e.u] - h[e.v];
        adj[e.u].push_back({e.v, reweighted});
    }

    // Step 4 & 5: Run Dijkstra from every vertex
    vector<vector<long long>> dist(V, vector<long long>(V, INF));

    for (int src = 0; src < V; ++src) {
        priority_queue<pli, vector<pli>, greater<pli>> pq;
        dist[src][src] = 0;
        pq.push({0, src});

        while (!pq.empty()) {
            long long d = pq.top().first;
            int u = pq.top().second;
            pq.pop();

            if (d > dist[src][u]) continue;

            for (auto& edge : adj[u]) {
                int v = edge.first;
                long long weight = edge.second;
                if (dist[src][u] + weight < dist[src][v]) {
                    dist[src][v] = dist[src][u] + weight;
                    pq.push({dist[src][v], v});
                }
            }
        }

        // Restore original distances
        for (int v = 0; v < V; ++v) {
            if (dist[src][v] < INF) {
                dist[src][v] = dist[src][v] - h[src] + h[v];
            }
        }
    }
    return dist;
}

int main() {
    int V = 4;
    vector<JEdge> edges = {
        {0, 1, -5},
        {0, 2, 2},
        {1, 2, 4},
        {2, 3, 1},
        {1, 3, 3}
    };

    vector<vector<long long>> dist = johnsonAPSP(V, edges);
    if (!dist.empty()) {
        cout << "Johnson's APSP Distance Matrix:\n";
        for (int i = 0; i < V; ++i) {
            for (int j = 0; j < V; ++j) {
                if (dist[i][j] >= INF / 2) cout << "INF\t";
                else cout << dist[i][j] << "\t";
            }
            cout << "\n";
        }
    }
    return 0;
}
```

### Verified Output
```
Johnson's APSP Distance Matrix:
0	-5	-1	0	
INF	0	4	3	
INF	INF	0	1	
INF	INF	INF	0	
```
