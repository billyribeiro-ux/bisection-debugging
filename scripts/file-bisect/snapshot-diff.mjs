async function takeSnapshot(label) {
  let chunks = '';
  const handler = ({ chunk }) => { chunks += chunk; };
  cdp.on('HeapProfiler.addHeapSnapshotChunk', handler);
  await cdp.send('HeapProfiler.takeHeapSnapshot', { reportProgress: false });
  cdp.off('HeapProfiler.addHeapSnapshotChunk', handler);
  await import('fs').then(fs => fs.writeFileSync(`heap-${label}.heapsnapshot`, chunks));
  return chunks.length; // returned size is a quick monotonic proxy
}
// Open both .heapsnapshot files in Chrome DevTools → Memory → "Comparison" view.
