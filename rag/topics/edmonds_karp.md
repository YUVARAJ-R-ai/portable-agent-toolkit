# Edmonds-Karp Algorithm for Maximum Network Flow

The Edmonds-Karp algorithm is an explicit, strongly polynomial implementation of the Ford-Fulkerson method that computes the maximum flow in a network by finding augmenting paths using **Breadth-First Search (BFS)**. Category: Network Flow Algorithms.

---

## 1. Algorithmic Invariants & Critical Pitfalls

### Key Difference from Classical Ford-Fulkerson
While the general Ford-Fulkerson method allows any search strategy (often DFS), Edmonds-Karp **strictly uses Breadth-First Search (BFS)** to choose an augmenting path with the **fewest number of edges** (shortest augmenting path in unweighted residual graph).

### Theoretical Guarantees
1. **Shortest Path Monotonicity**:
   For all vertices $v \in V \setminus \{s, t\}$, the shortest-path distance $\delta_{G_f}(s, v)$ in the residual network never decreases after any flow augmentation:
   $$\delta_{G_{f'}}(s, v) \ge \delta_{G_f}(s, v)$$
2. **Critical Edge Upper Bound**:
   An edge is deemed *critical* if it is the bottleneck edge of an augmenting path. An edge can become critical at most $|V| / 2$ times before it can never be used again in that direction.
3. **Strongly Polynomial Time**:
   Because each of the $2E$ directed edges can become critical at most $|V| / 2$ times, the total number of flow augmentations is strictly bounded by:
   $$O(V \cdot E)$$
   Since each BFS traversal takes $O(E)$ time, the overall worst-case runtime is strictly:
   $$O(V \cdot E^2)$$
   Unlike DFS-based Ford-Fulkerson, this runtime is completely independent of the numerical capacity values.

### Critical Implementation Rules
1. **Parent Array Pointer Maintenance**:
   During BFS, maintain `parent[v]` representing the predecessor of $v$ on the shortest augmenting path.
2. **Path Reconstruction & Bottleneck Calculation**:
   Backtrack from sink $t$ to source $s$ using `parent`:
   $$\Delta = \min_{(u, v) \in \text{path}} \text{resCapacity}[u][v]$$
3. **Double Edge Residual Update**:
   Update both forward and reverse edges simultaneously:
   $$\text{resCapacity}[u][v] \leftarrow \text{resCapacity}[u][v] - \Delta$$
   $$\text{resCapacity}[v][u] \leftarrow \text{resCapacity}[v][u] + \Delta$$

---

## 2. Canonical C++ Implementation (BFS-Based)

```cpp
#include <iostream>
#include <vector>
#include <queue>
#include <algorithm>

using namespace std;

const long long INF = 1e15;

class EdmondsKarp {
private:
    int V;
    vector<vector<long long>> capacity;
    vector<vector<long long>> resCapacity;
    vector<int> parent;

    // BFS to find the shortest augmenting path (fewest edges) from s to t
    long long bfs(int s, int t) {
        fill(parent.begin(), parent.end(), -1);
        parent[s] = -2; // Mark source visited

        // Pair: {current_node, bottleneck_flow_so_far}
        queue<pair<int, long long>> q;
        q.push({s, INF});

        while (!q.empty()) {
            int u = q.front().first;
            long long flow = q.front().second;
            q.pop();

            for (int v = 0; v < V; ++v) {
                // If unvisited and has positive residual capacity
                if (parent[v] == -1 && resCapacity[u][v] > 0) {
                    parent[v] = u;
                    long long newFlow = min(flow, resCapacity[u][v]);
                    if (v == t) {
                        return newFlow; // Reached sink!
                    }
                    q.push({v, newFlow});
                }
            }
        }
        return 0; // No augmenting path found
    }

public:
    EdmondsKarp(int vertices) : V(vertices) {
        capacity.assign(V, vector<long long>(V, 0));
        resCapacity.assign(V, vector<long long>(V, 0));
        parent.assign(V, -1);
    }

    void addEdge(int u, int v, long long cap) {
        capacity[u][v] += cap;
        resCapacity[u][v] += cap;
    }

    long long maxFlow(int s, int t) {
        long long totalFlow = 0;
        long long newFlow = 0;

        // Augment flow as long as a BFS augmenting path exists
        while ((newFlow = bfs(s, t)) > 0) {
            totalFlow += newFlow;
            int curr = t;
            // Backtrack and apply the flow update along the augmenting path
            while (curr != s) {
                int prev = parent[curr];
                resCapacity[prev][curr] -= newFlow;
                resCapacity[curr][prev] += newFlow;
                curr = prev;
            }
        }
        return totalFlow;
    }

    vector<pair<int, int>> getMinCutEdges(int s) {
        // Run BFS on residual graph to find reachable vertices from s
        vector<bool> reachable(V, false);
        queue<int> q;
        q.push(s);
        reachable[s] = true;

        while (!q.empty()) {
            int u = q.front();
            q.pop();
            for (int v = 0; v < V; ++v) {
                if (!reachable[v] && resCapacity[u][v] > 0) {
                    reachable[v] = true;
                    q.push(v);
                }
            }
        }

        vector<pair<int, int>> minCutEdges;
        for (int u = 0; u < V; ++u) {
            if (reachable[u]) {
                for (int v = 0; v < V; ++v) {
                    if (!reachable[v] && capacity[u][v] > 0) {
                        minCutEdges.push_back({u, v});
                    }
                }
            }
        }
        return minCutEdges;
    }
};

int main() {
    int V = 6;
    EdmondsKarp ek(V);

    // Source = 0, Sink = 5
    ek.addEdge(0, 1, 16);
    ek.addEdge(0, 2, 13);
    ek.addEdge(1, 2, 10);
    ek.addEdge(1, 3, 12);
    ek.addEdge(2, 1, 4);
    ek.addEdge(2, 4, 14);
    ek.addEdge(3, 2, 9);
    ek.addEdge(3, 5, 20);
    ek.addEdge(4, 3, 7);
    ek.addEdge(4, 5, 4);

    long long maxFlowVal = ek.maxFlow(0, 5);
    cout << "Maximum Flow (Edmonds-Karp): " << maxFlowVal << "\n";

    vector<pair<int, int>> minCut = ek.getMinCutEdges(0);
    cout << "Min-Cut Edges (Bottleneck Constraints):\n";
    for (const auto& edge : minCut) {
        cout << edge.first << " -> " << edge.second << "\n";
    }
    return 0;
}
```

---

## 3. Twisted Exam Variations & Implementations

### Variation 1: Maximum Number of Edge-Disjoint Paths
- **Scenario Keywords**: "Completely independent routing paths", "no shared communication links", "Menger's theorem edge connectivity".
- **Core Concept**:
  Two paths are *edge-disjoint* if they share no edges.
  - Set the capacity of every directed edge in the graph to $1$.
  - Run Edmonds-Karp from source $s$ to sink $t$.
  - The maximum flow value equals the maximum number of edge-disjoint paths!
  - To reconstruct individual paths: trace edges where flow was pushed (`resCapacity[v][u] == 1`).

```cpp
int maxEdgeDisjointPaths(int V, int s, int t, const vector<pair<int, int>>& directedEdges) {
    EdmondsKarp ek(V);
    for (const auto& e : directedEdges) {
        ek.addEdge(e.first, e.second, 1); // Unit capacity for all edges
    }
    return ek.maxFlow(s, t);
}
```

---

### Variation 2: Multi-Source, Multi-Sink Network Flow
- **Scenario Keywords**: "Multiple production factories and multiple consumer warehouses", "multi-source distribution".
- **Core Concept**:
  Given a set of sources $S = \{s_1, s_2, \dots, s_k\}$ with supplies $C(s_i)$ and sinks $T = \{t_1, t_2, \dots, t_m\}$ with demands $C(t_j)$.
- **Supersource / Supersink Transformation**:
  1. Introduce a single **Supersource** $S^*$.
  2. For each original source $s_i$, add directed edge $S^* \to s_i$ with capacity $C(s_i)$.
  3. Introduce a single **Supersink** $T^*$.
  4. For each original sink $t_j$, add directed edge $t_j \to T^*$ with capacity $C(t_j)$.
  5. Run Edmonds-Karp with source $S^*$ and sink $T^*$.

```cpp
long long multiSourceMultiSinkFlow(int V,
    const vector<pair<int, long long>>& sources, // {node_id, supply}
    const vector<pair<int, long long>>& sinks,   // {node_id, demand}
    const vector<tuple<int, int, long long>>& networkEdges) {

    int superSource = V;
    int superSink = V + 1;
    EdmondsKarp ek(V + 2);

    // 1. Connect SuperSource to each source with its production supply
    for (const auto& src : sources) {
        ek.addEdge(superSource, src.first, src.second);
    }

    // 2. Add all internal network links
    for (const auto& e : networkEdges) {
        ek.addEdge(get<0>(e), get<1>(e), get<2>(e));
    }

    // 3. Connect each sink to SuperSink with its consumption demand
    for (const auto& snk : sinks) {
        ek.addEdge(snk.first, superSink, snk.second);
    }

    return ek.maxFlow(superSource, superSink);
}
```

---

### Variation 3: Image Segmentation & Min-Cut Graph Cuts
- **Scenario Keywords**: "Foreground vs background pixel segmentation", "binary energy minimization", "graph cut".
- **Core Concept**:
  - Each pixel $i$ has a penalty $a_i$ for being background and $b_i$ for being foreground.
  - Neighboring pixels $i, j$ incur boundary penalty $p_{ij}$ if assigned to different segments.
  - Connect Supersource $s$ to each pixel $i$ with capacity $a_i$.
  - Connect each pixel $i$ to Supersink $t$ with capacity $b_i$.
  - Connect adjacent pixels $i, j$ with capacity $p_{ij}$.
  - The Minimum $s$-$t$ cut uniquely partitions the pixels into Foreground ($S$) and Background ($T$) minimizing total energy.

---

# FAT Lab-Exam Version & Your Lab Programs (BCSE204P, Dr. Sakthivel R)

Every program below was extracted from your lab reports / FAT guide, compiled with `g++ -std=c++17 -Wall -O2`, and run; outputs shown are the real program output.

## Lab questions & verified answers

| Lab question | Scenario & input data | Verified answer |
|---|---|---|
| Lab 9 Q1 / FAT | Oxygen: S→A 14, S→B 8, A→B 10, A→C 12, B→D 11, C→B 3, C→T 15, D→C 5, D→T 9 | 12 + 8 + 1 + 1 → **22 L/min** |
| Lab 8 Q1 | Data center: S→A 10, S→B 5, A→B 15, A→C 9, B→D 8, C→B 4, C→T 10, D→C 6, D→T 10 | 9 + 5 + 1 → **15 Gbps** |
| Lab 8 Q3 | Airport shuttle: S→A 12, S→B 10, A→C 8, A→D 4, B→A 3, B→D 7, C→T 10, D→C 5, D→T 8 | 8 + 4 + 4 + 2 → **18 passengers/hour** |

## Maximum Flow: Edmonds-Karp Algorithm (BFS)

### Edmonds-Karp Maximum Flow
**Lab scenario:** Deep-Space Oxygen Gas Routing & Data Center Bandwidth Transmission (Source S to Sink T)

Given a directed capacity graph $G = (V, E)$ with source $S$ and sink $T$, find the maximum flow that can be routed from $S$ to $T$ such that capacity constraints ($0 <= f(u, v) <= c(u, v)$) and flow conservation are preserved.

**Edmonds-Karp Mechanism:** Uses Breadth-First Search (BFS) to find the shortest augmenting path (fewest edges) in the residual network at each iteration. This guarantees $O(V E^2)$ runtime and avoids infinite loops with irrational capacities.

### Algorithm: EdmondsKarp
```python
EdmondsKarp(cap, source, sink):
    res = copy(cap)
    max_flow = 0

    WHILE (bottleneck, parent) = BFS(res, source, sink):
        max_flow = max_flow + bottleneck
        v = sink
        WHILE v != source:
            u = parent[v]
            res[u][v] = res[u][v] - bottleneck
            res[v][u] = res[v][u] + bottleneck     # Crucial reverse edge
            v = u

    RETURN max_flow

BFS(res, s, t):
    parent = [-1 for _ in range(V)]
    q = Queue(); q.push((s, INF))

    WHILE NOT q.empty():
        (u, flow) = q.pop()
        FOR v = 0 TO V - 1:
            IF parent[v] == -1 AND v != s AND res[u][v] > 0:
                parent[v] = u
                new_flow = min(flow, res[u][v])
                IF v == t: RETURN (new_flow, parent)
                q.push((v, new_flow))

    RETURN 0
```

### Step-by-Step BFS Augmentation Path Trace (Oxygen Routing)
| **Iter** | **Augmenting Path Found via BFS** | **Bottleneck** | **Total Flow** | **Residual Network Capacity Updates** |
|---|---|---|---|---|
| 1 | $S -> A -> C -> T$ | 12 | 12 | $S->A: 14-12=2$; $A->C: 12-12=0$; $C->T: 15-12=3$. Reverse edges added. |
| 2 | $S -> B -> D -> T$ | 8 | 20 | $S->B: 8-8=0$; $B->D: 11-8=3$; $D->T: 9-8=1$. Path saturated. |
| 3 | $S -> A -> B -> D -> T$ | 1 | 21 | $S->A: 2-1=1$; $A->B: 10-1=9$; $B->D: 3-1=2$; $D->T: 1-1=0$. |
| 4 | $S -> A -> B -> D -> C -> T$ | 1 | 22 | $S->A: 1-1=0$; $A->B: 9-1=8$; $B->D: 2-1=1$; $D->C: 5-1=4$; $C->T: 3-1=2$. |
| 5 | No path from $S$ to $T$ in residual network | 0 | **22** | Sink $T$ unreachable from source $S$. BFS returns 0. Algorithm terminates. |

**Key Residual Edge Mechanism:** In Iteration 4, the path routes through $D -> C$, utilizing the residual capacity to fill the remaining 1 unit of capacity to $T$ via $C -> T$.

### Concise C++ Implementation (With Path Logging)

```cpp
#include <iostream>
#include <vector>
#include <queue>
#include <climits>
#include <algorithm>
using namespace std;

const int NUM_NODES = 6; // S=0, A=1, B=2, C=3, D=4, T=5
const char NAMES[] = {'S', 'A', 'B', 'C', 'D', 'T'};

int bfs(const vector<vector<int>>& residual, int s, int t, vector<int>& parent) {
    fill(parent.begin(), parent.end(), -1);
    queue<pair<int, int>> q;
    q.push({s, INT_MAX});

    while (!q.empty()) {
        auto [u, flow] = q.front();
        q.pop();

        for (int v = 0; v < NUM_NODES; ++v) {
            if (parent[v] == -1 && v != s && residual[u][v] > 0) {
                parent[v] = u;
                int new_flow = min(flow, residual[u][v]);
                if (v == t) return new_flow;
                q.push({v, new_flow});
            }
        }
    }
    return 0;
}

int edmondsKarp(vector<vector<int>>& cap, int s, int t) {
    vector<vector<int>> res = cap;
    vector<int> parent(NUM_NODES);
    int max_flow = 0, iter = 1;

    cout << "=== Augmentation Iterations ===\n";
    while (int bottleneck = bfs(res, s, t, parent)) {
        max_flow += bottleneck;

        vector<int> path;
        for (int v = t; v != s; v = parent[v]) path.push_back(v);
        path.push_back(s);
        reverse(path.begin(), path.end());

        cout << "Iteration " << iter++ << ": Path = ";
        for (size_t i = 0; i < path.size(); ++i)
            cout << NAMES[path[i]] << (i + 1 < path.size() ? " -> " : "");
        cout << " | Bottleneck = " << bottleneck << " | Cumulative = " << max_flow << "\n";

        for (int v = t; v != s; v = parent[v]) {
            int u = parent[v];
            res[u][v] -= bottleneck;
            res[v][u] += bottleneck; // Crucial reverse edge
        }
    }
    return max_flow;
}

int main() {
    // Lab Example: Oxygen routing network
    vector<vector<int>> cap(NUM_NODES, vector<int>(NUM_NODES, 0));
    cap[0][1] = 14; // S -> A
    cap[0][2] = 8;  // S -> B
    cap[1][2] = 10; // A -> B
    cap[1][3] = 12; // A -> C
    cap[2][4] = 11; // B -> D
    cap[3][2] = 3;  // C -> B
    cap[3][5] = 15; // C -> T
    cap[4][3] = 5;  // D -> C
    cap[4][5] = 9;  // D -> T

    int maxFlow = edmondsKarp(cap, 0, 5);
    cout << "Final Maximum Flow: " << maxFlow << " L/min\n";
    return 0;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
### Augmentation Iterations ===
Iteration 1: Path = S -> A -> C -> T | Bottleneck = 12 | Cumulative = 12
Iteration 2: Path = S -> B -> D -> T | Bottleneck = 8 | Cumulative = 20
Iteration 3: Path = S -> A -> B -> D -> T | Bottleneck = 1 | Cumulative = 21
Iteration 4: Path = S -> A -> B -> D -> C -> T | Bottleneck = 1 | Cumulative = 22
Final Maximum Flow: 22 L/min
```

### Cheese Code: Clean 15-Line Matrix Edmonds-Karp
**Why it works in the exam:** A compact matrix-based Edmonds-Karp is simple to write and gives 100% full marks on any maximum flow problem!

```cpp
#include <bits/stdc++.h>
using namespace std;
int cap[6][6], parent[6];
int bfs(int s, int t) {
    memset(parent, -1, sizeof(parent));
    queue<pair<int,int>> q; q.push({s, 1e9});
    while (!q.empty()) {
        auto [u, f] = q.front(); q.pop();
        for (int v = 0; v < 6; ++v) if (parent[v] == -1 && v != s && cap[u][v] > 0) {
            parent[v] = u;
            int nf = min(f, cap[u][v]);
            if (v == t) return nf;
            q.push({v, nf});
        }
    }
    return 0;
}
int main() {
    cap[0][1]=14; cap[0][2]=8; cap[1][2]=10; cap[1][3]=12; cap[2][4]=11; cap[3][2]=3; cap[3][5]=15; cap[4][3]=5; cap[4][5]=9;
    int flow = 0, b;
    while ((b = bfs(0, 5))) {
        flow += b;
        for (int v = 5; v != 0; v = parent[v]) { cap[parent[v]][v] -= b; cap[v][parent[v]] += b; }
    }
    cout << "Max Flow: " << flow << endl;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
Max Flow: 22
```

### Silly Mistakes & Traps: Network Flows
1. **Forgetting Reverse Residual Edge:** Writing only `res[u][v] -= bottleneck` without `res[v][u] += bottleneck` prevents flow push-back. The algorithm will get permanently stuck in a sub-optimal local bottleneck!
2. **Reusing Visited/Parent Arrays Without Reset:** In the BFS loop, you MUST reset `parent` and `visited` at every iteration. Otherwise old search paths corrupt the next iteration.
3. **Using DFS instead of BFS:** DFS (pure Ford-Fulkerson) can take $O(E · |f|)$ iterations and loop exponentially on pathological networks. In exams, BFS (Edmonds-Karp) is always safer.

**Complexity:** best O(V E) · average O(V E^2) · worst O(V E^2) · auxiliary space O(V^2) matrix or O(V+E)  
**Recurrence:** At most O(V E) augmentations, each BFS takes O(E) => O(V E^2)
