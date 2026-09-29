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

The table shows the median µs per walk and per miu node, and roughly how many KB each walk
allocates. With `--baseline` it adds the change against those saved results. A run fails if a
fixture's instance count drifts across walks or doesn't match the count it states, so an
optimization that breaks rendering fails instead of looking fast.

| Fixture | Tree | What it isolates |
|---|---|---|
| `flat` | 500 static Frames | per-element walk and diff |
| `nested` | depth 6 × 3 static Frames | scope push, pop and prune |
| `tagged` | 500 static Frames with 3 tags | tag diffing |
| `stylesheet` | 8 × `StyleLink(StyleSheet(WindRules))` | re-walking static style sheets |
| `changing` | 500 TextLabels with new `Text` every walk | the write path |
| `churn` | keyed list of 200, 20 swapped per walk | mounting and unmounting |
| `transitions` | 50 settled + 50 flipping Transitions | Float and Transition |

Add a fixture by writing a module in `fixtures/` that returns
`{ name, summary, render(walk), expectedInstances? }` and listing it in `run.luau`.

**Results.** Commit a results file with each change it measures, named for that change, so the
commit carries its before and after. `latest.json` is scratch. Compare only runs made on the same
machine: absolute times vary with hardware and with whatever else Studio is doing.
