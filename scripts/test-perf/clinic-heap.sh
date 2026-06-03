# Profile only the suspect route.
ROUTES="/api/orders" pnpm exec clinic heapprofiler -- node server-with-route-subset.mjs &
sleep 2

# Drive the route for 90 seconds.
autocannon -c 30 -d 90 -R 200 http://localhost:3000/api/orders

# Stop the server; clinic opens the heap profile in a browser.
kill %1 2>/dev/null
wait
