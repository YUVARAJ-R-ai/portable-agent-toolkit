# Closest Pair of Points (Divide & Conquer)

Closest pair of points in 2D via divide & conquer with the strip check, O(n log n) (Lab 10, FAT Module 9). Category: Computational Geometry.

---

Every program below was extracted from your lab reports / FAT guide, compiled with `g++ -std=c++17 -Wall -O2`, and run; outputs shown are the real program output.

## Lab questions & verified answers

| Lab question | Scenario & input data | Verified answer |
|---|---|---|
| Lab 10 Q3 | Radar aircraft (2,3) (12,30) (40,50) (5,1) (12,10) (3,4) | **1.4142** between (2,3) and (3,4) |
| Lab 10 Q5 | AGVs (x,y→u,v): (0,0→4,4) (0,4→4,0) (6,1→8,3) | Min separation **4.00**; HAZARD (Vehicle 1 and Vehicle 2), paths cross at (2,2) |
| FAT Module 9 | Points (0,0) (4,4) (0,4) (4,0) (6,1) (8,3) | **2.24** = √5 between (4,0) and (6,1) |

## Closest Pair of Points (Divide & Conquer)

### Closest Pair of Points
**Lab scenario:** Air Traffic Control Radar Warning (Detecting minimal separation between airborne drones)

Given $N$ 2D points, find the pair with the smallest Euclidean distance $d(P_i, P_j)$.
- Divide points into two halves by vertical line $x = mid$.
- Recursively find minimum distance in left half ($d_L$) and right half ($d_R$). Let $delta = min(d_L, d_R)$.
- Inspect strip of points within distance $delta$ from median line. In the sorted $y$-strip, each point needs to be compared with at most 7 neighbors!

### Algorithm: ClosestPair
```python
ClosestPair(P_x, P_y, n):
    IF n <= 3: RETURN BruteForce(P_x)

    mid = n / 2; midPoint = P_x[mid]
    d_left = ClosestPair(P_x[0 .. mid], P_y_left, mid)
    d_right = ClosestPair(P_x[mid .. n], P_y_right, n - mid)
    delta = min(d_left, d_right)

    strip = [p in P_y where |p.x - midPoint.x| < delta]
    FOR i = 0 TO len(strip) - 1:
        FOR j = i + 1 TO min(i + 7, len(strip) - 1):
            IF (strip[j].y - strip[i].y) >= delta: BREAK
            delta = min(delta, dist(strip[i], strip[j]))

    RETURN delta
```

### Cheese Code: O(N^2) Brute Force (6 Lines)
**Why it works in the exam:** For N <= 1000 in lab exam test cases, checking all pairs takes less than 1ms and avoids 60 lines of recursive divide-and-conquer code!

```cpp
#include <bits/stdc++.h>
using namespace std;
struct P { double x, y; };
int main() {
    vector<P> pts = {{0,0}, {4,4}, {0,4}, {4,0}, {6,1}, {8,3}};
    double minD = 1e9;
    for (size_t i = 0; i < pts.size(); ++i)
        for (size_t j = i + 1; j < pts.size(); ++j)
            minD = min(minD, hypot(pts[i].x - pts[j].x, pts[i].y - pts[j].y));
    cout << fixed << setprecision(2) << "Min Starting Separation: " << minD << "\n";
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
Min Starting Separation: 2.24
```

**Complexity:** best O(n log n) · average O(n log n) · worst O(n log n) [O(n^2) Brute] · auxiliary space O(n) strip space  
**Recurrence:** T(n) = 2 T(n/2) + O(n) => O(n log n)

## Your lab-report programs

### Your Lab 10 Q3 program (divide & conquer)

