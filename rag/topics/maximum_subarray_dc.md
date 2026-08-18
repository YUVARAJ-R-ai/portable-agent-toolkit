# Maximum Subarray Sum — Divide and Conquer

Find the contiguous subarray (containing at least one element) with the
largest sum. Category: [Divide and Conquer](divide_and_conquer_overview.md).

This file contains **two** correct methods, clearly labeled — use Method 1
if the question specifically asks for a divide-and-conquer solution; Method
2 (Kadane's) is included for comparison and is a legitimate answer if the
question just asks for "the fastest" or "an O(n)" solution, but Method 2 is
**not** a divide-and-conquer algorithm — don't call it that.

## Method 1: Divide and Conquer (the D&C answer) — `O(n log n)`

**Idea**: split the array at the midpoint. The maximum subarray is entirely
in the left half, entirely in the right half, or it **crosses** the
midpoint. Recursively solve the two halves; find the best crossing subarray
directly (extend left from the midpoint as far as it keeps increasing the
sum, extend right the same way, add the two halves together) — that combine
step is `O(n)`, giving the recurrence `T(n) = 2T(n/2) + Θ(n)` → `Θ(n log n)`
by the Master Theorem (see the [D&C overview](divide_and_conquer_overview.md)).

## Method 2: Kadane's Algorithm (comparison only) — `O(n)`

**Idea**: scan once, keeping a running "best sum ending here." At each
element, either extend the previous subarray or start fresh at the current
element, whichever gives a larger sum: `cur = max(a[i], cur + a[i])`. Track
the best `cur` seen. This is a single linear pass, not a recursive
divide-and-conquer.

## Verified C++ implementation (both methods)

Compiled with `g++ -std=c++17 -Wall -O2` and run against the classic
textbook example `{-2, 1, -3, 4, -1, 2, 1, -5, 4}` — both methods agree on
the known correct answer, `6` (subarray `[4, -1, 2, 1]`).

```cpp
#include <bits/stdc++.h>
using namespace std;

// ---------- Method 1: Divide and Conquer ----------
struct CrossResult { int sum, left, right; };

CrossResult maxCrossingSubarray(const vector<int>& a, int lo, int mid, int hi) {
    int leftSum = INT_MIN, sum = 0, maxLeft = mid;
    for (int i = mid; i >= lo; i--) {
        sum += a[i];
        if (sum > leftSum) { leftSum = sum; maxLeft = i; }
    }
    int rightSum = INT_MIN, maxRight = mid + 1;
    sum = 0;
    for (int i = mid + 1; i <= hi; i++) {
        sum += a[i];
        if (sum > rightSum) { rightSum = sum; maxRight = i; }
    }
    return {leftSum + rightSum, maxLeft, maxRight};
}

// Returns {maxSum, startIndex, endIndex}
CrossResult maxSubarrayDC(const vector<int>& a, int lo, int hi) {
    if (lo == hi) return {a[lo], lo, hi}; // base case: single element

    int mid = lo + (hi - lo) / 2;
    CrossResult left = maxSubarrayDC(a, lo, mid);       // divide: left half
    CrossResult right = maxSubarrayDC(a, mid + 1, hi);  // divide: right half
    CrossResult cross = maxCrossingSubarray(a, lo, mid, hi); // combine

    if (left.sum >= right.sum && left.sum >= cross.sum) return left;
    if (right.sum >= left.sum && right.sum >= cross.sum) return right;
    return cross;
}

// ---------- Method 2: Kadane's Algorithm (comparison only) ----------
int maxSubarrayKadane(const vector<int>& a) {
    int best = a[0], cur = a[0];
    for (size_t i = 1; i < a.size(); i++) {
        cur = max((int)a[i], cur + a[i]);
        best = max(best, cur);
    }
    return best;
}

int main() {
    vector<int> a = {-2, 1, -3, 4, -1, 2, 1, -5, 4};

    CrossResult dc = maxSubarrayDC(a, 0, a.size() - 1);
    cout << "Divide & Conquer  -> maxSum = " << dc.sum
         << ", subarray = a[" << dc.left << ".." << dc.right << "]\n";

    int kadane = maxSubarrayKadane(a);
    cout << "Kadane's (compare)-> maxSum = " << kadane << "\n";
    return 0;
}
```

### Verified output

```
Divide & Conquer  -> maxSum = 6, subarray = a[3..6]
Kadane's (compare)-> maxSum = 6
```
(`a[3..6]` = `{4, -1, 2, 1}`, sum = 6 — both methods agree, as they must
since both are correct algorithms for the same problem.)
