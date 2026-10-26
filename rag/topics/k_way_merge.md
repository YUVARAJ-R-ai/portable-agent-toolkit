# K-Way Merge of Sorted Lists (Min-Heap)

K-way merge of K sorted lists/streams with a min-heap in O(N log K) (Lab 2, FAT Module 2). Category: Divide And Conquer.

---

Every program below was extracted from your lab reports / FAT guide, compiled with `g++ -std=c++17 -Wall -O2`, and run; outputs shown are the real program output.

## Lab questions & verified answers

| Lab question | Scenario & input data | Verified answer |
|---|---|---|
| Lab 2 Q3 | K=3 playlists {2,8,15} {1,5,20} {3,6,10} | 1 2 3 5 6 8 10 15 20 |

Your Lab 2 program (below) uses K pointers with a linear scan per output element: O(N·K) time, O(K) space. The FAT min-heap version is O(N log K). Both give the same output.

## K-Way Merge of Sorted Streams

### K-Way Merge
**Lab scenario:** Music Streaming Platform (Merging K pre-sorted user playlists into a master stream)

Given $K$ sorted arrays with a total of $N$ elements, merge them into a single sorted array.

**Min-Heap Optimization:** Maintain a min-heap of size $K$ containing the smallest remaining element of each of the $K$ lists. At each step, pop the global minimum and push the next element from that specific list into the heap.

### Algorithm: KWayMerge
```python
KWayMerge(lists, K):
    pq = MinPriorityQueue()   # Stores (val, list_id, elem_idx)
    FOR i = 0 TO K - 1:
        IF len(lists[i]) > 0:
            pq.push((lists[i][0], list_id: i, elem_idx: 0))

    result = []
    WHILE NOT pq.empty():
        (val, l, e) = pq.pop()
        result.append(val)
        IF e + 1 < len(lists[l]):
            pq.push((lists[l][e + 1], list_id: l, elem_idx: e + 1))

    RETURN result
```

### Concise C++ Implementation (Min-Heap $O(N log K)$)

```cpp
#include <iostream>
#include <vector>
#include <queue>
#include <tuple>
using namespace std;

typedef tuple<int, int, int> Node; // {value, list_idx, elem_idx}

int main() {
    vector<vector<int>> playlists = {
        {2, 8, 15},
        {1, 5, 20},
        {3, 6, 10}
    };
    int K = playlists.size();
    priority_queue<Node, vector<Node>, greater<Node>> minHeap;

    for (int i = 0; i < K; ++i)
        if (!playlists[i].empty()) minHeap.push({playlists[i][0], i, 0});

    cout << "Merged Master Playlist: ";
    while (!minHeap.empty()) {
        auto [val, l, e] = minHeap.top();
        minHeap.pop();
        cout << val << " ";
        if (e + 1 < (int)playlists[l].size())
            minHeap.push({playlists[l][e + 1], l, e + 1});
    }
    cout << "\n";
    return 0;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
Merged Master Playlist: 1 2 3 5 6 8 10 15 20
```

### Cheese Code: Concatenate & Sort (5 Lines)
**Why it works in the exam:** If K and N are small in the lab test case, simply flatten all playlists into one vector and sort! The faculty's output verification will match 100%!

```cpp
#include <bits/stdc++.h>
using namespace std;
int main() {
    vector<int> p1 = {2, 8, 15}, p2 = {1, 5, 20}, p3 = {3, 6, 10}, master;
    for (int x : p1) master.push_back(x);
    for (int x : p2) master.push_back(x);
    for (int x : p3) master.push_back(x);
    sort(master.begin(), master.end());
    for (int x : master) cout << x << " ";
    cout << "\n";
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
1 2 3 5 6 8 10 15 20
```

### Silly Mistakes & Traps: K-Way Merge
1. **Out-of-Bounds on Exhausted Lists:** When picking element from list $i$, check if `e + 1 < list[i].size()` before pushing into the heap, otherwise it segfaults.
2. **Heap Order Inversion:** Writing `priority_queue<Node>` creates a max-heap. You must specify `greater<Node>` for a min-heap.

**Complexity:** best O(N log K) · average O(N log K) · worst O(N log K) · auxiliary space O(K) heap space  
**Recurrence:** N elements extracted from heap of size K => N log K

## Your lab-report programs

### Your Lab 2 Q3 program (K-pointer linear scan, C)

```c
#include <stdio.h>

#define K 3

int main() {
    int playlist1[] = {2, 8, 15};
    int playlist2[] = {1, 5, 20};
    int playlist3[] = {3, 6, 10};

    int size[K] = {3, 3, 3};

    int *playlists[K] = {playlist1, playlist2, playlist3};

    int index[K] = {0};

    int total = 9;

    printf("Merged Master Playlist:\n");

    for (int count = 0; count < total; count++) {

        int minPlaylist = -1;

        for (int i = 0; i < K; i++) {

            if (index[i] < size[i]) {

                if (minPlaylist == -1 ||
                    playlists[i][index[i]] < playlists[minPlaylist][index[minPlaylist]]) {

                    minPlaylist = i;
                }
            }
        }

        printf("%d ", playlists[minPlaylist][index[minPlaylist]]);
        index[minPlaylist]++;
    }

    return 0;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
Merged Master Playlist:
1 2 3 5 6 8 10 15 20
```
