# MergeSort (Divide and Conquer)

Comparison sort with a guaranteed worst-case bound. Category:
[Divide and Conquer](divide_and_conquer_overview.md).

## Idea

1. **Divide**: split the array in half.
2. **Conquer**: recursively mergesort each half.
3. **Combine**: **merge** the two now-sorted halves into one sorted array —
   this is where the real work happens (opposite of quicksort, where the
   work is in "divide").

The merge step walks both halves with two pointers, always taking the
smaller of the two current elements, until one half is exhausted, then
appends the rest of the other half.

## Complexity

- **Always** `Θ(n log n)` — unlike quicksort, there is no bad-input worst
  case, because the split is always exactly in half regardless of the data.
- **Not in-place**: the merge step needs `Θ(n)` extra space for temporary
  left/right buffers (this implementation copies into two `vector<int>`
  buffers per merge call).
- **Stable**: equal elements keep their relative order (this implementation
  takes from `left` on ties, `left[i] <= right[j]`).

## Verified C++ implementation

Compiled with `g++ -std=c++17 -Wall -O2` and run — output confirms the
array is correctly sorted.

```cpp
#include <bits/stdc++.h>
using namespace std;

void merge(vector<int>& a, int lo, int mid, int hi) {
    vector<int> left(a.begin() + lo, a.begin() + mid + 1);
    vector<int> right(a.begin() + mid + 1, a.begin() + hi + 1);

    size_t i = 0, j = 0;
    int k = lo;
    while (i < left.size() && j < right.size()) {
        if (left[i] <= right[j]) a[k++] = left[i++];
        else a[k++] = right[j++];
    }
    while (i < left.size()) a[k++] = left[i++];
    while (j < right.size()) a[k++] = right[j++];
}

void mergeSort(vector<int>& a, int lo, int hi) {
    if (lo >= hi) return; // base case: 0 or 1 element
    int mid = lo + (hi - lo) / 2;
    mergeSort(a, lo, mid);       // divide: sort left half
    mergeSort(a, mid + 1, hi);   // divide: sort right half
    merge(a, lo, mid, hi);       // combine: merge the two sorted halves
}

int main() {
    vector<int> a = {12, 11, 13, 5, 6, 7};
    cout << "Before: ";
    for (int x : a) cout << x << " ";
    cout << "\n";

    mergeSort(a, 0, a.size() - 1);

    cout << "After:  ";
    for (int x : a) cout << x << " ";
    cout << "\n";
    return 0;
}
```

### Verified output

```
Before: 12 11 13 5 6 7
After:  5 6 7 11 12 13
```
