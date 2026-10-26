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

---

# FAT Lab-Exam Version & Your Lab Programs (BCSE204P, Dr. Sakthivel R)

Every program below was extracted from your lab reports / FAT guide, compiled with `g++ -std=c++17 -Wall -O2`, and run; outputs shown are the real program output.

## Lab questions & verified answers

| Lab question | Scenario & input data | Verified answer |
|---|---|---|
| Lab 3 Q5 | Solar station net energy A = [−3, 4, −1, 2, 1, −5, 4, 2, −1, 3] | **9 MWh** (indices 1..9: 4−1+2+1−5+4+2−1+3) |
| FAT / Lab 3 sheet | Stock changes [−2, 1, −3, 4, −1, 2, 1, −5, 4] | **6**, days 3 to 6 → [4, −1, 2, 1] |

## Maximum Subarray Problem (Divide & Conquer & Kadane)

### Maximum Subarray Problem
**Lab scenario:** High-Frequency Stock Volatility & Solar Station Net Energy Peak Period

Given an array of daily net profits/losses $A[0 … n-1]$, find the contiguous subarray with the largest possible sum, along with its start and end indices.

**Divide and Conquer Approach:** A maximum subarray must lie either:
1. Entirely in the left half $A[low … mid]$.
2. Entirely in the right half $A[mid+1 … high]$.
3. Crossing the midpoint $mid$.

### Algorithm: Divide & Conquer Maximum Subarray
```python
FindMaxCrossingSubarray(A, low, mid, high):
    left_sum = -INF; sum = 0; max_left = mid
    FOR i = mid DOWNTO low:
        sum = sum + A[i]
        IF sum > left_sum: left_sum = sum; max_left = i

    right_sum = -INF; sum = 0; max_right = mid + 1
    FOR j = mid + 1 TO high:
        sum = sum + A[j]
        IF sum > right_sum: right_sum = sum; max_right = j

    RETURN (max_left, max_right, left_sum + right_sum)

FindMaximumSubarray(A, low, high):
    IF low == high:
        RETURN (low, high, A[low])

    mid = (low + high) / 2
    (l_low, l_high, l_sum) = FindMaximumSubarray(A, low, mid)
    (r_low, r_high, r_sum) = FindMaximumSubarray(A, mid + 1, high)
    (c_low, c_high, c_sum) = FindMaxCrossingSubarray(A, low, mid, high)

    IF l_sum >= r_sum AND l_sum >= c_sum: RETURN (l_low, l_high, l_sum)
    ELSE IF r_sum >= l_sum AND r_sum >= c_sum: RETURN (r_low, r_high, r_sum)
    ELSE: RETURN (c_low, c_high, c_sum)
```

### Concise C++ Implementation (Divide & Conquer)

```cpp
#include <iostream>
#include <vector>
#include <tuple>
#include <climits>
using namespace std;

tuple<int, int, int> findMaxCrossing(const vector<int>& A, int low, int mid, int high) {
    int left_sum = INT_MIN, sum = 0, max_left = mid;
    for (int i = mid; i >= low; --i) {
        sum += A[i];
        if (sum > left_sum) { left_sum = sum; max_left = i; }
    }
    int right_sum = INT_MIN; sum = 0; int max_right = mid + 1;
    for (int j = mid + 1; j <= high; ++j) {
        sum += A[j];
        if (sum > right_sum) { right_sum = sum; max_right = j; }
    }
    return {max_left, max_right, left_sum + right_sum};
}

tuple<int, int, int> findMaxSubarray(const vector<int>& A, int low, int high) {
    if (low == high) return {low, high, A[low]};
    int mid = low + (high - low) / 2;
    auto [l_low, l_high, l_sum] = findMaxSubarray(A, low, mid);
    auto [r_low, r_high, r_sum] = findMaxSubarray(A, mid + 1, high);
    auto [c_low, c_high, c_sum] = findMaxCrossing(A, low, mid, high);

    if (l_sum >= r_sum && l_sum >= c_sum) return {l_low, l_high, l_sum};
    if (r_sum >= l_sum && r_sum >= c_sum) return {r_low, r_high, r_sum};
    return {c_low, c_high, c_sum};
}

int main() {
    // Lab Example: Daily net stock changes
    vector<int> A = {-2, 1, -3, 4, -1, 2, 1, -5, 4};
    auto [start_idx, end_idx, max_profit] = findMaxSubarray(A, 0, A.size() - 1);
    cout << "Maximum Profit: $" << max_profit << "k\n";
    cout << "Best Trading Period: Day " << start_idx << " to Day " << end_idx << "\n";
    return 0;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
Maximum Profit: $6k
Best Trading Period: Day 3 to Day 6
```

### Cheese Code: Kadane's Linear DP (10 Lines)
**Why it works in the exam:** Kadane's algorithm achieves O(N) time and O(1) space with 10 lines of code and gives the exact same start, end, and max sum!

```cpp
#include <bits/stdc++.h>
using namespace std;
int main() {
    vector<int> A = {-2, 1, -3, 4, -1, 2, 1, -5, 4};
    int max_so_far = A[0], curr_max = A[0], start = 0, end = 0, temp_s = 0;
    for (size_t i = 1; i < A.size(); ++i) {
        if (A[i] > curr_max + A[i]) { curr_max = A[i]; temp_s = i; }
        else { curr_max += A[i]; }
        if (curr_max > max_so_far) { max_so_far = curr_max; start = temp_s; end = i; }
    }
    cout << "Max Profit: $" << max_so_far << "k from Day " << start << " to " << end << "\n";
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
Max Profit: $6k from Day 3 to 6
```

### Silly Mistakes & Traps: Maximum Subarray
1. **Initializing Max Sum to 0:** If all elements in the array are negative (e.g. `[-5, -2, -8]`), initializing `max_so_far = 0` erroneously outputs 0! Initialize with `A[0]` or `INT_MIN`.
2. **Index Misalignment:** When crossing midpoint, the left loop MUST count downwards (`mid downto low`), and right loop MUST count upwards (`mid + 1 to high`).

**Complexity:** best O(n log n) [D&C] / O(n) [Kadane] · average O(n log n) [D&C] / O(n) [Kadane] · worst O(n log n) [D&C] / O(n) [Kadane] · auxiliary space O(log n) stack [D&C] / O(1) [Kadane]  
**Recurrence:** T(n) = 2 T(n/2) + O(n) => O(n log n)
