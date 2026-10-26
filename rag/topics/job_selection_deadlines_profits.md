# Job Selection with Deadlines and Profits (Branch and Bound)

Given $n$ jobs, each requiring 1 unit of execution time, having profit $p_i$ and deadline $d_i$. A job yields profit only if completed on or before its deadline. Only one job can execute per unit time slot. The objective is to maximize total profit using Branch and Bound. Category: Branch and Bound.

---

## 1. Algorithmic Invariants (Lab 6 Standard)

1. **Profit Sorting**: Pre-sort all jobs in non-increasing order of profit ($p_1 \ge p_2 \ge \dots \ge p_n$).
2. **Greedy Slot Allocation**: When exploring the inclusion of a job, schedule it at the **latest available slot** $t \le d_i$ (counting down from $d_i$ to 1). This leaves earlier slots open for jobs with tighter deadlines.
3. **1-Based Time Indexing**: Dr. Sakthivel's lab standard indexes time slots from $t = 1$ to $t = \max(d_i)$. The boolean slot array size must be $\max(d_i) + 1$.
4. **Optimistic Upper Bound**:
   $$\text{Bound}(\text{index}, \text{currentProfit}) = \text{currentProfit} + \sum_{k=\text{index}}^{n-1} p_k$$
5. **Pruning Condition**: If $\text{Bound} \le \text{bestProfit}$, prune the subtree immediately.

### Complexity
- **Time Complexity**: Best $O(n \log n)$ (sorting), Average $O(k^n)$ with $k < 2$ (pruned branch and bound), Worst case $O(2^n)$ (unpruned binary tree).
- **Space Complexity**: $O(n + D)$ where $D = \max(d_i)$ is maximum deadline (slot tracking vector + recursion stack depth $n$).

---

## 2. Canonical C++ Implementation (Lab 6 Standard)

```cpp
#include <iostream>
#include <vector>
#include <string>
#include <algorithm>
using namespace std;

struct Job {
    string name;
    int profit;
    int deadline;
};

class JobSelectionBB {
private:
    int n;
    int maxDeadline;
    vector<Job> jobs;
    int bestProfit;
    vector<string> bestJobs;
    vector<string> currentJobs;
    vector<bool> slot; // slot[t] == true if time slot t is occupied

    int findSlot(const Job& job) {
        // Greedily search latest available slot from deadline down to 1
        for (int t = min(job.deadline, maxDeadline); t >= 1; --t) {
            if (!slot[t]) return t;
        }
        return -1;
    }

    int calculateBound(int index, int currentProfit) {
        int bound = currentProfit;
        for (int i = index; i < n; ++i) {
            bound += jobs[i].profit; // Optimistic assumption: all remaining can be taken
        }
        return bound;
    }

    void branchAndBound(int index, int currentProfit) {
        if (index == n) {
            if (currentProfit > bestProfit) {
                bestProfit = currentProfit;
                bestJobs = currentJobs;
            }
            return;
        }

        // Pruning: if even optimistic bound cannot beat best profit, abort branch
        if (calculateBound(index, currentProfit) <= bestProfit) {
            return;
        }

        // --- Branch 1: Try Including Job ---
        int t = findSlot(jobs[index]);
        if (t != -1) {
            slot[t] = true;
            currentJobs.push_back(jobs[index].name);

            branchAndBound(index + 1, currentProfit + jobs[index].profit);

            currentJobs.pop_back();
            slot[t] = false; // Backtrack
        }

        // --- Branch 2: Exclude Job ---
        branchAndBound(index + 1, currentProfit);
    }

public:
    JobSelectionBB(vector<Job> inputJobs) : jobs(inputJobs), bestProfit(0) {
        n = jobs.size();
        maxDeadline = 0;
        for (const auto& j : jobs) maxDeadline = max(maxDeadline, j.deadline);
        slot.assign(maxDeadline + 1, false);

        // Sort descending by profit
        sort(jobs.begin(), jobs.end(), [](const Job& a, const Job& b) {
            return a.profit > b.profit;
        });
    }

    void solve() {
        branchAndBound(0, 0);
        cout << "Maximum Profit = " << bestProfit << "\nSelected Jobs = ";
        for (const auto& s : bestJobs) cout << s << " ";
        cout << "\n";
    }
};

int main() {
    vector<Job> jobs = {
        {"J1", 100, 2},
        {"J2", 19, 1},
        {"J3", 27, 2},
        {"J4", 25, 1},
        {"J5", 15, 3}
    };
    JobSelectionBB solver(jobs);
    solver.solve();
    return 0;
}
```

