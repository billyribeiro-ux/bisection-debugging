dotnet restore --locked-mode --use-lock-file 2>&1 || exit 125
dotnet test --no-restore
