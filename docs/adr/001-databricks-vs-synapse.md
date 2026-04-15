# ADR 001: Databricks over Azure Synapse Analytics

## Context
Stratum needed a single compute platform for ingestion, large-scale transformation, and AI workload serving on Azure. The realistic options were Databricks and Synapse Analytics.

## Decision
Databricks is the primary compute platform for Stratum.

## Reasoning
Databricks built Delta Lake, and the operational difference is real — OPTIMIZE, ZORDER, DESCRIBE HISTORY work without edge cases. Unity Catalog gives us automatic column-level lineage, which is a hard compliance requirement, not a nice-to-have; Synapse has nothing equivalent. The ML layer (Model Serving, MLflow, Feature Store) also reads directly from the same Delta tables the transformation layer writes, with no handoff or format conversion required.

## Trade-offs
Higher cost per compute unit than Synapse for pure SQL workloads. If Stratum were primarily a SQL analytics platform for a BI team, Synapse would probably win. It's not, so Databricks does.

## Alternatives
**Azure Synapse Analytics** — Delta Lake support lags the reference implementation; no Unity Catalog equivalent.

**Microsoft Fabric** — not production-mature for complex multi-environment deployments as of April 2026. Worth revisiting in a year.
