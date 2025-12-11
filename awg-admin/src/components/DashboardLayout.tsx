import { NavLink, Outlet, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import {
    HomeIcon,
    PhotoIcon,
    FolderIcon,
    UsersIcon,
    CreditCardIcon,
    ArrowRightOnRectangleIcon,
    Bars3CenterLeftIcon,
} from '@heroicons/react/24/outline';

const navigation = [
    { name: 'Dashboard', href: '/', icon: HomeIcon },
    { name: 'Wallpapers', href: '/wallpapers', icon: PhotoIcon },
    { name: 'Categories', href: '/categories', icon: FolderIcon },
    { name: 'Packs', href: '/packs', icon: FolderIcon },
    { name: 'Users', href: '/users', icon: UsersIcon },
    { name: 'Subscriptions', href: '/subscriptions', icon: CreditCardIcon },
];

export default function DashboardLayout() {
    const { user, logout } = useAuth();
    const navigate = useNavigate();
    const location = useLocation();

    const handleLogout = () => {
        logout();
        navigate('/login');
    };

    const currentPage = navigation.find(item => item.href === location.pathname)?.name || 'Dashboard';

    return (
        <div className="min-h-screen bg-slate-950 text-slate-200 font-sans selection:bg-violet-500/30 relative">
            {/* Background Gradients */}
            <div className="fixed inset-0 z-0 pointer-events-none overflow-hidden">
                <div className="absolute top-[-10%] left-[-10%] w-[50%] h-[50%] bg-violet-600/10 rounded-full blur-[120px]" />
                <div className="absolute bottom-[-10%] right-[-10%] w-[50%] h-[50%] bg-blue-600/10 rounded-full blur-[120px]" />
            </div>

            {/* Sidebar */}
            <aside className="fixed inset-y-0 left-0 z-50 w-72 bg-slate-900/80 backdrop-blur-xl border-r border-white/5 flex flex-col transition-transform duration-300 ease-in-out">
                {/* Logo area */}
                <div className="h-20 flex items-center px-8 border-b border-white/5">
                    <div className="flex items-center gap-3 cursor-pointer group">
                        <div className="relative w-10 h-10 rounded-xl bg-gradient-to-br from-violet-600 to-indigo-600 flex items-center justify-center shadow-lg shadow-violet-500/20 group-hover:scale-105 transition-transform duration-300">
                            <PhotoIcon className="w-5 h-5 text-white" />
                        </div>
                        <div>
                            <h1 className="text-lg font-bold text-white tracking-tight">AWG</h1>
                            <p className="text-[10px] text-slate-400 font-medium tracking-wider uppercase">Admin Panel</p>
                        </div>
                    </div>
                </div>

                {/* Navigation */}
                <nav className="flex-1 px-4 py-6 overflow-y-auto no-scrollbar">
                    <p className="px-4 mb-2 text-xs font-semibold text-slate-500 uppercase tracking-wider">Menu</p>
                    <ul className="space-y-1">
                        {navigation.map((item) => (
                            <li key={item.name}>
                                <NavLink
                                    to={item.href}
                                    className={({ isActive }) =>
                                        `group flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200 font-medium text-sm ${isActive
                                            ? 'bg-violet-600 text-white shadow-md shadow-violet-500/20'
                                            : 'text-slate-400 hover:text-white hover:bg-white/5'
                                        }`
                                    }
                                >
                                    <item.icon className={`w-5 h-5 transition-colors ${({ isActive }: { isActive: boolean }) => isActive ? 'text-white' : 'text-slate-400 group-hover:text-white'}`} />
                                    <span>{item.name}</span>
                                </NavLink>
                            </li>
                        ))}
                    </ul>
                </nav>

                {/* User Profile */}
                <div className="p-4 border-t border-white/5 bg-black/20">
                    <div className="flex items-center gap-3 p-3 rounded-xl hover:bg-white/5 transition-colors cursor-pointer group">
                        <div className="w-9 h-9 rounded-lg bg-gradient-to-tr from-sky-500 to-blue-600 flex items-center justify-center text-white text-sm font-bold shadow-md">
                            {user?.displayName?.charAt(0) || 'A'}
                        </div>
                        <div className="flex-1 min-w-0">
                            <p className="text-sm font-semibold text-white truncate">{user?.displayName || 'Admin'}</p>
                            <p className="text-xs text-slate-400 truncate">{user?.email}</p>
                        </div>
                        <button
                            onClick={handleLogout}
                            className="p-1.5 text-slate-400 hover:text-red-400 hover:bg-red-500/10 rounded-lg transition-colors"
                            title="Sign out"
                        >
                            <ArrowRightOnRectangleIcon className="w-5 h-5" />
                        </button>
                    </div>
                </div>
            </aside>

            {/* Main Content Wrapper */}
            <div className="pl-72 relative z-10 flex flex-col min-h-screen transition-all duration-300">
                {/* Top Header */}
                <header className="h-20 sticky top-0 z-40 px-8 flex items-center justify-between bg-slate-950/80 backdrop-blur-md border-b border-white/5">
                    <div className="flex items-center gap-4">
                        <button className="lg:hidden p-2 text-slate-400 hover:text-white">
                            <Bars3CenterLeftIcon className="w-6 h-6" />
                        </button>
                        <h2 className="text-lg font-bold text-white tracking-tight">{currentPage}</h2>
                    </div>

                    <div className="flex items-center gap-4">
                        <div className="px-3 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs font-medium flex items-center gap-1.5">
                            <span className="relative flex h-2 w-2">
                                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                                <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
                            </span>
                            System Operational
                        </div>
                        <div className="h-6 w-[1px] bg-white/10" />
                        <span className="text-sm text-slate-400 font-medium">
                            {new Date().toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' })}
                        </span>
                    </div>
                </header>

                {/* Page Content */}
                <main className="flex-1 p-8">
                    <div className="max-w-6xl mx-auto space-y-8 animate-fade-in-up">
                        <Outlet />
                    </div>
                </main>
            </div>
        </div>
    );
}

