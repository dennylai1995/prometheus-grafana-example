# Prometheus With Grafana Example
A minimum example of observability monitoring system with Prometheus and Grafana.

## Overview
![overview](./doc/overview.png)
*This diagram has been reworked based on architecture diagram of Prometheus ([Prometheus official introduction](https://prometheus.io/docs/introduction/overview/#architecture)).*

## Knowledge Points
- In terms of software observability, there are four commonly used tools
    1. Metrics (=indices, ex. Request Per Second)
    2. Log (=known issues printed by developer)
    3. Traces (=request processing path)
    4. Profile (=stacktraces)
- **Grafana** is a data visualization UI.
- **Prometheus** is a metrics collection system (stores data in Time Series DataBase, TSDB) written in Go.
    - Prometheus takes 2 kinds of rules file
        - `altering` rules: to trigger alerts
        - `recording` rules: to precompute frequently needed expressions (stores result as a new set of time series)
- **PromQL** is a query language for Prometheus.
- **Loki** is a log aggregation system.

## Prometheus Metric Types
There are 4 metric types in Prometheus (currently only used in client library, server flattens all data into untyped time series data).
1. Counter
    - a value which can only be increased or be reset to 0 on restart (ex. total number of requests).
2. Gauge
    - a value which can go up and down (ex. the number of concurrent requests).
3. Histogram
    - aggregation (from different instances) possible with PromQL.
    - quantile (ex. 0.95-quantile means 95th percentile) is calculated on server with `histogram_quantile()` PromQL function.
    - exposes the following extra metrics/labels,
    ```bash
    <metric_basename>_bucket{le="<upper inclusive bound>"}
    <metric_basename>_sum
    <metric_basename>_count
    ```
4. Summary
    - hard to aggregate (from different instances) cause quantile calculation happens on client.
    - quantile (ex. 0.95-quantile means 95th percentile) is pre-calculated on client (requires reconfiguring client when quantile value changes).
    - exposes the following extra metrics/labels,
    ```bash
    <metric_basename>{quantile="<φ>"}
    <metric_basename>_sum
    <metric_basename>_count
    ```

## Prometheus Default Metrics And Labels
- While scraping a target, the following labels are automatically added to identify the scraped target,
    - `job`: the **job_name** configured in `prometheus.yml`
    - `instance`: the `<host>:<port>` part of the target (one of the **targets** described in `prometheus.yml` under a **job_name**).
- For each target scrape, Prometheus stores a sample in the following metrics,
    - `up{job="<job-name>", instance="<instance-id>"}`: `1` mean healthy, `0` means scrape failed.
    - `scrape_duration_seconds{job="<job-name>", instance="<instance-id>"}`
    - `scrape_samples_post_metric_relabeling{job="<job-name>", instance="<instance-id>"}`
    - `scrape_samples_scraped{job="<job-name>", instance="<instance-id>"}`
    - `scrape_series_added{job="<job-name>", instance="<instance-id>"}`

## PromQL Syntax
```bash
# get data of a metric filtered by labels
<metric name>{<label name>=<label value>, ...}
# call a function with a metric within a time range, ex. 5m
<function name>(<metric name>[<time range>])
```

## Backup & Restore Prometheus TSDB
Currently there is no UI for this function. However, to achieve this, we can
1. Create snapshot of the TSDB via admin API
```bash
# find prometheus container IP
docker inspect prometheus

# trigger Prometheus admin API for snapshot (needs --web.enable-admin-api flag to be set)
curl -XPOST http://<prometheus_container_IP>:9090/api/v1/admin/tsdb/snapshot

# the admin API will create snapshot of current TSDB under data folder (for example, in our case: ./prometheus_runtime_data/snapshots/20250117T054020Z-3f530cc0f386edcf)
```
2. Manually copy (need `sudo`) folders under snapshot to Prometheus data folder (in our case: `prometheus_runtime_data` folder)
![prometheus_backup_restore](./doc/prometheus_backup_restore.png)
3. Start Prometheus

**NOTE**
- Restored TSDB is under governance of retention policies of the Prometheus instance restores it.
- Snapshot uses almost **the same disk space** as the TSDB being snapshot, remember to delete it after copying.

## Grafana Data Persistence
During runtime, Grafana stores data (configurations of datasources, dashboards...) to databases. To persist its data locally, one should do the followings (which is called **provision**),
```bash
# provision "dashboard"
1. Export dashboard JSON file (without sharing externally)
2. Put the JSON file under ./grafana/provisioning/dashboards
3. Restart Grafana (or wait for the value of {updateIntervalSeconds})

# provision "datasource"
1. Add datasource in ./grafana/provisioning/datasources/datasources.yaml
2. Restart Grafana
```
A good starting point: [Provisioning Grafana tutorial (in Chinese)](https://ithelp.ithome.com.tw/m/articles/10295816)

## Disk Usage Concerns
1. **Grafana**
    - datasource caching (per datasource)
    - dashboard version history (`versions_to_keep` in `grafana.ini`, comment out by default)
2. **Prometheus**
    - Retention policies of the TSDB: `time` or `size` (only one can be active).
        - when `time` is used, all samples in the oldest 2 hours must be out of the retention time to trigger deletion.
        - when `size` is used, the oldest 2-hours samples are deleted when retention size is reached (it is recommended to use 80-85% of the allocated disk space).
        
    - Data compaction happens every 2 hours, by default.
3. **Docker Container**
    - default log driver does not do log rotation

## Fine-tuned Items
- [x] Running `node-exporter` in host mode (so it can access all host Network Interfaces)
- [x] Docker container log auto-rotation
- [x] DB size limitation of Prometheus (1GB)
- [x] Persistent Grafana data (so it becomes portable)
- [x] Bind out Prometheus data (in `prometheus_runtime_data` folder)

## Handy Commands
```bash
# reload Prometheus configuration without restarting it
docker exec -it prometheus kill -HUP 1
# list all docker containers brought up by this project
docker ps --filter "label=observability_stack"
# list all docker containers responsible for "visualization"
docker ps --filter "label=observability_stack=visualization"
# list all docker containers act as "datasource"
docker ps --filter "label=observability_stack=datasource"
# list all docker containers act as "exporter"
docker ps --filter "label=observability_stack=exporter"
```

## References
- Grafana
    - [Grafana - datasource caching](https://grafana.com/docs/grafana/latest/administration/data-source-management/#query-and-resource-caching)
    - [Grafana - dashboard version_to_keep setting](https://grafana.com/docs/grafana/latest/setup-grafana/configure-grafana/#dashboards)
    - [Provision Grafana](https://grafana.com/docs/grafana/latest/administration/provisioning/)
- Prometheus
    - [Prometheus metric types](https://prometheus.io/docs/concepts/metric_types/#metric-types)
    - [Histogram V.S. Summary](https://prometheus.io/docs/practices/histograms/)
    - [Jobs and Instances](https://prometheus.io/docs/concepts/jobs_instances/)
    - [Prometheus storage](https://prometheus.io/docs/prometheus/latest/storage/)
    - [Admin API - snapshot](https://prometheus.io/docs/prometheus/latest/querying/api/#tsdb-admin-apis)
    - [stack overflow - prometheus DB backup and restore](https://stackoverflow.com/questions/67608379/backup-and-restore-prometheus-metrics)
