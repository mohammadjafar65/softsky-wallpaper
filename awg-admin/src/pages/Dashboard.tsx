import { useEffect, useRef, useState } from 'react';
import { Button } from '@carbon/react';
import { Renew } from '@carbon/icons-react';
import { useNavigate } from 'react-router-dom';
import { categoriesApi, usersApi, wallpapersApi } from '../services/api';
import { AdminPage, AdminPanel, StatTile } from '../components/admin/AdminPage';

interface Stats {
  totalWallpapers: number;
  totalCategories: number;
  totalUsers: number;
  proUsers: number;
  totalWallpaperDownloads: number;
  newUsersThisMonth: number;
}

const AUTO_REFRESH_INTERVAL = 60_000;

export default function Dashboard() {
  const navigate = useNavigate();
  const [stats, setStats] = useState<Stats>({
    totalWallpapers: 0,
    totalCategories: 0,
    totalUsers: 0,
    proUsers: 0,
    totalWallpaperDownloads: 0,
    newUsersThisMonth: 0,
  });
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => {
    void fetchStats();

    intervalRef.current = setInterval(() => {
      void fetchStats(true);
    }, AUTO_REFRESH_INTERVAL);

    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, []);

  const fetchStats = async (silent = false) => {
    if (silent) {
      setIsRefreshing(true);
    } else {
      setIsLoading(true);
    }

    try {
      const [wallpapersResponse, categoriesResponse, usersResponse] = await Promise.all([
        wallpapersApi.getAll({ limit: 1 }),
        categoriesApi.getAll(),
        usersApi.getStats(),
      ]);

      setStats({
        totalWallpapers: wallpapersResponse.data.pagination?.total || 0,
        totalCategories: categoriesResponse.data.categories?.length || 0,
        totalUsers: usersResponse.data.totalUsers || 0,
        proUsers: usersResponse.data.proUsers || 0,
        totalWallpaperDownloads: usersResponse.data.totalWallpaperDownloads || 0,
        newUsersThisMonth: usersResponse.data.newUsersThisMonth || 0,
      });
      setLastUpdated(new Date());
    } catch (error) {
      console.error('Failed to fetch dashboard stats:', error);
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  };

  return (
    <AdminPage
      title="Admin dashboard"
      subtitle="High-signal operational metrics for content inventory, subscriptions, and user growth."
      actions={
        <Button kind="secondary" renderIcon={Renew} onClick={() => void fetchStats(true)}>
          {isRefreshing ? 'Refreshing...' : 'Refresh'}
        </Button>
      }
    >
      <div className="admin-grid admin-grid--stats">
        <StatTile label="Total wallpapers" value={stats.totalWallpapers.toLocaleString()} tone="blue" loading={isLoading} />
        <StatTile label="Categories" value={stats.totalCategories.toLocaleString()} tone="purple" loading={isLoading} />
        <StatTile label="Total users" value={stats.totalUsers.toLocaleString()} tone="green" loading={isLoading} />
        <StatTile label="Pro subscribers" value={stats.proUsers.toLocaleString()} tone="orange" loading={isLoading} />
        <StatTile label="Downloads" value={stats.totalWallpaperDownloads.toLocaleString()} tone="red" loading={isLoading} />
        <StatTile label="New this month" value={stats.newUsersThisMonth.toLocaleString()} tone="blue" loading={isLoading} />
      </div>

      <div className="admin-grid admin-grid--cards">
        <AdminPanel title="Quick actions" description="Jump directly into the highest-frequency admin workflows.">
          <div className="admin-grid">
            <Button kind="ghost" onClick={() => navigate('/wallpapers')}>Manage wallpapers</Button>
            <Button kind="ghost" onClick={() => navigate('/categories')}>Manage categories</Button>
            <Button kind="ghost" onClick={() => navigate('/users')}>Review users</Button>
          </div>
        </AdminPanel>

        <AdminPanel title="Live status" description="A compact operational summary for the current session.">
          <div className="admin-info-list">
            <div className="admin-info-row">
              <span>Refresh cadence</span>
              <span>Every 60 seconds</span>
            </div>
            <div className="admin-info-row">
              <span>Last synced</span>
              <span>{lastUpdated ? lastUpdated.toLocaleTimeString() : 'Waiting for first sync'}</span>
            </div>
            <div className="admin-info-row">
              <span>System state</span>
              <span>Operational</span>
            </div>
          </div>
        </AdminPanel>
      </div>
    </AdminPage>
  );
}
