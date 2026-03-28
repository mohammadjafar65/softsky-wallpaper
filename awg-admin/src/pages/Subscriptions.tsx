import { useEffect, useState } from 'react';
import { usersApi } from '../services/api';
import { AdminPage, AdminPanel, EmptyState, StatTile } from '../components/admin/AdminPage';

interface Stats {
  totalUsers: number;
  proUsers: number;
  freeUsers: number;
  newUsersThisMonth: number;
  totalWallpaperDownloads: number;
  subscriptionBreakdown: Record<string, number>;
}

export default function Subscriptions() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    void fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      const response = await usersApi.getStats();
      setStats(response.data);
    } catch (error) {
      console.error('Failed to fetch stats:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const totalUsers = stats?.totalUsers || 0;

  return (
    <AdminPage
      title="Subscriptions"
      subtitle="Track plan distribution, premium adoption, and growth signals across the installed base."
    >
      <div className="admin-grid admin-grid--stats">
        <StatTile label="Total users" value={stats?.totalUsers || 0} tone="blue" loading={isLoading} />
        <StatTile label="Pro subscribers" value={stats?.proUsers || 0} tone="orange" loading={isLoading} />
        <StatTile label="Free users" value={stats?.freeUsers || 0} tone="purple" loading={isLoading} />
        <StatTile label="New this month" value={stats?.newUsersThisMonth || 0} tone="green" loading={isLoading} />
        <StatTile label="Downloads" value={stats?.totalWallpaperDownloads || 0} tone="red" loading={isLoading} />
      </div>

      <AdminPanel title="Plan distribution" description="A compact breakdown of active users by subscription plan.">
        {isLoading ? (
          <p>Loading subscription distribution...</p>
        ) : Object.keys(stats?.subscriptionBreakdown || {}).length === 0 ? (
          <EmptyState title="No subscription data" message="Stats will appear here once users and plans are synced." />
        ) : (
          <div className="admin-grid">
            {Object.entries(stats?.subscriptionBreakdown || {}).map(([plan, count]) => {
              const percentage = totalUsers ? Math.round((count / totalUsers) * 100) : 0;

              return (
                <div key={plan} className="admin-panel">
                  <div className="admin-info-row">
                    <span style={{ textTransform: 'capitalize' }}>{plan}</span>
                    <span>{count} users</span>
                  </div>
                  <div
                    style={{
                      width: '100%',
                      height: '0.75rem',
                      background: 'rgba(255,255,255,0.08)',
                      marginTop: '1rem',
                    }}
                  >
                    <div
                      style={{
                        width: `${percentage}%`,
                        height: '100%',
                        background: 'linear-gradient(90deg, #4589ff, #a56eff)',
                      }}
                    />
                  </div>
                  <p className="admin-authors" style={{ marginTop: '0.75rem' }}>
                    {percentage}% of current users
                  </p>
                </div>
              );
            })}
          </div>
        )}
      </AdminPanel>
    </AdminPage>
  );
}
