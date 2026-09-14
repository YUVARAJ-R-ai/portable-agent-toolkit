# N-Queens Problem (Backtracking & Branch-and-Bound Twists)

The N-Queens problem asks for all valid configurations to place $N$ non-attacking queens on an $N \times N$ chessboard such that no two queens share the same row, column, or diagonal. Category: Backtracking (with Branch-and-Bound pruning for weighted variants).

## 1. Algorithmic Invariant: $O(1)$ Conflict Lookup

Rather than scanning the board in $O(N)$ time per check, safety verification is achieved in $O(1)$ time using three boolean arrays:
1. **Columns**: `cols[col]` tracks whether column `col` is occupied ($0 \le \text{col} < N$).
2. **Major Diagonals (Top-Left to Bottom-Right, `\`)**: Along any major diagonal, the difference `row - col` is constant. To prevent negative indices, map this with an offset of $N - 1$:
   $$d_1 = \text{row} - \text{col} + N - 1 \quad (0 \le d_1 < 2N - 1)$$
3. **Minor Diagonals (Top-Right to Bottom-Left, `/`)**: Along any minor diagonal, the sum `row + col` is constant:
   $$d_2 = \text{row} + \text{col} \quad (0 \le d_2 < 2N - 1)$$

### Complexity
- **Time Complexity**: Best $O(N)$, Average $O(N!)$, Worst case $O(N!)$ (first row has $N$ choices, second has $\le N-2$, third has $\le N-4$).
- **Space Complexity**: $O(N)$ auxiliary stack space + $O(N)$ boolean tracking vectors.
- **Solution Counts**: $N=1 \to 1$, $N=2,3 \to 0$ (impossible), $N=4 \to 2$, $N=6 \to 4$, $N=8 \to 92$. Solvable for all $N \ge 4$.

---

## 2. Canonical C++ Implementation (Lab 5 Standard)

```cpp
#include <iostream>
#include <vector>
#include <string>
using namespace std;

class NQueensSolver {
private:
    int N;
    vector<vector<string>> solutions;
    vector<bool> cols;
    vector<bool> diag1; // row - col + N - 1
    vector<bool> diag2; // row + col

    void backtrack(int row, vector<string>& currentGrid) {
        if (row == N) {
            solutions.push_back(currentGrid);
            return;
        }
        for (int col = 0; col < N; ++col) {
            int d1 = row - col + N - 1;
            int d2 = row + col;
            if (cols[col] || diag1[d1] || diag2[d2]) continue;

            // 1. Place Queen
            currentGrid[row][col] = 'Q';
            cols[col] = diag1[d1] = diag2[d2] = true;

            // 2. Recurse to next row
            backtrack(row + 1, currentGrid);

            // 3. Backtrack (Undo placement)
            currentGrid[row][col] = '.';
            cols[col] = diag1[d1] = diag2[d2] = false;
        }
    }

public:
    NQueensSolver(int n) : N(n), cols(n, false),
                           diag1(2 * n - 1, false), diag2(2 * n - 1, false) {}

    vector<vector<string>> solve() {
        vector<string> grid(N, string(N, '.'));
        backtrack(0, grid);
        return solutions;
    }
};

int main() {
    int n = 4;
    NQueensSolver solver(n);
    vector<vector<string>> results = solver.solve();
    cout << "Total solutions for N=" << n << ": " << results.size() << "\n";
    for (const auto& board : results) {
        for (const auto& row : board) cout << row << "\n";
        cout << "---\n";
    }
    return 0;
}
```

---

## 3. Twisted Exam Variations & Implementations

### Variation 1: N-Queens with Obstacles (Damaged Solar Panels / Defective Matrix)
- **Scenario Keywords**: "Damaged tiles", "broken solar panels", "restricted zones", "defective node matrix".
- **Core Concept**: Certain cells $(r, c)$ are broken hardware where no queen/drone can be placed.
- **Adaptation**: Skip column if `board[row][col] == 'X'` before checking safety vectors.

```cpp
void backtrackObstacles(int row, int N, vector<vector<char>>& board,
                        vector<bool>& cols, vector<bool>& d1, vector<bool>& d2,
                        int& solutionCount) {
    if (row == N) {
        solutionCount++;
        return;
    }
    for (int col = 0; col < N; ++col) {
        // Skip obstacle / damaged cell
        if (board[row][col] == 'X') continue;

        int id1 = row - col + N - 1;
        int id2 = row + col;
        if (cols[col] || d1[id1] || d2[id2]) continue;

        board[row][col] = 'Q';
        cols[col] = d1[id1] = d2[id2] = true;

        backtrackObstacles(row + 1, N, board, cols, d1, d2, solutionCount);

        board[row][col] = '.';
        cols[col] = d1[id1] = d2[id2] = false;
    }
}
```

---

### Variation 2: Amazon / Super-Queens (Queen + Knight Attacks)
- **Scenario Keywords**: "Amazon piece", "Super-Queen", "dual radar transmitter", "Queen + Knight attack".
- **Core Concept**: A piece attacks along row, column, diagonal (Queen) AND makes L-shaped jumps (Knight: 2 by 1 or 1 by 2).
- **Adaptation**: Maintain standard `cols`, `d1`, `d2`. In addition, inspect rows `row - 1` and `row - 2` against Knight offsets: $(row - 1, col \pm 2)$ and $(row - 2, col \pm 1)$.

```cpp
bool isSafeAmazon(int row, int col, int N, const vector<int>& queenCol,
                  const vector<bool>& cols, const vector<bool>& d1, const vector<bool>& d2) {
    // Standard Queen conflict check
    if (cols[col] || d1[row - col + N - 1] || d2[row + col]) return false;

    // Knight attack check against previously placed queens
    int kRow1 = row - 1, kRow2 = row - 2;
    if (kRow1 >= 0) {
        if (queenCol[kRow1] == col - 2 || queenCol[kRow1] == col + 2) return false;
    }
    if (kRow2 >= 0) {
        if (queenCol[kRow2] == col - 1 || queenCol[kRow2] == col + 1) return false;
    }
    return true;
}

void solveAmazon(int row, int N, vector<int>& queenCol,
                 vector<bool>& cols, vector<bool>& d1, vector<bool>& d2, int& count) {
    if (row == N) { count++; return; }
    for (int col = 0; col < N; ++col) {
        if (isSafeAmazon(row, col, N, queenCol, cols, d1, d2)) {
            queenCol[row] = col;
            cols[col] = d1[row - col + N - 1] = d2[row + col] = true;

            solveAmazon(row + 1, N, queenCol, cols, d1, d2, count);

            queenCol[row] = -1;
            cols[col] = d1[row - col + N - 1] = d2[row + col] = false;
        }
    }
}
```

---

### Variation 3: Max-Weight N-Queens (Branch & Bound on Backtracking)
- **Scenario Keywords**: "Grid cell radiation values", "harvested solar power", "maximize weight/profit queen placement".
- **Core Concept**: Each cell $(r, c)$ has weight $W[r][c]$. Place $N$ non-attacking queens maximizing total weight.
- **Adaptation**: Compute `rowMaxPrefix` where `rowMaxPrefix[i]` is the cumulative sum of row-maximums up to row $i$. Upper bound of remaining rows $= \text{rowMaxPrefix}[N] - \text{rowMaxPrefix}[\text{row}]$. If `currentScore + optimisticRemaining <= maxProfit`, prune subtree!

```cpp
int maxProfitQueens = 0;
vector<int> bestPlacement;

void solveMaxWeightQueens(int row, int N, int currentScore,
                          const vector<vector<int>>& W, const vector<int>& rowMaxPrefix,
                          vector<int>& placement, vector<bool>& cols,
                          vector<bool>& d1, vector<bool>& d2) {
    if (row == N) {
        if (currentScore > maxProfitQueens) {
            maxProfitQueens = currentScore;
            bestPlacement = placement;
        }
        return;
    }

    // Branch & Bound Pruning: Upper bound check
    int optimisticRemaining = (row < N) ? (rowMaxPrefix[N] - rowMaxPrefix[row]) : 0;
    if (currentScore + optimisticRemaining <= maxProfitQueens) {
        return; // Prune branch: cannot beat best known solution
    }

    for (int col = 0; col < N; ++col) {
        int id1 = row - col + N - 1;
        int id2 = row + col;
        if (cols[col] || d1[id1] || d2[id2]) continue;

        placement[row] = col;
        cols[col] = d1[id1] = d2[id2] = true;

        solveMaxWeightQueens(row + 1, N, currentScore + W[row][col],
                             W, rowMaxPrefix, placement, cols, d1, d2);

        placement[row] = -1;
        cols[col] = d1[id1] = d2[id2] = false;
    }
}
```

---

### Variation 4: Pre-Fixed Queens (Partial Hardware Placement)
- **Scenario Keywords**: "Pre-installed cryptographic engines", "fixed sensors", "hardware hardwired positions".
- **Core Concept**: $K$ queens are pre-placed at known coordinates. Determine if remaining $N-K$ queens can be placed.
- **Adaptation**: Pre-mark `cols`, `d1`, `d2` for pre-fixed queens. When `row` already has `fixedPlacement[row] != -1`, directly recurse to `solvePreFixed(row + 1)` without a column loop.

```cpp
bool solvePreFixed(int row, int N, const vector<int>& fixedPlacement,
                   vector<int>& queenCol, vector<bool>& cols,
                   vector<bool>& d1, vector<bool>& d2) {
    if (row == N) return true; // Found valid completion

    // If this row has a pre-installed queen, skip column loop
    if (fixedPlacement[row] != -1) {
        return solvePreFixed(row + 1, N, fixedPlacement, queenCol, cols, d1, d2);
    }

    for (int col = 0; col < N; ++col) {
        int id1 = row - col + N - 1;
        int id2 = row + col;
        if (cols[col] || d1[id1] || d2[id2]) continue;

        queenCol[row] = col;
        cols[col] = d1[id1] = d2[id2] = true;

        if (solvePreFixed(row + 1, N, fixedPlacement, queenCol, cols, d1, d2))
            return true;

        queenCol[row] = -1;
        cols[col] = d1[id1] = d2[id2] = false;
    }
    return false;
}
```

---

### Variation 5: No Three Queens Collinear (General Linear Independence)
- **Scenario Keywords**: "No three queens collinear", "line of sight interference at any slope", "linear independence".
- **Core Concept**: No 3 queens may lie on any common straight line (not just 0°, 90°, or 45°).
- **Adaptation**: Cross-product slope check with all pairs of previously placed queens $(r_1, c_1)$ and $(r_2, c_2)$:
  $$(c_2 - c_1) \cdot (\text{row} - r_1) == (\text{col} - c_1) \cdot (r_2 - r_1)$$
  Using integer arithmetic avoids floating point inaccuracies!

```cpp
bool isCollinear(int r1, int c1, int r2, int c2, int r3, int c3) {
    return (long long)(c2 - c1) * (r3 - r1) == (long long)(c3 - c1) * (r2 - r1);
}

bool isSafeCollinear(int row, int col, int N, const vector<int>& qCol,
                     const vector<bool>& cols, const vector<bool>& d1, const vector<bool>& d2) {
    if (cols[col] || d1[row - col + N - 1] || d2[row + col]) return false;

    // Check against all pairs of already placed queens
    for (int r1 = 0; r1 < row; ++r1) {
        for (int r2 = r1 + 1; r2 < row; ++r2) {
            if (isCollinear(r1, qCol[r1], r2, qCol[r2], row, col))
                return false;
        }
    }
    return true;
}
```

---

### Variation 6: K-Queens on $N \times M$ Grid ($K < \min(N, M)$)
- **Scenario Keywords**: "K-queens", "rectangular board", "$K < N$ non-attacking pieces", "empty rows allowed".
- **Core Concept**: Place $K$ queens on an $N \times M$ grid. Since $K < N$, some rows MUST be left empty.
- **Adaptation**: Two recursive branches at each row:
  1. Branch 1: Place a queen in column `col` (if safe) and recurse with `queensPlaced + 1`.
  2. Branch 2: Leave current row completely empty and recurse with `queensPlaced`.
  - Pruning: If $N - \text{row} < K - \text{queensPlaced}$, prune immediately (not enough rows remain).

```cpp
void solveKQueens(int row, int queensPlaced, int K, int N, int M,
                  vector<bool>& cols, vector<bool>& d1, vector<bool>& d2, int& count) {
    if (queensPlaced == K) {
        count++;
        return;
    }
    if (row == N) return; // Exhausted rows without placing K queens
    if (N - row < K - queensPlaced) return; // Prune: not enough remaining rows

    // Branch 1: Place a queen in some column of this row
    for (int col = 0; col < M; ++col) {
        int id1 = row - col + M - 1;
        int id2 = row + col;
        if (cols[col] || d1[id1] || d2[id2]) continue;

        cols[col] = d1[id1] = d2[id2] = true;
        solveKQueens(row + 1, queensPlaced + 1, K, N, M, cols, d1, d2, count);
        cols[col] = d1[id1] = d2[id2] = false;
    }

    // Branch 2: Leave this row empty
    solveKQueens(row + 1, queensPlaced, K, N, M, cols, d1, d2, count);
}
```
