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

---

# FAT Lab-Exam Version & Your Lab Programs (BCSE204P, Dr. Sakthivel R)

Every program below was extracted from your lab reports / FAT guide, compiled with `g++ -std=c++17 -Wall -O2`, and run; outputs shown are the real program output.

## Lab questions & verified answers

| Lab question | Scenario & input data | Verified answer |
|---|---|---|
| Lab 8 Q5 / FAT | S→A 4, S→B 5, A→B −2, A→C 6, B→C 3, B→D 4, C→D −1, D→A 2 | A=4, B=2, C=5, D=4; **no** negative cycle (A→B→C→D→A = +2) |
| Lab 9 Q3 | S→A 5, S→B 6, A→B −3, A→C 7, B→C 2, B→D 5, C→D −2, D→A 1 | **Negative cycle: Yes**: A→B→C→D→A = −3+2−2+1 = −2, so shortest distances are undefined (the printed values keep dropping) |

Your Lab 8 report has the MST code pasted under Q5 (Bellman-Ford), so it has no Bellman-Ford program. The FAT program below uses exactly the Lab 8 Q5 graph and is the correct answer for it.

## Single-Source Shortest Path: Bellman-Ford Algorithm

### Bellman-Ford Algorithm (Handles Negative Edge Weights)
**Lab scenario:** Autonomous Electric Delivery Fleet (Downhill regenerative braking restores battery => negative energy costs)

Given a directed graph with edge weights (which may be negative), find the shortest paths from a single source $S$ to all other vertices, or detect if a negative weight cycle exists.

**Dynamic Programming Relaxation:**
A simple shortest path contains at most $|V| - 1$ edges. Relaxing all edges $|V| - 1$ times guarantees that all shortest paths are found. A further relaxation on the $|V|$-th iteration succeeds if and only if a reachable negative-weight cycle exists.

### Algorithm: BellmanFord
```python
BellmanFord(V, edges, source):
    dist = [INF for _ in range(V)]
    dist[source] = 0

    FOR iter = 1 TO V - 1:
        FOR (u, v, weight) in edges:
            IF dist[u] != INF AND dist[u] + weight < dist[v]:
                dist[v] = dist[u] + weight

    # Check for negative-weight cycles
    FOR (u, v, weight) in edges:
        IF dist[u] != INF AND dist[u] + weight < dist[v]:
            RETURN "Negative Weight Cycle Detected"

    RETURN dist
```

### Concise C++ Implementation

```cpp
#include <iostream>
#include <vector>
#include <climits>
using namespace std;

struct Edge { char u, v; int weight; };

int main() {
    // Lab Example: Electric delivery vehicle energy consumption
    const int V = 5; // S=0, A=1, B=2, C=3, D=4
    vector<Edge> edges = {
        {'S', 'A', 4}, {'S', 'B', 5}, {'A', 'B', -2}, {'A', 'C', 6},
        {'B', 'C', 3}, {'B', 'D', 4}, {'C', 'D', -1}, {'D', 'A', 2}
    };

    const int INF = 1e9;
    vector<int> dist(V, INF);
    dist[0] = 0; // S is source

    // Relax all edges V - 1 times
    for (int iter = 1; iter <= V - 1; ++iter) {
        for (const auto& e : edges) {
            int u = (e.u == 'S') ? 0 : (e.u - 'A' + 1);
            int v = (e.v == 'S') ? 0 : (e.v - 'A' + 1);
            if (dist[u] != INF && dist[u] + e.weight < dist[v]) {
                dist[v] = dist[u] + e.weight;
            }
        }
    }

    // Check for negative-weight cycles
    bool hasNegativeCycle = false;
    for (const auto& e : edges) {
        int u = (e.u == 'S') ? 0 : (e.u - 'A' + 1);
        int v = (e.v == 'S') ? 0 : (e.v - 'A' + 1);
        if (dist[u] != INF && dist[u] + e.weight < dist[v]) {
            hasNegativeCycle = true;
            break;
        }
    }

    if (hasNegativeCycle) cout << "Negative Weight Cycle Detected!\n";
    else {
        cout << "Shortest Energy Paths from S:\n";
        const char names[] = {'S', 'A', 'B', 'C', 'D'};
        for (int i = 0; i < V; ++i)
            cout << "  To " << names[i] << " : " << dist[i] << " kWh\n";
    }
    return 0;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
Shortest Energy Paths from S:
  To S : 0 kWh
  To A : 4 kWh
  To B : 2 kWh
  To C : 5 kWh
  To D : 4 kWh
```