---

## 3. Twisted Exam Variations & Implementations

### Variation 1: Variable Processing Times ($t_i \ge 1$) — Knapsack Scheduling Hybrid
- **Scenario Keywords**: "Variable duration jobs", "multi-unit processing time", "knapsack scheduling hybrid".
- **Core Concept**: Jobs take $t_i > 1$ units of time. A discrete slot array is replaced by cumulative elapsed time $T$.
- **Adaptation**: Sort jobs by profit density $(p_i / t_i)$ descending. The bounding function uses **Fractional Knapsack relaxation**: fill remaining available capacity with whole jobs, and take a fraction of the first job that overflows.

```cpp
struct VarJob {
    string name;
    int profit, deadline, duration;
};

int bestVarProfit = 0;
vector<string> bestVarSchedule;

int calcKnapsackBound(int index, int n, int currentTime, int currentProfit,
                      int maxTime, const vector<VarJob>& jobs) {
    int bound = currentProfit;
    int remainingTime = maxTime - currentTime;

    for (int i = index; i < n; ++i) {
        if (jobs[i].duration <= remainingTime) {
            bound += jobs[i].profit;
            remainingTime -= jobs[i].duration;
        } else {
            // Fractional relaxation: add proportional profit for leftover time
            bound += (int)(jobs[i].profit * ((double)remainingTime / jobs[i].duration));
            break;
        }
    }
    return bound;
}

void bbVariableJobs(int index, int n, int currentTime, int currentProfit, int maxTime,
                    const vector<VarJob>& jobs, vector<string>& currentSchedule) {
    if (index == n) {
        if (currentProfit > bestVarProfit) {
            bestVarProfit = currentProfit;
            bestVarSchedule = currentSchedule;
        }
        return;
    }

    if (calcKnapsackBound(index, n, currentTime, currentProfit, maxTime, jobs) <= bestVarProfit)
        return;

    // Branch 1: Include job if it finishes on or before its deadline
    if (currentTime + jobs[index].duration <= jobs[index].deadline) {
        currentSchedule.push_back(jobs[index].name);
        bbVariableJobs(index + 1, n, currentTime + jobs[index].duration,
                       currentProfit + jobs[index].profit, maxTime, jobs, currentSchedule);
        currentSchedule.pop_back();
    }

    // Branch 2: Exclude job
    bbVariableJobs(index + 1, n, currentTime, currentProfit, maxTime, jobs, currentSchedule);
}
```

---

### Variation 2: Job Selection with Rejection Penalties / Late Fines
- **Scenario Keywords**: "Uncompleted tasks incur fine", "rejection penalties", "emergency medical drop-offs with penalties".
- **Core Concept**: If job $i$ is rejected, penalty $c_i$ is incurred. Objective: Maximize $\sum_{\text{sched}} p_i - \sum_{\text{rej}} c_i$.
- **Mathematical Transformation**:
  $$\sum_{\text{sched}} p_i - \sum_{\text{rej}} c_i = \sum_{\text{sched}} p_i - \left(\sum_{\text{all}} c_i - \sum_{\text{sched}} c_i\right) = \sum_{\text{sched}} (p_i + c_i) - \sum_{\text{all}} c_i$$
- **Implementation Trick**: Define **effective profit** $P'_i = p_i + c_i$. Run canonical Job Selection using $P'_i$. At the end:
  $$\text{bestNetValue} = \text{bestEffectiveProfit} - \sum_{\text{all}} c_i$$

```cpp
struct PenaltyJob {
    string name;
    int profit, penalty, deadline, effectiveProfit;
};

// 1. For each job: effectiveProfit = profit + penalty;
// 2. totalPenalties = sum(all penalty);
// 3. Sort descending by effectiveProfit;
// 4. Run standard JobSelectionBB;
// 5. finalNetBenefit = bestProfit - totalPenalties;
```

---

