# $RANDOM uses a weak LCG and is predictable. $SRANDOM (bash 5.1+) draws
# from the OS entropy pool — useful for randomized test inputs that you
# want truly randomized between bisection rounds.
PORT=$((SRANDOM % 30000 + 30000))   # 30000-59999
echo "random port: $PORT"
