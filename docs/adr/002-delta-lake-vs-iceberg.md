# ADR 002: Delta Lake over Apache Iceberg

## Context
We needed to choose a table format for the Stratum lakehouse on ADLS Gen2. Delta Lake and Apache Iceberg are both credible options — both are open, both support ACID transactions, schema evolution, and time travel. This isn't a case where one option is clearly wrong; it's a case where the right answer depends on what you're actually building.

## Decision
Delta Lake is the table format across all medallion layers — bronze, silver, and gold.

## Reasoning

**We're running on Databricks, and Delta Lake is what Databricks is built around.** That's not a trivial point. OPTIMIZE, ZORDER, AUTO OPTIMIZE, DESCRIBE HISTORY — these work the way you'd expect, without edge cases, because Delta Lake is the reference implementation. Iceberg support on Databricks exists but feels like a second-class citizen in places that matter.

**Unity Catalog lineage only works properly with Delta tables.** This was actually the cleaner deciding factor. We need automatic column-level lineage for compliance reasons — not as a nice-to-have but as a hard requirement. Delta tables registered in Unity Catalog get that out of the box. Iceberg tables don't get the same treatment, and we're not in a position to build and maintain that instrumentation ourselves.

**Small file management is a real problem with streaming, and Delta handles it without extra work.** Streaming ingestion generates a lot of small files quickly, and small files kill query performance. Delta's AUTO OPTIMIZE compacts them in the background. With Iceberg you need to schedule and monitor explicit compaction jobs — which means more things to operate and more things to forget to do at 2am when something is wrong.

**Point-in-time recovery is a one-liner.** Every Delta table keeps a full transaction log. If we need to roll back a table — because of a bad upstream load, a botched transformation, whatever — it's a single command. We've already used this during testing and it's saved hours. The alternative is restoring from backup, which is slower and requires you to have thought ahead about backup schedules.

## Trade-offs accepted

Delta Lake is less portable than Iceberg. If we ever needed to move workloads to GCP or AWS, Iceberg would have been the safer choice — it has broader support across cloud-native query engines and doesn't carry the same Databricks association. But Stratum is Azure-native by design and that's not going to change. Cross-cloud portability isn't a requirement.

If it ever does become a requirement, migrating from Delta to Iceberg is doable but it's not trivial — it would be a real project, not an afternoon.

## Alternatives considered

**Apache Iceberg** — the right format for multi-cloud or vendor-neutral deployments. For this specific platform on Databricks on Azure, the Unity Catalog integration gap and the operational overhead of manual compaction made it the wrong choice.

**Apache Hudi** — we didn't look at this very hard. Smaller community, less mature tooling, and no meaningful advantage for what we're doing. Not worth the evaluation time.

## Consequences

Everything in bronze, silver, and gold is Delta format. Transformation logic can assume Delta semantics — MERGE, time travel, OPTIMIZE — are available. Any future tool or process that writes to the lakehouse needs to produce Delta tables. When evaluating new components, Delta compatibility should be an early filter, not an afterthought.