### Variation 3: Job Selection with Release Times $[r_i, d_i]$
- **Scenario Keywords**: "Release times", "job cannot start before $r_i$", "valid execution window $[r_i, d_i]$".
- **Core Concept**: Job $i$ can only be scheduled within time window $[r_i, d_i]$.
- **Adaptation**: In `findSlot()`, search downwards from $\min(d_i, \text{maxDeadline})$ only down to $r_i$ (inclusive).

```cpp
int findSlotWithRelease(const Job& job, int releaseTime, int maxDeadline,
                        const vector<bool>& slot) {
    int start = min(job.deadline, maxDeadline);
    // Search strictly within release window [releaseTime, deadline]
    for (int t = start; t >= releaseTime; --t) {
        if (!slot[t]) return t;
    }
    return -1;
}
```

---

# FAT Lab-Exam Version & Your Lab Programs (BCSE204P, Dr. Sakthivel R)

Every program below was extracted from your lab reports / FAT guide, compiled with `g++ -std=c++17 -Wall -O2`, and run; outputs shown are the real program output.

## Lab questions & verified answers

| Lab question | Scenario & input data | Verified answer |
|---|---|---|
| Lab 6 Q1 | 10 jobs (profit,deadline): J1(100,2) J2(80,1) J3(150,3) J4(120,2) J5(90,4) J6(200,3) J7(60,1) J8(180,4) J9(140,2) J10(110,3); 4 slots | **670**: J9 J3 J6 J8 |
| Lab 6 Q2 | 9 orders: O1(420,3) O2(250,1) O3(380,2) O4(300,4) O5(500,2) O6(450,3) O7(180,1) O8(550,4) O9(320,3); 4 slots | **1920**: O1 O5 O6 O8 |
| Lab 6 Q3 | 8 missions: M1(75,2) M2(120,1) M3(180,3) M4(150,2) M5(210,4) M6(130,3) M7(260,4) M8(90,1); 4 slots | **800**: M4 M3 M5 M7 |
| Lab 6 Q4 | Cloud jobs: C1(45,2) C2(80,1) C3(130,4) C4(95,3) C5(120,2) C6(150,5) C7(110,3) C8(70,1) C9(160,4) C10(100,3); 5 slots | **670**: C7 C5 C3 C9 C6 |
| Lab 6 Q5 | Film scenes: S1(210,2) S2(340,4) S3(180,1) S4(290,3) S5(250,2) S6(400,5) S7(360,3) S8(310,4) S9(280,5) S10(150,1); 5 slots | **1700**: S4 S8 S7 S2 S6 |
| Lab 6 Q6 | Deliveries: D1(95,2) D2(150,1) D3(180,3) D4(220,2) D5(170,4) D6(250,3) D7(300,5) D8(275,4) D9(100,1) D10(230,5) D11(190,3); 5 slots | **1275**: D4 D10 D6 D8 D7 |

All six answers above were also confirmed by exhaustive search over every feasible job subset.

**Bug in your Lab 6 Q1 report code:** the final loop prints `slots[i]` (the untouched, all-empty vector from `main`), so every slot shows "Empty". Keep a `bestSlots = slots;` copy whenever `bestProfit` improves and print that. The FAT code below solves exactly this Lab 6 Q1 data and prints the correct schedule.

## Job Sequencing with Deadlines using Branch & Bound

### Job Selection / Sequencing with Deadlines
**Lab scenario:** 10 Emergency Medical Equipment Delivery Jobs (Profits & Deadlines, 1 Unit Execution Time Each)

Given $N$ jobs where each job $i$ takes 1 unit of time and produces profit $P_i$ if completed on or before deadline $D_i$. Only one job executes at any time. Find the subset of jobs and slot assignments that maximizes total profit using **Branch & Bound**.

**Branch & Bound Mechanics:**
1. **Sort Jobs:** Arrange jobs in descending order of profit.
2. **Upper Bound Calculation:** Optimistically sum the highest profits among remaining jobs up to the number of remaining vacant time slots, temporarily ignoring deadline constraints.
3. **Pruning Condition:** If $Upper Bound <= Best Profit Found So Far$, prune the entire subtree.
4. **Branching:** At each step, either **Include** job (place in latest free slot $<= D_i$) or **Exclude** job.

