# Activity Selection Problem (Greedy, Earliest Finish Time)

Activity selection / interval scheduling: greedy by earliest finish time (Lab 1, FAT Module 1). Category: Greedy.

---

Every program below was extracted from your lab reports / FAT guide, compiled with `g++ -std=c++17 -Wall -O2`, and run; outputs shown are the real program output.

## Lab questions & verified answers

| Lab question | Scenario & input data | Verified answer |
|---|---|---|
| Lab 1 (lab-1/greedy.cpp) | 4 activities (id,start,finish): (1,1,3) (2,2,5) (3,3,7) (4,6,9) | Selected 1, 3 (2 activities) |
| Lab 1 practice 1 & 2 / FAT | Seminar hall requests (9,12) (10,11) (11,13) (12,14) (13,15) (14,16); freelance video gigs | Activities 2, 3, 5 → 3 activities |

**Guide correction:** the FAT guide's sample output lists activities 2, 4, 6. That is wrong under either rule. With `start >= last_finish` (back-to-back allowed) the greedy picks **2 (10→11), 3 (11→13), 5 (13→15)**, which is what the guide's own code prints. With strict `>` it picks only 2 and 4. Trust the program output.

## Activity Selection Problem

### Activity Selection Problem
**Lab scenario:** Seminar Hall Scheduling (Coding Club, Drama Club, etc.) & Freelance Video Gigs

Given $N$ activities with start times $S[i]$ and finish times $F[i]$, find the maximum number of mutually compatible activities that can be scheduled in a single shared resource (e.g., seminar hall / CPU).

**Greedy Choice Property:** Always select the activity that finishes earliest among the remaining compatible activities. This leaves the maximum possible free time for subsequent activities.

### Algorithm: ActivitySelection
```python
ActivitySelection(S, F, n):
    SORT activities by finish time F ascending: F[1] <= F[2] <= ... <= F[n]
    selected = [Activity 1]
    last_finish = F[1]

    FOR j = 2 TO n:
        IF S[j] >= last_finish:
            selected.append(Activity j)
            last_finish = F[j]

    RETURN selected
```

### Concise C++ Implementation

```cpp
#include <iostream>
#include <vector>
#include <algorithm>
using namespace std;

struct Activity {
    int id, start, finish;
};

void solveActivitySelection(vector<Activity>& acts) {
    // 1. Sort strictly by finish time
    sort(acts.begin(), acts.end(), [](const Activity& a, const Activity& b) {
        return a.finish < b.finish;
    });

    cout << "Selected Activities:\n";
    int last_finish = -1;
    int count = 0;

    for (const auto& act : acts) {
        if (act.start >= last_finish) {
            cout << "Activity " << act.id << " (" << act.start << " -> " << act.finish << ")\n";
            last_finish = act.finish;
            count++;
        }
    }
    cout << "Total Scheduled: " << count << "\n";
}

int main() {
    // Lab Example: Seminar Hall Event Requests
    vector<Activity> acts = {
        {1, 9, 12}, {2, 10, 11}, {3, 11, 13},
        {4, 12, 14}, {5, 13, 15}, {6, 14, 16}
    };
    solveActivitySelection(acts);
    return 0;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
Selected Activities:
Activity 2 (10 -> 11)
Activity 3 (11 -> 13)
Activity 5 (13 -> 15)
Total Scheduled: 3
```

### Cheese Code (Ultra-Short 8-Line Exam Hack)
**Why it works in the exam:** Using std::pair directly sorts by finish time automatically without defining any struct or custom comparator!

```cpp
#include <bits/stdc++.h>
using namespace std;
int main() {
    // store as {finish, start} so default sort orders by finish time!
    vector<pair<int,int>> a = {{12,9}, {11,10}, {13,11}, {14,12}, {15,13}, {16,14}};
    sort(a.begin(), a.end());
    int count = 0, last = -1;
    for (auto p : a)
        if (p.second >= last) { count++; last = p.first; cout << p.second << "->" << p.first << " "; }
    cout << "\nMax Count: " << count << endl;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
10->11 11->13 13->15 
Max Count: 3
```

### Silly Mistakes & Traps: Activity Selection
1. **Sorting by Start Time:** Sorting by start time or duration is a fatal greedy failure! A very long event starting at 09:00 will block all others. Always sort by **Finish Time**.
2. **Strict vs Non-Strict Inequality:** Check the problem specification. If an event ends at 11:00 and another starts at 11:00, use `act.start >= last_finish`. If back-to-back overlap is forbidden, use `>`.
3. **Passing Vector by Value:** Writing `void solve(vector<Activity> acts)` causes C++ to copy the entire vector ($O(N)$ overhead). Always pass by reference: `vector<Activity>& acts`.

**Complexity:** best O(n log n) · average O(n log n) · worst O(n log n) · auxiliary space O(1) aux  
**Recurrence:** T(n) = O(n log n) [sorting] + O(n) [single pass]

## Your lab-report programs

### Your Lab 1 program (lab-1/greedy.cpp)

```cpp
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

struct Activity {
    int id;
    int start;
    int finish;
};

bool comparedActivities(const Activity& a, const Activity& b) {
    return a.finish < b.finish;
}

void selectActivities(vector<Activity>& activities) {
    // Sort activities based on the finish time
    sort(activities.begin(), activities.end(), comparedActivities);

    // Select the first activity as it finishes the earliest
    vector<int> selected_activities = {0}; // Assuming the first activity is 1-based index for simplicity

    int i = 0; // Index of the last added activity
    for (int j = 1; j < activities.size(); j++) {
        if (activities[j].start >= activities[i].finish) {
            selected_activities.push_back(j);
            i = j;
        }
    }

    // Output the selected activities
    cout << "Selected Activities: ";
    for (int id : selected_activities) {
        cout << activities[id].id << " ";
    }
    cout << endl;
}

int main() {
    vector<Activity> activities = {
        {1, 1, 3},
        {2, 2, 5},
        {3, 3, 7},
        {4, 6, 9}
    };

    selectActivities(activities);

    return 0;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
Selected Activities: 1 3
```
