import { useState, useEffect } from 'react';
import { usersApi } from '../services/api';
import { XMarkIcon } from '@heroicons/react/24/outline';

interface EditUserModalProps {
    isOpen: boolean;
    onClose: () => void;
    user: any;
    onSuccess: () => void;
}

export default function EditUserModal({ isOpen, onClose, user, onSuccess }: EditUserModalProps) {
    const [isLoading, setIsLoading] = useState(false);
    const [formData, setFormData] = useState({
        displayName: '',
        isActive: true,
        plan: 'free',
        expiryDate: '',
    });

    useEffect(() => {
        if (user) {
            setFormData({
                displayName: user.displayName || '',
                isActive: user.isActive,
                plan: user.subscription?.plan || 'free',
                expiryDate: user.subscription?.expiryDate 
                    ? new Date(user.subscription.expiryDate).toISOString().split('T')[0] 
                    : '',
            });
        }
    }, [user]);

    if (!isOpen) return null;

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setIsLoading(true);

        try {
            await usersApi.update(user.id, {
                displayName: formData.displayName,
                isActive: formData.isActive,
                subscription: {
                    plan: formData.plan,
                    expiryDate: formData.expiryDate ? new Date(formData.expiryDate).toISOString() : null,
                }
            });
            onSuccess();
            onClose();
        } catch (error) {
            console.error('Failed to update user:', error);
            alert('Failed to update user');
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
            <div className="w-full max-w-md bg-slate-900 border border-white/10 rounded-2xl shadow-xl overflow-hidden animate-in fade-in zoom-in duration-200">
                <div className="flex items-center justify-between p-4 border-b border-white/5 bg-white/5">
                    <h3 className="text-lg font-semibold text-white">Edit User</h3>
                    <button onClick={onClose} className="text-slate-400 hover:text-white transition-colors">
                        <XMarkIcon className="w-6 h-6" />
                    </button>
                </div>

                <form onSubmit={handleSubmit} className="p-6 space-y-4">
                    {/* Display Name */}
                    <div>
                        <label className="block text-sm font-medium text-slate-400 mb-1">Display Name</label>
                        <input
                            type="text"
                            value={formData.displayName}
                            onChange={(e) => setFormData({ ...formData, displayName: e.target.value })}
                            className="w-full px-4 py-2 rounded-xl bg-slate-800/50 border border-slate-700/50 text-white focus:ring-2 focus:ring-violet-500/50 focus:border-violet-500/50 outline-none transition-all"
                            required
                        />
                    </div>

                    {/* Active Status */}
                    <div className="flex items-center gap-3">
                        <label className="text-sm font-medium text-slate-400">Account Status</label>
                        <div className="flex items-center gap-2">
                             <input
                                type="checkbox"
                                checked={formData.isActive}
                                onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })}
                                className="w-5 h-5 rounded border-slate-700 bg-slate-800 text-violet-600 focus:ring-violet-500/50"
                            />
                            <span className={formData.isActive ? "text-emerald-400 text-sm" : "text-slate-500 text-sm"}>
                                {formData.isActive ? "Active" : "Inactive"}
                            </span>
                        </div>
                    </div>

                    <div className="w-full h-px bg-white/5 my-2" />

                    {/* Subscription Plan */}
                    <div>
                        <label className="block text-sm font-medium text-slate-400 mb-1">Subscription Plan</label>
                        <select
                            value={formData.plan}
                            onChange={(e) => setFormData({ ...formData, plan: e.target.value })}
                            className="w-full px-4 py-2 rounded-xl bg-slate-800/50 border border-slate-700/50 text-white focus:ring-2 focus:ring-violet-500/50 focus:border-violet-500/50 outline-none transition-all appearance-none"
                        >
                            <option value="free">Free</option>
                            <option value="monthly">Monthly</option>
                            <option value="annual">Annual</option>
                            <option value="lifetime">Lifetime</option>
                        </select>
                    </div>

                    {/* Expiry Date */}
                    {formData.plan !== 'free' && formData.plan !== 'lifetime' && (
                        <div>
                            <label className="block text-sm font-medium text-slate-400 mb-1">Expiry Date</label>
                            <input
                                type="date"
                                value={formData.expiryDate}
                                onChange={(e) => setFormData({ ...formData, expiryDate: e.target.value })}
                                className="w-full px-4 py-2 rounded-xl bg-slate-800/50 border border-slate-700/50 text-white focus:ring-2 focus:ring-violet-500/50 focus:border-violet-500/50 outline-none transition-all calendar-picker-indicator-white"
                                required
                            />
                        </div>
                    )}
                    
                    {/* Lifetime Note */}
                     {formData.plan === 'lifetime' && (
                        <div className="p-3 bg-violet-500/10 border border-violet-500/20 rounded-xl text-xs text-violet-300">
                            Lifetime subscription does not expire.
                        </div>
                    )}

                    <div className="flex gap-3 mt-6">
                        <button
                            type="button"
                            onClick={onClose}
                            className="flex-1 px-4 py-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 font-medium transition-colors"
                        >
                            Cancel
                        </button>
                        <button
                            type="submit"
                            disabled={isLoading}
                            className="flex-1 px-4 py-2 rounded-xl bg-violet-600 hover:bg-violet-500 text-white font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                            {isLoading ? 'Saving...' : 'Save Changes'}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
}