### Algorithm: BranchAndBoundJobSelection
```python
BranchAndBoundJobSelection(jobs, index, current_profit, slots):
    IF current_profit > best_profit:
        best_profit = current_profit
        best_jobs = slots
    IF index == len(jobs): RETURN

    bound = CalculateBound(jobs, index, current_profit, used_slots)
    IF bound <= best_profit:
        RETURN   # PRUNE SUBTREE: cannot exceed best known profit

    # Branch 1: Include job (place in latest free slot <= deadline)
    IF can_schedule(jobs[index], new_slots):
        BranchAndBoundJobSelection(jobs, index + 1, current_profit + jobs[index].profit, new_slots)

    # Branch 2: Exclude job
    BranchAndBoundJobSelection(jobs, index + 1, current_profit, slots)
```

### Step-by-Step State-Space Tree Trace: Job Selection B&B
**Initial Sorted Jobs (by profit descending, Max Slots = 4):**
- J6 (p=200, d=3), J8 (p=180, d=4), J3 (p=150, d=3), J9 (p=140, d=2)
- J4 (p=120, d=2), J10 (p=110, d=3), J1 (p=100, d=2), J5 (p=90, d=4), J2 (p=80, d=1), J7 (p=60, d=1)

**State-Space Search Progression:**
- **Root Node:** Profit = 0, Slots = `[ - , - , - , - ]`. Optimistic Bound = $200 + 180 + 150 + 140 = 670$.
- **Step 1 (Consider J6: profit 200, deadline 3):**
- **Include Branch:** Place J6 in latest free slot $<= 3$ $->$ **Slot 3**.
- Slots: `[ - , - , J6 , - ]`, Profit = 200. Bound = $200 + (180 + 150 + 140) = 670$. Best Profit = 200.
- **Step 2 (Consider J8: profit 180, deadline 4):**
- **Include Branch:** Place J8 in latest free slot $<= 4$ $->$ **Slot 4**.
- Slots: `[ - , - , J6 , J8 ]`, Profit = 380. Bound = $380 + (150 + 140) = 670$. Best Profit = 380.
- **Step 3 (Consider J3: profit 150, deadline 3):**
- **Include Branch:** Slot 3 is occupied by J6; latest free slot $<= 3$ is **Slot 2**.
- Slots: `[ - , J3 , J6 , J8 ]`, Profit = 530. Bound = $530 + 140 = 670$. Best Profit = 530.
- **Step 4 (Consider J9: profit 140, deadline 2):**
- **Include Branch:** Slot 2 is occupied by J3; latest free slot $<= 2$ is **Slot 1**.
- Slots: `[ J9 , J3 , J6 , J8 ]`, Profit = 670. All 4 slots filled! Best Profit updated to **670**.
- **Why All Alternative Subtrees are Pruned:**
- **Exclude J9:** Current profit = 530. Bound with next best job (J4, profit 120) = $530 + 120 = 650 <= 670$ $→$ **PRUNED!**
- **Exclude J3:** Current profit = 380. Bound with remaining slots (J9:140, J4:120) = $380 + 140 + 120 = 640 <= 670$ $→$ **PRUNED!**
- **Exclude J8:** Current profit = 200. Bound = $200 + 150 + 140 + 120 = 610 <= 670$ $→$ **PRUNED!**
- **Exclude J6:** Profit = 0. Bound = $180 + 150 + 140 + 120 = 590 <= 670$ $→$ **PRUNED!**
- **Result:** Exact 4 nodes evaluated. The bounding function prunes 100% of sub-optimal branches!

### Concise C++ Implementation (Branch & Bound)

