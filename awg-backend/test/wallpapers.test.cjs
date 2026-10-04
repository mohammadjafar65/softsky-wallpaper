const { test } = require('node:test');
const assert = require('node:assert/strict');
process.env.JWT_SECRET = 'wallpaper-route-tests-only-secret';
const { AppDataSource } = require('../dist/data-source');
const router = require('../dist/routes/wallpapers').default;

async function request(query) {
  const calls = [];
  const builder = {};
  for (const name of ['leftJoinAndSelect', 'andWhere', 'where', 'orWhere',
    'orderBy', 'addOrderBy', 'skip', 'take']) {
    builder[name] = (...args) => { calls.push([name, ...args]); return builder; };
  }
  builder.getCount = async () => 0;
  builder.getMany = async () => [];
  const original = AppDataSource.getRepository;
  AppDataSource.getRepository = () => ({
    createQueryBuilder: () => builder,
    findOne: async () => null,
  });
  let response;
  try {
    const route = router.stack.find(layer => layer.route?.path === '/').route;
    await route.stack.at(-1).handle({ query }, {
      json: data => { response = data; },
      status: () => ({ json: data => { throw new Error(JSON.stringify(data)); } }),
    });
    return { calls, response };
  } finally {
    AppDataSource.getRepository = original;
  }
}

test('unknown category stays constrained instead of returning the entire catalog', async () => {
  const { calls } = await request({ category: 'not-a-category' });
  assert.ok(calls.some(([name, sql, params]) => name === 'andWhere'
    && sql.includes('category.slug') && params.category === 'not-a-category'));
});

test('numeric categories used by automatic wallpapers are filtered by ID', async () => {
  const { calls } = await request({ category: '7' });
  assert.ok(calls.some(([name, sql, params]) => name === 'andWhere'
    && sql.includes('wallpaper.categoryId') && params.categoryId === 7));
});

test('negative pagination never sends negative offsets or limits to MySQL', async () => {
  const { response, calls } = await request({ page: '-4', limit: '-3' });
  assert.equal(response.pagination.page, 1);
  assert.equal(response.pagination.limit, 20);
  assert.ok(calls.some(([name, value]) => name === 'skip' && value === 0));
});

test('large limits are bounded and pages have a stable tie breaker', async () => {
  const { response, calls } = await request({ limit: '10000' });
  assert.equal(response.pagination.limit, 100);
  assert.ok(calls.some(([name, column, direction]) => name === 'addOrderBy'
    && column === 'wallpaper.id' && direction === 'DESC'));
});
