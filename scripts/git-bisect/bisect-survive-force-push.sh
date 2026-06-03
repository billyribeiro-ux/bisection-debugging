# Pin the bisection range to objects in your local object database so they
# can't be garbage-collected mid-bisection.
git update-ref refs/bisect-pin/bad   $(git rev-parse HEAD)
git update-ref refs/bisect-pin/good  v2.3

# Now if `origin/main` rotates under you, your pins survive.
# Reference them by the pin ref:
git bisect start refs/bisect-pin/bad refs/bisect-pin/good

# When done:
git update-ref -d refs/bisect-pin/bad
git update-ref -d refs/bisect-pin/good
