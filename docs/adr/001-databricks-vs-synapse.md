# ADR 001: Databricks over Azure Synapse Analytics

## Context
We needed to pick a compute platform that could handle the full range of what Stratum does: raw ingestion, large-scale transformation, and eventually serving AI workloads — all on Azure. The two realistic options were Databricks and Synapse Analytics.

On paper they look similar. Both support Delta Lake. Both sit on top of ADLS Gen2. Both give you Spark. But as we dug into the details, the gap between them turned out to be much wider than the feature matrix suggested.

## Decision
Databricks is the primary compute platform for Stratum.

## Reasoning

**Databricks built Delta Lake, and it shows.** OPTIMIZE, ZORDER, DESCRIBE HISTORY — these aren't bolted on, they're just part of how the platform works. Synapse technically supports Delta, but it's always a version or two behind and some of the more useful operational commands either don't exist or behave differently. That gap matters when you're running this at scale.

**Unity Catalog was the deciding factor.** We need to be able to answer regulatory questions about where data came from and how it moved through the platform. Unity Catalog gives us column-level lineage automatically — every read and write is tracked without us having to instrument anything. Synapse has nothing equivalent. We'd be building that ourselves, and we'd probably never quite catch everything.

**The ML layer fits without extra work.** Databricks Model Serving, MLflow, and the Feature Store are all reading from the same Delta tables that the transformation layer writes to. There's no handoff, no export step, no format conversion. Getting the same result in Synapse would have required a meaningful amount of additional engineering that we'd then own forever.

## Trade-offs accepted

Databricks costs more per compute unit than Synapse for straight SQL workloads. If Stratum were primarily a SQL analytics platform running batch queries for a BI team, Synapse would probably be the right answer. It's also a gentler learning curve for people who've spent their careers in T-SQL.

But we're building for AI serving at enterprise scale, and for that the operational advantages of Databricks outweigh the cost premium. The lineage and governance story alone justifies it.

## Alternatives considered

**Azure Synapse Analytics** — we looked at it seriously, but the Delta Lake support lagging the reference implementation and the absence of any Unity Catalog equivalent were blockers, not just inconveniences.

**Microsoft Fabric** — interesting direction but not where we want to be right now. As of April 2026 it's not mature enough for a complex multi-environment deployment. Worth revisiting in a year.

## Consequences

All transformation and AI serving compute runs on Databricks. The team needs to be comfortable in PySpark and the Databricks workspace — this is a real investment for anyone coming from a pure SQL background. Going forward, any new tool or service we bring in should be evaluated against whether it works well in the Databricks ecosystem, because we're committing to it.
