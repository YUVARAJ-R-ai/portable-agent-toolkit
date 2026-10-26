# Matrix Chain Multiplication (Dynamic Programming)

Matrix chain multiplication: O(n^3) DP for minimum scalar multiplications + optimal parenthesization (Lab 3, FAT Module 3). Category: Dynamic Programming.

---

Every program below was extracted from your lab reports / FAT guide, compiled with `g++ -std=c++17 -Wall -O2`, and run; outputs shown are the real program output.

## Lab questions & verified answers

| Lab question | Scenario & input data | Verified answer |
|---|---|---|
| Lab 3 Q4 | 3D engine pipeline, P = [10, 30, 5, 60, 8] (A1 10×30, A2 30×5, A3 5×60, A4 60×8) | **4300** scalar multiplications, **((A1A2)(A3A4))**, split k=2 |

## Matrix Chain Multiplication (MCM)

### Matrix Chain Multiplication
**Lab scenario:** 3D Game Engine Coordinate Transformation Pipeline ($A_1 × A_2 × A_3 × A_4$)

Given a sequence of $n$ matrices $A_1, A_2, …, A_n$ where matrix $A_i$ has dimensions $p_(i-1) × p_i$, find the optimal parenthesization that minimizes the total number of scalar multiplications.

### Algorithm: MatrixChainOrder
```python
MatrixChainOrder(p, n):
    FOR i = 1 TO n:
        m[i][i] = 0

    FOR L = 2 TO n:                        # Chain length
        FOR i = 1 TO n - L + 1:
            j = i + L - 1
            m[i][j] = INF
            FOR k = i TO j - 1:
                cost = m[i][k] + m[k + 1][j] + p[i - 1] * p[k] * p[j]
                IF cost < m[i][j]:
                    m[i][j] = cost
                    bracket[i][j] = k

    RETURN m[1][n], bracket
```

### Step-by-Step Matrix Chain DP Table Walkthrough (m[i][j] & Split k)
**Dynamic Programming Cost Table $m[i][j]$ (Diagonal Fill Order by Chain Length $L$):**

| **$m[i][j]$** | **$j = 1$** | **$j = 2$** | **$j = 3$** | **$j = 4$** |
|---|---|---|---|---|
| **$i = 1$** | 0 | 1,500 | 4,500 | **4,300** |
| **$i = 2$** | - | 0 | 9,000 | 3,600 |
| **$i = 3$** | - | - | 0 | 2,400 |
| **$i = 4$** | - | - | - | 0 |

**Optimal Split Positions Table $bracket[i][j]$ ($k$ values):**

| **$s[i][j]$** | **$j = 1$** | **$j = 2$** | **$j = 3$** | **$j = 4$** |
|---|---|---|---|---|
| **$i = 1$** | - | $k=1$ | $k=2$ | **$k=2$** |
| **$i = 2$** | - | - | $k=2$ | $k=2$ |
| **$i = 3$** | - | - | - | $k=3$ |
| **$i = 4$** | - | - | - | - |

**Step-by-Step Chain Calculation Details:**
- **Length $L = 2$ (Single products):**
- $m[1][2] = p_0 p_1 p_2 = 10 · 30 · 5 = 1,500$ ($k=1$).
- $m[2][3] = p_1 p_2 p_3 = 30 · 5 · 60 = 9,000$ ($k=2$).
- $m[3][4] = p_2 p_3 p_4 = 5 · 60 · 8 = 2,400$ ($k=3$).
- **Length $L = 3$ (Three matrices):**
- For $m[1][3]$: Split $k=1$ gives $0 + 9000 + 10 · 30 · 60 = 27000$; Split $k=2$ gives $1500 + 0 + 10 · 5 · 60 = 4,500$. Minimum is **4,500** ($k=2$).
- For $m[2][4]$: Split $k=2$ gives $0 + 2400 + 30 · 5 · 8 = 3,600$; Split $k=3$ gives $9000 + 0 + 30 · 60 · 8 = 23400$. Minimum is **3,600** ($k=2$).
- **Length $L = 4$ (Full chain $A_1 … A_4$):**
- Split $k=1$: $m[1][1] + m[2][4] + p_0 p_1 p_4 = 0 + 3600 + 10 · 30 · 8 = 6000$.
- Split $k=2$: $m[1][2] + m[3][4] + p_0 p_2 p_4 = 1500 + 2400 + 10 · 5 · 8 = 4,300$ **(Optimal!)**.
- Split $k=3$: $m[1][3] + m[4][4] + p_0 p_3 p_4 = 4500 + 0 + 10 · 60 · 8 = 9300$.
- **Reconstruction:** $s[1][4] = 2$ splits into $(A_1 A_2)$ and $(A_3 A_4) → ((A_1 A_2) (A_3 A_4))$.

