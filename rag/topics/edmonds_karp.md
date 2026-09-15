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
