# Quick Fix for "No Data" in Grafana

## The Problem
The PostgreSQL exporter can't connect to the database because of Docker networking on Windows.

## The Fix

1. **Redeploy with updated configuration:**
   ```bash
   terraform apply
   ```

2. **Verify exporter is working:**
   ```bash
   # Check exporter logs (should see successful connections)
   docker logs postgres_exporter
   
   # Check metrics endpoint (should see pg_* metrics)
   curl http://localhost:9187/metrics | grep "pg_stat"
   ```

3. **Wait 15-30 seconds** for Prometheus to scrape new metrics

4. **Refresh Grafana dashboard** - metrics should now appear!

## Alternative: Simpler Dashboard

If the imported dashboard still shows "No Data", try this simpler approach:

### Create a Custom Dashboard in Grafana:

1. Go to Grafana → Dashboards → New → New Dashboard
2. Add Panel
3. Use these queries:

**Active Connections:**
```
pg_stat_database_numbackends{datname="dev_db"}
```

**Database Size:**
```
pg_database_size_bytes{datname="dev_db"}
```

**Transaction Rate:**
```
rate(pg_stat_database_xact_commit{datname="dev_db"}[1m])
```

**Table Row Count:**
```
pg_stat_user_tables_n_tup_ins{datname="dev_db"}
```

These should work once the exporter is properly connected!
