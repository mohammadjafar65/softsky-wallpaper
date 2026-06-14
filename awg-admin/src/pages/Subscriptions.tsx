import { useEffect, useMemo, useState } from 'react';
import { Edit, RefreshCw } from 'lucide-react';
import toast from 'react-hot-toast';
import { usersApi } from '../services/api';
import { AdminPage, AdminPanel, EmptyState, StatTile, StatusTag } from '../components/admin/AdminPage';
import EditUserModal from '../components/EditUserModal';
import { Button } from '../components/ui/button';

interface Stats {
  totalUsers: number;
  proUsers: number;
  freeUsers: number;
  newUsersThisMonth: number;
  totalWallpaperDownloads: number;
  subscriptionBreakdown: Record<string, number>;
}

interface User {
  id: string;
  email: string;
  displayName: string;
  subscription: { plan: string; expiryDate?: string };
  downloads: number;
  isActive: boolean;
  createdAt: string;
  hasFcmToken: boolean;
}

const planLabels: Record<string, string> = {
  free: 'Free',
  monthly: 'Monthly',
  annual: 'Annual',
  lifetime: 'Lifetime',
};

export default function Subscriptions() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [subscribers, setSubscribers] = useState<User[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);

  const loadSubscriptionData = async (refreshing = false) => {
    if (refreshing) {
      setIsRefreshing(true);
    } else {
      setIsLoading(true);
    }

    try {
      const [statsResponse, monthlyResponse, annualResponse, lifetimeResponse] = await Promise.all([
        usersApi.getStats(),
        usersApi.getAll({ page: 1, limit: 100, plan: 'monthly' }),
        usersApi.getAll({ page: 1, limit: 100, plan: 'annual' }),
        usersApi.getAll({ page: 1, limit: 100, plan: 'lifetime' }),
      ]);

      setStats(statsResponse.data);
      setSubscribers([
        ...(monthlyResponse.data.users || []),
        ...(annualResponse.data.users || []),
        ...(lifetimeResponse.data.users || []),
      ]);
    } catch (error) {
      console.error('Failed to fetch subscription data:', error);
      toast.error('Failed to load subscription data');
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  };

  useEffect(() => {
    void loadSubscriptionData();
  }, []);

  const totalUsers = stats?.totalUsers || 0;
  const paidRate = totalUsers && stats ? Math.round((stats.proUsers / totalUsers) * 100) : 0;

  const sortedBreakdown = useMemo(
    () =>
      Object.entries(stats?.subscriptionBreakdown || {}).sort(([left], [right]) => {
        const order = ['free', 'monthly', 'annual', 'lifetime'];
        return order.indexOf(left) - order.indexOf(right);
      }),
    [stats]
  );

  return (
    <AdminPage
      title="Subscriptions"
      subtitle="Monitor plan health, premium adoption, and subscriber accounts from one CMS workspace."
      actions={
        <Button variant="secondary" size="sm" disabled={isRefreshing} onClick={() => void loadSubscriptionData(true)}>
          <RefreshCw size={13} className={isRefreshing ? 'admin-icon-spin' : ''} />
          {isRefreshing ? 'Refreshing…' : 'Refresh'}
        </Button>
      }
    >
      <div className="admin-grid admin-grid--stats">
        <StatTile label="Total users" value={(stats?.totalUsers || 0).toLocaleString()} helper="Install base accounts" tone="blue" loading={isLoading} />
        <StatTile label="Pro subscribers" value={(stats?.proUsers || 0).toLocaleString()} helper={`${paidRate}% premium adoption`} tone="orange" loading={isLoading} />
        <StatTile label="Free users" value={(stats?.freeUsers || 0).toLocaleString()} helper="Non-paying accounts" tone="purple" loading={isLoading} />
        <StatTile label="New this month" value={(stats?.newUsersThisMonth || 0).toLocaleString()} helper="Current month growth" tone="green" loading={isLoading} />
        <StatTile label="Downloads" value={(stats?.totalWallpaperDownloads || 0).toLocaleString()} helper="Wallpaper engagement" tone="red" loading={isLoading} />
      </div>

      <div className="admin-grid admin-grid--cards">
        <AdminPanel title="Plan distribution" description="Active plan composition with expired plans folded into Free.">
          {isLoading ? (
            <p style={{ color: 'var(--admin-text-muted)', padding: '16px 0' }}>Loading subscription distribution…</p>
          ) : sortedBreakdown.length === 0 ? (
            <EmptyState title="No subscription data" message="Stats will appear here once users and plans are synced." />
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              {sortedBreakdown.map(([plan, count]) => {
                const percentage = totalUsers ? Math.round((count / totalUsers) * 100) : 0;
                return (
                  <div key={plan} className="admin-callout">
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6, fontSize: 13 }}>
                      <span>{planLabels[plan] || plan}</span>
                      <strong>{count.toLocaleString()} users</strong>
                    </div>
                    <div className="admin-progress-track">
                      <div className="admin-progress-bar" style={{ width: `${percentage}%` }} />
                    </div>
                    <p style={{ margin: '4px 0 0', fontSize: 11, color: 'var(--admin-text-muted)' }}>{percentage}% of current users</p>
                  </div>
                );
              })}
            </div>
          )}
        </AdminPanel>

        <AdminPanel title="Subscriber roster" description="Edit premium plans without leaving subscription operations.">
          {isLoading ? (
            <p style={{ color: 'var(--admin-text-muted)', padding: '16px 0' }}>Loading subscribers…</p>
          ) : subscribers.length === 0 ? (
            <EmptyState title="No active subscribers" message="Paid users will appear here after a plan is assigned or verified." />
          ) : (
            <div style={{ overflowX: 'auto' }}>
              <table className="admin-table">
                <thead>
                  <tr>
                    <th>User</th>
                    <th>Plan</th>
                    <th>Expiry</th>
                    <th>Downloads</th>
                    <th>Status</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {subscribers.map((user) => {
                    const expiry = user.subscription.expiryDate ? new Date(user.subscription.expiryDate) : null;
                    const isExpired = Boolean(expiry && expiry < new Date() && user.subscription.plan !== 'lifetime');
                    return (
                      <tr key={user.id}>
                        <td>
                          <strong style={{ fontSize: 13, display: 'block' }}>{user.displayName || 'Unnamed user'}</strong>
                          <div style={{ fontSize: 11, color: 'var(--admin-text-sub)', marginTop: 2 }}>{user.email}</div>
                        </td>
                        <td>
                          <StatusTag type={isExpired ? 'red' : 'green'}>
                            {planLabels[user.subscription.plan] || user.subscription.plan}
                          </StatusTag>
                        </td>
                        <td>{user.subscription.plan === 'lifetime' ? 'Lifetime' : expiry ? expiry.toLocaleDateString() : 'Not set'}</td>
                        <td>{(user.downloads || 0).toLocaleString()}</td>
                        <td>
                          <StatusTag type={user.isActive && !isExpired ? 'green' : 'cool-gray'}>
                            {isExpired ? 'Expired' : user.isActive ? 'Active' : 'Inactive'}
                          </StatusTag>
                        </td>
                        <td>
                          <button className="admin-round-button" title="Edit subscription" onClick={() => { setSelectedUser(user); setIsEditModalOpen(true); }}>
                            <Edit size={13} />
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </AdminPanel>
      </div>

      <EditUserModal
        isOpen={isEditModalOpen}
        onClose={() => setIsEditModalOpen(false)}
        user={selectedUser}
        onSuccess={() => { setIsEditModalOpen(false); void loadSubscriptionData(true); }}
      />
    </AdminPage>
  );
}
