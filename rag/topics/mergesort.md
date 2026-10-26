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

---

# FAT Lab-Exam Version & Your Lab Programs (BCSE204P, Dr. Sakthivel R)

Every program below was extracted from your lab reports / FAT guide, compiled with `g++ -std=c++17 -Wall -O2`, and run; outputs shown are the real program output.

## Lab questions & verified answers

| Lab question | Scenario & input data | Verified answer |
|---|---|---|
| Lab 2 Q1 | Transactions (user_id, arrival): (5,1) (2,2) (5,3) (1,4) (2,5); sort by user id, stable | 1 4 / 2 2 / 2 5 / 5 1 / 5 3 |
| Lab 2 Q2 | ECU temperatures (value, order): (72,1) (65,2) (80,3) (60,4) (75,5) | 60 4 / 65 2 / 72 1 / 75 5 / 80 3 |

**Bug in your Lab 2 Q1 report code:** the second copy loop is `for(int i=0;i<n1;i++) B[i]=...`. It must be `i<n2`. When `n1 > n2` (e.g. 5 elements split 3+2) it writes past the end of `B`. AddressSanitizer reports a heap-buffer-overflow, so the correct output was luck. The FAT code below (vector range constructors) does not have this bug.

## Merge Sort & Stable Multi-Key Sorting

### Merge Sort (Preserving Stability)
**Lab scenario:** Financial Auditing Marketplace Transactions (Sort by User ID while strictly preserving chronological arrival order)

Given $N$ records with primary key (User ID) and secondary timestamp (Arrival order), sort by primary key such that records with equal keys retain their original relative order (**Stable Sort**).

**Divide and Conquer Principle:**
1. **Divide:** Split the sequence of size $n$ into two halves of size $n/2$.
2. **Conquer:** Recursively sort both sub-arrays.
3. **Combine:** Merge the two sorted sub-arrays in linear time using a two-pointer technique.

### Algorithm: StableMergeSort
```python
MergeSort(A, left, right):
    IF left >= right: RETURN
    mid = left + (right - left) / 2
    MergeSort(A, left, mid)
    MergeSort(A, mid + 1, right)
    Merge(A, left, mid, right)

Merge(A, left, mid, right):
    L = A[left .. mid], R = A[mid + 1 .. right]
    i = 0, j = 0, k = left
    WHILE i < len(L) AND j < len(R):
        IF L[i].key <= R[j].key:   # '<=' GUARANTEES STABILITY
            A[k++] = L[i++]
        ELSE:
            A[k++] = R[j++]
    WHILE i < len(L): A[k++] = L[i++]
    WHILE j < len(R): A[k++] = R[j++]
```

### Concise C++ Implementation

```cpp
#include <iostream>
#include <vector>
using namespace std;

struct Transaction {
    int u_id;
    int arrival;
};

void merge(vector<Transaction>& arr, int left, int mid, int right) {
    int n1 = mid - left + 1, n2 = right - mid;
    vector<Transaction> L(arr.begin() + left, arr.begin() + mid + 1);
    vector<Transaction> R(arr.begin() + mid + 1, arr.begin() + right + 1);

    int i = 0, j = 0, k = left;
    while (i < n1 && j < n2) {
        // <= ensures STABILITY (earlier arrival remains before later arrival)
        if (L[i].u_id <= R[j].u_id) arr[k++] = L[i++];
        else arr[k++] = R[j++];
    }
    while (i < n1) arr[k++] = L[i++];
    while (j < n2) arr[k++] = R[j++];
}

void mergeSort(vector<Transaction>& arr, int left, int right) {
    if (left >= right) return;
    int mid = left + (right - left) / 2;
    mergeSort(arr, left, mid);
    mergeSort(arr, mid + 1, right);
    merge(arr, left, mid, right);
}

int main() {
    // Lab Example: Transactions {u_id, arrival}
    vector<Transaction> t = {{5, 1}, {2, 2}, {5, 3}, {1, 4}, {2, 5}};
    mergeSort(t, 0, t.size() - 1);
    cout << "Sorted Transactions (User ID, Arrival):\n";
    for (const auto& x : t) cout << x.u_id << " " << x.arrival << "\n";
    return 0;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
Sorted Transactions (User ID, Arrival):
1 4
2 2
2 5
5 1
5 3
```

### Cheese Code (STL std::stable_sort One-Liner)
**Why it works in the exam:** C++ STL provides std::stable_sort which guarantees O(N log N) stable sorting preserving exact arrival orders!

```cpp
#include <bits/stdc++.h>
using namespace std;
struct T { int id, arr; };
int main() {
    vector<T> t = {{5,1}, {2,2}, {5,3}, {1,4}, {2,5}};
    stable_sort(t.begin(), t.end(), [](const T& a, const T& b){ return a.id < b.id; });
    for (auto x : t) cout << x.id << " " << x.arr << "\n";
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
1 4
2 2
2 5
5 1
5 3
```

### Silly Mistakes & Traps: Merge Sort
1. **Breaking Stability with `<`:** Writing `if (L[i].u_id < R[j].u_id)` instead of `<=` swaps equal elements, completely failing the stability question!
2. **Passing Vectors by Value:** Writing `mergeSort(vector<Transaction> arr, ...)` modifies a temporary local copy and leaves the original array completely untouched! ALWAYS pass by reference: `vector<Transaction>& arr`.
3. **Integer Overflow in Midpoint:** `mid = (left + right) / 2` overflows when `left + right > INT_MAX`. Always write `mid = left + (right - left) / 2`.

**Complexity:** best O(n log n) · average O(n log n) · worst O(n log n) · auxiliary space O(n) auxiliary  
**Recurrence:** T(n) = 2 T(n/2) + O(n)
