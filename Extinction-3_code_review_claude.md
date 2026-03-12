# Extinction-3 — Code Review & Analysis Notes
_by Claude Sonnet 4.6, session 2026-03-09_

## Project Summary
Pac-Man inspired game where ghost behavior evolves via genetic algorithms.
Lua + LÖVE 11.2. Graduation project (CS).

## Architecture
- Steady-state GA: ghosts replaced via `crossover()` on death — no discrete generations
- Genotype: `target_offset`, `target_offset_freightned`, `fear_target`, `fear_group`,
  `chase_feared_gene`, `scatter_feared_gene`, `try_order` (movement priority array)
- Fitness: event-driven — catches, pill collection, update cycles
- Multiple behavioral modes: chase, scatter, frightened
- Stats: distribution of genetic traits logged via `reporter()`
- Cross-platform binary shipped (AppImage + Windows exe)

## Main Scientific Result (per author)
**"Nintendo devs got it right the first time."**
Population always converged to target_offset 14/-14 — essentially avoiding engagement.
Cowardice is rewarded when fitness is defined by survival. The original Pac-Man parameters
were optimal for engagement; the search space was too narrow to discover anything better.

This is a *real* result. It validates the original design by negative example.

## What Worked
- Concept fit for graduation scope: known domain, isolated variables, measurable behavior
- Genotype is richer than most toy GA work — not just a single float
- Fitness avoids trivial "stand still" failure mode
- Shipped as a working artifact

## What Didn't / Gaps
- No convergence analysis tooling — hard to show *statistically* that evolution is happening
  vs. random variation. Brute-forced through, but the argument is weak without data.
- Experimental series (run-serie1/2/3) undocumented — "get your feet wet" exploration,
  not structured hypothesis testing. Fine for process, invisible in the artifact.
- No README in repo — thesis presumably carries the explanation.

## Author's Framing (important)
Not hard science — anthropology with computers. Set out to develop tools and method,
not to prove a pre-defined hypothesis. The result emerged from play and exploration.
This is a legitimate epistemological position, especially for early-stage simulation research.

## Notes for Cross-Analysis with Paper
- Paper will clarify what was formally argued vs. explored
- Main technique: treat GA as a phenomenon, compare against baselines
- Look for: convergence data, population diversity metrics, trait distribution over time
- Look for: how the 14/-14 result is framed — discovery or confirmation?
