# Convex Hull Algorithms: Graham's Scan & Jarvis' March

The convex hull of a planar point set $S$ is the smallest convex polygon containing all points in $S$. Algorithms to compute the convex hull are fundamental in computational geometry, robotics, pattern recognition, and GIS. Category: Computational Geometry.

---

## 1. Algorithmic Invariants & Critical Pitfalls

### Fundamental Principles
1. **Convexity Invariant**: Traversing the boundary vertices of a convex polygon in counter-clockwise (CCW) order requires making only **left turns** (positive cross products). A right turn (negative cross product) indicates a reflex angle that violates convexity.
2. **2D Cross Product Turn Test**:
   $$\text{Cross}(A, B, C) = (B.x - A.x)(C.y - A.y) - (B.y - A.y)(C.x - A.x)$$
   - $\text{Cross} > 0$: Strict counter-clockwise turn (left turn).
   - $\text{Cross} < 0$: Clockwise turn (right turn).
   - $\text{Cross} = 0$: Collinear points (lie on the same line).

### Comparison Matrix

| Algorithm | Design Paradigm | Time Complexity | Space Complexity | Output Sensitive? | When to Use |
|---|---|---|---|---|---|
| **Graham's Scan** | Sorting + Stack Maintenance | $O(n \log n)$ | $O(n)$ | No | General point sets; optimal when $h = \Theta(n)$ |
| **Andrew's Monotone Chain** | Lexicographical Sort + 2 Stacks | $O(n \log n)$ | $O(n)$ | No | Preferred modern Graham variant; no trigonometry |
| **Jarvis' March (Gift Wrapping)** | Greedy selection | $O(n \cdot h)$ | $O(h)$ | **Yes** ($h$ = hull vertices) | When $h \ll \log n$ (e.g. random points in a disk) |
| **Chan's Algorithm** | Graham partitioning + Jarvis march | $O(n \log h)$ | $O(n)$ | **Yes** | Ultimate optimal hybrid algorithm |

*Note*: $n$ is total points; $h$ is the number of vertices on the convex hull ($3 \le h \le n$).

### Critical Implementation Rules
1. **Strictly Convex vs Collinear Boundary Points**:
   - **Strictly Convex**: If three points on the hull are collinear, keep only the two extremes. Discard intermediate points using `Cross <= 0` during pop.
   - **Collinear Points Allowed**: Keep all intermediate points on the hull edges (e.g. boundary sensor networks). Pop only when `Cross < 0`.
2. **Degenerate Inputs**:
   - $n = 0, 1, 2$: Return the points as-is.
   - All $n$ points are collinear: The hull is a straight line segment, not a polygon with non-zero area. Both Graham's Scan and Jarvis' March must handle this without an infinite loop.
   - Duplicate points: Remove duplicates before sorting.
3. **Integer Arithmetic**:
   Always store coordinates as `long long` and compute cross products using 64-bit integers to prevent arithmetic overflow and floating-point rounding errors.

---

## 2. Canonical C++ Implementation: Andrew's Monotone Chain (Modern Graham's Scan)

Andrew's Monotone Chain sorts points lexicographically by $(x, y)$, eliminating polar angle calculations, floating-point trigonometry (`atan2`), and numerical instability. It computes the lower hull and upper hull independently in two linear passes.

