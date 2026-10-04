const { test } = require('node:test');
const assert = require('node:assert/strict');
process.env.JWT_SECRET = 'community-tests-only-secret';
const { AppDataSource } = require('../dist/data-source');
const { CommunityPost } = require('../dist/entities/CommunityPost');
const router = require('../dist/routes/community').default;

async function trending(user, query = {}) {
  const rows = [
    { id: 1, isApproved: true, likesCount: 3, createdAt: new Date('2020-01-01'), imageUrl: 'https://example.com/1.jpg' },
    { id: 2, isApproved: true, likesCount: 7, createdAt: new Date('2020-01-01'), imageUrl: 'https://example.com/2.jpg' },
    { id: 3, isApproved: false, likesCount: 99, createdAt: new Date(), imageUrl: 'https://example.com/3.jpg' },
  ];
  let filtered = rows;
  let offset = 0;
  let limit = 20;
  const orders = [];
  const builder = {
    leftJoinAndSelect() { return this; },
    where(sql, params) {
      if (sql.includes('isApproved')) filtered = filtered.filter(p => p.isApproved);
      if (params?.since) filtered = filtered.filter(p => p.createdAt >= params.since);
      return this;
    },
    orderBy(column) { orders.push(column.split('.').at(-1)); return this; },
    addOrderBy(column) { orders.push(column.split('.').at(-1)); return this; },
    skip(value) { offset = value; return this; },
    take(value) { limit = value; return this; },
    async getMany() {
      return filtered.sort((a, b) => {
        for (const key of orders) { const diff = b[key] - a[key]; if (diff) return diff; }
        return 0;
      }).slice(offset, offset + limit);
    },
  };
  const original = AppDataSource.getRepository;
  AppDataSource.getRepository = entity => entity === CommunityPost ? {
    count: async () => rows.filter(p => p.isApproved).length,
    createQueryBuilder: () => builder,
  } : { findOne: async () => null };
  let response;
  try {
    const route = router.stack.find(layer => layer.route?.path === '/trending').route;
    const req = { query, headers: {}, user };
    let continued = false;
    await route.stack[0].handle(req, {}, () => { continued = true; });
    assert.equal(continued, true, 'trending must permit guests');
    await route.stack.at(-1).handle(req, {
      json: data => { response = data; },
      status: () => ({ json: data => { throw new Error(JSON.stringify(data)); } }),
    });
    return response;
  } finally {
    AppDataSource.getRepository = original;
  }
}

test('guests see older approved wallpapers ranked by popularity', async () => {
  const data = await trending();
  assert.deepEqual(data.posts.map(p => p.id), [2, 1]);
  assert.equal(data.totalCount, 2);
  assert.equal(data.hasMore, false);
});

test('signed-in viewers receive the same approved trending catalog', async () => {
  const data = await trending({ id: '42' });
  assert.deepEqual(data.posts.map(p => p.id), [2, 1]);
  assert.ok(data.posts.every(p => p.isApproved));
});

test('older wallpapers remain reachable on later trending pages', async () => {
  const data = await trending(undefined, { page: '2', limit: '1' });
  assert.deepEqual(data.posts.map(p => p.id), [1]);
});
