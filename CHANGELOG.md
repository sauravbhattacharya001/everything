# Changelog

All notable changes to **Everything** are documented in this file.
This project follows [Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-04-29

### ✨ Features
- Attention Debt Tracker — autonomous cognitive overhead monitor
- Adaptive Ritual Engine — autonomous daily ritual optimizer
- Willpower Budget Engine — autonomous cognitive resource manager
- Behavioral Fingerprint Engine — autonomous behavioral signature analysis
- ContactTrackerService, EnergyTrackerService, DriftDetectorService
- Finance & budgeting module

### ⚡ Performance
- O(log n) binary search in DriftDetectorService
- Eliminate redundant O(F×N) iterations in EnergyTrackerService

### 🐛 Bug Fixes
- Depth-bounded JSON tree analysis + wiki import size limits (security)

### ♻️ Refactoring
- Extract shared IdUtils, remove unused imports and duplicate helpers

### 🔧 Maintenance
- Docker image with Trivy vulnerability scanning, SBOM generation and attestation
- GitHub Actions CI, CodeQL, coverage, Pages deploy
- Auto-labeling with stale bot, PR size labels
