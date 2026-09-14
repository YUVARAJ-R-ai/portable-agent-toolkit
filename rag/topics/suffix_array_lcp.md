# Suffix Structures: Suffix Array & Kasai's LCP Algorithm

A Suffix Tree for string $S$ is a compressed trie storing all suffixes of $S$. While full Ukkonen construction requires complex pointers and active points, professors in DAA lab exams test suffix concepts through **Suffix Arrays** coupled with **Kasai's $O(n)$ Longest Common Prefix (LCP) Array**. This solves all canonical Suffix Tree queries (Longest Repeated Substring, Longest Common Substring, and Distinct Substrings) in clean, robust C++. Category: String Matching.

---

## 1. Theoretical Foundations & Suffix Trees

### Suffix Tree Properties
- Exactly $n$ leaves (one per suffix starting at index $0 \dots n-1$).
- At most $n - 1$ internal branching nodes (total nodes $\le 2n - 1$).
- Edges store string index pairs `[left, right]` to maintain $O(n)$ space.
- Ukkonen's algorithm constructs it in $O(n)$ time using suffix links.

### Suffix Array & LCP Array Definitions
- **Suffix Array (SA)**: An integer array of size $n$ containing the starting indices of all suffixes of $S$, sorted in lexicographical order.
- **LCP Array**: $\text{LCP}[i]$ stores the length of the longest common prefix between suffix $\text{SA}[i]$ and suffix $\text{SA}[i - 1]$.
- **Kasai's Algorithm**: Computes the complete LCP array in strictly linear $O(n)$ time by tracking rank and exploiting the invariant that the common prefix length drops by at most 1 when moving from suffix $i$ to suffix $i+1$.

### Complexity
- **Suffix Array Construction**: $O(n \log n)$ using standard comparator sort.
- **LCP Construction (Kasai)**: $O(n)$ time.
- **Space Complexity**: $O(n)$ auxiliary vectors for `sa`, `rank`, and `lcp`.

---

## 2. Complete C++ Implementation & Query Engine

```cpp
#include <iostream>
#include <vector>
#include <string>
#include <algorithm>
using namespace std;

// 1. Suffix Array Construction: O(n log n)
vector<int> buildSuffixArray(const string& s) {
    int n = s.length();
    vector<int> sa(n);
    for (int i = 0; i < n; ++i) sa[i] = i;

    sort(sa.begin(), sa.end(), [&](int a, int b) {
        return s.compare(a, string::npos, s, b, string::npos) < 0;
    });
    return sa;
}

// 2. Kasai's Algorithm for Longest Common Prefix (LCP) array in O(n)
vector<int> buildLCP(const string& s, const vector<int>& sa) {
    int n = s.length();
    vector<int> rank(n, 0), lcp(n, 0);
    for (int i = 0; i < n; ++i) rank[sa[i]] = i;

    int h = 0;
    for (int i = 0; i < n; ++i) {
        if (rank[i] > 0) {
            int j = sa[rank[i] - 1];
            while (i + h < n && j + h < n && s[i + h] == s[j + h]) h++;
            lcp[rank[i]] = h;
            if (h > 0) h--;
        }
    }
    return lcp;
}

// Query 1: Longest Repeated Substring (Deepest internal node in Suffix Tree)
string longestRepeatedSubstring(const string& s) {
    vector<int> sa = buildSuffixArray(s);
    vector<int> lcp = buildLCP(s, sa);

    int maxLen = 0, startIdx = 0;
    for (int i = 1; i < (int)s.length(); ++i) {
        if (lcp[i] > maxLen) {
            maxLen = lcp[i];
            startIdx = sa[i];
        }
    }
    return maxLen == 0 ? "" : s.substr(startIdx, maxLen);
}

// Query 2: Longest Common Substring of Two Strings (Generalized Suffix Tree)
string longestCommonSubstringTwoStrings(const string& s1, const string& s2) {
    string combined = s1 + "#" + s2 + "$";
    int n1 = s1.length();
    vector<int> sa = buildSuffixArray(combined);
    vector<int> lcp = buildLCP(combined, sa);

    int maxLen = 0, bestStart = 0;
    for (int i = 1; i < (int)combined.length(); ++i) {
        // One suffix from s1 (sa < n1) and one from s2 (sa > n1)
        bool fromS1_prev = (sa[i - 1] < n1);
        bool fromS1_curr = (sa[i] < n1);
        bool fromS2_prev = (sa[i - 1] > n1);
        bool fromS2_curr = (sa[i] > n1);

        if ((fromS1_prev && fromS2_curr) || (fromS2_prev && fromS1_curr)) {
            if (lcp[i] > maxLen) {
                maxLen = lcp[i];
                bestStart = sa[i];
            }
        }
    }
    return maxLen == 0 ? "" : combined.substr(bestStart, maxLen);
}

// Query 3: Count of Distinct Substrings = n*(n+1)/2 - sum(lcp)
long long countDistinctSubstrings(const string& s) {
    long long n = s.length();
    long long total = n * (n + 1) / 2;
    vector<int> sa = buildSuffixArray(s);
    vector<int> lcp = buildLCP(s, sa);
    for (int x : lcp) total -= x;
    return total;
}

int main() {
    string s = "banana";
    cout << "Longest Repeated Substring in 'banana': "
         << longestRepeatedSubstring(s) << "\n"; // "ana"

    string s1 = "geeksforgeeks", s2 = "quizgeeks";
    cout << "Longest Common Substring between 'geeksforgeeks' & 'quizgeeks': "
         << longestCommonSubstringTwoStrings(s1, s2) << "\n"; // "geeks"

    cout << "Distinct substrings in 'banana': "
         << countDistinctSubstrings(s) << "\n"; // 15
    return 0;
}
```

### Verified Output
```
Longest Repeated Substring in 'banana': ana
Longest Common Substring between 'geeksforgeeks' & 'quizgeeks': geeks
Distinct substrings in 'banana': 15
```
