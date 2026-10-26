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

---

# FAT Lab-Exam Version & Your Lab Programs (BCSE204P, Dr. Sakthivel R)

Every program below was extracted from your lab reports / FAT guide, compiled with `g++ -std=c++17 -Wall -O2`, and run; outputs shown are the real program output.

## Lab questions & verified answers

| Lab question | Scenario & input data | Verified answer |
|---|---|---|
| Lab 9 Q5 | Intrusion payload ABABDABACDABABCABAB, signature ABABCABAB | π = 0 0 1 2 0 1 2 3 4; match at index **10** |

## Knuth-Morris-Pratt (KMP) Algorithm & π-Array

### Knuth-Morris-Pratt (KMP) Algorithm
**Lab scenario:** Network Intrusion Detection Payload `ABABDABACDABABCABAB` Locating Signature `ABABCABAB`

Avoid redundant comparisons by precomputing the **Prefix Function ($pi$-array / LPS Table)**:
$pi[i]$ is the length of the longest proper prefix of $P[0 … i]$ that is also a suffix of $P[0 … i]$. When a mismatch occurs after matching $j$ characters, shift the pattern so that index $pi[j-1]$ aligns with the mismatched text character. Never backtrack the text pointer!

### Algorithm: KMP Prefix Function & Search
```python
ComputeLPS(P, m):
    pi = [0 for _ in range(m)]
    len = 0; i = 1
    WHILE i < m:
        IF P[i] == P[len]:
            len++; pi[i] = len; i++
        ELSE IF len != 0:
            len = pi[len - 1]
        ELSE:
            pi[i] = 0; i++
    RETURN pi

KMPSearch(T, P):
    pi = ComputeLPS(P, len(P))
    i = 0; j = 0
    WHILE i < len(T):
        IF T[i] == P[j]: i++; j++
        IF j == len(P):
            OUTPUT "Match found at shift", i - j
            j = pi[j - 1]
        ELSE IF i < len(T) AND T[i] != P[j]:
            IF j != 0: j = pi[j - 1]       # Fallback to prefix
            ELSE: i++
```

### Step-by-Step KMP Pointer Walkthrough (Mismatch Fallback Trace)
**Precomputed Prefix Table ($pi$-array / LPS):**

| **Index $j$** | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|---|
| **$P[j]$** | A | B | A | B | C | A | B | A | B |
| **$pi[j]$** | 0 | 0 | 1 | 2 | 0 | 1 | 2 | 3 | 4 |

**Crucial Search Pointer Trace:**
- **Step 1 ($i=0..3$):** $T[0..3] = ABAB$ matches $P[0..3] = ABAB$. $i$ reaches 4, $j$ reaches 4.
- **Step 2 ($i=4$):** $T[4] = 'D'$, but $P[4] = 'C'$. **MISMATCH!**
- Text pointer $i$ stays frozen at 4!
- Fallback: $j = pi[j-1] = pi[3] = 2$. Next character to check is $P[2] = 'A'$.
- $T[4] = 'D' != P[2] = 'A'$. **MISMATCH!**
- Fallback: $j = pi[2-1] = pi[1] = 0$. Next character to check is $P[0] = 'A'$.
- $T[4] = 'D' != P[0] = 'A'$. **MISMATCH at $j=0$!**
- Advance text pointer $i$ to 5.
- **Step 3 ($i=5..7$):** $T[5..7] = ABA$ matches $P[0..2] = ABA$.
- **Step 4 ($i=8$):** $T[8] = 'C'$, but $P[3] = 'B'$. Mismatch! Fallback $j = pi[2] = 1$. Mismatch again at $P[1]='B'$. Fallback $j = pi[0] = 0$. Mismatch at $P[0]='A'$. Advance $i$ to 9.
- **Step 5 ($i=9$):** $T[9] = 'D' != P[0]$. Advance $i$ to 10.
- **Step 6 ($i=10..18$):** Exact match of all 9 characters $T[10..18] == P[0..8] = ABABCABAB$.
- **Match Reported at shift:** $19 - 9 = 10$.

### Concise C++ Implementation (With Detailed π-Array)

```cpp
#include <iostream>
#include <vector>
#include <string>
using namespace std;

vector<int> computeLPS(const string& pat) {
    int m = pat.length();
    vector<int> pi(m, 0);
    int len = 0, i = 1;

    while (i < m) {
        if (pat[i] == pat[len]) {
            len++;
            pi[i] = len;
            i++;
        } else {
            if (len != 0) len = pi[len - 1]; // Fallback to previous prefix
            else { pi[i] = 0; i++; }
        }
    }
    return pi;
}

void KMPSearch(const string& text, const string& pat) {
    int n = text.length(), m = pat.length();
    vector<int> pi = computeLPS(pat);

    cout << "--- KMP pi-array (LPS Table) ---\n";
    for (int i = 0; i < m; ++i) cout << pat[i] << " ";
    cout << "\n";
    for (int i = 0; i < m; ++i) cout << pi[i] << " ";
    cout << "\n--------------------------------\n";

    int i = 0, j = 0;
    while (i < n) {
        if (text[i] == pat[j]) { i++; j++; }
        if (j == m) {
            cout << "Pattern matched at shift: " << i - j << "\n";
            j = pi[j - 1];
        } else if (i < n && text[i] != pat[j]) {
            if (j != 0) j = pi[j - 1]; // Crucial KMP jump!
            else i++;
        }
    }
}

int main() {
    // Lab Example: Network intrusion payload & signature
    string text = "ABABDABACDABABCABAB";
    string pat = "ABABCABAB";
    KMPSearch(text, pat);
    return 0;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
--- KMP pi-array (LPS Table) ---
A B A B C A B A B 
0 0 1 2 0 1 2 3 4 
--------------------------------
Pattern matched at shift: 10
```

### Silly Mistakes & Traps: KMP
1. **Resetting to 0 on Mismatch:** Writing `j = 0` on mismatch completely breaks KMP and turns it into a broken naive algorithm! You MUST write `j = pi[j - 1]`.
2. **Building LPS Table Mismatch Step:** When computing $pi$, if mismatch occurs and `len > 0`, set `len = pi[len - 1]`. DO NOT increment `i` in that branch!
3. **Array Index Underflow:** Checking `pi[j-1]` without verifying `j > 0` causes an out-of-bounds crash on `pi[-1]`.

**Complexity:** best O(n) · average O(n + m) · worst O(n + m) · auxiliary space O(m) for pi array  
**Recurrence:** Preprocessing O(m), Search O(n) => O(n + m) strictly linear!
