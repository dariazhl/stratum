# ADR 003: dbt for silver, Spark for complex aggregations

## Date
April 2026

## Status
Accepted

## Context
Stratum requires a transformation strategy across
the medallion layers. Two primary tools are available
within the Databricks ecosystem: dbt Core for
SQL-based transformation and Apache Spark for
distributed compute. The decision determines where
each tool is used and why — and establishes the
boundary between them as an architectural contract
rather than a preference.

## Decision
dbt Core handles all SQL-expressible transformation
logic from bronze to silver and silver to gold.
Apache Spark handles complex aggregations, window
functions at scale, and ML feature engineering
where distributed compute is required.

## Reasoning

**dbt brings software engineering discipline to SQL.**
Every dbt model is version controlled, tested,
and documented. Schema tests run automatically
on every deployment. Freshness checks alert when
source data stops arriving. The dbt DAG makes
data lineage visible without additional tooling.
None of this exists when transformation logic
lives in ad-hoc Spark notebooks.

**The boundary is expressibility in SQL.**
If the transformation can be expressed cleanly
in SQL it belongs in dbt. If it requires
procedural logic, distributed state, or compute
that exceeds what a SQL warehouse can handle
efficiently it belongs in Spark. This boundary
is not a preference — it is an architectural
contract that must be enforced in code review.

**dbt incremental materialisation solves the
full refresh problem.**
A full refresh on a 500 million row fact table
takes hours. An incremental dbt model that
processes only new or changed records takes
minutes. The business cannot wait hours for
updated data. Incremental materialisation is
not an optimisation — it is a business requirement
expressed as an architectural constraint.

**Spark notebooks without discipline become
technical debt.**
Undocumented Spark notebooks that contain
business logic are the most common source of
institutional knowledge loss in data platforms.
When the engineer who wrote the notebook leaves,
the logic leaves with them. dbt models are
self-documenting by design — the tests and
the documentation are part of the model,
not separate artifacts that get out of sync.

## Trade-offs accepted
dbt requires a SQL warehouse or Databricks SQL
endpoint for execution. This adds a small amount
of infrastructure complexity compared to running
everything in Spark. The operational cost is
worth the engineering discipline dbt enforces.

Complex window functions and ML feature engineering
that require Spark must be explicitly justified
and documented. The default is always dbt. Spark
is the exception that requires a reason.

## Alternatives considered
**Spark notebooks for everything** — rejected.
No version control for transformation logic,
no automated testing, no lineage, no documentation
by default. Creates institutional knowledge
dependency on specific engineers.

**dbt for everything** — rejected. dbt cannot
efficiently handle distributed aggregations
across billions of rows or ML feature engineering
that requires Python libraries. Forcing these
into dbt produces slow, expensive, and brittle
models.

## Consequences
All transformation logic that can be expressed
in SQL lives in dbt models with schema tests
and documentation. Complex aggregations and
ML feature engineering live in documented
Spark notebooks with explicit justification.
The boundary between the two is enforced
in code review. Any Spark notebook that contains
SQL-expressible logic is a code review rejection.