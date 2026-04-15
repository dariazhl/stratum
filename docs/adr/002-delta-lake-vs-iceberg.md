# ADR 002: Delta Lake over Apache Iceberg

## Context
The project needed an open table format for the lakehouse on ADLS Gen2. Delta Lake and Iceberg are both mature options with ACID transactions, schema evolution, and time travel. The right answer depends on where you're running.

## Decision
Delta Lake is the table format across all medallion layers: bronze, silver, and gold.

## Reasoning
Delta Lake is what Databricks is built around — OPTIMIZE, AUTO OPTIMIZE, and DESCRIBE HISTORY behave as documented without surprises. Unity Catalog lineage also only works properly with Delta tables, and automatic column-level lineage is a hard compliance requirement. The small file problem from streaming ingestion is handled in the background by AUTO OPTIMIZE; with Iceberg you'd need to schedule and monitor explicit compaction jobs. Point-in-time recovery is a single command — we've already used it during testing.

## Trade-offs
Delta is less portable than Iceberg across cloud providers. Stratum is Azure-native by design, so cross-cloud portability isn't a current requirement. If that changes, migrating to Iceberg is feasible but not trivial.

## Alternatives
**Apache Iceberg** — better for multi-cloud or vendor-neutral deployments. Lacks native Unity Catalog integration and requires manual compaction management.

**Apache Hudi** — smaller community, less mature tooling, no meaningful advantage for this use case.
