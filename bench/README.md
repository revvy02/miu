# bench

Fixed UI trees for measuring miu's own cost. Each run builds the dev place, opens it in a fresh
Studio, and times every fixture's walk in a tight loop: its render function run through a Portal
into its own ScreenGui. What's timed is miu's synchronous work (walking, diffing, pruning, and the
engine reads and writes it makes), with no frames in between, so layout and drawing costs aren't
included.

```sh
mise run bench                                        # writes bench/results/latest.json
mise run bench my-change --baseline bench/results/baseline.json
```

### A/B: a change against a git ref

```sh
mise run bench-ab                        # working tree vs HEAD, writes bench/results/ab-latest.json
mise run bench-ab 72a006a --label my-change
```

Separate runs drift: Studio slows down when it loses focus, and macOS throttles background apps,
so two runs of the same code can differ by several percent. `bench-ab` instead renders every
fixture against two independent copies of the packages in one session: the working tree and the
ref's sources, both imported at runtime the same way (a rojo-built copy measured a few percent
faster than an imported copy of the same code). The two alternate on every walk, each walk timed
on its own, so a stretch where Studio runs slow hits both sides, and the garbage collector's
work lands on each in proportion to what it allocates. The change is the median over 20 rounds
of 100 walk pairs. Use it to judge any change smaller than ~10%.

Both copies get retained-scope from the path `dev.project.json` mounts. When the change is in
retained-scope itself, point `dev.project.json` at `../retained-scope/src` for the candidate and
pass the installed copy for the baseline, e.g.
`--baseline-retained-scope roblox_packages/.pesde/revvy02_retained-scope@0.1.1/retained-scope/src`.

The table shows the median µs per walk and per miu node, and roughly how many KB each walk
allocates. With `--baseline` it adds the change against those saved results. A run fails if a
fixture's instance count drifts across walks, doesn't match the count it states, or its check
fails, so an optimization that breaks rendering fails instead of looking fast.

| Fixture | Tree | What it isolates |
|---|---|---|
| `flat` | 500 static Frames | per-element walk and diff |
| `nested` | depth 6 × 3 static Frames | scope push, pop and prune |
| `tagged` | 500 static Frames with 3 tags | tag diffing |
| `stylesheet` | 8 × `StyleLink(StyleSheet(WindRules))` | re-walking static style sheets |
| `changing` | 500 TextLabels with new `Text` every walk | the write path |
| `churn` | keyed list of 200, 20 swapped per walk | mounting and unmounting |
| `transitions` | 50 settled + 50 flipping Transitions in one list | Float and Transition while animating |
| `transitions-settled` | 100 settled Transitions in one list | the same list with nothing changing size |
| `nestedFloats` | auto Float around 20 resizing auto Floats | nested measurement; its check fails if the outer Float trails the inner ones |

Add a fixture by writing a module in `fixtures/` that returns a function taking a package set
(`pkgs.miu`, `pkgs.wind`, `pkgs.transition`; see `pkgs.luau`) and returning
`{ name, summary, render(walk), expectedInstances?, warmupSeconds?, check? }`, and listing it in
`run.luau`. Fixtures take the package set so A/B runs can render them against either copy. `warmupSeconds` keeps walking once per frame before timing starts, for fixtures that
ease by real time. `check(gui)` runs after each sample, outside the timing, and fails the run with
the message it returns.

**Results.** Commit a results file with each change it measures, named for that change, so the
commit carries its before and after. `latest.json` is scratch. Compare only runs made on the same
machine: absolute times vary with hardware and with whatever else Studio is doing.
