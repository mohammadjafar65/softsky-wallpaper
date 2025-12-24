import { useState, useEffect } from 'react';
import {
    BellIcon,
    PaperAirplaneIcon,
    UserIcon,
    UsersIcon,
    CheckCircleIcon,
    XCircleIcon,
} from '@heroicons/react/24/outline';
import { usersApi, notificationsApi } from '../services/api';

interface User {
    id: string;
    email: string;
    displayName: string;
}

export default function Notifications() {
    const [title, setTitle] = useState('');
    const [message, setMessage] = useState('');
    const [targetType, setTargetType] = useState<'all' | 'user'>('all');
    const [selectedUserId, setSelectedUserId] = useState('');
    const [users, setUsers] = useState<User[]>([]);
    const [isLoading, setIsLoading] = useState(false);
    const [loadingUsers, setLoadingUsers] = useState(false);
    const [result, setResult] = useState<{
        type: 'success' | 'error';
        message: string;
    } | null>(null);

    useEffect(() => {
        if (targetType === 'user') {
            fetchUsers();
        }
    }, [targetType]);

    const fetchUsers = async () => {
        try {
            setLoadingUsers(true);
            const response = await usersApi.getAll({ limit: 1000 });
            setUsers(response.data.users || []);
        } catch (error) {
            console.error('Failed to fetch users:', error);
        } finally {
            setLoadingUsers(false);
        }
    };

    const handleSend = async () => {
        if (!title.trim() || !message.trim()) {
            setResult({
                type: 'error',
                message: 'Please fill in both title and message',
            });
            return;
        }

        if (targetType === 'user' && !selectedUserId) {
            setResult({
                type: 'error',
                message: 'Please select a user',
            });
            return;
        }

        try {
            setIsLoading(true);
            setResult(null);

            if (targetType === 'all') {
                const response = await notificationsApi.sendToAll({
                    title,
                    message,
                });

                setResult({
                    type: 'success',
                    message: `Notification sent to ${response.data.successCount} users. ${response.data.failureCount} failed.`,
                });
            } else {
                await notificationsApi.sendToUser({
                    userId: selectedUserId,
                    title,
                    message,
                });

                setResult({
                    type: 'success',
                    message: 'Notification sent successfully!',
                });
            }

            // Clear form
            setTitle('');
            setMessage('');
            setSelectedUserId('');
        } catch (error: any) {
            setResult({
                type: 'error',
                message: error.response?.data?.error || 'Failed to send notification',
            });
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="space-y-8">
            {/* Header */}
            <div>
                <h1 className="text-3xl font-bold text-white flex items-center gap-3">
                    <BellIcon className="w-8 h-8" />
                    Push Notifications
                </h1>
                <p className="text-slate-400 mt-2 text-lg">
                    Send push notifications to your app users
                </p>
            </div>

            {/* Main Card */}
            <div className="rounded-3xl bg-slate-900/40 border border-white/5 p-8 backdrop-blur-md shadow-2xl">
                <div className="space-y-6">
                    {/* Target Selection */}
                    <div>
                        <label className="block text-sm font-medium text-slate-300 mb-3">
                            Target Audience
                        </label>
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <button
                                onClick={() => setTargetType('all')}
                                className={`flex items-center gap-4 p-6 rounded-2xl border-2 transition-all duration-300 ${targetType === 'all'
                                    ? 'border-violet-500 bg-violet-500/10'
                                    : 'border-white/5 bg-white/5 hover:bg-white/10'
                                    }`}
                            >
                                <div className={`p-3 rounded-xl ${targetType === 'all' ? 'bg-violet-500/20' : 'bg-white/5'}`}>
                                    <UsersIcon className="w-6 h-6 text-violet-400" />
                                </div>
                                <div className="text-left">
                                    <h3 className="text-lg font-semibold text-white">All Users</h3>
                                    <p className="text-sm text-slate-400">Broadcast to everyone</p>
                                </div>
                            </button>

                            <button
                                onClick={() => setTargetType('user')}
                                className={`flex items-center gap-4 p-6 rounded-2xl border-2 transition-all duration-300 ${targetType === 'user'
                                    ? 'border-blue-500 bg-blue-500/10'
                                    : 'border-white/5 bg-white/5 hover:bg-white/10'
                                    }`}
                            >
                                <div className={`p-3 rounded-xl ${targetType === 'user' ? 'bg-blue-500/20' : 'bg-white/5'}`}>
                                    <UserIcon className="w-6 h-6 text-blue-400" />
                                </div>
                                <div className="text-left">
                                    <h3 className="text-lg font-semibold text-white">Specific User</h3>
                                    <p className="text-sm text-slate-400">Send to one person</p>
                                </div>
                            </button>
                        </div>
                    </div>

                    {/* User Selection (if specific user) */}
                    {targetType === 'user' && (
                        <div>
                            <label className="block text-sm font-medium text-slate-300 mb-3">
                                Select User
                            </label>
                            <select
                                value={selectedUserId}
                                onChange={(e) => setSelectedUserId(e.target.value)}
                                disabled={loadingUsers}
                                className="w-full px-4 py-3 rounded-xl bg-slate-800 border border-white/10 text-white focus:outline-none focus:ring-2 focus:ring-violet-500 focus:border-transparent transition-all"
                            >
                                <option value="">
                                    {loadingUsers ? 'Loading users...' : 'Choose a user'}
                                </option>
                                {users.map((user) => (
                                    <option key={user.id} value={user.id}>
                                        {user.displayName} ({user.email})
                                    </option>
                                ))}
                            </select>
                        </div>
                    )}

                    {/* Title Input */}
                    <div>
                        <label className="block text-sm font-medium text-slate-300 mb-3">
                            Notification Title
                        </label>
                        <input
                            type="text"
                            value={title}
                            onChange={(e) => setTitle(e.target.value)}
                            placeholder="e.g., New Wallpapers Available!"
                            maxLength={50}
                            className="w-full px-4 py-3 rounded-xl bg-slate-800 border border-white/10 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-violet-500 focus:border-transparent transition-all"
                        />
                        <p className="text-xs text-slate-500 mt-2">
                            {title.length}/50 characters
                        </p>
                    </div>

                    {/* Message Input */}
                    <div>
                        <label className="block text-sm font-medium text-slate-300 mb-3">
                            Message
                        </label>
                        <textarea
                            value={message}
                            onChange={(e) => setMessage(e.target.value)}
                            placeholder="e.g., Check out 10 new premium wallpapers added today!"
                            maxLength={200}
                            rows={4}
                            className="w-full px-4 py-3 rounded-xl bg-slate-800 border border-white/10 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-violet-500 focus:border-transparent transition-all resize-none"
                        />
                        <p className="text-xs text-slate-500 mt-2">
                            {message.length}/200 characters
                        </p>
                    </div>

                    {/* Result Message */}
                    {result && (
                        <div
                            className={`flex items-center gap-3 p-4 rounded-xl ${result.type === 'success'
                                ? 'bg-emerald-500/10 border border-emerald-500/20'
                                : 'bg-rose-500/10 border border-rose-500/20'
                                }`}
                        >
                            {result.type === 'success' ? (
                                <CheckCircleIcon className="w-5 h-5 text-emerald-400 flex-shrink-0" />
                            ) : (
                                <XCircleIcon className="w-5 h-5 text-rose-400 flex-shrink-0" />
                            )}
                            <p
                                className={`text-sm ${result.type === 'success' ? 'text-emerald-300' : 'text-rose-300'
                                    }`}
                            >
                                {result.message}
                            </p>
                        </div>
                    )}

                    {/* Send Button */}
                    <button
                        onClick={handleSend}
                        disabled={isLoading || !title.trim() || !message.trim()}
                        className="w-full flex items-center justify-center gap-3 px-6 py-4 rounded-xl bg-gradient-to-r from-violet-600 to-purple-600 text-white font-semibold hover:from-violet-700 hover:to-purple-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-300 shadow-lg hover:shadow-violet-500/25"
                    >
                        {isLoading ? (
                            <>
                                <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                                Sending...
                            </>
                        ) : (
                            <>
                                <PaperAirplaneIcon className="w-5 h-5" />
                                Send Notification
                            </>
                        )}
                    </button>
                </div>
            </div>

            {/* Info Cards */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="p-6 rounded-2xl bg-blue-500/5 border border-blue-500/20">
                    <h3 className="text-lg font-semibold text-blue-400 mb-2">💡 Tips</h3>
                    <ul className="space-y-2 text-sm text-slate-400">
                        <li>• Keep titles short and engaging (max 50 chars)</li>
                        <li>• Use clear, actionable messages</li>
                        <li>• Test with yourself before broadcasting</li>
                    </ul>
                </div>

                <div className="p-6 rounded-2xl bg-amber-500/5 border border-amber-500/20">
                    <h3 className="text-lg font-semibold text-amber-400 mb-2">⚠️  Note</h3>
                    <ul className="space-y-2 text-sm text-slate-400">
                        <li>• Users must have the app installed</li>
                        <li>• Notifications require user permission</li>
                        <li>• Delivery is not guaranteed 100%</li>
                    </ul>
                </div>
            </div>
        </div>
    );
}
