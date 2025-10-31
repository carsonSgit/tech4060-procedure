# Add 50 more users
for i in {300..350}; do
    docker exec -it dev_postgres psql -U dev_user -d dev_db -c "INSERT INTO users (name, email) VALUES ('User$i', 'user$i@example.com');"
done

# Update random users - watch transaction graph
for i in {1..20}; do
    docker exec -it dev_postgres psql -U dev_user -d dev_db -c "UPDATE users SET name = 'UpdatedUser$i' WHERE id = $i;"
done

# Single command, inserts 100 rows at once
docker exec -it dev_postgres psql -U dev_user -d dev_db -c "
INSERT INTO users (name, email)
SELECT 'BulkUser' || generate_series, 'bulk' || generate_series || '@example.com'
FROM generate_series(1, 100);
"

# Run 5 queries simultaneously in background - watch connections spike
for i in {1..5}; do
    docker exec dev_postgres psql -U dev_user -d dev_db -c "SELECT pg_sleep(5), * FROM users;" &
done

# Delete users with ID > 200
docker exec -it dev_postgres psql -U dev_user -d dev_db -c "DELETE FROM users WHERE id > 200;"

# Add a products table
docker exec -it dev_postgres psql -U dev_user -d dev_db -c "
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name TEXT,
    price DECIMAL(10,2)
);
"

# Insert sample products
docker exec -it dev_postgres psql -U dev_user -d dev_db -c "
INSERT INTO products (name, price) VALUES
    ('Laptop', 999.99),
    ('Mouse', 29.99),
    ('Keyboard', 79.99);
"

# Runs for 2 minutes, inserting data every 2 seconds
# Watch your graphs update in real-time
for i in {1..60}; do
    docker exec -it dev_postgres psql -U dev_user -d dev_db -c "INSERT INTO users (name, email) VALUES ('AutoUser$i', 'auto$i@example.com');"
    echo "Inserted AutoUser$i - refresh Grafana!"
    sleep 2
done

# Mix of operations - looks impressive in dashboard
docker exec -it dev_postgres psql -U dev_user -d dev_db -c "
BEGIN;
INSERT INTO users (name, email) VALUES ('TestUser1', 'test1@example.com');
UPDATE users SET name = 'Updated' WHERE id = 1;
SELECT COUNT(*) FROM users;
COMMIT;
"

# See total user count (should increase after inserts)
docker exec -it dev_postgres psql -U dev_user -d dev_db -c "SELECT COUNT(*) FROM users;"

# See table sizes (shows in Grafana)
docker exec -it dev_postgres psql -U dev_user -d dev_db -c "
SELECT 
    tablename, 
    pg_size_pretty(pg_total_relation_size(tablename::text)) as size
FROM pg_tables 
WHERE schemaname = 'public';
"

# See current activity (watch this in Grafana)
docker exec -it dev_postgres psql -U dev_user -d dev_db -c "SELECT COUNT(*) FROM pg_stat_activity WHERE state = 'active';"