### Cheese Code: Triple Loop Bellman-Ford (12 Lines)
**Why it works in the exam:** Bellman-Ford is fundamentally just a loop of V-1 passes over an edge list!

```cpp
#include <bits/stdc++.h>
using namespace std;
int main() {
    vector<tuple<int,int,int>> e = {{0,1,4},{0,2,5},{1,2,-2},{1,3,6},{2,3,3},{2,4,4},{3,4,-1},{4,1,2}};
    vector<int> d(5, 1e9); d[0] = 0;
    for (int i = 0; i < 4; ++i)
        for (auto [u, v, w] : e)
            if (d[u] < 1e9 && d[u] + w < d[v]) d[v] = d[u] + w;
    for (int i = 0; i < 5; ++i) cout << "To " << i << ": " << d[i] << "\n";
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
To 0: 0
To 1: 4
To 2: 2
To 3: 5
To 4: 4
```

### Silly Mistakes & Traps: Bellman-Ford
1. **Integer Overflow with `INT_MAX`:** Setting `INF = INT_MAX` causes `dist[u] + weight` to overflow into negative numbers! Always check `dist[u] != INF` before adding, or set `INF = 1e9`.
2. **Vertex Mapping Offsets:** When mixing node 'S' with letters 'A'-'D', ensure consistent 0-based indexing ($S=0, A=1, B=2, …$).

**Complexity:** best O(E) · average O(V E) · worst O(V E) · auxiliary space O(V) distance vector  
**Recurrence:** V-1 iterations over all E edges => O(V E)

## Your lab-report programs

### Your Lab 9 Q3 program (per-iteration trace + negative-cycle check)

```cpp
#include <iostream>
#include <vector>
#include <climits>
using namespace std;

struct Edge {
    int u, v, weight;
};

int main() {
    int V = 5;
    const int INF = 1e9;

    vector<Edge> edges = {
        {0,1,5}, {0,2,6}, {1,2,-3}, {1,3,7},
        {2,3,2}, {2,4,5}, {3,4,-2}, {4,1,1}
    };

    vector<string> names = {"S","A","B","C","D"};
    vector<int> dist(V, INF);
    dist[0] = 0;

    cout << "Bellman-Ford Relaxation Iterations:\n";

    for (int i = 1; i <= V - 1; i++) {
        bool updated = false;

        for (const auto& e : edges) {
            if (dist[e.u] != INF &&
                dist[e.u] + e.weight < dist[e.v]) {
                dist[e.v] = dist[e.u] + e.weight;
                updated = true;
            }
        }

        cout << "Iteration " << i << ": ";
        for (int j = 0; j < V; j++) {
            if (dist[j] == INF)
                cout << names[j] << "=INF ";
            else
                cout << names[j] << "=" << dist[j] << " ";
        }
        cout << "\n";

        if (!updated)
            break;
    }

    bool negativeCycle = false;

    for (const auto& e : edges) {
        if (dist[e.u] != INF &&
            dist[e.u] + e.weight < dist[e.v]) {
            negativeCycle = true;
            break;
        }
    }

    cout << "\nShortest Distances from S:\n";
    for (int i = 0; i < V; i++)
        cout << "S -> " << names[i] << " = " << dist[i] << "\n";

    cout << "\nNegative-weight cycle: "
         << (negativeCycle ? "Yes" : "No") << "\n";

    return 0;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
Bellman-Ford Relaxation Iterations:
Iteration 1: S=0 A=3 B=2 C=4 D=2 
Iteration 2: S=0 A=1 B=0 C=2 D=0 
Iteration 3: S=0 A=-1 B=-2 C=0 D=-2 
Iteration 4: S=0 A=-3 B=-4 C=-2 D=-4 

Shortest Distances from S:
S -> S = 0
S -> A = -3
S -> B = -4
S -> C = -2
S -> D = -4

Negative-weight cycle: Yes
```
