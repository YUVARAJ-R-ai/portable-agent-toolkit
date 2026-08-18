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