### Concise C++ Implementation (With Parenthesis Printing)

```cpp
#include <iostream>
#include <vector>
#include <climits>
using namespace std;

const int N = 5; // matrices + 1
int m[N][N], bracket[N][N];

void printParenthesis(int i, int j, char& name) {
    if (i == j) { cout << name++; return; }
    cout << "(";
    printParenthesis(i, bracket[i][j], name);
    printParenthesis(bracket[i][j] + 1, j, name);
    cout << ")";
}

int main() {
    int p[] = {10, 30, 5, 60, 8}; // Dimensions for A1: 10x30, A2: 30x5, A3: 5x60, A4: 60x8
    int n = 4; // 4 matrices

    for (int i = 1; i <= n; ++i) m[i][i] = 0;

    for (int L = 2; L <= n; ++L) {
        for (int i = 1; i <= n - L + 1; ++i) {
            int j = i + L - 1;
            m[i][j] = INT_MAX;
            for (int k = i; k < j; ++k) {
                int cost = m[i][k] + m[k + 1][j] + p[i - 1] * p[k] * p[j];
                if (cost < m[i][j]) {
                    m[i][j] = cost;
                    bracket[i][j] = k;
                }
            }
        }
    }

    cout << "Minimum Multiplications: " << m[1][n] << "\n";
    char name = 'A';
    cout << "Optimal Grouping: ";
    printParenthesis(1, n, name);
    cout << "\n";
    return 0;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
Minimum Multiplications: 4300
Optimal Grouping: ((AB)(CD))
```

### Cheese Code: Memoized MCM (No Complex Loop Bounds to Memorize)
**Why it works in the exam:** Memorizing the 3 nested loops of MCM is tricky in exams. A simple top-down memoized function memo[i][j] is intuitive and foolproof!

```cpp
#include <bits/stdc++.h>
using namespace std;
int p[] = {10, 30, 5, 60, 8}, memo[10][10];
int mcm(int i, int j) {
    if (i == j) return 0;
    if (memo[i][j]) return memo[i][j];
    int ans = 1e9;
    for (int k = i; k < j; ++k)
        ans = min(ans, mcm(i, k) + mcm(k + 1, j) + p[i-1] * p[k] * p[j]);
    return memo[i][j] = ans;
}
int main() { cout << "Min Scalar Multiplications: " << mcm(1, 4) << endl; }
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
Min Scalar Multiplications: 4300
```

### Silly Mistakes & Traps: MCM
1. **Dimension Array Sizing:** $N$ matrices require $N+1$ dimensions in array $P$. Matrix $A_i$ has dimension $P[i-1] × P[i]$. Forgetting the $i-1$ index offsets the entire dimension lookup.
2. **Loop Bounds:** Chain length $L$ starts from 2 up to $n$. Subsequence end index $j = i + L - 1$.

**Complexity:** best O(n^3) · average O(n^3) · worst O(n^3) · auxiliary space O(n^2) table  
**Recurrence:** O(n^2) states, each requiring O(n) split evaluations => O(n^3)
