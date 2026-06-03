# Extract every package whose version differs between two lockfile commits.
git show HEAD~1:pnpm-lock.yaml > /tmp/lock.old
git show HEAD:pnpm-lock.yaml   > /tmp/lock.new

node -e '
  const yaml = require("yaml");
  const fs = require("fs");
  const old = yaml.parse(fs.readFileSync("/tmp/lock.old", "utf8")).packages || {};
  const neu = yaml.parse(fs.readFileSync("/tmp/lock.new", "utf8")).packages || {};
  const bumps = [];
  for (const k of Object.keys(neu)) {
    if (old[k]) continue;
    // pnpm lock keys look like /react@18.3.1
    const m = k.match(/^\/(.+)@([^\/]+)/);
    if (!m) continue;
    const [, name, version] = m;
    const oldKey = Object.keys(old).find(o => o.startsWith("/" + name + "@"));
    if (!oldKey) continue;
    const oldV = oldKey.match(/@([^\/]+)$/)[1];
    if (oldV !== version) bumps.push({ name, old: oldV, new: version });
  }
  process.stdout.write(JSON.stringify(bumps, null, 2));
' > bumps-transitive.json
