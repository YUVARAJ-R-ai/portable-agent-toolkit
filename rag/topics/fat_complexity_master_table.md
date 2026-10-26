# FAT Master Time & Space Complexity Matrix (All Labs 1-11)

FAT guide master complexity table: paradigm, best/average/worst time and space for every lab algorithm (FAT Module 11). Category: Exam Reference.

---

Every program below was extracted from your lab reports / FAT guide, compiled with `g++ -std=c++17 -Wall -O2`, and run; outputs shown are the real program output.

#import "macros.typ": *

## Module 11: Master Time & Space Complexity Matrix

Below is the complete reference matrix of all algorithms taught across the DAA Lab curriculum (Labs 1–11), specifying design paradigm, asymptotic runtimes, space bounds, and mathematical recurrences.

| **Algorithm** | **Paradigm** | **Best Time** | **Average Time** | **Worst Time** | **Aux Space** |
|---|---|---|---|---|---|
| Activity Selection | Greedy | $Omega(n log n)$ | $Theta(n log n)$ | $O(n log n)$ | $O(1)$ |
| Huffman Coding | Greedy | $Omega(n log n)$ | $Theta(n log n)$ | $O(n log n)$ | $O(n)$ |
| Merge Sort | Divide & Conquer | $Omega(n log n)$ | $Theta(n log n)$ | $O(n log n)$ | $O(n)$ |
| K-Way Merge | Min-Heap / D&C | $Omega(N log K)$ | $Theta(N log K)$ | $O(N log K)$ | $O(K)$ |
| Quick Sort (Lomuto) | Divide & Conquer | $Omega(n log n)$ | $Theta(n log n)$ | $O(n^2)$ | $O(log n)$ |
| Max Subarray (D&C) | Divide & Conquer | $Omega(n log n)$ | $Theta(n log n)$ | $O(n log n)$ | $O(log n)$ |
| Max Subarray (Kadane) | Dynamic Prog. | $Omega(n)$ | $Theta(n)$ | $O(n)$ | $O(1)$ |
| Karatsuba Mult. | Divide & Conquer | $Omega(n^1.585)$ | $Theta(n^1.585)$ | $O(n^1.585)$ | $O(log n)$ |
| Assembly Line Sched. | Dynamic Prog. | $Omega(n)$ | $Theta(n)$ | $O(n)$ | $O(1)$ |
| Matrix Chain Mult. | Dynamic Prog. | $Omega(n^3)$ | $Theta(n^3)$ | $O(n^3)$ | $O(n^2)$ |
| 0/1 Knapsack (DP) | Dynamic Prog. | $Omega(n W)$ | $Theta(n W)$ | $O(n W)$ | $O(n W)$ |
| LCS (DP) | Dynamic Prog. | $Omega(m n)$ | $Theta(m n)$ | $O(m n)$ | $O(m n)$ |
| N-Queens | Backtracking | $Omega(N)$ | $Theta(N!)$ | $O(N!)$ | $O(N)$ |
| Job Selection (B&B) | Branch & Bound | $Omega(n log n)$ | $Theta(2^n)$ (pruned) | $O(2^n)$ | $O(n)$ |
| 0/1 Knapsack (LCBB) | Branch & Bound | $Omega(n log n)$ | $Theta(2^n)$ (pruned) | $O(2^n)$ | $O(2^n)$ |
| Edmonds-Karp (Max Flow) | Network Flow / BFS | $Omega(V E)$ | $Theta(V E^2)$ | $O(V E^2)$ | $O(V^2)$ |
| Ford-Fulkerson (DFS) | Network Flow / DFS | $Omega(E)$ | $Theta(E |f|)$ | $O(E |f|)$ | $O(V)$ |
| Kruskal's MST | Greedy (DSU) | $Omega(E log E)$ | $Theta(E log E)$ | $O(E log E)$ | $O(V)$ |
| Prim's MST | Greedy (Heap) | $Omega(E log V)$ | $Theta(E log V)$ | $O(E log V)$ | $O(V)$ |
| Bellman-Ford | Dynamic Prog. | $Omega(E)$ | $Theta(V E)$ | $O(V E)$ | $O(V)$ |
| Floyd-Warshall | Dynamic Prog. | $Omega(V^3)$ | $Theta(V^3)$ | $O(V^3)$ | $O(V^2)$ |
| Naive String Matching | Brute Force | $Omega(n)$ | $Theta(n + m)$ | $O((n - m + 1) m)$ | $O(1)$ |
| Rabin-Karp | Rolling Hash | $Omega(n + m)$ | $Theta(n + m)$ | $O((n - m + 1) m)$ | $O(1)$ |
| Knuth-Morris-Pratt | DFA / Prefix Table | $Omega(n + m)$ | $Theta(n + m)$ | $O(n + m)$ | $O(m)$ |
| Segment Intersection | Sweep-Line | $Omega(n log n)$ | $Theta(n log n)$ | $O(n^2)$ | $O(n)$ |
| Convex Hull (Graham) | Monotone Stack | $Omega(n log n)$ | $Theta(n log n)$ | $O(n log n)$ | $O(n)$ |
| Closest Pair of Points | Divide & Conquer | $Omega(n log n)$ | $Theta(n log n)$ | $O(n log n)$ | $O(n)$ |
| NPC Job Verification | Verification | $Omega(N)$ | $Theta(N)$ | $O(N)$ | $O(1)$ |
| Network Verification | Verification (BFS) | $Omega(V + E)$ | $Theta(V + E)$ | $O(V + E)$ | $O(V + E)$ |
| Greedy Set Cover | Approximation | $Omega(M N)$ | $Theta(M N)$ | $O(M N)$ | $O(N)$ |
| Vertex Cover 2-Approx | Approximation | $Omega(V + E)$ | $Theta(V + E)$ | $O(V + E)$ | $O(V)$ |
| Random Server Audit | Randomized | $Omega(S)$ | $Theta(S)$ | $O(S)$ | $O(N)$ |
