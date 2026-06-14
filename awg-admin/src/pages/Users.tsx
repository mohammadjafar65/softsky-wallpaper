import { useEffect, useMemo, useState } from 'react';
import { Download, Edit, Search, Trash2 } from 'lucide-react';
import toast from 'react-hot-toast';
import axios from 'axios';
import { usersApi } from '../services/api';
import { AdminPage, AdminPanel, EmptyState, StatTile, StatusTag } from '../components/admin/AdminPage';
import EditUserModal from '../components/EditUserModal';
import { Button } from '../components/ui/button';

interface User {
  id: string;
  email: string;
  displayName: string;
  photoUrl?: string;
  authProvider: string;
  subscription: { plan: string; expiryDate?: string };
  downloads: number;
  isActive: boolean;
  createdAt: string;
  hasFcmToken: boolean;
}

export default function Users() {
  const [users, setUsers] = useState<User[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalUsers, setTotalUsers] = useState(0);
  const [planFilter, setPlanFilter] = useState('all');
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);

  useEffect(() => {
    void fetchUsers({ pageNumber: page });
  }, [page, planFilter]);

  const visibleStats = useMemo(() => {
    const active = users.filter((user) => user.isActive).length;
    const paid = users.filter((user) => user.subscription?.plan && user.subscription.plan !== 'free').length;
    const pushReady = users.filter((user) => user.hasFcmToken).length;
    const downloads = users.reduce((sum, user) => sum + (user.downloads || 0), 0);

    return { active, paid, pushReady, downloads };
  }, [users]);

  const fetchUsers = async ({ pageNumber = page, search = searchQuery } = {}) => {
    setIsLoading(true);
    try {
      const params: { page: number; limit: number; search?: string; plan?: string } = { page: pageNumber, limit: 10 };
      if (search.trim()) params.search = search.trim();
      if (planFilter !== 'all') params.plan = planFilter;

      const response = await usersApi.getAll(params);
      setUsers(response.data.users || []);
      setTotalPages(response.data.pagination?.pages || 1);
      setTotalUsers(response.data.pagination?.total || response.data.total || response.data.users?.length || 0);
    } catch (error) {
      console.error('Failed to fetch users:', error);
      toast.error('Failed to load users');
    } finally {
      setIsLoading(false);
    }
  };

  const handleSearch = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setPage(1);
    await fetchUsers({ pageNumber: 1 });
  };

  const handleExportCsv = async () => {
    try {
      const response = await usersApi.getAll({
        page: 1,
        limit: Math.max(totalUsers, users.length, 1000),
        search: searchQuery.trim() || undefined,
        plan: planFilter !== 'all' ? planFilter : undefined,
      });
      const exportUsers: User[] = response.data.users || users;
      const rows = [
        ['Name', 'Email', 'Provider', 'Plan', 'Downloads', 'Push Ready', 'Joined'],
        ...exportUsers.map((user) => [
          user.displayName,
          user.email,
          user.authProvider,
          user.subscription?.plan || 'free',
          String(user.downloads ?? 0),
          user.hasFcmToken ? 'yes' : 'no',
          user.createdAt ? new Date(user.createdAt).toISOString() : '',
        ]),
      ];
      const csv = rows
        .map((row) => row.map((value) => `"${String(value).replaceAll('"', '""')}"`).join(','))
        .join('\n');
      const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `softsky-users-${new Date().toISOString().slice(0, 10)}.csv`;
      link.click();
      URL.revokeObjectURL(url);
      toast.success(`Exported ${exportUsers.length} users`);
    } catch (error) {
      console.error('Failed to export users:', error);
      toast.error('Failed to export users');
    }
  };

  const handleDeleteUser = async (userId: string, userName: string) => {
    if (!window.confirm(`Are you sure you want to delete user "${userName}"? This action cannot be undone.`)) {
      return;
    }

    try {
      await usersApi.delete(userId);
      await fetchUsers();
      toast.success('User deleted');
    } catch (error: unknown) {
      console.error('Failed to delete user:', error);
      const message = axios.isAxiosError<{ error?: string }>(error)
        ? error.response?.data?.error
        : undefined;
      toast.error(message || 'Failed to delete user. Please try again.');
    }
  };

  return (
    <AdminPage
      title="Users"
      subtitle="Inspect account health, subscription status, messaging readiness, and high-value behaviors."
      actions={
        <Button variant="secondary" size="sm" onClick={() => void handleExportCsv()}>
          <Download size={14} /> Export CSV
        </Button>
      }
    >
      <div className="admin-grid admin-grid--stats">
        <StatTile label="Total users" value={totalUsers.toLocaleString()} helper="All matching accounts" tone="blue" loading={isLoading} />
        <StatTile label="Visible active" value={visibleStats.active.toLocaleString()} helper="Active on this page" tone="green" loading={isLoading} />
        <StatTile label="Paid visible" value={visibleStats.paid.toLocaleString()} helper="Non-free plans here" tone="orange" loading={isLoading} />
        <StatTile label="Push ready" value={visibleStats.pushReady.toLocaleString()} helper="Can receive campaigns" tone="purple" loading={isLoading} />
        <StatTile label="Downloads" value={visibleStats.downloads.toLocaleString()} helper="Visible user total" tone="red" loading={isLoading} />
      </div>

      <AdminPanel title="Filters" description="Search across your customer base and narrow by subscription plan.">
        <div className="admin-form-grid">
          <form onSubmit={(e) => void handleSearch(e)}>
            <div className="afield">
              <label className="afield__label">Search users</label>
              <div style={{ position: 'relative' }}>
                <Search size={13} style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', color: 'var(--admin-text-sub)' }} />
                <input className="afield__input" style={{ paddingLeft: 32 }} placeholder="Search by name or email" value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} />
              </div>
            </div>
          </form>
          <div className="afield">
            <label className="afield__label">Plan</label>
            <select className="afield__select" value={planFilter} onChange={(e) => { setPlanFilter(e.target.value); setPage(1); }}>
              <option value="all">All plans</option>
              <option value="free">Free</option>
              <option value="monthly">Monthly</option>
              <option value="annual">Annual</option>
              <option value="lifetime">Lifetime</option>
            </select>
          </div>
        </div>
      </AdminPanel>

      <AdminPanel title="User directory" description="An operational view of account and plan data.">
        {isLoading ? (
          <p style={{ color: 'var(--admin-text-muted)', padding: '16px 0' }}>Loading users…</p>
        ) : users.length === 0 ? (
          <EmptyState title="No users found" message="Adjust the filters or search query to broaden the result set." />
        ) : (
          <div className="admin-grid">
            <div style={{ overflowX: 'auto' }}>
              <table className="admin-table">
                <thead>
                  <tr>
                    <th>User</th>
                    <th>Provider</th>
                    <th>Plan</th>
                    <th>Push</th>
                    <th>Downloads</th>
                    <th>Joined</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {users.map((user) => {
                    const isExpired = user.subscription.expiryDate && new Date(user.subscription.expiryDate) < new Date() && user.subscription.plan !== 'lifetime';
                    return (
                      <tr key={user.id}>
                        <td>
                          <strong style={{ display: 'block', fontSize: 13 }}>{user.displayName}</strong>
                          <div style={{ fontSize: 11, color: 'var(--admin-text-sub)', marginTop: 2 }}>{user.email}</div>
                        </td>
                        <td style={{ textTransform: 'capitalize' }}>{user.authProvider}</td>
                        <td>
                          <StatusTag type={user.subscription.plan === 'free' || isExpired ? 'cool-gray' : 'green'}>
                            {isExpired ? `${user.subscription.plan} expired` : user.subscription.plan}
                          </StatusTag>
                        </td>
                        <td>
                          <StatusTag type={user.hasFcmToken ? 'green' : 'cool-gray'}>
                            {user.hasFcmToken ? 'Ready' : 'Missing token'}
                          </StatusTag>
                        </td>
                        <td>{(user.downloads || 0).toLocaleString()}</td>
                        <td>{new Date(user.createdAt).toLocaleDateString()}</td>
                        <td>
                          <div className="admin-inline-actions">
                            <button className="admin-round-button" title="Edit user" onClick={() => { setSelectedUser(user); setIsEditModalOpen(true); }}>
                              <Edit size={13} />
                            </button>
                            <button className="admin-round-button" title="Delete user" style={{ color: 'var(--admin-red)' }} onClick={() => void handleDeleteUser(user.id, user.displayName)}>
                              <Trash2 size={13} />
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>

            {totalPages > 1 ? (
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '4px 0', fontSize: 13 }}>
                <Button variant="secondary" size="sm" disabled={page <= 1} onClick={() => setPage((p) => p - 1)}>← Previous</Button>
                <span style={{ color: 'var(--admin-text-muted)' }}>Page {page} of {totalPages}</span>
                <Button variant="secondary" size="sm" disabled={page >= totalPages} onClick={() => setPage((p) => p + 1)}>Next →</Button>
              </div>
            ) : null}
          </div>
        )}
      </AdminPanel>

      <EditUserModal
        isOpen={isEditModalOpen}
        onClose={() => setIsEditModalOpen(false)}
        user={selectedUser}
        onSuccess={() => { void fetchUsers({ pageNumber: page }); setIsEditModalOpen(false); }}
      />
    </AdminPage>
  );
}
      <div className="admin-grid admin-grid--stats">
        <StatTile label="Total users" value={totalUsers.toLocaleString()} helper="All matching accounts" tone="blue" loading={isLoading} />
        <StatTile label="Visible active" value={visibleStats.active.toLocaleString()} helper="Active on this page" tone="green" loading={isLoading} />
        <StatTile label="Paid visible" value={visibleStats.paid.toLocaleString()} helper="Non-free plans here" tone="orange" loading={isLoading} />
        <StatTile label="Push ready" value={visibleStats.pushReady.toLocaleString()} helper="Can receive campaigns" tone="purple" loading={isLoading} />
        <StatTile label="Downloads" value={visibleStats.downloads.toLocaleString()} helper="Visible user total" tone="red" loading={isLoading} />
      </div>

      <AdminPanel title="Filters" description="Search across your customer base and narrow by subscription plan.">
        <div className="admin-form-grid">
          <form onSubmit={(event) => void handleSearch(event)}>
            <Search
              id="user-search"
              labelText="Search users"
              placeholder="Search by name or email"
              value={searchQuery}
              onChange={(event) => setSearchQuery(event.target.value)}
            />
          </form>

          <Select
            id="plan-filter"
            labelText="Plan"
            value={planFilter}
            onChange={(event) => {
              setPlanFilter(event.target.value);
              setPage(1);
            }}
          >
            <SelectItem value="all" text="All plans" />
            <SelectItem value="free" text="Free" />
            <SelectItem value="monthly" text="Monthly" />
            <SelectItem value="annual" text="Annual" />
            <SelectItem value="lifetime" text="Lifetime" />
          </Select>
        </div>
      </AdminPanel>

      <AdminPanel title="User directory" description="An operational view of account and plan data.">
        {isLoading ? (
          <p>Loading users...</p>
        ) : users.length === 0 ? (
          <EmptyState
            title="No users found"
            message="Adjust the filters or search query to broaden the result set."
          />
        ) : (
          <div className="admin-grid">
            <div style={{ overflowX: 'auto' }}>
              <table className="admin-table">
                <thead>
                  <tr>
                    <th>User</th>
                    <th>Provider</th>
                    <th>Plan</th>
                    <th>Push</th>
                    <th>Downloads</th>
                    <th>Joined</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {users.map((user) => {
                    const isExpired =
                      user.subscription.expiryDate &&
                      new Date(user.subscription.expiryDate) < new Date() &&
                      user.subscription.plan !== 'lifetime';

                    return (
                      <tr key={user.id}>
                        <td>
                          <div>
                            <strong>{user.displayName}</strong>
                            <div className="admin-authors">{user.email}</div>
                          </div>
                        </td>
                        <td style={{ textTransform: 'capitalize' }}>{user.authProvider}</td>
                        <td>
                          <StatusTag
                            type={
                              user.subscription.plan === 'free' || isExpired
                                ? 'cool-gray'
                                : 'green'
                            }
                          >
                            {isExpired ? `${user.subscription.plan} expired` : user.subscription.plan}
                          </StatusTag>
                        </td>
                        <td>
                          <StatusTag type={user.hasFcmToken ? 'green' : 'cool-gray'}>
                            {user.hasFcmToken ? 'Ready' : 'Missing token'}
                          </StatusTag>
                        </td>
                        <td>{(user.downloads || 0).toLocaleString()}</td>
                        <td>{new Date(user.createdAt).toLocaleDateString()}</td>
                        <td>
                          <div className="admin-inline-actions">
                            <Button
                              kind="ghost"
                              size="sm"
                              renderIcon={Edit}
                              iconDescription="Edit user"
                              hasIconOnly
                              onClick={() => {
                                setSelectedUser(user);
                                setIsEditModalOpen(true);
                              }}
                            />
                            <Button
                              kind="ghost"
                              size="sm"
                              renderIcon={TrashCan}
                              iconDescription="Delete user"
                              hasIconOnly
                              onClick={() => void handleDeleteUser(user.id, user.displayName)}
                            />
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>

            {totalPages > 1 ? (
              <Pagination
                backwardText="Previous page"
                forwardText="Next page"
                itemsPerPageText="Rows per page"
                page={page}
                pageSize={10}
                pageSizes={[10]}
                totalItems={totalItems}
                onChange={({ page }) => setPage(page)}
              />
            ) : null}
          </div>
        )}
      </AdminPanel>

      <EditUserModal
        isOpen={isEditModalOpen}
        onClose={() => setIsEditModalOpen(false)}
        user={selectedUser}
        onSuccess={() => {
          void fetchUsers({ pageNumber: page });
          setIsEditModalOpen(false);
        }}
      />
    </AdminPage>
  );
}