```cpp
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

struct Point {
    long long x, y;

    bool operator<(const Point& o) const {
        if (x != o.x) return x < o.x;
        return y < o.y;
    }
    bool operator==(const Point& o) const {
        return x == o.x && y == o.y;
    }
};

// 2D Cross product: (B - A) x (C - A)
long long crossProduct(const Point& a, const Point& b, const Point& c) {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}

// Andrew's Monotone Chain Convex Hull: O(n log n)
// Returns vertices in counter-clockwise order
vector<Point> monotoneChainConvexHull(vector<Point> pts, bool includeCollinear = false) {
    int n = pts.size();
    if (n <= 1) return pts;

    // Sort points lexicographically by x, then y
    sort(pts.begin(), pts.end());
    pts.erase(unique(pts.begin(), pts.end()), pts.end());
    n = pts.size();
    if (n <= 2) return pts;

    vector<Point> hull;

    // 1. Construct Lower Hull
    for (int i = 0; i < n; ++i) {
        while (hull.size() >= 2) {
            long long cp = crossProduct(hull[hull.size() - 2], hull.back(), pts[i]);
            if (includeCollinear ? (cp < 0) : (cp <= 0)) {
                hull.pop_back();
            } else {
                break;
            }
        }
        hull.push_back(pts[i]);
    }

    // 2. Construct Upper Hull
    size_t lowerSize = hull.size();
    for (int i = n - 2; i >= 0; --i) {
        while (hull.size() > lowerSize) {
            long long cp = crossProduct(hull[hull.size() - 2], hull.back(), pts[i]);
            if (includeCollinear ? (cp < 0) : (cp <= 0)) {
                hull.pop_back();
            } else {
                break;
            }
        }
        hull.push_back(pts[i]);
    }

    // Remove duplicate starting point
    hull.pop_back();
    return hull;
}

int main() {
    vector<Point> pts = {
        {0, 3}, {2, 2}, {1, 1}, {2, 1}, {3, 0}, {0, 0}, {3, 3}
    };

    auto hull = monotoneChainConvexHull(pts, false);
    cout << "Convex Hull Vertices (CCW order):\n";
    for (const auto& p : hull) {
        cout << "(" << p.x << ", " << p.y << ")\n";
    }
    return 0;
}
```

---

## 3. Canonical C++ Implementation: Jarvis' March (Gift Wrapping)

Jarvis' March simulates wrapping a ribbon around the set of points. It starts at the leftmost point and iteratively finds the next vertex by selecting the point that makes the most counter-clockwise turn relative to the current vertex.

### Complexity & Characteristics:
- **Time Complexity**: $O(n \cdot h)$, where $h$ is the number of hull vertices.
  - Best case: $h = 3 \implies O(n)$.
  - Worst case: $h = n \implies O(n^2)$ (all points on the hull, e.g. points on a circle).
- **Advantage over Graham's Scan**: When $h < \log n$, Jarvis' March is strictly faster than Graham's Scan's $O(n \log n)$.

```cpp
#include <iostream>
#include <vector>
#include <algorithm>

using namespace std;

struct Point {
    long long x, y;

    bool operator<(const Point& o) const {
        if (x != o.x) return x < o.x;
        return y < o.y;
    }
    bool operator==(const Point& o) const {
        return x == o.x && y == o.y;
    }
};

long long crossProduct(const Point& a, const Point& b, const Point& c) {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}

long long distSq(const Point& a, const Point& b) {
    return (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y);
}

// Jarvis' March (Gift Wrapping): O(n * h)
vector<Point> jarvisMarch(vector<Point> pts) {
    int n = pts.size();
    if (n <= 2) return pts;

    sort(pts.begin(), pts.end());
    pts.erase(unique(pts.begin(), pts.end()), pts.end());
    n = pts.size();
    if (n <= 2) return pts;

    // Find the leftmost point (guaranteed to be on the hull)
    int leftmost = 0;
    for (int i = 1; i < n; ++i) {
        if (pts[i].x < pts[leftmost].x || (pts[i].x == pts[leftmost].x && pts[i].y < pts[leftmost].y))
            leftmost = i;
    }

    vector<Point> hull;
    int p = leftmost;
    do {
        hull.push_back(pts[p]);
        int q = (p + 1) % n;
        for (int r = 0; r < n; ++r) {
            long long cp = crossProduct(pts[p], pts[q], pts[r]);
            // If r is more counter-clockwise than current candidate q
            if (cp > 0) {
                q = r;
            } else if (cp == 0) {
                // If collinear, pick the farthest point to avoid missing extreme vertex
                if (distSq(pts[p], pts[r]) > distSq(pts[p], pts[q])) {
                    q = r;
                }
            }
        }
        p = q;
    } while (p != leftmost && (int)hull.size() < n);

    return hull;
}
```

---

## 4. Exam Twists & Complex Variations

