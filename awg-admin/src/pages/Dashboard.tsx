import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { usersApi, wallpapersApi, categoriesApi } from '../services/api';
import {
    PhotoIcon,
    UsersIcon,
    FolderIcon,
    CreditCardIcon,
    ArrowRightIcon,
    ArrowDownTrayIcon,
} from '@heroicons/react/24/outline';

interface Stats {
    totalWallpapers: number;
    totalCategories: number;
    totalUsers: number;
    proUsers: number;
    totalWallpaperDownloads: number;
}

export default function Dashboard() {
    const navigate = useNavigate();
    const [stats, setStats] = useState<Stats>({
        totalWallpapers: 0,
        totalCategories: 0,
        totalUsers: 0,
        proUsers: 0,
        totalWallpaperDownloads: 0,
    });
    const [isLoading, setIsLoading] = useState(true);

    useEffect(() => {
        fetchStats();
    }, []);

    const fetchStats = async () => {
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
            });
        } catch (error) {
            console.error('Failed to fetch stats:', error);
        } finally {
            setIsLoading(false);
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
            </div>

            {/* Stats Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
                {statCards.map((card) => (
                    <div
                        key={card.name}
                        className={`group relative p-6 rounded-2xl bg-slate-900/50 border ${card.border} backdrop-blur-sm hover:transform hover:scale-[1.02] transition-all duration-300 shadow-lg`}
                    >
                        <div className="absolute inset-0 bg-gradient-to-br from-white/5 to-transparent rounded-2xl opacity-0 group-hover:opacity-100 transition-opacity" />

                        <div className="relative flex justify-between items-start">
                            <div>
                                <p className="text-slate-400 text-sm font-medium">{card.name}</p>
                                <div className="mt-4 flex items-baseline gap-2">
                                    <h3 className="text-3xl font-bold text-white">
                                        {isLoading ? (
                                            <div className="h-8 w-16 bg-slate-800 animate-pulse rounded" />
                                        ) : (
                                            card.value.toLocaleString()
                                        )}
                                    </h3>
                                </div>
                            </div>
                            <div className={`p-3 rounded-xl ${card.bg} ${card.color}`}>
                                <card.icon className="w-6 h-6" />
                            </div>
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