```cpp
#include <iostream>
#include <vector>
#include <string>
#include <algorithm>
using namespace std;

struct Job {
    string id;
    int profit;
    int deadline;
};

int bestProfit = 0;
vector<string> bestJobs;
const int MAX_SLOTS = 4; // Max deadline in dataset

bool scheduleInSlot(const Job& job, vector<string>& slots) {
    for (int i = min((int)slots.size(), job.deadline) - 1; i >= 0; --i) {
        if (slots[i] == "") {
            slots[i] = job.id;
            return true;
        }
    }
    return false;
}

int calculateBound(const vector<Job>& jobs, int index, int currentProfit, int usedSlots) {
    int b = currentProfit;
    int remainingSlots = MAX_SLOTS - usedSlots;
    for (size_t i = index; i < jobs.size() && remainingSlots > 0; ++i) {
        b += jobs[i].profit;
        remainingSlots--;
    }
    return b;
}

void branchAndBound(const vector<Job>& jobs, int index, int currentProfit, vector<string> slots) {
    if (currentProfit > bestProfit) {
        bestProfit = currentProfit;
        bestJobs.clear();
        for (const string& s : slots) if (s != "") bestJobs.push_back(s);
    }
    if (index == (int)jobs.size()) return;

    int usedSlots = 0;
    for (const string& s : slots) if (s != "") usedSlots++;

    // Prune if optimistic bound cannot beat best known solution
    if (calculateBound(jobs, index, currentProfit, usedSlots) <= bestProfit) return;

    // Branch 1: Try Include
    vector<string> newSlots = slots;
    if (scheduleInSlot(jobs[index], newSlots)) {
        branchAndBound(jobs, index + 1, currentProfit + jobs[index].profit, newSlots);
    }

    // Branch 2: Exclude
    branchAndBound(jobs, index + 1, currentProfit, slots);
}

int main() {
    // Lab Example: 10 Emergency Medical Equipment Delivery Jobs
    vector<Job> jobs = {
        {"J1", 100, 2}, {"J2", 80, 1},  {"J3", 150, 3}, {"J4", 120, 2}, {"J5", 90, 4},
        {"J6", 200, 3}, {"J7", 60, 1},  {"J8", 180, 4}, {"J9", 140, 2}, {"J10", 110, 3}
    };

    // Sort by profit descending
    sort(jobs.begin(), jobs.end(), [](const Job& a, const Job& b) {
        return a.profit > b.profit;
    });

    vector<string> slots(MAX_SLOTS, "");
    branchAndBound(jobs, 0, 0, slots);

    cout << "Maximum Profit: " << bestProfit << "\n";
    cout << "Selected Jobs: ";
    for (const string& id : bestJobs) cout << id << " ";
    cout << "\n";
    return 0;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
Maximum Profit: 670
Selected Jobs: J9 J3 J6 J8
```

### Cheese Code: Pure Greedy Job Sequencing (12 Lines)
**Why it works in the exam:** Greedy slot assignment yields the mathematically identical maximum profit and optimal job set! If Branch & Bound feels overwhelming to recall in the exam, write this!

```cpp
#include <bits/stdc++.h>
using namespace std;
struct J { string id; int p, d; };
int main() {
    vector<J> jobs = {{"J1",100,2},{"J2",80,1},{"J3",150,3},{"J4",120,2},{"J5",90,4},
                      {"J6",200,3},{"J7",60,1},{"J8",180,4},{"J9",140,2},{"J10",110,3}};
    sort(jobs.begin(), jobs.end(), [](J a, J b){ return a.p > b.p; });
    vector<string> slot(5, "");
    int profit = 0;
    for (auto& j : jobs)
        for (int s = j.d; s > 0; --s)
            if (slot[s] == "") { slot[s] = j.id; profit += j.p; break; }
    cout << "Max Profit: " << profit << "\nJobs: ";
    for (int s = 1; s <= 4; ++s) if (slot[s] != "") cout << slot[s] << " ";
    cout << "\n"; // Exact Profit: 670, Jobs: J9 J4 J6 J8
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
Max Profit: 670
Jobs: J9 J3 J6 J8
```

### Silly Mistakes & Traps: Job Selection Branch & Bound
1. **Unsorted Input:** Branch and Bound bounding guarantees rely entirely on jobs being sorted by profit in descending order! If unsorted, the greedy upper bound is invalid and prunes optimal branches.
2. **Latest Free Slot Placement:** When placing a job with deadline $D$, search backwards from $D$ down to $1$ (or $D-1$ down to $0$). Placing it in the earliest slot blocks future jobs with earlier deadlines.
3. **Bound Calculation Slot Cap:** The bound calculation must stop adding profits when `remainingSlots == 0`. Failing to cap by remaining slots creates an overly loose bound that never prunes.

**Complexity:** best O(n log n) · average O(2^n) pruned · worst O(2^n) unpruned · auxiliary space O(n) recursion stack & state slots  
**Recurrence:** T(n) <= 2 T(n-1) with state-space pruning