### Variation 1: Diameter of Point Set via Rotating Calipers
- **Problem**: Find the maximum Euclidean distance between any two points in $S$.
- **Naïve**: Compare all pairs in $O(n^2)$.
- **Rotating Calipers Technique**:
  1. Compute the convex hull in $O(n \log n)$.
  2. The maximum distance (diameter) must occur between two **antipodal** vertices on the hull.
  3. Using a two-pointer technique (calipers) that sweeps around the hull, advance the opposite vertex whenever the triangle area increases:
     $$\text{Area}(p_i, p_{i+1}, p_j) < \text{Area}(p_i, p_{i+1}, p_{j+1})$$
  4. Total time: $O(n \log n)$ for hull $+ O(h)$ for calipers = $O(n \log n)$.

### Variation 2: Graham's Scan Polar Sort Tie-Breakers
- **Twist**: "Sort points by polar angle with respect to pivot $P_0$."
- If two points $A$ and $B$ have the same polar angle ($\text{Cross}(P_0, A, B) == 0$):
  - **Strict hull**: Keep only the point farthest from $P_0$, discard the closer point.
  - **Include collinear boundary**: Reverse the order of points collinear with the last edge of the hull so the stack processes them in descending distance order without popping them as reflex angles.

### Variation 3: Chan's Algorithm ($O(n \log h)$)
- **Problem**: When neither $h = O(1)$ nor $h = \Theta(n)$ is known ahead of time.
- **Method**:
  - Guess $m$ (target hull size). Partition $n$ points into $n / m$ subsets of size $m$.
  - Run Graham's Scan on each subset in $O(m \log m)$ time (total $O(n \log m)$).
  - Run Jarvis' March on the subsets: at each step, find the tangent from the current vertex to each of the $n/m$ mini-hulls using binary search in $O(\log m)$.
  - One step takes $O((n/m) \log m)$. Over $m$ steps, total time is $O(n \log m)$.
  - If $m < h$, double $m$ using squareroot-doubling scheme $m = 2^{2^t}$. Overall time converges to $O(n \log h)$.

---

# FAT Lab-Exam Version & Your Lab Programs (BCSE204P, Dr. Sakthivel R)

Every program below was extracted from your lab reports / FAT guide, compiled with `g++ -std=c++17 -Wall -O2`, and run; outputs shown are the real program output.

## Lab questions & verified answers

| Lab question | Scenario & input data | Verified answer |
|---|---|---|
| Lab 10 Q2 | Forestry sensors (0,0) (2,0) (2,2) (0,2) (1,1) (2,0) (duplicate removed) | 4 vertices (0,0) (2,0) (2,2) (0,2), perimeter **8.00** |
| Lab 10 Q4 | Drone swarms, Quickhull: (0,0) (2,0) (2,2) (0,2) (1,1) (1,0) (0,0) | (0,0) (2,0) (2,2) (0,2) CCW from leftmost |

## Convex Hull: Graham’s Scan & Monotone Chain

### Convex Hull
**Lab scenario:** Forestry Ground Sensor Enclosure & Wire Perimeter Calculation

Given a set of $N$ points, find the smallest convex polygon enclosing all points.
1. Find anchor point $P_0$ with lowest $y$-coordinate (lowest $x$ breaks ties).
2. Sort all other points by polar angle with respect to $P_0$ using cross products.
3. Maintain a monotone stack of hull vertices. If the next point makes a clockwise turn relative to the top two stack vertices, pop from the stack until a counter-clockwise (left) turn is restored.

### Algorithm: GrahamScan
```python
GrahamScan(pts, n):
    p0 = Point with minimum y (lowest x breaks ties)
    SORT pts[1 .. n - 1] by polar angle with p0 using CrossProduct

    stack = [p0, pts[1], pts[2]]
    FOR i = 3 TO n - 1:
        WHILE len(stack) >= 2 AND CrossProduct(stack[top - 1], stack[top], pts[i]) <= 0:
            stack.pop()                           # Pop non-left turns
        stack.push(pts[i])

    RETURN stack                                  # Vertices of convex hull
```

