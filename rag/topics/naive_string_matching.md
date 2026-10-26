# Naïve String Matching Algorithm

The Naïve string matching algorithm searches for occurrences of pattern $P[0 \dots m-1]$ inside text $T[0 \dots n-1]$ by testing every possible shift $s \in [0, n - m]$ with a sliding window. Category: String Matching.

---

## 1. Algorithmic Principles & Complexity

- **Sliding Window**: For each start index $s \in [0, n-m]$, compare characters $T[s + j]$ and $P[j]$ for $j = 0 \dots m-1$.
- **Best Case Time**: $O(n)$ — occurs when the very first character of the pattern mismatches text at each shift.
- **Worst Case Time**: $O((n - m + 1) \cdot m)$ — occurs when text and pattern have repetitive identical characters with mismatch at the end (e.g., $T = \text{"AAAAAAAAAB"}$, $P = \text{"AAAAB"}$).
- **Space Complexity**: $O(1)$ auxiliary space (no precomputed lookup tables).
- **Primary Use**: Serves as a baseline, and is often modified in lab exams for custom constraints (wildcards, adjacency rules) where advanced table construction is unnecessary.

---

## 2. Canonical C++ Implementation

```cpp
#include <iostream>
#include <vector>
#include <string>
using namespace std;

vector<int> naiveSearch(const string& text, const string& pattern) {
    int n = text.length(), m = pattern.length();
    vector<int> occurrences;
    if (m == 0 || n < m) return occurrences;

    for (int s = 0; s <= n - m; ++s) {
        int j = 0;
        while (j < m && text[s + j] == pattern[j]) {
            j++;
        }
        if (j == m) {
            occurrences.push_back(s); // Pattern matched starting at shift s
        }
    }
    return occurrences;
}

int main() {
    string text = "AABAACAADAABAABA";
    string pattern = "AABA";
    vector<int> matches = naiveSearch(text, pattern);

    cout << "Pattern found at shifts: ";
    for (int idx : matches) cout << idx << " ";
    cout << "\n";
    return 0;
}
```

---

## 3. Twisted Exam Variations & Implementations

### Variation 1: Wildcard Character Matching ('?' matches any single character)
- **Scenario Keywords**: "Wildcard matching", "'?' single-char wildcard", "tolerant string comparison".
- **Adaptation**: Allow match if `pattern[j] == '?' || text[s + j] == pattern[j]`.

```cpp
bool matchWithQuestionMark(const string& text, int s, const string& pattern) {
    int m = pattern.length();
    for (int j = 0; j < m; ++j) {
        if (pattern[j] != '?' && text[s + j] != pattern[j]) return false;
    }
    return true;
}

vector<int> naiveWithWildcard(const string& text, const string& pattern) {
    int n = text.length(), m = pattern.length();
    vector<int> occurrences;
    for (int s = 0; s <= n - m; ++s) {
        if (matchWithQuestionMark(text, s, pattern)) occurrences.push_back(s);
    }
    return occurrences;
}
```

---

### Variation 2: PAT-1 Style Twist — "No Two Consecutive Matched Characters Identical"
- **Scenario Keywords**: "No adjacent identical characters", "no consecutive duplicates in matched substring", "alternating character filter".
- **Core Concept**: Even if pattern matches text at shift $s$, reject the match if any two adjacent characters in the matched window $T[s \dots s + m - 1]$ are identical (e.g. "ABA" accepted, "AAB" or "ABB" rejected).
- **Adaptation**: Add a post-match verification loop:

```cpp
vector<int> naiveWithNoAdjacentDuplicates(const string& text, const string& pattern) {
    int n = text.length(), m = pattern.length();
    vector<int> validOccurrences;

    for (int s = 0; s <= n - m; ++s) {
        bool match = true;
        for (int j = 0; j < m; ++j) {
            if (text[s + j] != pattern[j]) { match = false; break; }
        }
        if (match) {
            // Twist: Enforce no two adjacent characters in matched window are equal
            bool valid = true;
            for (int k = s; k < s + m - 1; ++k) {
                if (text[k] == text[k + 1]) { valid = false; break; }
            }
            if (valid) validOccurrences.push_back(s);
        }
    }
    return validOccurrences;
}
```

---

# FAT Lab-Exam Version & Your Lab Programs (BCSE204P, Dr. Sakthivel R)

Every program below was extracted from your lab reports / FAT guide, compiled with `g++ -std=c++17 -Wall -O2`, and run; outputs shown are the real program output.

## Lab questions & verified answers

| Lab question | Scenario & input data | Verified answer |
|---|---|---|
| FAT Module 8 | Text ABABDABACDABABCABAB, pattern ABABCABAB | shift **10** |

## Naive String Matching Algorithm

### Naive String Matching
**Lab scenario:** Direct Exhaustive Pattern Search in Payload

Given a text $T[0 … n-1]$ and pattern $P[0 … m-1]$, slide $P$ over all $n - m + 1$ possible shift positions $s$ and check character-by-character whether $T[s … s+m-1] == P[0 … m-1]$.

### Concise C++ Implementation

```cpp
#include <iostream>
#include <string>
using namespace std;

void naiveSearch(const string& text, const string& pat) {
    int n = text.length(), m = pat.length();
    for (int i = 0; i <= n - m; ++i) {
        int j = 0;
        while (j < m && text[i + j] == pat[j]) j++;
        if (j == m) cout << "Pattern found at shift: " << i << "\n";
    }
}

int main() {
    naiveSearch("ABABDABACDABABCABAB", "ABABCABAB");
    return 0;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
Pattern found at shift: 10
```

**Complexity:** best O(n) · average O(n + m) · worst O((n - m + 1) m) · auxiliary space O(1)  
**Recurrence:** Exhaustive nested loop checking
