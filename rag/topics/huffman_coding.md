# Huffman Coding (Greedy)

Builds an optimal **prefix code** (no code is a prefix of another, so a
bitstream can be decoded unambiguously without delimiters) that minimizes
the expected number of bits per symbol, given each symbol's frequency.
Category: [Greedy algorithm](greedy_overview.md).

## Idea

1. Put every symbol in a min-priority-queue keyed by frequency.
2. Repeatedly remove the **two least-frequent** nodes and merge them into a
   new internal node whose frequency is their sum; push the merged node back.
3. Stop when one node remains — that's the root of the Huffman tree.
4. Walk the tree: each left edge appends `0`, each right edge appends `1` to
   the code. A symbol's code is the bit-string on the path from root to its
   leaf.

**Why this is greedy, and why it's correct**: at every step, the algorithm
makes the locally-best choice (merge the two *currently* least-frequent
nodes) and never revisits it. The greedy-choice property holds because in
*some* optimal tree, the two globally least-frequent symbols can always be
placed as siblings at the deepest level — swapping any other pair of leaves
to make this true never increases the tree's total cost. Once that first
merge is fixed, the rest of the problem is identical on a smaller alphabet
(the merged node standing in for both symbols) — this is the optimal
substructure. Both properties together are what make the greedy choice at
every step provably lead to a globally optimal (minimum expected code
length) tree.

## Complexity

`O(n log n)` for `n` distinct symbols — each of the `n-1` merges does two
`O(log n)` priority-queue pops and one push.

## Verified C++ implementation

Compiled with `g++ -std=c++17 -Wall -O2` and run — output included below,
confirming the decode round-trip matches the original input exactly.

```cpp
#include <bits/stdc++.h>
using namespace std;

struct Node {
    char ch;
    int freq;
    Node *left, *right;
    Node(char c, int f, Node* l = nullptr, Node* r = nullptr)
        : ch(c), freq(f), left(l), right(r) {}
};

struct Compare {
    bool operator()(Node* a, Node* b) { return a->freq > b->freq; } // min-heap
};

void generateCodes(Node* root, string code, unordered_map<char, string>& table) {
    if (!root) return;
    if (!root->left && !root->right) { // leaf
        table[root->ch] = code.empty() ? "0" : code; // handle single-symbol edge case
        return;
    }
    generateCodes(root->left, code + "0", table);
    generateCodes(root->right, code + "1", table);
}

Node* buildHuffmanTree(const unordered_map<char, int>& freq) {
    priority_queue<Node*, vector<Node*>, Compare> pq;
    for (auto& [ch, f] : freq) pq.push(new Node(ch, f));

    if (pq.size() == 1) { // single distinct symbol: wrap so it still gets a code
        Node* only = pq.top(); pq.pop();
        return new Node('\0', only->freq, only, nullptr);
    }

    while (pq.size() > 1) {
        Node* left = pq.top(); pq.pop();
        Node* right = pq.top(); pq.pop();
        Node* merged = new Node('\0', left->freq + right->freq, left, right);
        pq.push(merged);
    }
    return pq.top();
}

int main() {
    string text = "abracadabra";
    unordered_map<char, int> freq;
    for (char c : text) freq[c]++;

    Node* root = buildHuffmanTree(freq);
    unordered_map<char, string> codes;
    generateCodes(root, "", codes);

    cout << "Character frequencies:\n";
    for (auto& [ch, f] : freq) cout << "  '" << ch << "': " << f << "\n";

    cout << "\nHuffman codes:\n";
    vector<pair<char, string>> sorted(codes.begin(), codes.end());
    sort(sorted.begin(), sorted.end());
    for (auto& [ch, code] : sorted) cout << "  '" << ch << "': " << code << "\n";

    string encoded;
    for (char c : text) encoded += codes[c];
    cout << "\nOriginal length (bits, 8/char): " << text.size() * 8 << "\n";
    cout << "Encoded length (bits): " << encoded.size() << "\n";

    // Decode to verify correctness
    string decoded;
    Node* cur = root;
    for (char bit : encoded) {
        cur = (bit == '0') ? cur->left : cur->right;
        if (!cur->left && !cur->right) { decoded += cur->ch; cur = root; }
    }
    cout << "Decoded matches original: " << (decoded == text ? "YES" : "NO") << "\n";
    return 0;
}
```

### Verified output (input: `"abracadabra"`)

```
Character frequencies:
  'd': 1
  'c': 1
  'r': 2
  'b': 2
  'a': 5

Huffman codes:
  'a': 0
  'b': 111
  'c': 101
  'd': 100
  'r': 110

Original length (bits, 8/char): 88
Encoded length (bits): 23
Decoded matches original: YES
```
Note the most frequent character (`'a'`, freq 5) gets the shortest code
(`0`) — that's the whole point of the algorithm. Exact codes for
equal-frequency symbols (`'r'` and `'b'`, both freq 2) depend on priority
queue tie-breaking and can legitimately differ between correct
implementations; the *lengths* and the total encoded size are what matter.

---

# FAT Lab-Exam Version & Your Lab Programs (BCSE204P, Dr. Sakthivel R)

Every program below was extracted from your lab reports / FAT guide, compiled with `g++ -std=c++17 -Wall -O2`, and run; outputs shown are the real program output.

## Lab questions & verified answers

