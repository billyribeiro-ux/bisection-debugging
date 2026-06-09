export GOFLAGS=-mod=readonly   # never let the toolchain rewrite go.mod mid-bisect
go test ./... >/dev/null 2>&1
