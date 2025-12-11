import { useEffect, useState } from 'react';
import { usersApi } from '../services/api';
import { MagnifyingGlassIcon, FunnelIcon, ArrowDownTrayIcon } from '@heroicons/react/24/outline';

interface User {
    id: string;
    email: string;
    displayName: string;
    photoUrl?: string;
    authProvider: string;
    subscription: { plan: string; expiryDate?: string };
    downloads: number;
    isActive: boolean;
    createdAt: string;
}

export default function Users() {
    const [users, setUsers] = useState<User[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [searchQuery, setSearchQuery] = useState('');
    const [page, setPage] = useState(1);
    const [totalPages, setTotalPages] = useState(1);
    const [planFilter, setPlanFilter] = useState('all');

    useEffect(() => {
        fetchUsers();
    }, [page, planFilter]);

    const fetchUsers = async () => {
        setIsLoading(true);
        try {
            const params: any = { page, limit: 10 };
            if (searchQuery) params.search = searchQuery;
            if (planFilter !== 'all') params.plan = planFilter;

            const response = await usersApi.getAll(params);
            setUsers(response.data.users || []);
            setTotalPages(response.data.pagination?.pages || 1);
        } catch (error) {
            console.error('Failed to fetch users:', error);
        } finally {
            setIsLoading(false);
        }
    };

    const handleSearch = (e: React.FormEvent) => {
        e.preventDefault();
        setPage(1);
        fetchUsers();
    };

    return (
        <div className="space-y-8">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                    <h1 className="text-3xl font-bold text-white tracking-tight">Users Management</h1>
                    <p className="text-slate-400 mt-2">View and manage detailed user information.</p>
                </div>
                <button className="flex items-center gap-2 px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-xl transition-colors border border-white/5">
                    <ArrowDownTrayIcon className="w-5 h-5" />
                    <span>Export CSV</span>
                </button>
            </div>

            {/* Filters Bar */}
            <div className="flex flex-col md:flex-row items-center gap-4 p-4 bg-slate-900/40 backdrop-blur-md border border-white/5 rounded-2xl">
                <form onSubmit={handleSearch} className="relative flex-1 w-full">
                    <MagnifyingGlassIcon className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
                    <input
                        type="text"
                        placeholder="Search by name or email..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        className="w-full pl-11 pr-4 py-2.5 rounded-xl bg-slate-900/50 border border-slate-700/50 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-violet-500/50 focus:border-violet-500/50 transition-all font-medium"
                    />
                </form>

                <div className="flex items-center gap-3 w-full md:w-auto">
                    <div className="relative group">
                        <FunnelIcon className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400 group-focus-within:text-violet-400" />
                        <select
                            value={planFilter}
                            onChange={(e) => setPlanFilter(e.target.value)}
                            className="appearance-none pl-10 pr-8 py-2.5 rounded-xl bg-slate-900/50 border border-slate-700/50 text-white focus:outline-none focus:ring-2 focus:ring-violet-500/50 focus:border-violet-500/50 transition-all font-medium min-w-[160px]"
                        >
                            <option value="all">All Plans</option>
                            <option value="free">Free</option>
                            <option value="weekly">Weekly</option>
                            <option value="monthly">Monthly</option>
                            <option value="yearly">Yearly</option>
                            <option value="lifetime">Lifetime</option>
                        </select>
                    </div>
                </div>
            </div>

            {/* Table */}
            <div className="bg-slate-900/40 backdrop-blur-md rounded-2xl border border-white/5 overflow-hidden">
                <div className="overflow-x-auto">
                    <table className="w-full text-left border-collapse">
                        <thead>
                            <tr className="border-b border-white/5 bg-white/5">
                                <th className="px-6 py-5 text-xs font-semibold text-slate-400 uppercase tracking-wider">User</th>
                                <th className="px-6 py-5 text-xs font-semibold text-slate-400 uppercase tracking-wider">Provider</th>
                                <th className="px-6 py-5 text-xs font-semibold text-slate-400 uppercase tracking-wider">Plan</th>
                                <th className="px-6 py-5 text-xs font-semibold text-slate-400 uppercase tracking-wider">Downloads</th>
                                <th className="px-6 py-5 text-xs font-semibold text-slate-400 uppercase tracking-wider">Joined</th>
                                <th className="px-6 py-5 text-xs font-semibold text-slate-400 uppercase tracking-wider text-right">Actions</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-white/5">
                            {isLoading ? (
                                [...Array(5)].map((_, i) => (
                                    <tr key={i} className="animate-pulse">
                                        <td colSpan={6} className="px-6 py-4">
                                            <div className="h-10 bg-slate-800/50 rounded-xl" />
                                        </td>
                                    </tr>
                                ))
                            ) : users.length === 0 ? (
                                <tr>
                                    <td colSpan={6} className="px-6 py-12 text-center text-slate-400">
                                        <div className="flex flex-col items-center gap-3">
                                            <div className="w-12 h-12 rounded-full bg-slate-800/50 flex items-center justify-center">
                                                <MagnifyingGlassIcon className="w-6 h-6 text-slate-500" />
                                            </div>
                                            <p>No users found matching your criteria</p>
                                        </div>
                                    </td>
                                </tr>
                            ) : (
                                users.map((user) => (
                                    <tr key={user.id} className="group hover:bg-white/[0.02] transition-colors">
                                        <td className="px-6 py-4">
                                            <div className="flex items-center gap-3">
                                                <div className="relative">
                                                    <div className="w-10 h-10 rounded-full bg-gradient-to-br from-violet-500 to-indigo-600 flex items-center justify-center text-white font-bold text-sm shadow-lg shadow-violet-500/20">
                                                        {user.photoUrl ? (
                                                            <img src={user.photoUrl} alt="" className="w-full h-full rounded-full object-cover" />
                                                        ) : (
                                                            user.displayName?.charAt(0) || 'U'
                                                        )}
                                                    </div>
                                                    <div className={`absolute bottom-0 right-0 w-3 h-3 rounded-full border-2 border-slate-900 ${user.isActive ? 'bg-emerald-500' : 'bg-slate-500'}`} />
                                                </div>
                                                <div>
                                                    <p className="text-white font-medium group-hover:text-violet-400 transition-colors">{user.displayName}</p>
                                                    <p className="text-slate-500 text-xs">{user.email}</p>
                                                </div>
                                            </div>
                                        </td>
                                        <td className="px-6 py-4">
                                            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-slate-800 border border-slate-700 text-slate-300 text-xs font-medium capitalize">
                                                <span className={`w-1.5 h-1.5 rounded-full ${user.authProvider === 'google' ? 'bg-blue-500' : 'bg-slate-400'}`} />
                                                {user.authProvider}
                                            </span>
                                        </td>
                                        <td className="px-6 py-4">
                                            <span className={`inline-flex px-2.5 py-1 rounded-lg text-xs font-medium border capitalize ${user.subscription.plan === 'free'
                                                    ? 'bg-slate-800/50 border-slate-700 text-slate-400'
                                                    : 'bg-amber-500/10 border-amber-500/20 text-amber-400'
                                                }`}>
                                                {user.subscription.plan}
                                            </span>
                                        </td>
                                        <td className="px-6 py-4">
                                            <span className="text-slate-300 font-medium font-mono">{user.downloads}</span>
                                        </td>
                                        <td className="px-6 py-4 text-slate-400 text-sm">
                                            {new Date(user.createdAt).toLocaleDateString(undefined, {
                                                year: 'numeric',
                                                month: 'short',
                                                day: 'numeric'
                                            })}
                                        </td>
                                        <td className="px-6 py-4 text-right">
                                            <button className="text-slate-400 hover:text-violet-400 transition-colors font-medium text-sm">
                                                Edit
                                            </button>
                                        </td>
                                    </tr>
                                ))
                            )}
                        </tbody>
                    </table>
                </div>
            </div>

            {/* Pagination */}
            {totalPages > 1 && (
                <div className="flex items-center justify-center gap-2">
                    <button
                        onClick={() => setPage(p => Math.max(1, p - 1))}
                        disabled={page === 1}
                        className="px-4 py-2 rounded-xl bg-slate-900/50 border border-slate-700/50 text-slate-400 disabled:opacity-50 hover:bg-slate-800 transition-colors text-sm font-medium"
                    >
                        Previous
                    </button>
                    <div className="flex gap-1">
                        {[...Array(totalPages)].map((_, i) => (
                            <button
                                key={i}
                                onClick={() => setPage(i + 1)}
                                className={`w-9 h-9 rounded-xl text-sm font-bold transition-all ${page === i + 1
                                        ? 'bg-violet-600 text-white shadow-lg shadow-violet-500/30'
                                        : 'bg-slate-900/50 text-slate-500 hover:bg-slate-800 border border-slate-700/50'
                                    }`}
                            >
                                {i + 1}
                            </button>
                        ))}
                    </div>
                    <button
                        onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                        disabled={page === totalPages}
                        className="px-4 py-2 rounded-xl bg-slate-900/50 border border-slate-700/50 text-slate-400 disabled:opacity-50 hover:bg-slate-800 transition-colors text-sm font-medium"
                    >
                        Next
                    </button>
                </div>
            )}
        </div>
    );
}

