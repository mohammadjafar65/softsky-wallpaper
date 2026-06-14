import { useMemo, useState } from 'react';
import { NavLink, Outlet, useLocation, useNavigate } from 'react-router-dom';
import {
  Bell,
  Boxes,
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
import { Button } from './ui/button';
import { useAuth } from '../context/AuthContext';

const navigation = [
  { label: 'Dashboard', to: '/', icon: LayoutDashboard },
  { label: 'Wallpapers', to: '/wallpapers', icon: Images },
  { label: 'Reassign', to: '/reassign-wallpapers', icon: MoveHorizontal },
  { label: 'Categories', to: '/categories', icon: Grid2X2 },
  { label: 'Packs', to: '/packs', icon: Boxes },
  { label: 'Users', to: '/users', icon: Users },
  { label: 'Subscriptions', to: '/subscriptions', icon: CreditCard },
  { label: 'Notifications', to: '/notifications', icon: Bell },
];

export default function DashboardLayout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [isNavOpen, setIsNavOpen] = useState(false);

  const currentPage = useMemo(
    () => navigation.find((item) => item.to === location.pathname)?.label ?? 'Dashboard',
    [location.pathname]
  );

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <div className="admin-shell">
      <aside className={`admin-sidebar ${isNavOpen ? 'admin-sidebar--open' : ''}`}>
        <NavLink to="/" className="admin-sidebar__brand" onClick={() => setIsNavOpen(false)}>
          <span className="admin-sidebar__brand-mark">
            <GalleryVerticalEnd size={16} />
          </span>
          <strong>SoftSky</strong>
        </NavLink>

        <div className="admin-sidebar__section">
          <p className="admin-sidebar__eyebrow">Overview</p>
          <nav className="admin-sidebar__nav">
            {navigation.slice(0, 5).map((item) => {
              const Icon = item.icon;
              const isActive =
                item.to === '/' ? location.pathname === '/' : location.pathname.startsWith(item.to);

              return (
                <NavLink
                  key={item.to}
                  to={item.to}
                  onClick={() => setIsNavOpen(false)}
                  className={`admin-sidebar__link ${isActive ? 'admin-sidebar__link--active' : ''}`}
                >
                  <Icon size={16} />
                  <span>{item.label}</span>
                </NavLink>
              );
            })}
          </nav>
        </div>

        <div className="admin-sidebar__section">
          <p className="admin-sidebar__eyebrow">Business</p>
          <nav className="admin-sidebar__nav">
            {navigation.slice(5).map((item) => {
              const Icon = item.icon;
              const isActive = location.pathname.startsWith(item.to);

              return (
                <NavLink
                  key={item.to}
                  to={item.to}
                  onClick={() => setIsNavOpen(false)}
                  className={`admin-sidebar__link ${isActive ? 'admin-sidebar__link--active' : ''}`}
                >
                  <Icon size={16} />
                  <span>{item.label}</span>
                </NavLink>
              );
            })}
          </nav>
        </div>

        <div className="admin-sidebar__footer">
          <p className="admin-sidebar__eyebrow">Settings</p>
          <button type="button" className="admin-sidebar__link">
            <Settings size={16} />
            <span>Setting</span>
          </button>
          <button type="button" className="admin-sidebar__link admin-sidebar__logout" onClick={handleLogout}>
            <LogOut size={16} />
            <span>Logout</span>
          </button>
        </div>
      </aside>

      <section className="admin-main">
        <header className="admin-topbar">
          <button
            type="button"
            className="admin-menu-toggle"
            aria-label={isNavOpen ? 'Close navigation' : 'Open navigation'}
            onClick={() => setIsNavOpen((value) => !value)}
          >
            {isNavOpen ? <X size={18} /> : <Menu size={18} />}
          </button>

          <div className="admin-search">
            <Search size={15} />
            <span>Search {currentPage.toLowerCase()}...</span>
          </div>

          <div className="admin-topbar__actions">
            <button type="button" className="admin-round-button" aria-label="Messages">
              <GalleryVerticalEnd size={15} />
            </button>
            <button type="button" className="admin-round-button" aria-label="Notifications">
              <Bell size={15} />
            </button>
            <Button variant="ghost" onClick={handleLogout} className="admin-profile-chip" title={user?.email || 'Sign out'}>
              <span className="admin-profile-chip__avatar">{(user?.displayName || 'A').slice(0, 1)}</span>
              <span>{user?.displayName || 'Admin'}</span>
            </Button>
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
