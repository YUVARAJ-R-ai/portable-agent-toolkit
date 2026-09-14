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
