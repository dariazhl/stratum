# ADR 002: Delta Lake over Apache Iceberg

## Date
April 2026

## Status
Accepted

## Context
Stratum requires an open table format for the 
lakehouse storage layer on ADLS Gen2. Both Delta 
Lake and Apache Iceberg are mature open table formats
that support ACID transactions, schema evolution, 
and time travel. The decision determines the storage 
protocol that all downstream transformation and 
serving layers depend on.

## Decision
Delta Lake is the table format for all layers of
the Stratum medallion architecture.

## Reasoning

**Delta Lake is native to Databricks.**
Databricks created Delta Lake. The OPTIMIZE and 
ZORDER commands for file compaction and data 
skipping are first-class operations. AUTO OPTIMIZE
reduces small file accumulation automatically.
DESCRIBE HISTORY provides a complete audit trail
of every operation on every table. These capabilities
are available out of the box without additional
configuration.

**Unity Catalog integration is native.**
Delta Lake tables registered in Unity Catalog get
automatic column-level lineage tracking. Every read,
write, and transformation is recorded without
additional instrumentation. For a platform designed
to answer regulatory questions about data provenance
this is a significant operational advantage.

**The small files problem is solved at the protocol
level.**
Streaming ingestion produces many small files which
degrade query performance over time. Delta Lake's
AUTO OPTIMIZE and OPTIMIZE commands compact small
files automatically. In Iceberg this requires 
explicit compaction jobs that must be scheduled
and monitored separately.

**DESCRIBE HISTORY enables point-in-time recovery.**
Every Delta table maintains a complete transaction
log. Rolling back to any previous version of a
table is a single command. For a platform ingesting
data from multiple sources where upstream errors
are inevitable, this capability reduces recovery
time from hours to seconds.

## Trade-offs accepted
Delta Lake is less portable than Iceberg across
cloud providers. Iceberg has stronger multi-cloud
support and is the preferred format for organisations
that need to move data between AWS, GCP, and Azure
without vendor dependency. Stratum is Azure-native
by design. Cross-cloud portability is not a current
requirement. If this changes, migration from Delta
to Iceberg is feasible but non-trivial.

## Alternatives considered
**Apache Iceberg** — rejected for this deployment.
Superior multi-cloud portability but lacks native
Unity Catalog integration and requires explicit
compaction management. Correct choice for 
multi-cloud or vendor-neutral deployments.

**Apache Hudi** — rejected. Smaller community,
less mature tooling, and no meaningful advantage
over Delta Lake for the Stratum use case.

## Consequences
All tables in bronze, silver, and gold layers use
Delta format. Transformation logic assumes Delta
semantics — MERGE, OPTIMIZE, and DESCRIBE HISTORY
are available as first-class operations. Future
architectural decisions should be evaluated against
Delta Lake compatibility first.