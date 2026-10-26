# Ford-Fulkerson Method for Maximum Network Flow

The Ford-Fulkerson method computes the maximum possible flow from a designated source vertex $s$ to a sink vertex $t$ in a directed network with non-negative edge capacities. It is grounded in the fundamental **Max-Flow Min-Cut Theorem**. Category: Network Flow Algorithms.

---

## 1. Algorithmic Invariants & Critical Pitfalls

### The Residual Graph ($G_f$)
For each directed edge $(u, v)$ with original capacity $C(u, v)$ and current flow $F(u, v)$:
- **Forward Edge Residual Capacity**:
  $$C_f(u, v) = C(u, v) - F(u, v)$$
  (represents remaining capacity that can still be sent from $u$ to $v$)
- **Backward (Reverse) Edge Residual Capacity**:
  $$C_f(v, u) = F(u, v)$$
  (represents flow that can be "undone" or redirected back from $v$ to $u$)

### Critical Implementation Rules
1. **Flow Augmentation Mechanism**:
   Find any path $P$ from $s$ to $t$ in $G_f$ where all edges have $C_f > 0$. The bottleneck capacity of the path is:
   $$\Delta = \min_{(u, v) \in P} C_f(u, v)$$
   For each edge on the path:
   $$\text{res}[u][v] \leftarrow \text{res}[u][v] - \Delta$$
   $$\text{res}[v][u] \leftarrow \text{res}[v][u] + \Delta$$
2. **Reverse Edge Initialization**:
   Always initialize reverse edge capacity `res[v][u] = 0` (or `res[v][u] += capacity` if bidirectional). Never leave it uninitialized!
3. **Max-Flow Min-Cut Theorem**:
   $$\text{Value of Maximum Flow} = \text{Capacity of Minimum } s\text{-}t \text{ Cut}$$
   When no augmenting path exists in $G_f$, partition $V$ into $S$ (vertices reachable from $s$ in $G_f$) and $T = V \setminus S$. The edges in the original graph originating in $S$ and terminating in $T$ constitute the minimum cut.
4. **Augmenting Path Strategy**:
   The classical Ford-Fulkerson method uses **Depth-First Search (DFS)** to find augmenting paths.
   *(Note: Using BFS instead of DFS guarantees polynomial runtime $O(V \cdot E^2)$, known specifically as the Edmonds-Karp algorithm).*

### Complexity
- **Time Complexity**: $O(E \cdot |f^*|)$ where $|f^*|$ is the maximum flow value (pseudo-polynomial with integer capacities).
- **Space Complexity**: $O(V^2)$ (residual capacity matrix) or $O(V + E)$ (adjacency list with reverse edge pointers).

---

## 2. Canonical C++ Implementation (DFS-Based)

```cpp
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

const long long INF = 1e15;

class FordFulkerson {
private:
    int V;
    vector<vector<long long>> capacity;
    vector<vector<long long>> resCapacity;
    vector<bool> visited;

    // DFS to find augmenting path and return bottleneck flow along path
    long long dfs(int u, int t, long long currentFlow) {
        if (u == t) return currentFlow;
        visited[u] = true;

        for (int v = 0; v < V; ++v) {
            if (!visited[v] && resCapacity[u][v] > 0) {
                long long bottleneck = dfs(v, t, min(currentFlow, resCapacity[u][v]));
                if (bottleneck > 0) {
                    // Augment flow: decrement forward, increment reverse
                    resCapacity[u][v] -= bottleneck;
                    resCapacity[v][u] += bottleneck;
                    return bottleneck;
                }
            }
        }
        return 0;
    }

public:
    FordFulkerson(int vertices) : V(vertices) {
        capacity.assign(V, vector<long long>(V, 0));
        resCapacity.assign(V, vector<long long>(V, 0));
        visited.assign(V, false);
    }

    void addEdge(int u, int v, long long cap) {
        capacity[u][v] += cap;
        resCapacity[u][v] += cap;
    }

    long long maxFlow(int s, int t) {
        long long totalFlow = 0;

        while (true) {
            fill(visited.begin(), visited.end(), false);
            long long pushed = dfs(s, t, INF);
            if (pushed == 0) break; // No more augmenting paths found
            totalFlow += pushed;
        }

        return totalFlow;
    }

    // Identifies vertices in partition S and the edges forming the Minimum Cut
    void printMinCut(int s) {
        fill(visited.begin(), visited.end(), false);
        // Reachability DFS in final residual graph
        vector<int> stack = {s};
        visited[s] = true;
        while (!stack.empty()) {
            int u = stack.back();
            stack.pop_back();
            for (int v = 0; v < V; ++v) {
                if (!visited[v] && resCapacity[u][v] > 0) {
                    visited[v] = true;
                    stack.push_back(v);
                }
            }
        }

        cout << "--- Minimum s-t Cut Edges (Bottle-neck Links) ---\n";
        long long cutCapacity = 0;
        for (int u = 0; u < V; ++u) {
            if (visited[u]) {
                for (int v = 0; v < V; ++v) {
                    if (!visited[v] && capacity[u][v] > 0) {
                        cout << u << " -> " << v << " (Capacity: " << capacity[u][v] << ")\n";
                        cutCapacity += capacity[u][v];
                    }
                }
            }
        }
        cout << "Total Cut Capacity: " << cutCapacity << "\n";
    }
};

int main() {
    // 6-node flow network: 0 = source, 5 = sink
    int V = 6;
    FordFulkerson ff(V);

    ff.addEdge(0, 1, 16);
    ff.addEdge(0, 2, 13);
    ff.addEdge(1, 2, 10);
    ff.addEdge(1, 3, 12);
    ff.addEdge(2, 1, 4);
    ff.addEdge(2, 4, 14);
    ff.addEdge(3, 2, 9);
    ff.addEdge(3, 5, 20);
    ff.addEdge(4, 3, 7);
    ff.addEdge(4, 5, 4);

    long long maxFlowVal = ff.maxFlow(0, 5);
    cout << "Maximum Flow from 0 to 5: " << maxFlowVal << "\n";

    ff.printMinCut(0);
    return 0;
}
```