| Lab question | Scenario & input data | Verified answer |
|---|---|---|
| Lab 3 Q2 | CAN-bus telemetry: I=50000, S=25000, P=12000, A=8000, W=4000, C=1000 (100,000 frames) | Codes I=0, S=10, P=110, A=1111, W=11101, C=11100 → **193,000 bits** vs 300,000 bits fixed 3-bit |

**Guide corrections:** (1) the FAT guide's "cheese code" comment claims 174000 bits. The real total for the lab frequencies is **193000** (depths 1,2,3,4,5,5). (2) The guide's sample I/O box uses the CLRS frequencies 45/13/12/16/9/5 (224 bits), not the lab frequencies used by its code. Use the program outputs below.

Shortcut: total encoded bits = sum of all internal-node weights created while merging (5000+13000+25000+50000+100000 = 193000).

## Huffman Coding (Optimal Prefix-Free Codes)

### Huffman Coding
**Lab scenario:** CAN Bus Vehicle Telemetry Compression (I, S, P, A, W, C status codes)

Given a set of characters and their frequencies, construct a binary tree of minimal external path weight such that more frequent characters receive shorter variable-length prefix-free codes.

**Greedy Property:** The two symbols with the lowest frequencies must appear as sibling leaf nodes at the deepest level of the optimal code tree.

### Algorithm: Huffman
```python
Huffman(C, f, n):
    Q = MinPriorityQueue(C, f)   # Leaf nodes: character, frequency

    FOR i = 1 TO n - 1:
        z = allocate_node()
        z.left = Q.extract_min()
        z.right = Q.extract_min()
        z.freq = z.left.freq + z.right.freq
        Q.insert(z)

    RETURN Q.extract_min()       # Root of optimal prefix-free tree
```

### Concise C++ Implementation

```cpp
#include <iostream>
#include <vector>
#include <queue>
#include <string>
#include <map>
using namespace std;

struct Node {
    char ch;
    int freq;
    Node *left, *right;
    Node(char c, int f, Node* l = nullptr, Node* r = nullptr)
        : ch(c), freq(f), left(l), right(r) {}
};

struct Compare {
    bool operator()(Node* a, Node* b) { return a->freq > b->freq; } // Min-heap!
};

void buildCodes(Node* root, string code, map<char, string>& codes) {
    if (!root) return;
    if (!root->left && !root->right) {
        codes[root->ch] = code;
        return;
    }
    buildCodes(root->left, code + "0", codes);
    buildCodes(root->right, code + "1", codes);
}

int main() {
    vector<char> chars = {'I', 'S', 'P', 'A', 'W', 'C'};
    vector<int> freq = {50000, 25000, 12000, 8000, 4000, 1000};

    priority_queue<Node*, vector<Node*>, Compare> pq;
    for (size_t i = 0; i < chars.size(); ++i)
        pq.push(new Node(chars[i], freq[i]));

    while (pq.size() > 1) {
        Node* left = pq.top(); pq.pop();
        Node* right = pq.top(); pq.pop();
        pq.push(new Node('$', left->freq + right->freq, left, right));
    }

    map<char, string> huffmanCodes;
    buildCodes(pq.top(), "", huffmanCodes);

    cout << "--- Huffman Codes ---\n";
    long long totalBits = 0;
    for (size_t i = 0; i < chars.size(); ++i) {
        cout << chars[i] << " : " << huffmanCodes[chars[i]] << "\n";
        totalBits += (long long)freq[i] * huffmanCodes[chars[i]].length();
    }
    cout << "Total Encoded Size: " << totalBits << " bits\n";
    cout << "Fixed (3-bit) Size: 300000 bits\n";
    return 0;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
--- Huffman Codes ---
I : 0
S : 10
P : 110
A : 1111
W : 11101
C : 11100
Total Encoded Size: 193000 bits
Fixed (3-bit) Size: 300000 bits
```

### Cheese Code: Calculating Total Encoded Bits Without Building Trees
**Why it works in the exam:** The total length of encoded text equals the sum of frequencies of all internal nodes in the Huffman tree! No string or tree manipulation needed!

```cpp
#include <bits/stdc++.h>
using namespace std;
int main() {
    priority_queue<long long, vector<long long>, greater<long long>> pq;
    for (int f : {50000, 25000, 12000, 8000, 4000, 1000}) pq.push(f);
    long long totalBits = 0;
    while (pq.size() > 1) {
        long long a = pq.top(); pq.pop();
        long long b = pq.top(); pq.pop();
        totalBits += (a + b);
        pq.push(a + b);
    }
    cout << "Total Encoded Bits: " << totalBits << "\n"; // Outputs exact 174000 bits!
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
Total Encoded Bits: 193000
```

### Silly Mistakes & Traps: Huffman Coding
1. **C++ Priority Queue Comparator Direction:** In C++ STL, `priority_queue` is a **MAX-HEAP** by default. If you write `a->freq < b->freq`, it pops the **LARGEST** frequencies first! You MUST write `a->freq > b->freq` to make it a min-heap.
2. **Base Case Leaf Check:** Check `!root->left && !root->right`. Do not compare `root->ch != '$'` because internal dummy characters might clash.
3. **Integer Overflow on Large Frequencies:** In the lab problem, frequencies reach 50,000 and total bit calculations exceed $10^8$. Use `long long` for total bit counters!

**Complexity:** best O(n log n) · average O(n log n) · worst O(n log n) · auxiliary space O(n)  
**Recurrence:** T(n) = sum_(i=1)^(n-1) O(log i) = O(n log n)
