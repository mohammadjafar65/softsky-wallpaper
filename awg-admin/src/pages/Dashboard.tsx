import { useEffect, useRef, useState } from 'react';
import {
  ArrowRight,
  ExternalLink,
  FolderOpen,
  Images,
  Play,
  RefreshCw,
  Users,
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Line,
  LineChart,
  ReferenceLine,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
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

  // ── Synthetic chart data (replace with real API data when available) ──
  const barData = [
    { month: 'Jan', uploads: 38 },
    { month: 'Feb', uploads: 52 },
    { month: 'Mar', uploads: 61 },
    { month: 'Apr', uploads: 45, highlight: true },
    { month: 'May', uploads: 70 },
    { month: 'Jun', uploads: 55 },
  ];
  const avgUploads = Math.round(barData.reduce((s, d) => s + d.uploads, 0) / barData.length);

  const lineData = [
    { month: 'Jan', users: 12, pro: 2, downloads: 30, active: 8 },
    { month: 'Feb', users: 19, pro: 4, downloads: 48, active: 14 },
    { month: 'Mar', users: 28, pro: 7, downloads: 62, active: 20 },
    { month: 'Apr', users: 38, pro: 11, downloads: 89, active: 28 },
    { month: 'May', users: 51, pro: 16, downloads: 110, active: 37 },
    { month: 'Jun', users: stats.totalUsers > 0 ? stats.totalUsers : 64, pro: stats.proUsers > 0 ? stats.proUsers : 22, downloads: stats.totalWallpaperDownloads > 0 ? Math.min(stats.totalWallpaperDownloads, 999) : 140, active: 46 },
  ];

  const recentActivity = [
    { title: 'New wallpaper pack published', time: 'Today · 10:24 AM', color: 'orange' },
    { title: 'Category "Nature" updated', time: 'Today · 09:05 AM', color: 'blue' },
    { title: 'Pro subscription activated', time: 'Yesterday · 4:47 PM', color: 'green' },
    { title: 'Bulk upload completed (24 items)', time: 'Yesterday · 2:10 PM', color: 'purple' },
    { title: 'User account flagged for review', time: '2 days ago', color: 'red' },
  ];

  return (
    <AdminPage
      title="Dashboard"
      subtitle="Wallpaper inventory, subscribers, downloads, and backend readiness — all in one place."
      actions={
        <Button variant="secondary" onClick={() => void fetchStats(true)} disabled={isRefreshing}>
          <RefreshCw className={isRefreshing ? 'admin-icon-spin' : ''} size={14} />
          {isRefreshing ? 'Refreshing…' : 'Refresh'}
        </Button>
      }
    >
      {/* ── Hero ──────────────────────────────────────────── */}
      <section className="admin-hero-panel">
        <div>
          <p>Admin CMS</p>
          <h2>Sharpen your wallpaper business with a focused content dashboard</h2>
          <button type="button" onClick={() => navigate('/wallpapers')}>
            Manage library
            <span>
              <Play size={10} fill="currentColor" />
            </span>
          </button>
        </div>
        <div className="admin-hero-panel__metrics">
          <span>{stats.totalWallpapers.toLocaleString()} wallpapers</span>
          <span>{stats.totalUsers.toLocaleString()} users</span>
          <span>{stats.proUsers.toLocaleString()} pro subscribers</span>
        </div>
      </section>

      {/* ── Stat tiles ────────────────────────────────────── */}
      <div className="admin-grid admin-grid--stats">
        <StatTile label="Total wallpapers" value={stats.totalWallpapers.toLocaleString()} helper="Published inventory" tone="blue" loading={isLoading} />
        <StatTile label="Categories" value={stats.totalCategories.toLocaleString()} helper="Active content groups" tone="purple" loading={isLoading} />
        <StatTile label="Total users" value={stats.totalUsers.toLocaleString()} helper="Known accounts" tone="green" loading={isLoading} />
        <StatTile label="Pro subscribers" value={stats.proUsers.toLocaleString()} helper="Premium access" tone="orange" loading={isLoading} />
        <StatTile label="Downloads" value={stats.totalWallpaperDownloads.toLocaleString()} helper="Lifetime saves" tone="red" loading={isLoading} />
        <StatTile label="New this month" value={stats.newUsersThisMonth.toLocaleString()} helper="Fresh signups" tone="blue" loading={isLoading} />
      </div>

      {/* ── Main chart grid ────────────────────────────────── */}
      <div className="admin-dash-grid">
        <div className="admin-dash-left">

          {/* Bar chart — uploads over time */}
          <div className="admin-chart-panel">
            <div className="admin-chart-header">
              <div>
                <h3 className="admin-chart-title">Uploads Over Time</h3>
                <p className="admin-chart-subtitle">Monthly wallpaper uploads · {avgUploads} avg</p>
              </div>
              <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                <div className="admin-chart-legend">
                  <div className="admin-chart-legend__item">
                    <div className="admin-chart-legend__dot" style={{ background: '#e8560c' }} />
                    Uploads
                  </div>
                  <div className="admin-chart-legend__item">
                    <div className="admin-chart-legend__line" style={{ background: '#9ca3af', borderTop: '2px dashed #9ca3af', height: 0 }} />
                    Average
                  </div>
                </div>
                <button className="admin-chart-menu" title="More options">···</button>
              </div>
            </div>
            <ResponsiveContainer width="100%" height={200}>
              <BarChart data={barData} barCategoryGap="30%" margin={{ top: 4, right: 4, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" vertical={false} />
                <XAxis dataKey="month" tick={{ fontSize: 11, fill: '#9ca3af' }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fontSize: 11, fill: '#9ca3af' }} axisLine={false} tickLine={false} />
                <Tooltip
                  contentStyle={{ border: '1px solid #e8eaef', borderRadius: 8, fontSize: 12, boxShadow: '0 4px 12px rgba(0,0,0,0.08)' }}
                  cursor={{ fill: 'rgba(232,86,12,0.05)' }}
                />
                <ReferenceLine y={avgUploads} stroke="#9ca3af" strokeDasharray="4 4" strokeWidth={1.5} />
                <Bar dataKey="uploads" radius={[4, 4, 0, 0]}>
                  {barData.map((entry, i) => (
                    <Cell key={i} fill={entry.highlight ? '#e8560c' : '#e0e3ea'} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </div>

          {/* Line chart — growth curves */}
          <div className="admin-chart-panel">
            <div className="admin-chart-header">
              <div>
                <h3 className="admin-chart-title">Growth Overview</h3>
                <p className="admin-chart-subtitle">Users, pro subscribers & downloads over 6 months</p>
              </div>
              <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                <div className="admin-chart-legend">
                  <div className="admin-chart-legend__item">
                    <div className="admin-chart-legend__dot" style={{ background: '#e8560c' }} />
                    Users
                  </div>
                  <div className="admin-chart-legend__item">
                    <div className="admin-chart-legend__dot" style={{ background: '#1b1e2b' }} />
                    Pro
                  </div>
                  <div className="admin-chart-legend__item">
                    <div className="admin-chart-legend__dot" style={{ background: '#60a5fa' }} />
                    Downloads
                  </div>
                  <div className="admin-chart-legend__item">
                    <div className="admin-chart-legend__dot" style={{ background: '#d1d5db' }} />
                    Active
                  </div>
                </div>
                <button className="admin-chart-menu" title="More options">···</button>
              </div>
            </div>
            <ResponsiveContainer width="100%" height={200}>
              <LineChart data={lineData} margin={{ top: 4, right: 4, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" vertical={false} />
                <XAxis dataKey="month" tick={{ fontSize: 11, fill: '#9ca3af' }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fontSize: 11, fill: '#9ca3af' }} axisLine={false} tickLine={false} />
                <Tooltip
                  contentStyle={{ border: '1px solid #e8eaef', borderRadius: 8, fontSize: 12, boxShadow: '0 4px 12px rgba(0,0,0,0.08)' }}
                />
                <Line type="monotone" dataKey="users" stroke="#e8560c" strokeWidth={2.5} dot={false} activeDot={{ r: 4 }} />
                <Line type="monotone" dataKey="pro" stroke="#1b1e2b" strokeWidth={2.5} dot={false} activeDot={{ r: 4 }} />
                <Line type="monotone" dataKey="downloads" stroke="#60a5fa" strokeWidth={2} dot={false} activeDot={{ r: 4 }} strokeDasharray="0" />
                <Line type="monotone" dataKey="active" stroke="#d1d5db" strokeWidth={1.5} dot={false} />
              </LineChart>
            </ResponsiveContainer>
          </div>

          {/* Assets overview */}
          <div className="admin-chart-panel">
            <div className="admin-chart-header">
              <div>
                <h3 className="admin-chart-title">Assets Overview</h3>
                <p className="admin-chart-subtitle">Snapshot across all content dimensions</p>
              </div>
              <select style={{ fontSize: 12, border: '1px solid #e8eaef', borderRadius: 6, padding: '4px 8px', background: '#fff', color: '#6b7280', cursor: 'pointer' }}>
                <option>All time</option>
                <option>30 Days</option>
                <option>7 Days</option>
              </select>
            </div>
            <div className="admin-overview-grid">
              <div className="admin-overview-cell">
                <div className="admin-overview-cell__label">New Assets</div>
                <div className="admin-overview-cell__value">{stats.newUsersThisMonth}</div>
              </div>
              <div className="admin-overview-cell">
                <div className="admin-overview-cell__label">Domains</div>
                <div className="admin-overview-cell__value">{stats.totalCategories}</div>
              </div>
              <div className="admin-overview-cell">
                <div className="admin-overview-cell__label">Website</div>
                <div className="admin-overview-cell__value">{stats.totalWallpapers}</div>
              </div>
              <div className="admin-overview-cell">
                <div className="admin-overview-cell__label">Live Users</div>
                <div className="admin-overview-cell__value">{stats.totalUsers}</div>
              </div>
              <div className="admin-overview-cell">
                <div className="admin-overview-cell__label">Pro</div>
                <div className="admin-overview-cell__value">{stats.proUsers}</div>
              </div>
              <div className="admin-overview-cell">
                <div className="admin-overview-cell__label">Downloads</div>
                <div className="admin-overview-cell__value">{stats.totalWallpaperDownloads}</div>
              </div>
            </div>
          </div>
        </div>

        {/* ── Right column ──────────────────────────────────── */}
        <div className="admin-dash-right">

          {/* Activity feed */}
          <div className="admin-chart-panel">
            <div className="admin-chart-header">
              <div>
                <h3 className="admin-chart-title">Recent Activity</h3>
                <p className="admin-chart-subtitle">Latest changes across the platform</p>
              </div>
              <button className="admin-chart-menu" title="More options">···</button>
            </div>
            <div className="admin-feed">
              {recentActivity.map((item, i) => (
                <div key={i} className={`admin-feed__item admin-feed__item--${item.color}`}>
                  <div className="admin-feed__title">{item.title}</div>
                  <div className="admin-feed__time">{item.time}</div>
                </div>
              ))}
            </div>
            <button className="admin-feed__view-all">
              View all <ExternalLink size={11} />
            </button>
          </div>

          {/* Quick actions */}
          <AdminPanel title="Quick Actions" description="Jump into frequently used workflows.">
            <div className="admin-action-list">
              <button type="button" className="admin-action-card" onClick={() => navigate('/wallpapers')}>
                <Images size={16} />
                <span>
                  <strong>Manage wallpapers</strong>
                  <small>Upload, edit, promote, delete</small>
                </span>
                <ArrowRight size={14} />
              </button>
              <button type="button" className="admin-action-card" onClick={() => navigate('/categories')}>
                <FolderOpen size={16} />
                <span>
                  <strong>Manage categories</strong>
                  <small>Organize taxonomy and imports</small>
                </span>
                <ArrowRight size={14} />
              </button>
              <button type="button" className="admin-action-card" onClick={() => navigate('/users')}>
                <Users size={16} />
                <span>
                  <strong>Review users</strong>
                  <small>Plans, push state, downloads</small>
                </span>
                <ArrowRight size={14} />
              </button>
            </div>
          </AdminPanel>

          {/* Server status */}
          <AdminPanel title="Server Status" description="Live backend health for this session.">
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
                <span>Health</span>
                <span style={{ fontSize: 12, maxWidth: 160, textAlign: 'right' }}>{healthMessage}</span>
              </div>
              <div className="admin-info-row">
                <span>Last synced</span>
                <span>{lastUpdated ? lastUpdated.toLocaleTimeString() : '—'}</span>
              </div>
              <div className="admin-info-row">
                <span>Refresh</span>
                <span>Every 60s</span>
              </div>
            </div>

            <div style={{ marginTop: 16, display: 'flex', flexDirection: 'column', gap: 10 }}>
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6, fontSize: 12 }}>
                  <span style={{ color: '#6b7280' }}>Premium mix</span>
                  <span style={{ fontWeight: 600 }}>{premiumMix}%</span>
                </div>
                <div className="admin-progress-track">
                  <div className="admin-progress-bar" style={{ width: `${premiumMix}%` }} />
                </div>
              </div>
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6, fontSize: 12 }}>
                  <span style={{ color: '#6b7280' }}>Inventory density</span>
                  <span style={{ fontWeight: 600 }}>{inventoryDensity} / category</span>
                </div>
                <div className="admin-progress-track">
                  <div className="admin-progress-bar" style={{ width: `${Math.min(inventoryDensity * 2, 100)}%`, background: '#2563eb' }} />
                </div>
              </div>
            </div>
          </AdminPanel>

        </div>
      </div>
    </AdminPage>
  );
}
