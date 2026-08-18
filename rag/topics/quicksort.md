# QuickSort (Divide and Conquer)

In-place comparison sort. Category:
[Divide and Conquer](divide_and_conquer_overview.md).

## Idea

1. **Divide**: pick a pivot element, then **partition** the array so every
   element `<= pivot` ends up to its left and every element `> pivot` ends
   up to its right. This is the real work — it happens during the "divide"
   step, unlike mergesort where the real work is in "combine".
2. **Conquer**: recursively quicksort the left partition and the right
   partition.
3. **Combine**: nothing to do — once both partitions are sorted in place
   around a correctly-placed pivot, the whole array is sorted.

This implementation uses the **Lomuto partition scheme** (pivot = last
element; a single left-to-right scan swaps elements `<= pivot` into a
growing prefix, then the pivot is swapped into its final position).

## Complexity

- **Average case**: `Θ(n log n)` — random/typical pivot choices split the
  array roughly in half each time.
- **Worst case**: `Θ(n²)` — happens when the pivot is consistently a bad
  choice, e.g. this Lomuto scheme (pivot = last element) on an
  **already-sorted** array always partitions into a size-`(n-1)` and a
  size-`0` piece. Mitigations: pick a random pivot, or the "median-of-three"
  heuristic, before partitioning.
- **In-place**: `O(log n)` extra space for the recursion stack (average
  case); no extra array needed for the data itself, unlike mergesort.

## Verified C++ implementation

Compiled with `g++ -std=c++17 -Wall -O2` and run — output confirms the
array is correctly sorted.

```cpp
#include <bits/stdc++.h>
using namespace std;

int partition(vector<int>& a, int lo, int hi) {
    int pivot = a[hi]; // choose last element as pivot
    int i = lo - 1;     // boundary of elements <= pivot
    for (int j = lo; j < hi; j++) {
        if (a[j] <= pivot) {
            i++;
            swap(a[i], a[j]);
        }
    }
    swap(a[i + 1], a[hi]);
    return i + 1; // final pivot index
}

void quickSort(vector<int>& a, int lo, int hi) {
    if (lo >= hi) return; // base case: 0 or 1 element
    int p = partition(a, lo, hi);   // divide (this IS the real work)
    quickSort(a, lo, p - 1);        // conquer: recurse left of pivot
    quickSort(a, p + 1, hi);        // conquer: recurse right of pivot
}

int main() {
    vector<int> a = {10, 7, 8, 9, 1, 5};
    cout << "Before: ";
    for (int x : a) cout << x << " ";
    cout << "\n";

    quickSort(a, 0, a.size() - 1);

    cout << "After:  ";
    for (int x : a) cout << x << " ";
    cout << "\n";
    return 0;
}
```

### Verified output

```
Before: 10 7 8 9 1 5
After:  1 5 7 8 9 10
```
