# Knuth-Morris-Pratt (KMP) String Matching Algorithm

The Knuth-Morris-Pratt (KMP) algorithm searches for occurrences of pattern $P[0 \dots m-1]$ within text $T[0 \dots n-1]$ in strictly linear $O(n + m)$ time. It eliminates backtracking of the text pointer by precomputing the **Prefix Function** ($\pi$ or LPS array) of the pattern. Category: String Matching.

---

## 1. Algorithmic Invariants

### Longest Prefix Suffix (LPS) Definition
$\text{LPS}[i]$ is the length of the longest proper prefix of $P[0 \dots i]$ that is also a suffix of $P[0 \dots i]$. A proper prefix of a string cannot be equal to the whole string itself.

### LPS Array Construction Invariant
1. $\text{LPS}[0] = 0$.
2. Maintain `len` (length of the previous longest prefix-suffix).
3. If $P[i] == P[\text{len}]$, increment `len`, set $\text{LPS}[i] = \text{len}$, and increment $i$.
4. If mismatch and $\text{len} > 0$, fallback $\text{len} = \text{LPS}[\text{len} - 1]$ without advancing $i$.
5. If mismatch and $\text{len} == 0$, set $\text{LPS}[i] = 0$, and increment $i$.

### Text Matching Invariant
- When character mismatch occurs at $T[i] \ne P[j]$:
  - If $j > 0$, pattern shifts by setting $j = \text{LPS}[j - 1]$ while text pointer $i$ stays fixed.
  - If $j == 0$, increment $i$.
- When a complete match occurs ($j == m$):
  - Record match at index $i - j$.
  - Prepare for subsequent matches by setting $j = \text{LPS}[j - 1]$.

### Complexity
- **Preprocessing Time**: $O(m)$ to build LPS array.
- **Matching Time**: $O(n)$ (each text character compared at most twice amortized).
- **Total Time Complexity**: $O(n + m)$ strictly linear.
- **Space Complexity**: $O(m)$ auxiliary space for LPS array.
- **Streaming Guarantee**: Text pointer $i$ strictly moves forward; never backtracks.

---

## 2. Canonical C++ Implementation (Lab Standard)

```cpp
#include <iostream>
#include <vector>
#include <string>
using namespace std;

vector<int> computeLPS(const string& P) {
    int m = P.length();
    vector<int> lps(m, 0);
    int len = 0; // Length of previous longest prefix suffix
    int i = 1;

    while (i < m) {
        if (P[i] == P[len]) {
            len++;
            lps[i] = len;
            i++;
        } else {
            if (len != 0) {
                len = lps[len - 1]; // Fall back to previous prefix
            } else {
                lps[i] = 0;
                i++;
            }
        }
    }
    return lps;
}

vector<int> KMPSearch(const string& text, const string& pattern) {
    int n = text.length(), m = pattern.length();
    vector<int> occurrences;
    if (m == 0 || n < m) return occurrences;

    vector<int> lps = computeLPS(pattern);
    int i = 0; // Text pointer
    int j = 0; // Pattern pointer

    while (i < n) {
        if (pattern[j] == text[i]) {
            i++;
            j++;
        }
        if (j == m) {
            occurrences.push_back(i - j); // Match found at index (i - j)
            j = lps[j - 1];               // Reset pattern pointer for next match
        } else if (i < n && pattern[j] != text[i]) {
            if (j != 0) {
                j = lps[j - 1]; // Shift pattern using LPS table
            } else {
                i++;
            }
        }
    }
    return occurrences;
}

int main() {
    string text = "ABABDABACDABABCABAB";
    string pattern = "ABABCABAB";
    vector<int> matches = KMPSearch(text, pattern);

    cout << "Pattern found at index: ";
    for (int idx : matches) cout << idx << " ";
    cout << "\n";
    return 0;
}
```

---

## 3. Twisted Exam Variations & Implementations

### Variation 1: Periodic String Detection / Minimum Repeating Base Substring
- **Scenario Keywords**: "Periodic signal", "smallest repeating telemetry packet", "cyclic repeated pattern".
- **Core Concept**: Check if string $S$ of length $L$ is composed of repetitions of a shorter substring $T$ (e.g., "ABCABCABC").
- **Mathematical Invariant**: Let $k = L - \text{LPS}[L - 1]$. If $\text{LPS}[L - 1] > 0$ and $L \pmod k == 0$, then $S$ is periodic with repeating unit of length $k$, repeated $L/k$ times!

```cpp
bool isPeriodicString(const string& s, int& repeatLength, int& repeatCount) {
    int L = s.length();
    if (L == 0) return false;
    vector<int> lps = computeLPS(s);
    int longestPrefixSuffix = lps[L - 1];
    int unitLen = L - longestPrefixSuffix;

    if (longestPrefixSuffix > 0 && L % unitLen == 0) {
        repeatLength = unitLen;
        repeatCount = L / unitLen;
        return true;
    }
    repeatLength = L;
    repeatCount = 1;
    return false;
}
```

---

### Variation 2: Non-Overlapping Matches Constraint
- **Scenario Keywords**: "Non-overlapping occurrences", "disjoint pattern matches", "token consumption".
- **Core Concept**: By default, KMP finds overlapping matches (e.g. "AAA" in "AAAA" matches at 0 and 1). When overlaps are forbidden, after recording a match, pattern pointer $j$ is reset to 0 instead of $\text{LPS}[j - 1]$.
- **Adaptation**:
```cpp
if (j == m) {
    occurrences.push_back(i - j);
    j = 0; // Non-overlapping: consume window completely
}
```

---

### Variation 3: Cyclic Shift / Rotational Equivalence
- **Scenario Keywords**: "Circular rotation", "cyclic shift", "rotational equivalence", "check if B is rotation of A".
- **Core Concept**: String $B$ is a rotation of $A$ if and only if $|A| == |B|$ and $B$ is a substring of the doubled string $A + A$.
- **Complexity**: $O(|A|)$ time using KMP search.

```cpp
bool isCyclicRotation(const string& A, const string& B) {
    if (A.length() != B.length()) return false;
    string doubled = A + A;
    vector<int> matches = KMPSearch(doubled, B);
    return !matches.empty();
}
```

---

### Variation 4: Longest Palindromic Prefix
- **Scenario Keywords**: "Longest palindromic prefix", "prefix palindrome".
- **Adaptation**: Construct combined string $R = S + \text{"#"} + \text{reverse}(S)$. The value $\text{LPS}[|R|-1]$ gives the exact length of the longest palindromic prefix of $S$ in $O(|S|)$ time.
