import { useEffect, useState, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { usersApi, wallpapersApi, categoriesApi } from '../services/api';
import {
    PhotoIcon,
    UsersIcon,
    FolderIcon,
    CreditCardIcon,
    ArrowRightIcon,
    ArrowDownTrayIcon,
    UserPlusIcon,
    ArrowPathIcon,
} from '@heroicons/react/24/outline';

interface Stats {
    totalWallpapers: number;
    totalCategories: number;
    totalUsers: number;
    proUsers: number;
    totalWallpaperDownloads: number;
    newUsersThisMonth: number;
}

const AUTO_REFRESH_INTERVAL = 60 * 1000; // 60 seconds

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
    const [lastUpdated, setLastUpdated] = useState<Date | null>(null);
    const [isRefreshing, setIsRefreshing] = useState(false);
    const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

    useEffect(() => {
        fetchStats();

        // Auto-refresh every 60 seconds
        intervalRef.current = setInterval(() => {
            fetchStats(true);
        }, AUTO_REFRESH_INTERVAL);

        return () => {
            if (intervalRef.current) clearInterval(intervalRef.current);
        };
    }, []);

    const fetchStats = async (silent = false) => {
        if (!silent) setIsLoading(true);
        else setIsRefreshing(true);

        try {
            const [wallpapersRes, categoriesRes, usersRes] = await Promise.all([
                wallpapersApi.getAll({ limit: 1 }),
                categoriesApi.getAll(),
                usersApi.getStats(),
            ]);

            setStats({
                totalWallpapers: wallpapersRes.data.pagination?.total || 0,
                totalCategories: categoriesRes.data.categories?.length || 0,
                totalUsers: usersRes.data.totalUsers || 0,
                proUsers: usersRes.data.proUsers || 0,
                totalWallpaperDownloads: usersRes.data.totalWallpaperDownloads || 0,
                newUsersThisMonth: usersRes.data.newUsersThisMonth || 0,
            });
            setLastUpdated(new Date());
        } catch (error) {
            console.error('Failed to fetch stats:', error);
        } finally {
            setIsLoading(false);
            setIsRefreshing(false);
        }
    };

    const statCards = [
        {
            name: 'Total Wallpapers',
            value: stats.totalWallpapers,
            icon: PhotoIcon,
            color: 'text-blue-400',
            bg: 'bg-blue-500/10',
            border: 'border-blue-500/20'
        },
        {
            name: 'Categories',
            value: stats.totalCategories,
            icon: FolderIcon,
            color: 'text-purple-400',
            bg: 'bg-purple-500/10',
            border: 'border-purple-500/20'
        },
        {
            name: 'Total Users',
            value: stats.totalUsers,
            icon: UsersIcon,
            color: 'text-emerald-400',
            bg: 'bg-emerald-500/10',
            border: 'border-emerald-500/20'
        },
        {
            name: 'Pro Subscribers',
            value: stats.proUsers,
            icon: CreditCardIcon,
            color: 'text-amber-400',
            bg: 'bg-amber-500/10',
            border: 'border-amber-500/20'
        },
        {
            name: 'Total Downloads',
            value: stats.totalWallpaperDownloads,
            icon: ArrowDownTrayIcon,
            color: 'text-rose-400',
            bg: 'bg-rose-500/10',
            border: 'border-rose-500/20'
        },
        {
            name: 'New This Month',
            value: stats.newUsersThisMonth,
            icon: UserPlusIcon,
            color: 'text-cyan-400',
            bg: 'bg-cyan-500/10',
            border: 'border-cyan-500/20'
        },
    ];

    const quickActions = [
        {
            name: 'Upload Wallpaper',
            desc: 'Add new wallpapers',
            icon: PhotoIcon,
            href: '/wallpapers',
            color: 'text-blue-400',
            bg: 'bg-blue-500/10',
        },
        {
            name: 'Manage Categories',
            desc: 'Add or edit categories',
            icon: FolderIcon,
            href: '/categories',
            color: 'text-purple-400',
            bg: 'bg-purple-500/10',
        },
        {
            name: 'View Users',
            desc: 'Manage user accounts',
            icon: UsersIcon,
            href: '/users',
            color: 'text-emerald-400',
            bg: 'bg-emerald-500/10',
        },
    ];

    return (
        <div className="space-y-10">
            {/* Greeting Section */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold text-white tracking-tight">Dashboard Overview</h1>
                    <p className="text-slate-400 mt-2 text-lg">Detailed statistics of your platform performance.</p>
                </div>
                <div className="flex items-center gap-3">
                    {lastUpdated && (
                        <span className="text-xs text-slate-500">
                            Updated {lastUpdated.toLocaleTimeString()}
                        </span>
                    )}
                    <button
                        onClick={() => fetchStats(true)}
                        disabled={isRefreshing}
                        className="flex items-center gap-2 px-3 py-2 rounded-xl bg-slate-800 hover:bg-slate-700 border border-white/5 text-slate-300 text-sm transition-colors disabled:opacity-50"
                        title="Refresh now"
                    >
                        <ArrowPathIcon className={`w-4 h-4 ${isRefreshing ? 'animate-spin' : ''}`} />
                        {isRefreshing ? 'Refreshing...' : 'Refresh'}
                    </button>
                </div>
            </div>

            {/* Stats Grid — 2 cols on mobile, 3 on md, 6 on xl */}
            <div className="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-6 gap-6">
                {statCards.map((card) => (
                    <div
                        key={card.name}
                        className={`group relative p-5 rounded-2xl bg-slate-900/50 border ${card.border} backdrop-blur-sm hover:transform hover:scale-[1.02] transition-all duration-300 shadow-lg`}
                    >
                        <div className="absolute inset-0 bg-gradient-to-br from-white/5 to-transparent rounded-2xl opacity-0 group-hover:opacity-100 transition-opacity" />

                        <div className="relative">
                            <div className={`w-10 h-10 rounded-xl ${card.bg} flex items-center justify-center mb-3`}>
                                <card.icon className={`w-5 h-5 ${card.color}`} />
                            </div>
                            <p className="text-slate-400 text-xs font-medium leading-tight">{card.name}</p>
                            <h3 className="text-2xl font-bold text-white mt-1">
                                {isLoading ? (
                                    <div className="h-7 w-14 bg-slate-800 animate-pulse rounded" />
                                ) : (
                                    card.value.toLocaleString()
                                )}
                            </h3>
                        </div>
                    </div>
                ))}
            </div>

            {/* Quick Actions */}
            <div className="rounded-3xl bg-slate-900/40 border border-white/5 p-8 backdrop-blur-md shadow-2xl">
                <div className="flex items-center justify-between mb-8">
                    <h2 className="text-xl font-bold text-white">Quick Actions</h2>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                    {quickActions.map((action) => (
                        <div
                            key={action.name}
                            onClick={() => navigate(action.href)}
                            className="group cursor-pointer flex items-center gap-5 p-6 rounded-2xl bg-white/5 hover:bg-white/10 border border-white/5 transition-all duration-300 hover:shadow-xl hover:shadow-violet-500/5 hover:-translate-y-1"
                        >
                            <div className={`w-14 h-14 rounded-2xl ${action.bg} flex items-center justify-center transition-transform group-hover:rotate-6`}>
                                <action.icon className={`w-7 h-7 ${action.color}`} />
                            </div>
                            <div className="flex-1">
                                <h3 className="text-lg text-white font-bold group-hover:text-violet-400 transition-colors">{action.name}</h3>
                                <p className="text-slate-400 text-sm mt-1">{action.desc}</p>
                            </div>
                            <ArrowRightIcon className="w-5 h-5 text-slate-500 group-hover:translate-x-1 group-hover:text-white transition-all" />
                        </div>
                    ))}
                </div>
            </div>
        </div>
    );
}
