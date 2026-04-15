# ADR 003: dbt for silver, Spark for complex aggregations

## Context
Once we committed to Databricks, we still needed to decide how transformation logic actually gets written. The main contenders were dbt Core for SQL-based work and Apache Spark for anything that needs distributed compute. Some teams use one or the other for everything. We decided the right answer is both, but with a clear and enforced boundary between them.

## Decision
dbt Core handles transformation from bronze to silver and silver to gold wherever the logic can be expressed in SQL. Apache Spark handles complex aggregations, large-scale window functions, and ML feature engineering where SQL isn't the right tool.

## Reasoning

**dbt makes SQL transformation something you can actually maintain.** Every model is versioned, tested, and has a documented lineage. Schema tests run automatically. If a source stops sending data, freshness checks catch it before anyone notices in a dashboard. The DAG makes dependencies visible without anyone having to draw them. None of this happens naturally when transformation logic is spread across Spark notebooks — it requires significant discipline and convention-building that most teams don't sustain long-term.

**The boundary between dbt and Spark is about what SQL can cleanly express, not about preference.** If you can write it in SQL and have it run in a reasonable time on a SQL warehouse, it goes in dbt. If it needs procedural logic, distributed state, or Python libraries that don't exist in SQL, it goes in Spark. This isn't a style guide — it's meant to be enforced at code review. A Spark notebook that's doing something a dbt model could do is a code review rejection.

**Incremental materialisation isn't optional at this scale.** A full refresh on a large fact table can take hours. An incremental dbt model that only processes new or changed records takes minutes. The business isn't going to wait hours for data to be current, and we shouldn't architect ourselves into a position where that's our only option.

**Undocumented Spark notebooks are where institutional knowledge goes to die.** We've all seen this. A notebook gets written by one person, nobody else fully understands it, the person leaves, and now you have business-critical logic that nobody wants to touch. dbt models don't prevent this entirely but they make it significantly harder — the tests and docs are part of the model, not a separate artifact that drifts out of sync.

## Trade-offs accepted

dbt requires a SQL warehouse or Databricks SQL endpoint, which is a small amount of additional infrastructure. It's worth it.

The flip side: anything that goes into Spark has to be explicitly justified and documented. The default is always dbt. Spark is the exception, and exceptions need a reason written down somewhere. This will occasionally feel bureaucratic to engineers who want to just get something done in a notebook, but the alternative is what we're trying to avoid.

## Alternatives considered

**Spark for everything** — rejected. Without enforced structure you end up with notebook sprawl, no automated testing, no lineage, and transformation logic that only the original author understands. We've seen what this looks like in mature data platforms and it's not where we want to be in three years.

**dbt for everything** — also rejected, but for a different reason. dbt is genuinely not good at distributed aggregations across billions of rows or at anything that requires Python libraries for ML feature engineering. Forcing those use cases into dbt produces slow, expensive models and engineers will find workarounds that are worse than just using Spark properly.

## Consequences

SQL-expressible transformation logic lives in dbt with schema tests and documentation. Complex aggregations and ML feature engineering live in Spark notebooks that are documented and explicitly justified. The boundary is enforced in code review — any Spark notebook doing something that belongs in dbt gets sent back.
