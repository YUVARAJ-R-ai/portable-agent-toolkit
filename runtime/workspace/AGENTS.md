# Agent instructions for this workspace

## Always use your tools — never just describe code in your reply
When asked to write, create, or fix a file, you MUST call your `write` or
`edit` tool to actually create/modify the file on disk. Do not respond with
the code in a markdown block and stop there — that is not the same as
completing the task, and the user has no file to compile or run afterward.
After writing a file, verify it exists and briefly show its content back
(e.g. via your `shell`/`tree` tool), don't just claim you created it.

## C++ modulo with negative numbers
In C++, `%` returns a result with the same sign as the *dividend* — so for
negative `x`, `x % n` can be negative (e.g. `-3 % 5 == -3`, not `2`). This
routinely breaks code that compares `(a % n) == (b % n)` when `a` or `b` can
be negative (e.g. modular/toroidal grid problems, circular buffer indices,
wrap-around diagonal checks). Whenever an index or difference can go
negative, normalize with `((x % n) + n) % n` before comparing — never
compare raw `%` results directly when either operand can be negative.

## Compile-check before declaring something done
For C++ tasks, compile the file with `g++ -std=c++17 -Wall` (or the
portable `zig c++` from the dev environment, if installed) via your `shell`
tool before telling the user it's done, and actually run it against at
least one concrete input to sanity-check the output — don't just assert
correctness from reading the code.

## DAA algorithm questions — use the RAG lookup tool, MANDATORY, not optional

For **any question that asks you to explain, implement, or debug a specific
algorithm or algorithm-design technique** (sorting, greedy methods, divide
and conquer, dynamic programming, encoding/compression, scheduling, graph
algorithms, etc.) — call `bash ../rag-search.sh "<the topic, in a few
words>"` with your `shell` tool **first, before** writing any explanation or
code yourself, even for topics you don't immediately recognize as covered.

**Do not pre-judge whether a topic is "in scope" yourself — always ask the
tool and let its own answer decide that.** This corpus specifically covers
Huffman coding, fractional knapsack, greedy algorithms (general idea),
divide and conquer (general idea), maximum subarray, quicksort, mergesort,
and assembly line scheduling — but you don't reliably know in advance
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
- If the tool says `NOT COVERED` (this happens specifically for 0/1
  knapsack, which is a different problem from fractional knapsack): say so
  plainly. Do not answer a 0/1 knapsack question using the fractional
  knapsack solution just because it's the closest thing available — they
  require genuinely different algorithms (DP vs greedy) with different
  answers.
- If the tool says `AMBIGUOUS`: pick the specific topic id it lists that
  actually matches the user's question and re-run
  `bash ../rag-search.sh "<that exact topic id>"`, rather than guessing
  which one they meant.
- Run `bash ../rag-search.sh --list` if you're unsure what's covered at all.

## Switching the model you're running on
If the user asks you to switch/change the model (e.g. "switch to nanbeige",
"use the other model"), use your `shell` tool to run
`bash ../switch-model.sh <filename>` (path is relative to this workspace
dir). Get the exact filename first with `bash ../switch-model.sh --list` —
never guess it. This hot-swaps koboldcpp's loaded model in place (same port,
same server process) and takes ~10-30s; the script blocks until the new
model is confirmed ready, so just report its final "Now serving: ..." line
back to the user. Do not use the interactive picker form (no arguments) —
you don't have a terminal the user can interact with.
