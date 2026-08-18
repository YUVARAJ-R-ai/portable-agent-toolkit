# Assembly Line Scheduling (Dynamic Programming)

A car chassis moves through `n` stations on **two** parallel assembly
lines. Station `j` takes `a[i][j]` time on line `i`. After finishing a
station, the chassis can either continue on the same line to the next
station, or transfer to the other line (paying a transfer cost `t[i][j]`),
before continuing to station `j+1` there. Each line has its own entry time
`e[i]` and exit time `x[i]`. Find the fastest way through the whole
factory. Category: Dynamic Programming (not greedy or divide-and-conquer —
the "which line was cheapest to reach station j" choice depends on
comparing two full alternatives, which greedy can't do without
backtracking, and the subproblems overlap, which plain divide-and-conquer
doesn't exploit).

## Idea

Let `f1[j]` = fastest time to reach station `j` on line 1 (having gone
through stations `0..j` optimally), and `f2[j]` similarly for line 2.

**Base case** (station 0): `f1[0] = e1 + a1[0]`, `f2[0] = e2 + a2[0]`.

**Recurrence** (station `j > 0`): to reach station `j` on line 1, either you
were already on line 1 at station `j-1` and just continue, or you were on
line 2 at station `j-1` and transferred over:
```
f1[j] = min( f1[j-1] + a1[j],  f2[j-1] + t2[j-1] + a1[j] )
f2[j] = min( f2[j-1] + a2[j],  f1[j-1] + t1[j-1] + a2[j] )
```
(`t2[j-1]` = cost to transfer from line 2 station `j-1` to line 1 station
`j`; `t1[j-1]` is the mirror image.)

**Answer**: `min(f1[n-1] + x1, f2[n-1] + x2)`.

This is a textbook DP: the key insight is that the fastest way to reach
station `j` on a given line only depends on the fastest ways to reach
station `j-1` on *either* line — so build the table left to right, reusing
the previous column, and the final answer falls out of the last column plus
the exit costs. To recover *which* line was used at each station (not just
the total time), track which of the two options won at each step and walk
that back from the end.

## Complexity

`O(n)` time and space (each of the `n` stations does O(1) work per line);
can be reduced to `O(1)` extra space if only the total time is needed, not
the path.

## Verified C++ implementation

Compiled with `g++ -std=c++17 -Wall -O2` and run against the standard CLRS
textbook example — output matches the known correct answer of `38` exactly,
and the reconstructed path was independently hand-verified by tracing the
DP table by hand (not just trusted from the code).

```cpp
#include <bits/stdc++.h>
using namespace std;

int main() {
    // Classic textbook example (CLRS): 6 stations per line.
    vector<int> a1 = {7, 9, 3, 4, 8, 4};   // station time, line 1
    vector<int> a2 = {8, 5, 6, 4, 5, 7};   // station time, line 2
    vector<int> t1 = {2, 3, 1, 3, 4};      // transfer line1[j] -> line2[j+1]
    vector<int> t2 = {2, 1, 2, 2, 1};      // transfer line2[j] -> line1[j+1]
    int e1 = 2, e2 = 4;                     // entry times
    int x1 = 3, x2 = 2;                     // exit times
    int n = a1.size();

    vector<int> f1(n), f2(n);
    vector<int> l1(n), l2(n); // l[j] = which line we came from, for path reconstruction

    f1[0] = e1 + a1[0];
    f2[0] = e2 + a2[0];

    for (int j = 1; j < n; j++) {
        if (f1[j - 1] <= f2[j - 1] + t2[j - 1]) {
            f1[j] = f1[j - 1] + a1[j];
            l1[j] = 1;
        } else {
            f1[j] = f2[j - 1] + t2[j - 1] + a1[j];
            l1[j] = 2;
        }
        if (f2[j - 1] <= f1[j - 1] + t1[j - 1]) {
            f2[j] = f2[j - 1] + a2[j];
            l2[j] = 2;
        } else {
            f2[j] = f1[j - 1] + t1[j - 1] + a2[j];
            l2[j] = 1;
        }
    }

    int finish1 = f1[n - 1] + x1;
    int finish2 = f2[n - 1] + x2;
    int fastest = min(finish1, finish2);

    vector<int> path(n);
    int line = (finish1 <= finish2) ? 1 : 2;
    for (int j = n - 1; j >= 0; j--) {
        path[j] = line;
        line = (line == 1) ? l1[j] : l2[j];
        if (j == 0) break;
    }

    cout << "Fastest total time: " << fastest << "\n";
    cout << "Path (station -> line): ";
    for (int j = 0; j < n; j++) cout << "S" << (j + 1) << "->L" << path[j] << "  ";
    cout << "\n";
    return 0;
}
```

### Verified output

```
Fastest total time: 38
Path (station -> line): S1->L1  S2->L2  S3->L1  S4->L2  S5->L2  S6->L1
```