---

## 3. Twisted Exam Variations & Implementations

### Variation 1: Minimum $s$-$t$ Cut & Critical Bottleneck Edge Detection
- **Scenario Keywords**: "Identify weakest links in communication grid", "minimum capacity cut", "critical bottleneck links".
- **Core Concept**:
  1. Solve Max Flow.
  2. Run DFS/BFS from source $s$ on the residual graph to find set $S = \{v \in V \mid \text{reachable from } s \text{ with } C_f > 0\}$.
  3. The Min-Cut consists of all edges $(u, v)$ where $u \in S$, $v \notin S$, and original capacity $C(u, v) > 0$.
  4. Total capacity of these edges strictly equals the Max Flow value.

---

### Variation 2: Maximum Cardinality Bipartite Matching (MCBM)
- **Scenario Keywords**: "Assign tasks to workers", "doctors to hospitals", "maximum matching in bipartite graph".
- **Core Concept**:
  - Given two disjoint sets of nodes: Left set $L$ (size $N_1$) and Right set $R$ (size $N_2$).
  - Add a **Supersource** $s$ connected to every $u \in L$ with capacity $1$.
  - Add a **Supersink** $t$ connected from every $v \in R$ with capacity $1$.
  - For each valid match between $u \in L$ and $v \in R$, add edge $u \to v$ with capacity $1$.
  - Run Ford-Fulkerson: $\text{Maximum Cardinality Matching} = \text{Max Flow}$.

```cpp
int solveBipartiteMatching(int N1, int N2, const vector<pair<int, int>>& matchingEdges) {
    int s = 0;
    int t = N1 + N2 + 1;
    int totalVertices = t + 1;
    FordFulkerson flow(totalVertices);

    // 1. Source to Left vertices (1 .. N1) with capacity 1
    for (int i = 1; i <= N1; ++i) flow.addEdge(s, i, 1);

    // 2. Left vertices to Right vertices (N1 + 1 .. N1 + N2) with capacity 1
    for (const auto& edge : matchingEdges) {
        int u = edge.first;            // 1 <= u <= N1
        int v = N1 + edge.second;      // 1 <= edge.second <= N2
        flow.addEdge(u, v, 1);
    }

    // 3. Right vertices to Sink with capacity 1
    for (int j = 1; j <= N2; ++j) flow.addEdge(N1 + j, t, 1);

    return flow.maxFlow(s, t);
}
```

---

### Variation 3: Flow Networks with Vertex Throughput Limits (Node Capacities)
- **Scenario Keywords**: "Routers have processing throughput limits", "junction maximum capacity", "node limits".
- **Core Concept**:
  Each vertex $v$ has a maximum throughput capacity $C_v$.
- **Transformation (Node Splitting)**:
  Split each vertex $v$ into two nodes: $v_{\text{in}}$ and $v_{\text{out}}$.
  - Add a directed edge $v_{\text{in}} \to v_{\text{out}}$ with capacity $C_v$.
  - All original incoming edges to $v$ now enter $v_{\text{in}}$.
  - All original outgoing edges from $v$ now leave $v_{\text{out}}$.
  - Source and sink can be given $C_s = C_t = \infty$.
  - Solve standard Max Flow on the transformed network.

