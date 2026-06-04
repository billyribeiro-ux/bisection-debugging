C(p) = 1 − H₂(p)
     = 1 − [−p·log₂(p) − (1−p)·log₂(1−p)]

p = 0.00 → C = 1.000 bits/query   (perfect predicate)
p = 0.05 → C = 0.714 bits/query
p = 0.10 → C = 0.531 bits/query
p = 0.15 → C = 0.390 bits/query   (a "bad flake")
p = 0.25 → C = 0.189 bits/query
p = 0.50 → C = 0.000 bits/query   (no signal at all)

Minimum expected queries needed = log₂(N) / C(p).
