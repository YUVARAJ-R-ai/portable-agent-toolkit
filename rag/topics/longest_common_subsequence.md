# Longest Common Subsequence (Dynamic Programming)

Longest common subsequence (LCS): O(mn) DP table + backtracking to recover the sequence (Lab 4, FAT Module 4). Category: Dynamic Programming.

---

Every program below was extracted from your lab reports / FAT guide, compiled with `g++ -std=c++17 -Wall -O2`, and run; outputs shown are the real program output.

## Lab questions & verified answers

| Lab question | Scenario & input data | Verified answer |
|---|---|---|
| Lab 4 Q5 | Developer A: CREATE READ UPDATE LOG DELETE EXIT; Developer B: INIT CREATE UPDATE CACHE LOG EXIT | Length **4**: CREATE → UPDATE → LOG → EXIT |
| Lab 4 Q6 | Manuscripts S1 = [I,W,F,S,R,P,L], S2 = [I,F,W,S,P,S,L] | Length **5**: I F S P L |

Do not confuse with longest common **substring** (contiguous), which is in `suffix_array_lcp`.

## Longest Common Subsequence (LCS)

### Longest Common Subsequence (LCS)
**Lab scenario:** Automated Plagiarism Code Audit (Function call trace) & Ancient Manuscript Chapter Comparison

Given two sequences $X$ and $Y$, find the longest subsequence common to both. Subsequences are not required to occupy contiguous positions within the original sequences.

### Algorithm: LCS
```python
LCS(X, Y, m, n):
    FOR i = 0 TO m: dp[i][0] = 0
    FOR j = 0 TO n: dp[0][j] = 0

    FOR i = 1 TO m:
        FOR j = 1 TO n:
            IF X[i - 1] == Y[j - 1]:
                dp[i][j] = 1 + dp[i - 1][j - 1]
            ELSE:
                dp[i][j] = max(dp[i - 1][j], dp[i][j - 1])

    # Backtrack to reconstruct sequence
    result = []; i = m; j = n
    WHILE i > 0 AND j > 0:
        IF X[i - 1] == Y[j - 1]:
            result.append(X[i - 1]); i--; j--
        ELSE IF dp[i - 1][j] > dp[i][j - 1]:
            i--
        ELSE:
            j--

    RETURN dp[m][n], REVERSE(result)
```

### Concise C++ Implementation (String Tokens & Trace Plagiarism)

```cpp
#include <iostream>
#include <vector>
#include <string>
#include <algorithm>
using namespace std;

int main() {
    // Lab Example: Code Audit Function Call Trace Plagiarism
    vector<string> A = {"CREATE", "READ", "UPDATE", "LOG", "DELETE", "EXIT"};
    vector<string> B = {"INIT", "CREATE", "UPDATE", "CACHE", "LOG", "EXIT"};
    int m = A.size(), n = B.size();

    vector<vector<int>> dp(m + 1, vector<int>(n + 1, 0));

    for (int i = 1; i <= m; ++i) {
        for (int j = 1; j <= n; ++j) {
            if (A[i - 1] == B[j - 1]) dp[i][j] = 1 + dp[i - 1][j - 1];
            else dp[i][j] = max(dp[i - 1][j], dp[i][j - 1]);
        }
    }

    cout << "Length of LCS = " << dp[m][n] << "\n";

    // Backtrack to extract matching tokens
    vector<string> lcs;
    int i = m, j = n;
    while (i > 0 && j > 0) {
        if (A[i - 1] == B[j - 1]) {
            lcs.push_back(A[i - 1]);
            i--; j--;
        } else if (dp[i - 1][j] > dp[i][j - 1]) {
            i--;
        } else {
            j--;
        }
    }
    reverse(lcs.begin(), lcs.end());

    cout << "LCS: ";
    for (size_t k = 0; k < lcs.size(); ++k)
        cout << lcs[k] << (k + 1 < lcs.size() ? " -> " : "\n");
    return 0;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
Length of LCS = 4
LCS: CREATE -> UPDATE -> LOG -> EXIT
```

### Cheese Code: Recursive Memoization for LCS (8 Lines)
**Why it works in the exam:** Top-down memoization avoids dealing with 2D array offsets and reverse traversal in time-pressured exams!

```cpp
#include <bits/stdc++.h>
using namespace std;
string s1 = "IWFSRPL", s2 = "IFWSPSL";
int memo[20][20];
int lcs(int i, int j) {
    if (i == s1.size() || j == s2.size()) return 0;
    if (memo[i][j]) return memo[i][j];
    if (s1[i] == s2[j]) return memo[i][j] = 1 + lcs(i+1, j+1);
    return memo[i][j] = max(lcs(i+1, j), lcs(i, j+1));
}
int main() { cout << "LCS Length: " << lcs(0, 0) << endl; } // Outputs 5
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
LCS Length: 5
```

### Silly Mistakes & Traps: LCS
1. **Forgetting to Reverse Recovered LCS:** Backtracking starts from the end $(m, n)$ and walks backwards. The extracted tokens are in reverse order! You MUST call `reverse(lcs.begin(), lcs.end())`.
2. **Table Size Allocation:** Allocating `dp[m][n]` instead of `dp[m+1][n+1]` causes immediate memory corruption on `dp[i][j]`.
3. **String Token vs Character Equality:** If comparing function call logs, compare `string` tokens, not individual letters!

**Complexity:** best O(m n) · average O(m n) · worst O(m n) · auxiliary space O(m n) table  
**Recurrence:** T(m, n) = O(m n) subproblems

## Your lab-report programs

### Your Lab 4 Q6 program (single-character tokens)

```cpp
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

int main() {
    vector<char> S1 = {'I','W','F','S','R','P','L'};
    vector<char> S2 = {'I','F','W','S','P','S','L'};

    int m = S1.size();
    int n = S2.size();

    vector<vector<int>> dp(m + 1, vector<int>(n + 1, 0));

    // Fill DP table
    for (int i = 1; i <= m; i++) {
        for (int j = 1; j <= n; j++) {
            if (S1[i - 1] == S2[j - 1])
                dp[i][j] = dp[i - 1][j - 1] + 1;
            else
                dp[i][j] = max(dp[i - 1][j], dp[i][j - 1]);
        }
    }

    cout << "Length of LCS = " << dp[m][n] << endl;

    // Find the LCS
    vector<char> lcs;
    int i = m, j = n;

    while (i > 0 && j > 0) {
        if (S1[i - 1] == S2[j - 1]) {
            lcs.push_back(S1[i - 1]);
            i--;
            j--;
        }
        else if (dp[i - 1][j] > dp[i][j - 1]) {
            i--;
        }
        else {
            j--;
        }
    }

    reverse(lcs.begin(), lcs.end());

    cout << "LCS = ";
    for (char ch : lcs)
        cout << ch << " ";

    cout << endl;

    return 0;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
Length of LCS = 5
LCS = I F S P L
```
