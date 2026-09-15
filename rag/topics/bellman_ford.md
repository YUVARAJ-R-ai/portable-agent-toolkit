# Bellman-Ford Single-Source Shortest Path (SSSP)

The Bellman-Ford algorithm computes the shortest paths from a single source vertex to all other vertices in a weighted digraph. Unlike Dijkstra's algorithm, it correctly handles edges with negative weights and reliably detects reachable negative weight cycles. Category: Graph Algorithms.

---

## 1. Algorithmic Invariants & Critical Pitfalls

### Edge Relaxation Principle
For each directed edge $(u, v)$ with weight $w$:
$$\text{dist}[v] = \min(\text{dist}[v], \text{dist}[u] + w)$$
If a path from source $s$ to $v$ exists without cycles, it contains at most $V - 1$ edges. Therefore, relaxing all $E$ edges $V - 1$ times guarantees that all shortest paths converge.

### Critical Implementation Rules
1. **$V - 1$ Iterations for Convergence**:
   Relaxation must be executed across all edges up to $V - 1$ times.
2. **Early Stopping Optimization**:
   Maintain an `updated` flag during each pass. If no edge distance changes during an entire pass, the shortest paths have converged and the loop can terminate immediately ($O(E)$ best-case time for already-optimal or DAG structures).
3. **Negative Cycle Detection ($V$-th Pass)**:
   Run a final pass over all edges. If for any edge $(u, v)$ with weight $w$:
   $$\text{dist}[u] \ne \text{INF} \quad \text{and} \quad \text{dist}[u] + w < \text{dist}[v]$$
   then vertex $v$ is part of (or reachable from) a negative weight cycle.
4. **Reachability Check (`dist[u] != INF`)**:
   Never relax an edge from an unreached vertex! In C++, if `dist[u] == INF`, `dist[u] + w` can cause false relaxations or arithmetic underflow.
5. **Integer Overflow Prevention**:
   Never use `INF = INT_MAX`! Always use `const long long INF = 1e15;` and `long long` for distance arrays.

### Complexity
- **Time Complexity**:
  - Worst Case: $O(V \cdot E)$
  - Average Case: $O(V \cdot E)$
  - Best Case: $O(E)$ (with early termination check)
- **Space Complexity**: $O(V)$ for distance and predecessor arrays, $O(E)$ for the edge list.
- **Negative Edge Support**: Fully supported; detects negative cycles reachable from the source.

---

## 2. Canonical C++ Implementation with Path Reconstruction

```cpp
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

const long long INF = 1e15;

struct Edge {
    int u, v;
    long long weight;
};

struct BellmanFordResult {
    bool hasNegativeCycle;
    vector<long long> dist;
    vector<int> parent;
};

BellmanFordResult bellmanFord(int V, int source, const vector<Edge>& edges) {
    vector<long long> dist(V, INF);
    vector<int> parent(V, -1);
    dist[source] = 0;

    // V - 1 relaxation phases
    for (int i = 1; i <= V - 1; ++i) {
        bool updated = false;
        for (const auto& edge : edges) {
            if (dist[edge.u] < INF && dist[edge.u] + edge.weight < dist[edge.v]) {
                dist[edge.v] = dist[edge.u] + edge.weight;
                parent[edge.v] = edge.u;
                updated = true;
            }
        }
        if (!updated) break; // Early termination optimization
    }

    // V-th phase: Negative cycle detection
    bool hasNegativeCycle = false;
    for (const auto& edge : edges) {
        if (dist[edge.u] < INF && dist[edge.u] + edge.weight < dist[edge.v]) {
            hasNegativeCycle = true;
            break;
        }
    }

    return {hasNegativeCycle, dist, parent};
}

vector<int> getPath(int target, const vector<int>& parent) {
    vector<int> path;
    for (int curr = target; curr != -1; curr = parent[curr]) {
        path.push_back(curr);
    }
    reverse(path.begin(), path.end());
    return path;
}

int main() {
    int V = 5;
    // Graph with negative edges but no negative cycle
    vector<Edge> edges = {
        {0, 1, -1},
        {0, 2, 4},
        {1, 2, 3},
        {1, 3, 2},
        {1, 4, 2},
        {3, 2, 5},
        {3, 1, 1},
        {4, 3, -3}
    };

    int source = 0;
    BellmanFordResult result = bellmanFord(V, source, edges);

    if (result.hasNegativeCycle) {
        cout << "Graph contains a negative weight cycle reachable from source " << source << "!\n";
    } else {
        cout << "Shortest distances from source " << source << ":\n";
        for (int i = 0; i < V; ++i) {
            if (result.dist[i] >= INF / 2) {
                cout << "Node " << i << ": UNREACHABLE\n";
            } else {
                cout << "Node " << i << ": Distance = " << result.dist[i] << " | Path: ";
                vector<int> path = getPath(i, result.parent);
                for (int node : path) cout << node << " ";
                cout << "\n";
            }
        }
    }
    return 0;
}
```

