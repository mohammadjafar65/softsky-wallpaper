import { useEffect, useState } from 'react';
import { usersApi } from '../services/api';
import {
    UsersIcon,
    StarIcon,
    ChartBarIcon,
    CreditCardIcon,
    TicketIcon
} from '@heroicons/react/24/outline';

interface Stats {
    totalUsers: number;
    proUsers: number;
    freeUsers: number;
    newUsersThisMonth: number;
    subscriptionBreakdown: Record<string, number>;
}

export default function Subscriptions() {
    const [stats, setStats] = useState<Stats | null>(null);
    const [isLoading, setIsLoading] = useState(true);

    useEffect(() => {
        fetchStats();
    }, []);

    const fetchStats = async () => {
        try {
            const response = await usersApi.getStats();
            setStats(response.data);
        } catch (error) {
            console.error('Failed to fetch stats:', error);
        } finally {
            setIsLoading(false);
        }
    };

    const gradientColors: Record<string, string> = {
        free: 'from-slate-500 to-slate-600',
        monthly: 'from-violet-500 to-purple-600',
        annual: 'from-fuchsia-500 to-pink-600',
        lifetime: 'from-amber-400 to-orange-500',
    };

    const statsConfig = [
        { label: 'Total Users', value: stats?.totalUsers || 0, icon: UsersIcon, color: 'text-blue-400', bg: 'bg-blue-500/10' },
        { label: 'Pro Subscribers', value: stats?.proUsers || 0, icon: StarIcon, color: 'text-amber-400', bg: 'bg-amber-500/10' },
        { label: 'Free Users', value: stats?.freeUsers || 0, icon: TicketIcon, color: 'text-slate-400', bg: 'bg-slate-500/10' },
        { label: 'New This Month', value: stats?.newUsersThisMonth || 0, icon: ChartBarIcon, color: 'text-emerald-400', bg: 'bg-emerald-500/10' },
    ];

    return (
        <div className="space-y-8">
            <div>
                <h1 className="text-3xl font-bold text-white tracking-tight">Subscriptions</h1>
                <p className="text-slate-400 mt-2">Analytics and revenue overview</p>
            </div>

            {/* Stats Overview */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                {statsConfig.map((stat, index) => (
                    <div key={index} className="bg-slate-800/50 backdrop-blur-md rounded-2xl p-6 border border-white/5 hover:border-violet-500/20 transition-all hover:shadow-lg">
                        <div className="flex items-center justify-between mb-4">
                            <div className={`p-3 rounded-xl ${stat.bg}`}>
                                <stat.icon className={`w-6 h-6 ${stat.color}`} />
                            </div>
                            {/* <span className="text-xs font-medium text-emerald-400 bg-emerald-400/10 px-2 py-1 rounded-lg">+2.5%</span> */}
                        </div>
                        <p className="text-slate-400 text-sm font-medium">{stat.label}</p>
                        <p className="text-3xl font-bold text-white mt-1">
                            {isLoading ? <div className="h-8 w-24 bg-slate-700/50 animate-pulse rounded-lg" /> : stat.value}
                        </p>
                    </div>
                ))}
            </div>

            {/* Detailed Breakdown */}
            <div className="bg-slate-800/40 backdrop-blur-xl rounded-3xl border border-white/5 p-8 shadow-2xl">
                <div className="flex items-center gap-3 mb-8">
                    <div className="p-3 rounded-xl bg-violet-500/10">
                        <CreditCardIcon className="w-6 h-6 text-violet-400" />
                    </div>
                    <div>
                        <h2 className="text-xl font-bold text-white">Plan Distribution</h2>
                        <p className="text-slate-400 text-sm">Active subscriptions by plan type</p>
                    </div>
                </div>

                {isLoading ? (
                    <div className="space-y-6">
                        {[...Array(4)].map((_, i) => (
                            <div key={i} className="space-y-2">
                                <div className="flex justify-between">
                                    <div className="h-4 w-20 bg-slate-700/50 rounded animate-pulse" />
                                    <div className="h-4 w-10 bg-slate-700/50 rounded animate-pulse" />
                                </div>
                                <div className="h-4 w-full bg-slate-700/50 rounded-full animate-pulse" />
                            </div>
                        ))}
                    </div>
                ) : (
                    <div className="space-y-8">
                        {Object.entries(stats?.subscriptionBreakdown || {}).map(([plan, count]) => {
                            const percentage = ((count || 0) / (stats?.totalUsers || 1)) * 100;
                            return (
                                <div key={plan} className="group">
                                    <div className="flex justify-between items-end mb-2">
                                        <div className="flex items-center gap-3">
                                            <div className={`w-3 h-3 rounded-full bg-gradient-to-br ${gradientColors[plan] || 'from-slate-500 to-slate-600'}`} />
                                            <span className="text-slate-200 font-medium capitalize text-lg">{plan} Plan</span>
                                        </div>
                                        <div className="text-right">
                                            <span className="text-white font-bold text-lg">{count}</span>
                                            <span className="text-slate-500 text-sm ml-1">users</span>
                                        </div>
                                    </div>
                                    <div className="relative h-4 bg-slate-700/30 rounded-full overflow-hidden backdrop-blur-sm">
                                        <div
                                            className={`absolute inset-y-0 left-0 bg-gradient-to-r ${gradientColors[plan] || 'from-slate-500 to-slate-600'} rounded-full transition-all duration-1000 ease-out group-hover:shadow-[0_0_15px_rgba(124,58,237,0.5)]`}
                                            style={{ width: `${percentage}%` }}
                                        />
                                    </div>
                                </div>
                            );
                        })}

                        {Object.keys(stats?.subscriptionBreakdown || {}).length === 0 && (
                            <div className="text-center py-12 text-slate-500">
                                <p>No subscription data available</p>
                            </div>
                        )}
                    </div>
                )}
            </div>
        </div>
    );
}
