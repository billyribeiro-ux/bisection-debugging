# After the bisector reports a culprit, confirm by ROLLING BACK ONLY that one
# service. If the bug disappears, it really is the culprit. If it doesn't,
# you have an interaction bug — fall back to delta debugging.
SVC="$1"
helm upgrade --install platform ./chart \
  --reuse-values \
  --set "$SVC.tag=$(grep -oE '[^:]+$' <<< "${OLD[$SVC]}")" \
  --wait
./run-e2e.sh && echo "CONFIRMED: $SVC was the sole cause" \
              || echo "INTERACTION — try delta-debugging the full bump set"
