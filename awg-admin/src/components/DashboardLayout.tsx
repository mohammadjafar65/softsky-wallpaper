import { useEffect, useMemo, useState } from 'react';
import { NavLink, Outlet, useLocation, useNavigate } from 'react-router-dom';
import {
  Button,
  Content,
  Header,
  HeaderGlobalBar,
  HeaderGlobalAction,
  HeaderMenuButton,
  HeaderName,
  SideNav,
  SideNavItems,
  SideNavLink,
} from '@carbon/react';
import {
  Dashboard,
  Image,
  Category,
  UserMultiple,
  Catalog,
  Currency,
  Notification,
  ArrowsHorizontal,
  Logout,
} from '@carbon/icons-react';
import { useAuth } from '../context/AuthContext';

const navigation = [
  { label: 'Dashboard', to: '/', icon: Dashboard },
  { label: 'Wallpapers', to: '/wallpapers', icon: Image },
  { label: 'Reassign', to: '/reassign-wallpapers', icon: ArrowsHorizontal },
  { label: 'Categories', to: '/categories', icon: Category },
  { label: 'Packs', to: '/packs', icon: Catalog },
  { label: 'Users', to: '/users', icon: UserMultiple },
  { label: 'Subscriptions', to: '/subscriptions', icon: Currency },
  { label: 'Notifications', to: '/notifications', icon: Notification },
];

export default function DashboardLayout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [isSideNavExpanded, setIsSideNavExpanded] = useState(false);

  useEffect(() => {
    setIsSideNavExpanded(false);
  }, [location.pathname]);

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
      <Header aria-label="SoftSky Admin" className="admin-header">
        <HeaderMenuButton
          aria-label={isSideNavExpanded ? 'Close navigation menu' : 'Open navigation menu'}
          isActive={isSideNavExpanded}
          onClick={() => setIsSideNavExpanded((value) => !value)}
        />
        <HeaderName prefix="SoftSky">Admin</HeaderName>
        <div className="cds--header__global">
          <span className="admin-header__status">
            <span className="admin-header__dot" />
            {currentPage}
          </span>
        </div>
        <HeaderGlobalBar>
          <HeaderGlobalAction
            aria-label="Sign out"
            onClick={handleLogout}
            tooltipAlignment="end"
          >
            <Logout size={20} />
          </HeaderGlobalAction>
        </HeaderGlobalBar>
      </Header>

      <SideNav
        aria-label="Side navigation"
        expanded={isSideNavExpanded}
        isChildOfHeader={false}
        onOverlayClick={() => setIsSideNavExpanded(false)}
      >
        <SideNavItems>
          {navigation.map((item) => (
            <SideNavLink
              key={item.to}
              as={NavLink}
              to={item.to}
              renderIcon={item.icon}
              isActive={item.to === '/' ? location.pathname === '/' : location.pathname.startsWith(item.to)}
            >
              {item.label}
            </SideNavLink>
          ))}
        </SideNavItems>

        <div style={{ marginTop: 'auto', padding: '1rem' }}>
          <div className="admin-authors">{user?.displayName || 'Admin'}</div>
          <div className="admin-authors" style={{ marginTop: '0.25rem', marginBottom: '1rem' }}>
            {user?.email || 'Signed in'}
          </div>
          <Button kind="ghost" onClick={handleLogout} size="sm" renderIcon={Logout}>
            Sign out
          </Button>
        </div>
      </SideNav>

      <Content id="main-content" className="admin-content">
        <div className="admin-content__inner">
          <Outlet />
        </div>
      </Content>
    </div>
  );
}
