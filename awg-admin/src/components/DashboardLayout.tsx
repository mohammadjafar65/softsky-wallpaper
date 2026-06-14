import { useMemo, useState } from 'react';
import { NavLink, Outlet, useLocation, useNavigate } from 'react-router-dom';
import {
  Bell,
  Boxes,
  ChevronRight,
  CreditCard,
  GalleryVerticalEnd,
  Grid2X2,
  Images,
  LayoutDashboard,
  LogOut,
  Menu,
  MoveHorizontal,
  Search,
  Settings,
  Users,
  X,
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';

const navOverview = [
  { label: 'Dashboard', to: '/', icon: LayoutDashboard },
  { label: 'Wallpapers', to: '/wallpapers', icon: Images },
  { label: 'Reassign', to: '/reassign-wallpapers', icon: MoveHorizontal },
  { label: 'Categories', to: '/categories', icon: Grid2X2 },
  { label: 'Packs', to: '/packs', icon: Boxes },
];

const navBusiness = [
  { label: 'Users', to: '/users', icon: Users },
  { label: 'Subscriptions', to: '/subscriptions', icon: CreditCard },
  { label: 'Notifications', to: '/notifications', icon: Bell },
];

export default function DashboardLayout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [isNavOpen, setIsNavOpen] = useState(false);

  const allNav = [...navOverview, ...navBusiness];
  const currentPage = useMemo(
    () =>
      allNav.find((item) =>
        item.to === '/' ? location.pathname === '/' : location.pathname.startsWith(item.to)
      )?.label ?? 'Dashboard',
    [location.pathname]
  );

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  const isActive = (to: string) =>
    to === '/' ? location.pathname === '/' : location.pathname.startsWith(to);

  return (
    <div className="admin-shell">
      {/* ── Sidebar ──────────────────────────────────────── */}
      <aside className={`admin-sidebar ${isNavOpen ? 'admin-sidebar--open' : ''}`}>
        <NavLink to="/" className="admin-sidebar__brand" onClick={() => setIsNavOpen(false)}>
          <span className="admin-sidebar__brand-mark">
            <GalleryVerticalEnd size={15} />
          </span>
          SoftSky Admin
        </NavLink>

        <div className="admin-sidebar__section">
          <p className="admin-sidebar__eyebrow">Overview</p>
          <nav className="admin-sidebar__nav">
            {navOverview.map((item) => {
              const Icon = item.icon;
              return (
                <NavLink
                  key={item.to}
                  to={item.to}
                  end={item.to === '/'}
                  onClick={() => setIsNavOpen(false)}
                  className={`admin-sidebar__link ${isActive(item.to) ? 'admin-sidebar__link--active' : ''}`}
                >
                  <Icon size={15} />
                  <span>{item.label}</span>
                </NavLink>
              );
            })}
          </nav>
        </div>

        <div className="admin-sidebar__section">
          <p className="admin-sidebar__eyebrow">Business</p>
          <nav className="admin-sidebar__nav">
            {navBusiness.map((item) => {
              const Icon = item.icon;
              return (
                <NavLink
                  key={item.to}
                  to={item.to}
                  onClick={() => setIsNavOpen(false)}
                  className={`admin-sidebar__link ${isActive(item.to) ? 'admin-sidebar__link--active' : ''}`}
                >
                  <Icon size={15} />
                  <span>{item.label}</span>
                </NavLink>
              );
            })}
          </nav>
        </div>

        <div className="admin-sidebar__footer">
          <button type="button" className="admin-sidebar__link">
            <Settings size={15} />
            <span>Settings</span>
          </button>
          <button
            type="button"
            className="admin-sidebar__link admin-sidebar__logout"
            onClick={handleLogout}
          >
            <LogOut size={15} />
            <span>Sign out</span>
          </button>
          <div className="admin-sidebar__user" style={{ marginTop: 8, paddingTop: 12, borderTop: '1px solid rgba(255,255,255,0.07)' }}>
            <div style={{ fontWeight: 600, fontSize: 12, color: '#e8eaf0' }}>
              {user?.displayName || 'Admin'}
            </div>
            <div style={{ fontSize: 11, color: '#4c5269', marginTop: 2 }}>
              {user?.email || ''}
            </div>
          </div>
        </div>
      </aside>

      {/* ── Main ─────────────────────────────────────────── */}
      <section className="admin-main">
        <header className="admin-topbar">
          <button
            type="button"
            className="admin-menu-toggle"
            aria-label={isNavOpen ? 'Close navigation' : 'Open navigation'}
            onClick={() => setIsNavOpen((v) => !v)}
          >
            {isNavOpen ? <X size={16} /> : <Menu size={16} />}
          </button>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
            <div className="admin-topbar__breadcrumb">
              SoftSky{' '}
              <ChevronRight size={10} style={{ display: 'inline', verticalAlign: 'middle' }} />{' '}
              <span>{currentPage}</span>
            </div>
            <h1 style={{ margin: 0, fontSize: 15, fontWeight: 700, letterSpacing: '-0.01em' }}>
              {currentPage}
            </h1>
          </div>

          <div className="admin-search">
            <Search size={13} />
            <span>Search {currentPage.toLowerCase()}…</span>
          </div>

          <div className="admin-topbar__actions">
            <div className="admin-header__status">
              <span className="admin-header__dot" />
              Active
            </div>
            <button type="button" className="admin-round-button" aria-label="Notifications">
              <Bell size={14} />
            </button>
            <button
              type="button"
              className="admin-profile-chip"
              onClick={handleLogout}
              title={user?.email || 'Sign out'}
            >
              <span className="admin-profile-chip__avatar">
                {(user?.displayName || 'A').slice(0, 1).toUpperCase()}
              </span>
              <span>{user?.displayName || 'Admin'}</span>
            </button>
          </div>
        </header>

        <main className="admin-content">
          <div className="admin-content__inner">
            <Outlet />
          </div>
        </main>
      </section>
    </div>
  );
}
