# Extract every package whose version differs between two lockfile commits.
git show HEAD~1:pnpm-lock.yaml > /tmp/lock.old
git show HEAD:pnpm-lock.yaml   > /tmp/lock.new

node -e '
  const yaml = require("yaml");
  const fs = require("fs");
  const old = yaml.parse(fs.readFileSync("/tmp/lock.old", "utf8")).packages || {};
  const neu = yaml.parse(fs.readFileSync("/tmp/lock.new", "utf8")).packages || {};
  const bumps = [];
  // Lockfile key shapes differ by version:
  //   v6 (pnpm 8):  /react@18.3.1   or  /vite@5.0.0(@types/node@20.1.0)
  //   v9 (pnpm 9+): react@18.3.1    (no leading slash; same peer suffix)
  // Strip the optional slash and the (peer…) suffix in one regex.
  const parse = (k) => k.match(/^\/?(.+?)@([^()/]+)/);
  for (const k of Object.keys(neu)) {
    if (old[k]) continue;
    const m = parse(k);
    if (!m) continue;
    const [, name, version] = m;
    const oldKey = Object.keys(old).find(o => {
      const om = parse(o);
      return om && om[1] === name;
    });
    if (!oldKey) continue;
    const oldV = parse(oldKey)[2];
    if (oldV !== version) bumps.push({ name, old: oldV, new: version });
  }
  process.stdout.write(JSON.stringify(bumps, null, 2));
' > bumps-transitive.json
