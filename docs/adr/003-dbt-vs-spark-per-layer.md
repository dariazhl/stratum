# ADR 003: dbt for silver and gold, Spark for complex aggregations

## Context
Within Databricks, transformation logic can be written in dbt Core (SQL) or Apache Spark. The decision is where each tool is used and what enforces the boundary.

## Decision
dbt Core handles all SQL-expressible transformation from bronze through gold. Spark handles complex aggregations, large-scale window functions, and ML feature engineering where SQL isn't the right tool.

## Reasoning
dbt makes SQL transformation maintainable where every model is versioned, tested, and documented, and the DAG makes dependencies visible without extra tooling. Incremental materialisation is also a practical necessity: a full refresh on a large fact table takes hours; an incremental run takes minutes. The boundary between dbt and Spark is about what SQL can cleanly express, not preference — and it's enforced at code review, not left to convention.

## Trade-offs
dbt requires a SQL warehouse or Databricks SQL endpoint. Small infrastructure overhead, worth it. Anything that genuinely needs Spark must be explicitly justified and documented — the default is always dbt.

## Alternatives
**Spark for everything** — no automated testing, no lineage, no documentation by default. Creates dependency on specific engineers.

**dbt for everything** — dbt can't handle distributed aggregations at scale or ML feature engineering that needs Python. Forcing those in produces slow, expensive models.