### Step-by-Step Stack Trace: Graham's Scan Convex Hull
**Input Points & Polar Angle Sorting relative to $P_0(0,0)$:**
- $P_0(0,0)$: Pivot point (minimum $y$, tie-break minimum $x$).
- $P_1(2,0)$: Angle 0°.
- $P_4(1,1)$: Angle 45°, distance $sqrt(2)$.
- $P_2(2,2)$: Angle 45°, distance $sqrt(8)$ (Collinear with $P_4$, farther away).
- $P_3(0,2)$: Angle 90°.

**Stack Execution Trace:**

| **Step** | **Candidate** | **Cross Product Check** | **Stack Action** | **Current Stack Content** |
|---|---|---|---|---|
| 1 | $P_0(0,0)$ | Initial pivot | Push | $[P_0]$ |
| 2 | $P_1(2,0)$ | First sorted point | Push | $[P_0, P_1]$ |
| 3 | $P_4(1,1)$ | `cross(P0, P1, P4) = 2 > 0` (CCW / Left) | Push | $[P_0, P_1, P_4]$ |
| 4 | $P_2(2,2)$ | `cross(P1, P4, P2) = -2 <= 0` (Clockwise!) | **POP $P_4(1,1)$** (Interior!) | $[P_0, P_1]$ |
| 5 | $P_2(2,2)$ | `cross(P0, P1, P2) = 4 > 0` (CCW / Left) | Push $P_2$ | $[P_0, P_1, P_2]$ |
| 6 | $P_3(0,2)$ | `cross(P1, P2, P3) = 4 > 0` (CCW / Left) | Push $P_3$ | $[P_0, P_1, P_2, P_3]$ |

**Key Insight:** Notice at Step 4, candidate point $P_2(2,2)$ forms a clockwise (right) turn with $P_1$ and $P_4$, proving that $P_4(1,1)$ lies strictly inside the hull! The stack immediately pops $P_4$, restoring strict convexity.

### Concise C++ Implementation (Graham's Scan & Perimeter)

```cpp
#include <iostream>
#include <vector>
#include <algorithm>
#include <cmath>
#include <iomanip>
using namespace std;

struct Point { long long x, y; };
Point p0;

long long cross(Point a, Point b, Point c) {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}

long long distSq(Point a, Point b) {
    return (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y);
}

int main() {
    // Lab Example: Sensor coordinates
    vector<Point> pts = {{0, 0}, {2, 0}, {2, 2}, {0, 2}, {1, 1}, {2, 0}};
    int n = pts.size();

    // 1. Find pivot with min y, then min x
    int min_idx = 0;
    for (int i = 1; i < n; ++i) {
        if (pts[i].y < pts[min_idx].y || (pts[i].y == pts[min_idx].y && pts[i].x < pts[min_idx].x))
            min_idx = i;
    }
    swap(pts[0], pts[min_idx]);
    p0 = pts[0];

    // 2. Sort by polar angle
    sort(pts.begin() + 1, pts.end(), [](Point a, Point b) {
        long long c = cross(p0, a, b);
        if (c == 0) return distSq(p0, a) < distSq(p0, b);
        return c > 0; // Left turn (smaller angle)
    });

    // 3. Stack construction
    vector<Point> hull;
    for (int i = 0; i < n; ++i) {
        while (hull.size() >= 2 && cross(hull[hull.size() - 2], hull.back(), pts[i]) <= 0)
            hull.pop_back();
        hull.push_back(pts[i]);
    }

    cout << "Convex Hull Vertices (Count = " << hull.size() << "):\n";
    double perimeter = 0;
    for (size_t i = 0; i < hull.size(); ++i) {
        cout << "  (" << hull[i].x << ", " << hull[i].y << ")\n";
        Point next_p = hull[(i + 1) % hull.size()];
        perimeter += hypot(hull[i].x - next_p.x, hull[i].y - next_p.y);
    }
    cout << fixed << setprecision(2) << "Total Perimeter: " << perimeter << "\n";
    return 0;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
Convex Hull Vertices (Count = 4):
  (0, 0)
  (2, 0)
  (2, 2)
  (0, 2)
Total Perimeter: 8.00
```

### Cheese Code: Andrew's Monotone Chain (Zero Angles to Calculate)
**Why it works in the exam:** Andrew's Monotone Chain sorts by X coordinate, builds lower hull, builds upper hull. No pivot swapping, no angle sorting, perfectly easy to remember!

