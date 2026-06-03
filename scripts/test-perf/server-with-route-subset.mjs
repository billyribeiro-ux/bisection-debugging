// server-with-route-subset.mjs
// Boots the app but only mounts the routes listed in ROUTES env var.
//
// In your app code, separate route registration from server start:
//   export const allRoutes = [
//     { path: '/api/users',    handler: userRouter },
//     { path: '/api/products', handler: productRouter },
//     ...
//   ];
//
import { createServer } from 'http';
import express from 'express';
import { allRoutes } from './app.js';

const SUBSET = (process.env.ROUTES || '').split(',').filter(Boolean);
const routes = SUBSET.length
  ? allRoutes.filter(r => SUBSET.includes(r.path))
  : allRoutes;

const app = express();
for (const { path, handler } of routes) app.use(path, handler);
app.get('/__health', (_req, res) => res.json({ ok: true, routes: routes.map(r => r.path) }));

createServer(app).listen(3000, () => {
  console.log(`Listening with ${routes.length} routes: ${routes.map(r=>r.path).join(',')}`);
});
