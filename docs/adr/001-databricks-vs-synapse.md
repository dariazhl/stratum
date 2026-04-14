# ADR 001: Databricks over Azure Synapse Analytics

## Date
April 2026

## Status
Accepted

## Context
Stratum requires a unified compute environment for 
large-scale data transformation, streaming ingestion,
and AI workload serving on Azure. Two credible options
exist in the Azure ecosystem: Databricks and Synapse
Analytics.

Both support Delta Lake. Both integrate with ADLS Gen2.
Both offer Spark-based compute. The decision hinges on
which platform better supports the full lifecycle from
raw ingestion through to AI serving at enterprise scale.

## Decision
Databricks is the primary compute platform for Stratum.

## Reasoning

**Delta Lake is native in Databricks.**
Databricks created Delta Lake. OPTIMIZE, ZORDER, 
AUTO OPTIMIZE, and DESCRIBE HISTORY are first-class
operations. Unity Catalog governance is native.
In Synapse, Delta Lake support exists but lags the
reference implementation and lacks Unity Catalog
integration.

**Unity Catalog provides column-level lineage 
automatically.**
For a platform designed to answer regulatory questions
about data provenance, automatic lineage tracking from
ingestion to serving is not optional. Synapse has no
equivalent capability.

**The AI serving layer integrates without additional
architectural complexity.**
Databricks Model Serving, MLflow, and Feature Store
sit on top of the same Delta tables the transformation
layer writes to. In Synapse this connection requires
significant additional engineering.

## Trade-offs accepted
Higher per-DBU cost than Synapse for pure SQL workloads.
Steeper learning curve for SQL-only teams. Synapse is 
the correct choice for organisations that are deeply
Azure-native with primarily SQL workloads at modest
scale. Stratum is designed for AI workload serving
at enterprise scale — the operational advantages of
Databricks outweigh the cost premium.

## Alternatives considered
**Azure Synapse Analytics** — rejected. Delta Lake 
support lags the reference implementation. Unity 
Catalog lineage unavailable.

**Microsoft Fabric** — rejected. Not production-mature
for complex multi-environment enterprise deployments
as of April 2026. Worth revisiting in 12 months.

## Consequences
All transformation and AI serving compute runs on
Databricks. The team must be comfortable with PySpark
and the Databricks workspace. Future decisions should
be evaluated against compatibility with the Databricks
ecosystem first.