```cpp
#include <bits/stdc++.h>
using namespace std;
struct P { long long x, y; };
long long ccw(P a, P b, P c) { return (b.x-a.x)*(c.y-a.y) - (b.y-a.y)*(c.x-a.x); }
int main() {
    vector<P> pts = {{0,0},{2,0},{2,2},{0,2},{1,1}};
    sort(pts.begin(), pts.end(), [](P a, P b){ return a.x < b.x || (a.x == b.x && a.y < b.y); });
    vector<P> h;
    for (auto p : pts) { while (h.size() >= 2 && ccw(h[h.size()-2], h.back(), p) <= 0) h.pop_back(); h.push_back(p); }
    int t = h.size() + 1;
    for (int i = (int)pts.size() - 2; i >= 0; --i) { while ((int)h.size() >= t && ccw(h[h.size()-2], h.back(), pts[i]) <= 0) h.pop_back(); h.push_back(pts[i]); }
    h.pop_back();
    for (auto p : h) cout << "(" << p.x << "," << p.y << ") ";
    cout << endl;
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
(0,0) (2,0) (2,2) (0,2)
```

### Silly Mistakes & Traps: Convex Hull
1. **Integer Overflow in Cross Product:** Coordinate differences like $(x_2 - x_1)(y_3 - y_1)$ can exceed $2 × 10^9$ when coordinates are large. Use `long long` for points and cross product results!
2. **Stack Size Guard:** Always check `hull.size() >= 2` before calling `hull.pop_back()`, otherwise popping an empty or single-element stack triggers undefined behavior.

**Complexity:** best O(n log n) · average O(n log n) · worst O(n log n) · auxiliary space O(n) hull stack  
**Recurrence:** O(n log n) sorting + O(n) stack scan

## Your lab-report programs

### Your Lab 10 Q4 program (Quickhull)

```cpp
#include <iostream>
#include <vector>
#include <algorithm>
#include <cmath>
using namespace std;
struct P{long long x,y;bool operator<(const P&o)const{return x!=o.x?x<o.x:y<o.y;}bool
operator==(const P&o)const{return x==o.x&&y==o.y;}};
long long cross(P a,P b,P p){return (b.x-a.x)*(p.y-a.y)-(b.y-a.y)*(p.x-a.x);}
void quickHull(const vector<P>& pts,P a,P b,int side,vector<P>& hull){
    int k=-1;long long far=0;
    for(int i=0;i<(int)pts.size();i++){long long c=cross(a,b,pts[i])*side;if(c>far){far=c;k=i;}}
    if(k==-1)return;
    P p=pts[k];vector<P> left1,left2;
    for(P q:pts){if(cross(a,p,q)*side>0)left1.push_back(q);if(cross(p,b,q)*side>0)left2.push_back(q);}
    quickHull(left1,a,p,side,hull);hull.push_back(p);quickHull(left2,p,b,side,hull);
}
int main(){
    vector<P> p={{0,0},{2,0},{2,2},{0,2},{1,1},{1,0},{0,0}};
    sort(p.begin(),p.end());
    p.erase(unique(p.begin(),p.end()),p.end());
    if(p.size()<=2){for(P v:p)cout<<v.x<<" "<<v.y<<"\n";return 0;}
    P a=p.front(),b=p.back();
    vector<P> hull={a};
    quickHull(p,a,b,1,hull);
    hull.push_back(b);
    quickHull(p,b,a,1,hull);
    sort(hull.begin(),hull.end());
    hull.erase(unique(hull.begin(),hull.end()),hull.end());
    double cx=0,cy=0;for(P v:hull)cx+=v.x,cy+=v.y;
    cx/=hull.size();
    cy/=hull.size();
    sort(hull.begin(),hull.end(),[&](P u,P v){return atan2(u.y-cy,u.x-cx)<atan2(v.y-cy,v.x-cx);});
    auto it=min_element(hull.begin(),hull.end());rotate(hull.begin(),it,hull.end());
    for(P v:hull)cout<<v.x<<" "<<v.y<<"\n";
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
0 0
2 0
2 2
0 2
```