---

## 3. Twisted Exam Variations & Implementations

### Variation 1: Negative Cycle Identification and Cycle Vertex Extraction
- **Scenario Keywords**: "Detect financial arbitrage", "identify exact looping nodes with negative latency", "dump vertices of negative cycle".
- **Core Concept**: When an edge $(u, v)$ is relaxed during the $V$-th pass, $v$ is in or reachable from a negative cycle. To guarantee reaching a vertex on the cycle itself, trace `parent` pointers back $V$ times from $v$. The cycle can then be reconstructed by walking backwards until the starting node repeats.

```cpp
vector<int> findNegativeCycle(int V, const vector<Edge>& edges) {
    vector<long long> dist(V, 0); // Start from 0 to detect cycles in ANY disconnected component
    vector<int> parent(V, -1);
    int cycleStart = -1;

    for (int i = 0; i < V; ++i) {
        cycleStart = -1;
        for (const auto& edge : edges) {
            if (dist[edge.u] + edge.weight < dist[edge.v]) {
                dist[edge.v] = dist[edge.u] + edge.weight;
                parent[edge.v] = edge.u;
                cycleStart = edge.v;
            }
        }
    }

    if (cycleStart == -1) return {}; // No negative cycle

    // Step back V times to guarantee landing inside the cycle
    for (int i = 0; i < V; ++i) {
        cycleStart = parent[cycleStart];
    }

    vector<int> cycle;
    for (int curr = cycleStart;; curr = parent[curr]) {
        cycle.push_back(curr);
        if (curr == cycleStart && cycle.size() > 1) break;
    }
    reverse(cycle.begin(), cycle.end());
    return cycle;
}
```

---

### Variation 2: Shortest Path with At Most $K$ Edges / Hops (Flight Booking with $K$ Layovers)
- **Scenario Keywords**: "At most K layovers", "maximum K hops", "bounded-hop shortest path".
- **Core Concept**: Standard Bellman-Ford allows chaining multiple edge relaxations within a single iteration if edges are ordered favorably. To strictly limit the path to at most $K$ edges, copy `dist` into `prevDist` at the start of each iteration, and only relax edges using `prevDist[edge.u]`.
- **Number of Iterations**: Exactly $K$ iterations.

```cpp
long long shortestPathWithAtMostKHops(int V, int src, int dst, int K, const vector<Edge>& edges) {
    vector<long long> dist(V, INF);
    dist[src] = 0;

    // Run exactly K passes (each pass explores paths with one more edge)
    for (int i = 0; i < K; ++i) {
        vector<long long> prevDist = dist; // Snapshot previous state
        for (const auto& edge : edges) {
            if (prevDist[edge.u] < INF && prevDist[edge.u] + edge.weight < dist[edge.v]) {
                dist[edge.v] = min(dist[edge.v], prevDist[edge.u] + edge.weight);
            }
        }
    }

    return (dist[dst] >= INF / 2) ? -1 : dist[dst];
}
```

---

### Variation 3: Currency Arbitrage Detection
- **Scenario Keywords**: "Currency exchange rates", "maximize multiplier through conversion loop", "arbitrage opportunity".
- **Core Concept**: Given exchange rates $R[u][v]$ where converting $1$ unit of currency $u$ gives $R[u][v]$ of currency $v$. A profitable arbitrage cycle exists if along a cycle:
  $$R_1 \times R_2 \times \dots \times R_k > 1$$
- **Mathematical Transformation**:
  Take the negative logarithm of both sides:
  $$\ln(R_1 \times R_2 \times \dots \times R_k) > 0 \iff -\sum \ln(R_i) < 0$$
  Assign edge weight $w(u, v) = -\ln(R[u][v])$. Any negative cycle found by Bellman-Ford corresponds to a profitable arbitrage cycle!
