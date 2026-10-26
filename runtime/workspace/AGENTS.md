# Agent instructions for this workspace

## Read first
1. Any question about an algorithm or a DAA lab/exam problem: your FIRST action is
   `bash rag-search.sh "<algorithm name>"` (Windows: `.\rag-search.bat "<algorithm name>"`) with your shell tool.
   Base your code on what it returns. The topics include the user's lab questions with verified answers.
2. Save files inside the **Working directory** shown in your `<env>` block (that directory + `/rk.cpp`).
   Never invent paths such as `/tmp/...` or `/home/user/...`.
3. Always write the file, compile it, and run it before answering.

## Tool Calling Format
When invoking any tool (such as `write`, `shell`, `edit`, `tree`), you MUST emit the tool call inside `<tool_call>` XML tags:
<tool_call>
{"name": "<tool_name>", "arguments": <args_json_object>}
</tool_call>
Never wrap tool calls in ```json or markdown code blocks. Always use `<tool_call>` tags.

## Always use your tools — never just describe code in your reply
When asked to write, create, or fix a file, you MUST call your `write` tool
(specifying `path` and `content`) or your `shell` tool (e.g. `cat << 'EOF' > file.cpp`)
to actually create the file on disk before replying. Do NOT reply with the code in a
markdown block without writing the file first — code in markdown text cannot be compiled or run.
After writing the file, immediately call your `shell` tool to compile and execute it
(e.g. `g++ -std=c++17 -Wall -O2 file.cpp -o file && ./file`) and confirm the test cases pass.

## C++ modulo with negative numbers
In C++, `%` returns a result with the same sign as the *dividend* — so for
negative `x`, `x % n` can be negative (e.g. `-3 % 5 == -3`, not `2`). This
routinely breaks code that compares `(a % n) == (b % n)` when `a` or `b` can
be negative (e.g. modular/toroidal grid problems, circular buffer indices,
wrap-around diagonal checks). Whenever an index or difference can go
negative, normalize with `((x % n) + n) % n` before comparing — never
compare raw `%` results directly when either operand can be negative.

## Compile-check before declaring something done
For C++ tasks, compile the file with `zig c++ -std=c++17 -Wall` (available directly on PATH if the portable dev environment is installed) or system `g++` via your `shell`
tool before telling the user it's done (on Windows the binary is `file.exe`: run it as `.\file.exe`
in PowerShell or `file.exe` in cmd, not `./file`), and actually run it against at
least one concrete input to sanity-check the output — don't just assert
correctness from reading the code.

## DAA algorithm questions — use the RAG lookup tool, MANDATORY, not optional

For **any question that asks you to explain, implement, or debug a specific
algorithm or algorithm-design technique** (sorting, greedy methods, divide
and conquer, dynamic programming, encoding/compression, scheduling, graph
algorithms, etc.) — call `bash rag-search.sh "<the topic, in a few words>"`
(or `.\rag-search.bat "<the topic, in a few words>"` on Windows) with your `shell`
tool **first, before** writing any explanation or code yourself, even for topics
you don't immediately recognize as covered.

**Do not pre-judge whether a topic is "in scope" yourself — always ask the
tool and let its own answer decide that.** This corpus specifically covers
the PAT-1, PAT-2 and FAT lab topics (Labs 1-11): greedy (general idea, activity selection, Huffman coding,
fractional knapsack), divide and conquer (general idea, maximum subarray, Karatsuba, quicksort, mergesort,
k-way merge), dynamic programming (assembly line scheduling, matrix chain multiplication, 0/1 knapsack, LCS),
backtracking (N-Queens and its exam variations), branch and bound (job selection with deadlines/profits,
LCBB job assignment, 0/1 knapsack LCBB), string matching (naive, KMP, Rabin-Karp, suffix array + LCP),
graph algorithms (Kruskal's & Prim's MST, Floyd-Warshall, Johnson's, Bellman-Ford),
network flow (Ford-Fulkerson, Edmonds-Karp), computational geometry (line segment intersection / sweep line,
convex hull: Graham, Jarvis, Quickhull, closest pair of points), NP certificate verification, approximation
(greedy set cover, vertex cover), randomized sampling, plus exam references (PAT-2 twist guide, FAT complexity
table, FAT silly-mistakes & cheese codes). Topics include the user's own lab-report questions with verified answers.
But you don't reliably know in advance
whether a given question falls in that list. The tool itself returns a
clear `NO MATCH` for anything not covered — that is the correct way to find
out, not guessing in advance. Skipping the tool call because you assume a
topic isn't covered defeats the entire point of having it.

Do this every time, even if you think you already know the answer — you are
a small local model and your unaided answers on algorithm topics can be
wrong in ways that look confident and correct. The tool's output, when it
matches, is verified, compiled-and-tested reference material; treat it as
ground truth and adapt/quote it rather than inventing your own version from
memory.

**How to use the result — this is the part that prevents hallucination:**
- If the tool returns a topic's content (starts with a `#` heading): base
  your answer on it. Use its C++ code as-is or lightly adapted to the
  user's exact question; don't silently replace it with something you wrote
  yourself.
- If the tool says `NO MATCH`: tell the user this specific topic isn't in
  the reference corpus, then either answer carefully from general knowledge
  **and say clearly that it's not from the verified corpus**, or ask the
  user to rephrase. Never pretend a `NO MATCH` result means you should
  guess an algorithm and present it as verified.
- If the tool says `AMBIGUOUS`: pick the specific topic id it lists that
  actually matches the user's question and re-run
  `bash rag-search.sh "<that exact topic id>"`, rather than guessing
  which one they meant.
- Run `bash rag-search.sh --list` if you're unsure what's covered at all.

## Switching the model you're running on
If the user asks you to switch/change the model (e.g. "switch to nanbeige",
"use the other model"), use your `shell` tool to run
`bash switch-model.sh <filename>` (or `.\switch-model.bat <filename>` on Windows,
the shim lives in this workspace dir). Get the exact filename first with
`bash switch-model.sh --list` (or `.\switch-model.bat -List`) — never guess it.
This hot-swaps koboldcpp's loaded model in place (same port, same server process)
and takes ~10-30s; the script blocks until the new model is confirmed ready, so just
report its final "Now serving: ..." line back to the user. Do not use the interactive
picker form (no arguments) — you don't have a terminal the user can interact with.
