# NYC Taxi BigQuery dbt Project

This repository contains a dbt project that transforms NYC taxi trip data in
BigQuery into analytics-ready staging, intermediate, mart, and reporting models.

The project standardizes raw yellow and green taxi data, enriches it with lookup
data, builds a trip fact table, and creates a monthly revenue reporting table by
pickup zone and service type.

## Project Overview

Project name: `ny_taxi_bigquery`

Target warehouse: BigQuery

Expected dbt profile: `ny_taxi_bigquery`

Raw source location:

- BigQuery project: `silje-no-org-zoomcamp`
- BigQuery dataset: `nytaxi`

Configured raw source tables:

- `yellow_tripdata_non_partitioned`
- `green_tripdata_non_partitioned`
- `fhv_tripdata_2019_non_partitione`

## Data Flow

```text
Raw BigQuery tables
        |
        v
Staging models
  - stg_yellow_tripdata
  - stg_green_tripdata
  - stg_fhv_tripdata
        |
        v
Intermediate models
  - int_trips_unioned
  - int_trips
        |
        v
Mart models
  - fct_trips
  - dim_zones
  - dim_vendors
        |
        v
Reporting model
  - fct_monthly_zone_revenue
```

## Repository Structure

```text
.
├── dbt_project.yml
├── packages.yml
├── package-lock.yml
├── macros/
├── models/
│   ├── staging/
│   ├── intermediate/
│   └── marts/
│       └── reporting/
├── seeds/
├── analyses/
├── snapshots/
└── tests/
```

## Models

### Staging

The staging layer reads raw BigQuery sources and standardizes names and data
types.

- `stg_yellow_tripdata`: cleans yellow taxi trip records.
- `stg_green_tripdata`: cleans green taxi trip records.
- `stg_fhv_tripdata`: cleans FHV trip records.

For the `dev` target, the taxi staging models apply a deterministic filter for
January 2019:

```sql
where pickup_datetime >= '2019-01-01'
  and pickup_datetime < '2019-02-01'
```

### Intermediate

- `int_trips_unioned`: unions green and yellow taxi trips into one normalized
  schema and adds `service_type`.
- `int_trips`: enriches trips with payment type descriptions, generates a
  surrogate `trip_id`, and deduplicates trip records.

### Marts

- `fct_trips`: incremental fact table containing taxi trips enriched with pickup
  and dropoff zone information.
- `dim_zones`: taxi zone dimension built from the `taxi_zone_lookup` seed.
- `dim_vendors`: vendor dimension derived from trip records and the
  `get_vendor_data` macro.

### Reporting

- `fct_monthly_zone_revenue`: monthly revenue aggregation by pickup zone and
  service type. It includes revenue components, trip counts, average passenger
  count, and average trip distance.

## Seeds

The project includes two seed files:

- `taxi_zone_lookup.csv`: NYC taxi zone reference data.
- `payment_type_lookup.csv`: payment type code descriptions.

Load seeds with:

```bash
dbt seed
```

## Macros

- `safe_cast(column, data_type)`: uses BigQuery `safe_cast` when running on
  BigQuery and regular `cast` otherwise.
- `get_trip_duration_minutes(pickup_datetime, dropoff_datetime)`: calculates trip
  duration in minutes.
- `get_vendor_data(vendor_id_column)`: generates a SQL `case` expression mapping
  vendor IDs to vendor names.

## Dependencies

The project uses the following dbt packages:

- `dbt-labs/dbt_utils`
- `dbt-labs/codegen`

Install dependencies with:

```bash
dbt deps
```

## Setup

1. Install dbt with the BigQuery adapter.

   ```bash
   pip install dbt-bigquery
   ```

2. Configure a dbt profile named `ny_taxi_bigquery`.

   Example `~/.dbt/profiles.yml`:

   ```yaml
   ny_taxi_bigquery:
     target: dev
     outputs:
       dev:
         type: bigquery
         method: oauth
         project: silje-no-org-zoomcamp
         dataset: dbt_dev
         threads: 4
         location: US
   ```

   Adjust `method`, `project`, `dataset`, and `location` to match your BigQuery
   environment.

3. Install package dependencies.

   ```bash
   dbt deps
   ```

4. Validate the project.

   ```bash
   dbt parse
   ```

5. Load seeds, run models, and execute tests.

   ```bash
   dbt seed
   dbt run
   dbt test
   ```

## Common Commands

Run all models:

```bash
dbt run
```

Run only staging models:

```bash
dbt run --select staging
```

Run only marts:

```bash
dbt run --select marts
```

Run the reporting model and its upstream dependencies:

```bash
dbt run --select +fct_monthly_zone_revenue
```

Run tests:

```bash
dbt test
```

Generate and serve documentation:

```bash
dbt docs generate
dbt docs serve
```

## Data Quality Checks

Schema YAML files define tests for key model contracts, including:

- non-null IDs and timestamps
- unique trip IDs
- accepted values for `service_type`
- relationships between trip location IDs and `dim_zones`
- unique monthly reporting grain for `fct_monthly_zone_revenue`

## Notes

- The downstream mart flow currently uses yellow and green taxi data. The FHV
  staging model exists, but FHV records are not yet included in the intermediate
  or mart models.
- The configured FHV source table name is
  `fhv_tripdata_2019_non_partitione`. Confirm this matches the actual BigQuery
  table name.
- `fct_trips` is incremental and uses `trip_id` as the unique key with a BigQuery
  merge strategy.
- In the current environment used to inspect this repository, `dbt` was not
  installed, so project parsing and tests were not executed.
