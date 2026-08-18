# Portable Dev Environment

Optional component (`components/dev-environment.sh`) that installs four
language toolchains into `<target>/dev/` — fully self-contained, no host
compiler, package manager, or language runtime required.

| Language | Tool | Source |
|---|---|---|
| C / C++ | `zig cc` / `zig c++` | [ziglang.org](https://ziglang.org/download/) — official release tarball |
| Rust | `rustc` + `cargo` | [static.rust-lang.org](https://static.rust-lang.org/dist/channel-rust-stable.toml) — official standalone installer, **no rustup** |
| Node.js + npm | `node`, `npm` (React via `npm create vite@latest`) | [nodejs.org](https://nodejs.org/dist/) — official prebuilt tarball, current LTS |
| Python | `python3` | [python-build-standalone](https://github.com/astral-sh/python-build-standalone) — "install_only" build |

## Use it

```bash
bash dev.sh
```
Drops you into a subshell with all four on `PATH`. `exit` returns you to
your normal shell exactly as it was — nothing was added to your system PATH
permanently, nothing was written outside `dev/`.

```
$ bash dev.sh
Portable dev environment active. Available:
  zig     0.16.0  (zig cc / zig c++ for C and C++)
  rustc   1.97.1
  cargo   1.97.1
  node    v24.19.0  (React: npm create vite@latest)
  npm     11.17.0
  python3 3.13.15
```

## The one non-obvious piece: Rust needs a linker, and doesn't ship one

`rustc` alone compiles to object files — it relies on a separate C linker
to produce the final executable. Requiring the host to already have
`gcc`/`clang` installed would break this whole project's "no host
dependency" rule, and confirmed directly during development: `cargo build`
on a host with no system C toolchain fails with `linker \`cc\` not found`.

**Fix**: `dev/rust/config.toml` (picked up automatically via `CARGO_HOME`)
points cargo's linker at a tiny wrapper script that calls `zig cc` — Zig is
already part of this bundle for C/C++, and it happens to work excellently
as a drop-in linker too. Verified live: a real `cargo build` + run succeeds
using nothing outside `dev/`, on a host with no system C compiler at all.

## Verification performed

Every toolchain was tested with a real compile-and-run through the
*installed* binaries specifically, with `PATH` scrubbed of system compilers
(`env -i PATH="$installdir/dev/...:/usr/bin:/bin"`) so a pass couldn't be
accidentally due to a host-installed toolchain filling in:

- **C**: `zig cc hello.c` → ran, correct output.
- **C++**: `zig c++ hello.cpp` → ran, correct output (first C++ use
  triggers a one-time build of Zig's bundled libc++ from source — slow,
  noisy with nullability warnings, but expected and not an error).
- **Rust**: a real `cargo build` (using the zig-linker config above) → ran,
  correct output.
- **Node/React**: `npm create vite@latest` → real scaffold → `npm install`
  → `npm run build` → real production build artifacts (`dist/index.html`,
  bundled JS/CSS) produced successfully.
- **Python**: `python3 -c "..."` → ran, correct output, reports the
  expected standalone-build version string.
