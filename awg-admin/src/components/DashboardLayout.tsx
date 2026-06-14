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
      <header className="admin-topbar">
        <NavLink to="/" className="admin-topbar__brand" onClick={() => setIsNavOpen(false)}>
          <span className="admin-topbar__brand-mark">
            <GalleryVerticalEnd size={18} />
          </span>
          <span>SoftSky</span>
        </NavLink>

        <nav className={`admin-topnav ${isNavOpen ? 'admin-topnav--open' : ''}`}>
          {navigation.map((item) => {
            const Icon = item.icon;
            const isActive =
              item.to === '/' ? location.pathname === '/' : location.pathname.startsWith(item.to);

            return (
              <NavLink
                key={item.to}
                to={item.to}
                onClick={() => setIsNavOpen(false)}
                className={`admin-topnav__link ${isActive ? 'admin-topnav__link--active' : ''}`}
              >
                <Icon size={14} />
                <span>{item.label}</span>
              </NavLink>
            );
          })}
        </nav>

        <div className="admin-topbar__actions">
          <span className="admin-header__status">
            <span className="admin-header__dot" />
            {currentPage}
          </span>
          <button type="button" className="admin-round-button" aria-label="Search">
            <Search size={16} />
          </button>
          <button type="button" className="admin-round-button" aria-label="Notifications">
            <Bell size={16} />
          </button>
          <Button variant="ghost" onClick={handleLogout} size="icon" className="admin-round-button" title={user?.email || 'Sign out'}>
            <LogOut size={16} />
          </Button>
          <button
            type="button"
            className="admin-menu-toggle"
            aria-label={isNavOpen ? 'Close navigation' : 'Open navigation'}
            onClick={() => setIsNavOpen((value) => !value)}
          >
            {isNavOpen ? <X size={18} /> : <Menu size={18} />}
          </button>
        </div>
      </header>

      <main className="admin-content">
        <div className="admin-content__inner">
          <Outlet />
        </div>
      </main>

      <div className="admin-shell__footer">
        <span>{user?.displayName || 'Admin'}</span>
        <span>{user?.email || 'Signed in'}</span>
      </div>
    </div>
  );
}
