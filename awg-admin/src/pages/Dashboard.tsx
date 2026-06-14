import { useEffect, useRef, useState } from 'react';
import { Activity, ArrowRight, FolderOpen, Images, RefreshCw, Sparkles, Users } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { categoriesApi, healthApi, usersApi, wallpapersApi } from '../services/api';
import { AdminPage, AdminPanel, StatTile, StatusTag } from '../components/admin/AdminPage';
import { Button } from '../components/ui/button';

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
  const [healthState, setHealthState] = useState<'Checking' | 'Connected' | 'Degraded'>('Checking');
  const [healthMessage, setHealthMessage] = useState('Checking backend connection');
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

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
      setHealthState('Connected');
      setHealthMessage('Wallpaper server is reachable and responding.');
    } catch (error) {
      console.error('Failed to fetch dashboard stats:', error);
      setHealthState('Degraded');
      setHealthMessage('Stats could not be refreshed. Check the API URL or server status.');
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  };

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

  useEffect(() => {
    const checkHealth = async () => {
      try {
        const response = await healthApi.get();
        const isConnected = response.data?.database?.connected !== false;
        setHealthState(isConnected ? 'Connected' : 'Degraded');
        setHealthMessage(
          isConnected
            ? 'Backend and database are available for admin operations.'
            : 'API is up, but the database connection needs attention.'
        );
      } catch (error) {
        console.error('Failed to fetch health status:', error);
        setHealthState('Degraded');
        setHealthMessage('Health endpoint is unavailable right now.');
      }
    };

    void checkHealth();
  }, []);

  const inventoryDensity = stats.totalCategories
    ? Math.round(stats.totalWallpapers / stats.totalCategories)
    : 0;
  const premiumMix = stats.totalUsers ? Math.round((stats.proUsers / stats.totalUsers) * 100) : 0;

  return (
    <AdminPage
      title="Wallpaper command center"
      subtitle="A focused control surface for content inventory, subscribers, downloads, and backend readiness."
      actions={
        <Button variant="secondary" onClick={() => void fetchStats(true)} disabled={isRefreshing}>
          <RefreshCw className={isRefreshing ? 'admin-icon-spin' : ''} size={16} />
          {isRefreshing ? 'Refreshing...' : 'Refresh'}
        </Button>
      }
    >
      <div className="admin-grid admin-grid--stats">
        <StatTile label="Total wallpapers" value={stats.totalWallpapers.toLocaleString()} helper="Published inventory" tone="blue" loading={isLoading} />
        <StatTile label="Categories" value={stats.totalCategories.toLocaleString()} helper="Active content groups" tone="purple" loading={isLoading} />
        <StatTile label="Total users" value={stats.totalUsers.toLocaleString()} helper="Known accounts" tone="green" loading={isLoading} />
        <StatTile label="Pro subscribers" value={stats.proUsers.toLocaleString()} helper="Premium access" tone="orange" loading={isLoading} />
        <StatTile label="Downloads" value={stats.totalWallpaperDownloads.toLocaleString()} helper="Lifetime saves" tone="red" loading={isLoading} />
        <StatTile label="New this month" value={stats.newUsersThisMonth.toLocaleString()} helper="Fresh signups" tone="blue" loading={isLoading} />
      </div>

      <div className="admin-grid admin-grid--cards">
        <AdminPanel title="Quick actions" description="Jump into the workflows used most often by content operators.">
          <div className="admin-action-list">
            <button type="button" className="admin-action-card" onClick={() => navigate('/wallpapers')}>
              <Images size={18} />
              <span>
                <strong>Manage wallpapers</strong>
                <small>Upload, edit, promote, delete</small>
              </span>
              <ArrowRight size={16} />
            </button>
            <button type="button" className="admin-action-card" onClick={() => navigate('/categories')}>
              <FolderOpen size={18} />
              <span>
                <strong>Manage categories</strong>
                <small>Organize taxonomy and imports</small>
              </span>
              <ArrowRight size={16} />
            </button>
            <button type="button" className="admin-action-card" onClick={() => navigate('/users')}>
              <Users size={18} />
              <span>
                <strong>Review users</strong>
                <small>Plans, push state, downloads</small>
              </span>
              <ArrowRight size={16} />
            </button>
          </div>
        </AdminPanel>

        <AdminPanel title="Server connection" description="Live backend visibility for this admin app session.">
          <div className="admin-info-list">
            <div className="admin-info-row">
              <span>Backend</span>
              <span>
                <StatusTag type={healthState === 'Connected' ? 'green' : healthState === 'Degraded' ? 'red' : 'cool-gray'}>
                  {healthState}
                </StatusTag>
              </span>
            </div>
            <div className="admin-info-row">
              <span>Health note</span>
              <span>{healthMessage}</span>
            </div>
            <div className="admin-info-row">
              <span>Last synced</span>
              <span>{lastUpdated ? lastUpdated.toLocaleTimeString() : 'Waiting for first sync'}</span>
            </div>
            <div className="admin-info-row">
              <span>Refresh cadence</span>
              <span>Every 60 seconds</span>
            </div>
          </div>
        </AdminPanel>

        <AdminPanel title="Operating posture" description="Fast signals for what needs attention next.">
          <div className="admin-action-list">
            <div className="admin-signal-row">
              <Activity size={18} />
              <span>Inventory density</span>
              <strong>{inventoryDensity} per category</strong>
            </div>
            <div className="admin-signal-row">
              <Sparkles size={18} />
              <span>Premium mix</span>
              <strong>{premiumMix}% pro</strong>
            </div>
          </div>
        </AdminPanel>
      </div>
    </AdminPage>
  );
}
