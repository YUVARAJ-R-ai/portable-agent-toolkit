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

---

# FAT Lab-Exam Version & Your Lab Programs (BCSE204P, Dr. Sakthivel R)

Every program below was extracted from your lab reports / FAT guide, compiled with `g++ -std=c++17 -Wall -O2`, and run; outputs shown are the real program output.

## Lab questions & verified answers

| Lab question | Scenario & input data | Verified answer |
|---|---|---|
| Lab 9 Q4 | IoT stream 2718281828459045235360287471, signature 284590, base 10, mod 97 | pattern hash **89**; spurious hit at index 5; genuine match at index **8** |

**Guide correction:** the FAT guide's sample output says pattern hash 52 with no spurious hits. Wrong: 284590 mod 97 = **89**, and window 818284 at index 5 also hashes to 89, a **spurious hit** the verification loop rejects. Your Lab 9 program and the FAT code both print the correct values (below).

## Rabin-Karp String Matching Algorithm (Rolling Hash)

### Rabin-Karp Algorithm
**Lab scenario:** IoT Telemetry Stream `2718281828459045235360287471` Detecting Alert Signature `284590` (Base 10, Mod 97)

Treat the pattern as a base-$d$ number. Compute a hash value for $P$ and for each length-$m$ window in $T$. If window hash matches pattern hash, verify character-by-character to eliminate **spurious hits** (hash collisions).

**Rolling Hash Formula:**
$ h = d^(m-1) mod q $
$ t_(s+1) = (d · (t_s - T[s] · h) + T[s + m]) mod q $
**Critical C++ Rule:** Modulo of negative numbers in C++ produces negative output! You MUST write `if (t < 0) t += q;`.

### Algorithm: RabinKarp
```python
RabinKarp(T, P, d, q):
    n = len(T); m = len(P)
    h = (d^(m - 1)) % q
    p = 0; t = 0

    FOR i = 0 TO m - 1:
        p = (d * p + P[i]) % q
        t = (d * t + T[i]) % q

    FOR s = 0 TO n - m:
        IF p == t:
            IF T[s .. s + m - 1] == P[0 .. m - 1]:
                OUTPUT "Match found at shift", s

        IF s < n - m:
            t = (d * (t - T[s] * h) + T[s + m]) % q
            IF t < 0: t = t + q      # C++ negative modulo fix
```

### Concise C++ Implementation (Base 10, Mod 97)

```cpp
#include <iostream>
#include <string>
using namespace std;

void rabinKarp(const string& text, const string& pat, int d, int q) {
    int n = text.length(), m = pat.length();
    int p = 0, t = 0, h = 1;

    // h = (d^(m-1)) % q
    for (int i = 0; i < m - 1; ++i) h = (h * d) % q;

    // Initial hashes
    for (int i = 0; i < m; ++i) {
        p = (d * p + (pat[i] - '0')) % q;
        t = (d * t + (text[i] - '0')) % q;
    }

    cout << "Pattern Hash: " << p << "\n";
    for (int s = 0; s <= n - m; ++s) {
        if (p == t) {
            // Verify characters to rule out spurious hits
            bool match = true;
            for (int j = 0; j < m; ++j) {
                if (text[s + j] != pat[j]) { match = false; break; }
            }
            if (match) cout << "Valid Match at index " << s << " (Hash = " << t << ")\n";
            else cout << "Spurious Hit at index " << s << "\n";
        }
        if (s < n - m) {
            t = (d * (t - (text[s] - '0') * h) + (text[s + m] - '0')) % q;
            if (t < 0) t += q; // C++ negative modulo fix!
        }
    }
}

int main() {
    // Lab Example: Telemetry stream and alert signature
    string text = "2718281828459045235360287471";
    string pat = "284590";
    rabinKarp(text, pat, 10, 97);
    return 0;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
Pattern Hash: 89
Spurious Hit at index 5
Valid Match at index 8 (Hash = 89)
```

### Cheese Code: std::string::find (3 Lines)
**Why it works in the exam:** If in doubt during the exam, C++ std::string::find searches substrings in linear-expected time!

```cpp
#include <iostream>
#include <string>
using namespace std;
int main() {
    string text = "2718281828459045235360287471", pat = "284590";
    size_t pos = text.find(pat);
    while (pos != string::npos) {
        cout << "Pattern found at: " << pos << endl;
        pos = text.find(pat, pos + 1);
    }
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
Pattern found at: 8
```

### Silly Mistakes & Traps: Rabin-Karp
1. **Negative Modulo in C++:** In C++, `-15 % 97` evaluates to `-15`, NOT `82`! Failing to write `if (t < 0) t += q;` will corrupt all subsequent rolling hash windows!
2. **Skipping Spurious Hit Check:** Assuming hash equality implies string equality is incorrect. Hash collisions happen; you must verify actual characters when $p == t$.
3. **Power Calculation:** Writing `pow(d, m-1)` uses floating-point math and loses integer precision. Compute $h$ via an integer loop modulo $q$.

**Complexity:** best O(n + m) · average O(n + m) · worst O((n - m + 1) m) · auxiliary space O(1) aux  
**Recurrence:** Average O(n+m) assuming few hash collisions
