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
        <div className="admin-sidebar__brand">
          <div className="admin-sidebar__brand-mark">
            <GalleryVerticalEnd size={20} />
          </div>
          <div>
            <p className="admin-sidebar__eyebrow">SoftSky</p>
            <h2>Admin App</h2>
          </div>
        </div>

        <nav className="admin-sidebar__nav">
          {navigation.map((item) => {
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
                <Icon size={18} />
                <span>{item.label}</span>
              </NavLink>
            );
          })}
        </nav>

        <div className="admin-sidebar__footer">
          <div className="admin-sidebar__user">
            <strong>{user?.displayName || 'Admin'}</strong>
            <span>{user?.email || 'Signed in'}</span>
          </div>
          <Button variant="ghost" onClick={handleLogout} size="sm" className="admin-sidebar__logout">
            <LogOut size={16} />
            <span>Sign out</span>
          </Button>
        </div>
      </aside>

      <div className="admin-main">
        <header className="admin-topbar">
          <div>
            <p className="admin-topbar__eyebrow">Connected workspace</p>
            <h1>{currentPage}</h1>
          </div>

          <div className="admin-topbar__actions">
            <button
              type="button"
              className="admin-menu-toggle"
              aria-label={isNavOpen ? 'Close navigation' : 'Open navigation'}
              onClick={() => setIsNavOpen((value) => !value)}
            >
              {isNavOpen ? <X size={18} /> : <Menu size={18} />}
            </button>
            <span className="admin-header__status">
              <span className="admin-header__dot" />
              Admin API connected
            </span>
          </div>
        </header>

        <main className="admin-content">
          <div className="admin-content__inner">
            <Outlet />
          </div>
        </main>
      </div>
    </div>
  );
}
