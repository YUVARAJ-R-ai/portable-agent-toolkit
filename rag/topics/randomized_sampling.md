# Randomized Algorithms: Sampling Without Replacement (Monte Carlo Estimation)

Randomized estimation by sampling without replacement with a fixed seed (std::mt19937 + shuffle); Monte Carlo vs Las Vegas (Lab 11, FAT Module 10). Category: Randomized.

---

Every program below was extracted from your lab reports / FAT guide, compiled with `g++ -std=c++17 -Wall -O2`, and run; outputs shown are the real program output.

## Lab questions & verified answers

| Lab question | Scenario & input data | Verified answer |
|---|---|---|
| Lab 11 Q4 | 20 servers, statuses 0 1 0 0 1 0 1 0 0 0 1 0 0 1 0 0 1 0 0 1, sample 8, seed 42 | estimate **37.50%** vs actual **35.00%** (g++/libstdc++) |
| Lab 11 Q5 | 15 sensors IDs 101–115, sample 6, seed 17 | estimate **50.00%** vs actual **33.33%** (g++/libstdc++) |

**Reproducibility caveat:** `std::shuffle` / `uniform_int_distribution` are implemented differently by libstdc++ (g++), libc++ (clang) and MSVC, so the *sampled IDs* differ across compilers even with the same seed. The FAT guide's listed sample (19 12 18 10 …, 25.0%) is not what g++ produces. Only the population rate (35%) is compiler-independent. If the examiner needs identical output, implement Fisher-Yates yourself with `mt19937` raw draws (`gen() % (i+1)`), which is deterministic everywhere.

## Randomized Sampling & Estimation (Monte Carlo & Las Vegas)

### Randomized Sampling without Replacement
**Lab scenario:** Estimating Failed Servers (N=20, S=8, Seed=42) & Faulty Sensors (N=15, S=6, Seed=17)

When auditing massive clusters where testing every unit is cost-prohibitive, draw a uniform random sample of size $S$ without replacement using a pseudo-random number generator (e.g., `std::mt19937` or Fisher-Yates shuffle). Compare sample failure proportion with actual population proportion.

### Algorithm: RandomizedAudit
```python
RandomizedAudit(status, N, S, seed):
    rng = SeedRandom(seed)
    indices = [0, 1, ..., N - 1]
    SHUFFLE(indices, rng)                # Uniform sample without replacement

    sampleFailed = 0
    FOR i = 0 TO S - 1:
        sampleFailed = sampleFailed + status[indices[i]]

    estRate = (sampleFailed / S) * 100
    actRate = (SUM(status) / N) * 100
    RETURN estRate, actRate
```

### Concise C++ Implementation (Randomized Server Audit)

```cpp
#include <iostream>
#include <vector>
#include <algorithm>
#include <random>
using namespace std;

int main() {
    // Lab Example: N=20 servers, Sample size S=8, Seed=42
    const int N = 20, S = 8, SEED = 42;
    vector<int> status = {0, 1, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1};

    int actualFailed = 0;
    for (int x : status) actualFailed += x;

    vector<int> indices(N);
    for (int i = 0; i < N; ++i) indices[i] = i;

    mt19937 rng(SEED);
    shuffle(indices.begin(), indices.end(), rng);

    int sampleFailed = 0;
    cout << "Sampled Server IDs: ";
    for (int i = 0; i < S; ++i) {
        int id = indices[i];
        cout << id << " ";
        sampleFailed += status[id];
    }
    cout << "\n";

    cout << "Sampled Failed Count: " << sampleFailed << "/" << S << "\n";
    cout << "Estimated Failure Rate: " << (100.0 * sampleFailed / S) << "%\n";
    cout << "Actual Population Failure Rate: " << (100.0 * actualFailed / N) << "%\n";
    return 0;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
Sampled Server IDs: 1 6 16 0 5 9 11 12 
Sampled Failed Count: 3/8
Estimated Failure Rate: 37.5%
Actual Population Failure Rate: 35%
```

### Silly Mistakes & Traps: Verification, Approx & Randomized
1. **Vertex Cover Approximation:** Adding only one endpoint $u$ does **not** guarantee a 2-approximation! You MUST add **both** endpoints $u$ and $v$ to achieve the proven 2-factor guarantee.
2. **Random Sampling with Replacement:** Drawing samples with replacement allows duplicate IDs. Use `std::shuffle` on an index array to guarantee sampling **without replacement**.
3. **1-Based vs 0-Based ID Mismatches:** In network verification, edge IDs are often given as 1-indexed (`1, 2, 3, 4`). Accessing `edges[id]` instead of `edges[id - 1]` leads to an out-of-bounds segfault!

## Your lab-report programs

### Your Lab 11 Q5 program (faulty sensors)

```cpp
#include <iostream>
#include <vector>
#include <algorithm>
#include <random>
#include <iomanip>
using namespace std;

struct Sensor { int id, faulty; };

int main() {
    const int N = 15, S = 6, seed = 17;
    vector<Sensor> sensors = {
        {101,0},{102,1},{103,0},{104,0},{105,1},
        {106,0},{107,1},{108,0},{109,0},{110,1},
        {111,0},{112,0},{113,1},{114,0},{115,0}
    };
    vector<int> order(N);
    for (int i = 0; i < N; i++) order[i] = i;
    mt19937 rng(seed);
    shuffle(order.begin(), order.end(), rng);

    int sampleFaulty = 0, actualFaulty = 0;
    cout << "Sampled sensors (ID: status):\n";
    for (int i = 0; i < S; i++) {
        const Sensor &x = sensors[order[i]];
        cout << x.id << ": " << (x.faulty ? "Faulty" : "Working") << '\n';
        sampleFaulty += x.faulty;
    }
    for (const Sensor &x : sensors) actualFaulty += x.faulty;
    cout << "Faulty in Sample: " << sampleFaulty << "/" << S << '\n';
    cout << fixed << setprecision(2);
    cout << "Estimated Faulty Sensor Percentage: " << 100.0 * sampleFaulty / S <<
"%\n";
    cout << "Actual Faulty Sensor Percentage: " << 100.0 * actualFaulty / N << "%\n";
    return 0;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
Sampled sensors (ID: status):
114: Working
110: Faulty
101: Working
106: Working
102: Faulty
105: Faulty
Faulty in Sample: 3/6
Estimated Faulty Sensor Percentage: 50.00%
Actual Faulty Sensor Percentage: 33.33%
```