```cpp
#include <iostream>
#include <vector>
#include <algorithm>
#include <cmath>
#include <iomanip>
using namespace std;
struct P{double x,y;};
struct Ans{double d;P a,b;};
double dist(P a,P b){return hypot(a.x-b.x,a.y-b.y);}
bool byY(P a,P b){return a.y!=b.y?a.y<b.y:a.x<b.x;}
Ans solve(vector<P>& p,int l,int r){
    if(r-l<=3){
        Ans z={1e100,{0,0},{0,0}};
        for(int i=l;i<r;i++)for(int j=i+1;j<r;j++){double d=dist(p[i],p[j]);if(d<z.d)z={d,p[i],p[j]};}
        sort(p.begin()+l,p.begin()+r,byY);
        return z;
    }
    int m=(l+r)/2;double midX=p[m].x;
    Ans a=solve(p,l,m),b=solve(p,m,r),z=a.d<b.d?a:b;
    inplace_merge(p.begin()+l,p.begin()+m,p.begin()+r,byY);
    vector<P> strip;
    for(int i=l;i<r;i++)if(abs(p[i].x-midX)<z.d)strip.push_back(p[i]);
    for(int i=0;i<(int)strip.size();i++)for(int j=i+1;j<(int)strip.size()&&strip[j].y-strip[i].y<z.d;j++){
        double d=dist(strip[i],strip[j]);if(d<z.d)z={d,strip[i],strip[j]};
    }
    return z;
}
int main(){
    vector<P> p={{2,3},{12,30},{40,50},{5,1},{12,10},{3,4}};
    sort(p.begin(),p.end(),[](P a,P b){return a.x!=b.x?a.x<b.x:a.y<b.y;});
    Ans z=solve(p,0,p.size());
    cout<<fixed<<setprecision(4)<<z.d<<"\n("<<z.a.x<<", "<<z.a.y<<") and ("<<z.b.x<<", "<<z.b.y<<")\n";
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
1.4142
(2.0000, 3.0000) and (3.0000, 4.0000)
```

### Your Lab 10 Q5 program (closest pair + path-intersection hazard)

```cpp
#include <iostream>
#include <vector>
#include <cmath>
#include <iomanip>
using namespace std;
struct P{long long x,y;};
struct V{P a,b;};
long long orient(P a,P b,P c){
    long long z=(b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x);
    return z==0?0:(z>0?1:-1);
}
bool on(P a,P b,P p){return
orient(a,b,p)==0&&min(a.x,b.x)<=p.x&&p.x<=max(a.x,b.x)&&min(a.y,b.y)<=p.y&&p.y<=max(a.y,b.
y);}
bool hit(P a,P b,P c,P d){
    long long x=orient(a,b,c),y=orient(a,b,d),z=orient(c,d,a),w=orient(c,d,b);
    if(x*y<0&&z*w<0)return true;
    return (x==0&&on(a,b,c))||(y==0&&on(a,b,d))||(z==0&&on(c,d,a))||(w==0&&on(c,d,b));
}
double dist(P a,P b){return hypot(double(a.x)-double(b.x),double(a.y)-double(b.y));}
int main(){
    vector<V> v={{{0,0},{4,4}},{{0,4},{4,0}},{{6,1},{8,3}}};
    if(v.size()<2)cout<<"Min Starting Separation: N/A\n";
    else{
        double best=1e100;
        for(int i=0;i<(int)v.size();i++)for(int j=i+1;j<(int)v.size();j++)best=min(best,dist(v[i].a,v[j].a));
        cout<<fixed<<setprecision(2)<<"Min Starting Separation: "<<best<<"\n";
    }
    for(int i=0;i<(int)v.size();i++)for(int j=i+1;j<(int)v.size();j++)if(hit(v[i].a,v[i].b,v[j].a,v[j].b)){
        cout<<"Trajectory Status: HAZARD (Vehicle "<<i+1<<" and Vehicle "<<j+1<<")\n";return 0;
    }
    cout<<"Trajectory Status: SAFE\n";
}
```

Verified output (compiled with `g++ -std=c++17 -Wall -O2` and run):
```text
Min Starting Separation: 4.00
Trajectory Status: HAZARD (Vehicle 1 and Vehicle 2)
```
