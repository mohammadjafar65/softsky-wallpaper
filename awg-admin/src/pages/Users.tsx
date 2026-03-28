import { useEffect, useState } from 'react';
import { Button, Pagination, Search, Select, SelectItem } from '@carbon/react';
import { Download, Edit, TrashCan } from '@carbon/icons-react';
import { usersApi } from '../services/api';
import { AdminPage, AdminPanel, EmptyState, StatusTag } from '../components/admin/AdminPage';
import EditUserModal from '../components/EditUserModal';

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
  const [planFilter, setPlanFilter] = useState('all');
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);

  useEffect(() => {
    void fetchUsers();
  }, [page, planFilter]);

  const fetchUsers = async () => {
    setIsLoading(true);
    try {
      const params: any = { page, limit: 10 };
      if (searchQuery) params.search = searchQuery;
      if (planFilter !== 'all') params.plan = planFilter;

      const response = await usersApi.getAll(params);
      setUsers(response.data.users || []);
      setTotalPages(response.data.pagination?.pages || 1);
    } catch (error) {
      console.error('Failed to fetch users:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleSearch = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setPage(1);
    await fetchUsers();
  };

  const handleDeleteUser = async (userId: string, userName: string) => {
    if (!window.confirm(`Are you sure you want to delete user "${userName}"? This action cannot be undone.`)) {
      return;
    }

    try {
      await usersApi.delete(userId);
      await fetchUsers();
    } catch (error: any) {
      console.error('Failed to delete user:', error);
      alert(error.response?.data?.error || 'Failed to delete user. Please try again.');
    }
  };

  const totalItems = Math.max(totalPages * 10, users.length || 0);

  return (
    <AdminPage
      title="Users"
      subtitle="Inspect account health, subscription status, messaging readiness, and high-value behaviors."
      actions={
        <Button kind="secondary" renderIcon={Download}>
          Export CSV
        </Button>
      }
    >
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
            onChange={(event) => setPlanFilter(event.target.value)}
          >
            <SelectItem value="all" text="All plans" />
            <SelectItem value="free" text="Free" />
            <SelectItem value="monthly" text="Monthly" />
            <SelectItem value="annual" text="Annual" />
            <SelectItem value="lifetime" text="Lifetime" />
          </Select>
        </div>
      </AdminPanel>

      <AdminPanel title="User directory" description="A Carbon-styled operational view of account and plan data.">
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
                        <td>{user.downloads}</td>
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
          void fetchUsers();
          setIsEditModalOpen(false);
        }}
      />
    </AdminPage>
  );
}
