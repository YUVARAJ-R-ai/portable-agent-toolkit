# Rabin-Karp String Matching Algorithm

The Rabin-Karp algorithm uses a polynomial rolling hash function to search for pattern occurrences in linear average time $O(n + m)$. It slides a hash window over the text, testing the pattern against the text in $O(1)$ arithmetic steps per shift, falling back to character-by-character comparison only on hash matches. Category: String Matching.

---

## 1. Algorithmic Invariants & Modulo Arithmetic

### Rolling Hash Formula
Using radix base $B = 256$ and prime modulus $Q = 10^9 + 7$:
$$H(S[0 \dots m-1]) = \sum_{k=0}^{m-1} S[k] \cdot B^{m - 1 - k} \pmod Q$$

### $O(1)$ Sliding Window Invariant
To compute $H_{i+1}$ from $H_i$:
1. Subtract the leading character: $H' = H_i - T[i] \cdot B^{m-1} \pmod Q$.
2. Multiply by radix $B$: $H'' = H' \cdot B \pmod Q$.
3. Add the incoming character: $H_{i+1} = H'' + T[i + m] \pmod Q$.

Combined formula:
$$H_{i+1} = \left((H_i - T[i] \cdot B^{m-1}) \cdot B + T[i + m]\right) \pmod Q$$

### Critical C++ Implementation Invariant
In C++, the `%` operator on negative numbers yields negative results. To guarantee a valid positive modulo residue:
```cpp
textHash = (textHash + MOD) % MOD;
```

### Complexity
- **Average / Expected Time**: $O(n + m)$.
- **Worst Case Time**: $O((n - m + 1) \cdot m)$ (occurs if bad hash causes spurious collisions at every shift).
- **Space Complexity**: $O(1)$ auxiliary space.
- **Collision Resolution**: Every hash match is followed by a character-by-character verification loop to discard spurious collisions.

---

## 2. Canonical C++ Implementation

```cpp
#include <iostream>
#include <vector>
#include <string>
using namespace std;

const long long RADIX = 256;
const long long MOD = 1000000007;

vector<int> rabinKarpSearch(const string& text, const string& pattern) {
    int n = text.length(), m = pattern.length();
    vector<int> occurrences;
    if (m == 0 || n < m) return occurrences;

    // Precompute hMultiplier = RADIX^(m - 1) % MOD
    long long hMultiplier = 1;
    for (int i = 0; i < m - 1; ++i) {
        hMultiplier = (hMultiplier * RADIX) % MOD;
    }

    long long patternHash = 0;
    long long textHash = 0;

    // Compute initial hash of pattern and first text window
    for (int i = 0; i < m; ++i) {
        patternHash = (patternHash * RADIX + pattern[i]) % MOD;
        textHash = (textHash * RADIX + text[i]) % MOD;
    }

    for (int s = 0; s <= n - m; ++s) {
        // Hash match check
        if (patternHash == textHash) {
            // Verify characters to eliminate spurious collision
            bool match = true;
            for (int j = 0; j < m; ++j) {
                if (text[s + j] != pattern[j]) {
                    match = false;
                    break;
                }
            }
            if (match) occurrences.push_back(s);
        }

        // Slide hash window to next character
        if (s < n - m) {
            textHash = (textHash - text[s] * hMultiplier) % MOD;
            textHash = (textHash * RADIX + text[s + m]) % MOD;
            textHash = (textHash + MOD) % MOD; // Guarantee non-negative residue
        }
    }
    return occurrences;
}

int main() {
    string text = "GEEKS FOR GEEKS";
    string pattern = "GEEK";
    vector<int> matches = rabinKarpSearch(text, pattern);

    cout << "Pattern found at positions: ";
    for (int idx : matches) cout << idx << " ";
    cout << "\n";
    return 0;
}
```

---

## 3. Twisted Exam Variations & Implementations

### Variation: Multiple Pattern Search of Equal Length (Dictionary Matching)
- **Scenario Keywords**: "Detect multiple signatures simultaneously", "fixed-length virus signatures", "dictionary pattern matching".
- **Core Concept**: Search for $K$ different patterns of equal length $M$ in a text of length $N$.
- **Adaptation**:
  1. Hash all $K$ patterns and insert hashes into an `unordered_set<long long> patternHashes`.
  2. Slide the hash window across the text once.
  3. When `patternHashes.count(textHash)`, perform exact string check against candidates.
- **Time Complexity**: $O(N + K \cdot M)$ instead of $O(K \cdot (N + M))$!