---

# FAT Lab-Exam Version & Your Lab Programs (BCSE204P, Dr. Sakthivel R)

Every program below was extracted from your lab reports / FAT guide, compiled with `g++ -std=c++17 -Wall -O2`, and run; outputs shown are the real program output.

## Lab questions & verified answers

| Lab question | Scenario & input data | Verified answer |
|---|---|---|
| Lab 8 Q2 | Evacuation: S→A 10, S→B 8, A→C 5, A→B 4, B→C 6, B→D 3, C→T 7, D→T 5 | paths S-A-C-T 5, S-B-C-T 2, S-B-D-T 3 → **10 people/hour** |

## Your lab-report programs

### Your Lab 8 Q2 program (Ford-Fulkerson)

```cpp
#include <iostream>
#include <vector>
#include <queue>
#include <algorithm>
#include <climits>
#include <string>

using namespace std;

const int V = 6;

// Helper function to map node indices to character labels
string getNodeLabel(int i) {
    string labels[] = {"S", "A", "B", "C", "D", "T"};
    return labels[i];
}

// Breadth-First Search (BFS) to find an augmenting path in the residual graph
bool bfs(int rGraph[V][V], int s, int t, int parent[]) {
    vector<bool> visited(V, false);
    queue<int> q;
    q.push(s);
    visited[s] = true;
    parent[s] = -1;

    while (!q.empty()) {
        int u = q.front();
        q.pop();

        for (int v = 0; v < V; v++) {
            if (!visited[v] && rGraph[u][v] > 0) {
                if (v == t) {
                    parent[v] = u;
                    return true;
                }
                q.push(v);
                visited[v] = true;
                parent[v] = u;
            }
        }
    }
    return false;
}

// Ford-Fulkerson algorithm function
int fordFulkerson(int graph[V][V], int s, int t) {
    int u, v;

    // Create a residual graph and initialize residual capacities with original capacities
    int rGraph[V][V];
    for (u = 0; u < V; u++) {
        for (v = 0; v < V; v++) {
            rGraph[u][v] = graph[u][v];
        }
    }

    int parent[V];
    int max_flow = 0;
    int iteration = 1;

    cout << "=== Augmentation Steps ===\n";

    // Augment the flow while an augmenting path exists from source to sink
    while (bfs(rGraph, s, t, parent)) {
        int path_flow = INT_MAX;

        // Find the bottleneck capacity along the BFS path
        for (v = t; v != s; v = parent[v]) {
            u = parent[v];
            path_flow = min(path_flow, rGraph[u][v]);
        }

        // Reconstruct path for printing
        vector<int> path;
        for (v = t; v != s; v = parent[v]) {
            path.push_back(v);
        }
        path.push_back(s);
        reverse(path.begin(), path.end());

        cout << "Iteration " << iteration++ << ": Path ";
        for (size_t i = 0; i < path.size(); i++) {
            cout << getNodeLabel(path[i]) << (i + 1 < path.size() ? " -> " : "");
        }
        cout << " | Bottleneck: " << path_flow << "\n";

        // Update residual capacities of the edges and reverse edges
        for (v = t; v != s; v = parent[v]) {
            u = parent[v];
            rGraph[u][v] -= path_flow;
            rGraph[v][u] += path_flow;
        }

        max_flow += path_flow;
    }

    return max_flow;
}

int main() {
    // Node mapping: S=0, A=1, B=2, C=3, D=4, T=5
    int graph[V][V] = {0};

    // Capacity definitions
    graph[0][1] = 10; // S -> A
    graph[0][2] = 8;  // S -> B
    graph[1][3] = 5;  // A -> C
    graph[1][2] = 4;  // A -> B
    graph[2][3] = 6;  // B -> C
    graph[2][4] = 3;  // B -> D
    graph[3][5] = 7;  // C -> T
    graph[4][5] = 5;  // D -> T

    int source = 0; // S
    int sink = 5;   // T

    int max_flow = fordFulkerson(graph, source, sink);

    cout << "\nMaximum Evacuation Flow Rate: " << max_flow << " people per hour\n";

    return 0;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
=== Augmentation Steps ===
Iteration 1: Path S -> A -> C -> T | Bottleneck: 5
Iteration 2: Path S -> B -> C -> T | Bottleneck: 2
Iteration 3: Path S -> B -> D -> T | Bottleneck: 3

Maximum Evacuation Flow Rate: 10 people per hour
```
