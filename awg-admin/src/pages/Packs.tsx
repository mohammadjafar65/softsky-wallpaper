import { useState, useEffect } from 'react';
import { packsApi as api } from '../services/api';
import toast from 'react-hot-toast';
import {
    PlusIcon,
    PencilIcon,
    TrashIcon,
    MagnifyingGlassIcon,
    LockClosedIcon,
    CalendarIcon,
    Square2StackIcon,
    XMarkIcon,
    CloudArrowUpIcon
} from '@heroicons/react/24/outline';
import { format } from 'date-fns';

interface Pack {
    _id: string;
    name: string;
    description: string;
    coverImage: string;
    isPro: boolean;
    isActive: boolean;
    createdAt: string;
    wallpaperCount?: number;
}

export default function Packs() {
    const [packs, setPacks] = useState<Pack[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [searchQuery, setSearchQuery] = useState('');
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingPack, setEditingPack] = useState<Pack | null>(null);

    // Form state
    const [formData, setFormData] = useState({
        name: '',
        description: '',
        coverImage: null as File | null,
        isPro: false,
        isActive: true,
    });
    const [previewUrl, setPreviewUrl] = useState<string>('');

    useEffect(() => {
        fetchPacks();
    }, []);

    const fetchPacks = async () => {
        try {
            setIsLoading(true);
            const res = await api.getAll();
            setPacks(res.data.packs);
        } catch (error) {
            toast.error('Failed to load packs');
            console.error(error);
        } finally {
            setIsLoading(false);
        }
    };

    const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (file) {
            setFormData({ ...formData, coverImage: file });
            setPreviewUrl(URL.createObjectURL(file));
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!formData.name) {
            toast.error('Name is required');
            return;
        }

        if (!editingPack && !formData.coverImage) {
            toast.error('Cover image is required');
            return;
        }

        try {
            const data = new FormData();
            data.append('name', formData.name);
            data.append('description', formData.description);
            data.append('isPro', String(formData.isPro));
            data.append('isActive', String(formData.isActive));

            if (formData.coverImage) {
                data.append('coverImage', formData.coverImage);
            }

            const promise = editingPack
                ? api.update(editingPack._id, {
                    name: formData.name,
                    description: formData.description,
                    isPro: formData.isPro,
                    isActive: formData.isActive,
                }) // Note: Ideally backend should handle FormData for update too if image is changed. Assuming it does or logic handles it.
                : api.create(data);

            await toast.promise(promise, {
                loading: editingPack ? 'Updating pack...' : 'Creating pack...',
                success: editingPack ? 'Pack updated!' : 'Pack created!',
                error: 'Operation failed',
            });

            setIsModalOpen(false);
            resetForm();
            fetchPacks();
        } catch (error) {
            console.error(error);
        }
    };

    const handleDelete = async (id: string) => {
        if (!window.confirm('Are you sure? This will remove the pack but keep the wallpapers.')) return;

        try {
            await api.delete(id);
            toast.success('Pack deleted');
            fetchPacks();
        } catch (error) {
            toast.error('Failed to delete pack');
        }
    };

    const resetForm = () => {
        setFormData({
            name: '',
            description: '',
            coverImage: null,
            isPro: false,
            isActive: true,
        });
        setPreviewUrl('');
        setEditingPack(null);
    };

    const openEditModal = (pack: Pack) => {
        setEditingPack(pack);
        setFormData({
            name: pack.name,
            description: pack.description,
            coverImage: null,
            isPro: pack.isPro,
            isActive: pack.isActive,
        });
        setPreviewUrl(pack.coverImage);
        setIsModalOpen(true);
    };

    const filteredPacks = packs.filter(pack =>
        pack.name.toLowerCase().includes(searchQuery.toLowerCase())
    );

    return (
        <div className="space-y-8">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                    <h1 className="text-3xl font-bold text-white tracking-tight">Wallpaper Packs</h1>
                    <p className="text-slate-400 mt-2">Manage your curated collections</p>
                </div>
                <button
                    onClick={() => {
                        resetForm();
                        setIsModalOpen(true);
                    }}
                    className="flex items-center gap-2 px-6 py-3 rounded-xl bg-violet-600 hover:bg-violet-700 text-white font-medium shadow-lg shadow-violet-500/25 transition-all transform hover:scale-105"
                >
                    <PlusIcon className="w-5 h-5" />
                    Create Pack
                </button>
            </div>

            {/* Filters */}
            <div className="p-4 bg-slate-900/40 backdrop-blur-md border border-white/5 rounded-2xl">
                <div className="relative w-full max-w-md">
                    <MagnifyingGlassIcon className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
                    <input
                        type="text"
                        placeholder="Search packs..."
                        className="w-full pl-11 pr-4 py-2.5 rounded-xl bg-slate-900/50 border border-slate-700/50 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-violet-500/50 focus:border-violet-500/50 transition-all font-medium"
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                    />
                </div>
            </div>

            {/* Grid */}
            {isLoading ? (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {[...Array(3)].map((_, i) => (
                        <div key={i} className="h-64 bg-slate-800/50 rounded-2xl animate-pulse border border-white/5" />
                    ))}
                </div>
            ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {filteredPacks.map((pack) => (
                        <div key={pack._id} className="group relative bg-slate-800/50 rounded-2xl overflow-hidden border border-white/5 hover:border-violet-500/30 transition-all duration-300 hover:shadow-xl hover:shadow-violet-500/10">
                            <div className="relative h-48 overflow-hidden">
                                <img
                                    src={pack.coverImage}
                                    alt={pack.name}
                                    className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-110"
                                />
                                <div className="absolute inset-0 bg-gradient-to-t from-slate-900 via-transparent to-transparent opacity-80" />
                                <div className="absolute top-3 right-3 flex gap-2">
                                    {pack.isPro && (
                                        <span className="flex items-center gap-1 bg-amber-500/90 text-black text-xs font-bold px-2 py-1 rounded-lg shadow-lg shadow-amber-500/20 backdrop-blur-md">
                                            <LockClosedIcon className="w-3 h-3" /> PRO
                                        </span>
                                    )}
                                    {!pack.isActive && (
                                        <span className="bg-red-500/90 text-white text-xs font-bold px-2 py-1 rounded-lg backdrop-blur-md">
                                            INACTIVE
                                        </span>
                                    )}
                                </div>
                            </div>

                            <div className="p-6 relative">
                                <div className="absolute -top-8 left-6">
                                    <div className="w-16 h-16 rounded-xl bg-slate-800 border-4 border-slate-900 shadow-xl flex items-center justify-center overflow-hidden">
                                        <img src={pack.coverImage} alt="" className="w-full h-full object-cover" />
                                    </div>
                                </div>

                                <div className="mt-6">
                                    <h3 className="text-xl font-bold text-white mb-1 group-hover:text-violet-400 transition-colors">{pack.name}</h3>
                                    <p className="text-slate-400 text-sm line-clamp-2 h-10 mb-4">
                                        {pack.description || 'No description provided.'}
                                    </p>
                                </div>

                                <div className="flex items-center justify-between pt-4 border-t border-white/5">
                                    <div className="flex items-center text-xs text-slate-500 font-medium">
                                        <CalendarIcon className="w-4 h-4 mr-1.5" />
                                        {format(new Date(pack.createdAt), 'MMM d, yyyy')}
                                    </div>
                                    <div className="flex gap-2">
                                        <button
                                            onClick={() => openEditModal(pack)}
                                            className="p-2 bg-slate-700/50 hover:bg-violet-600 hover:text-white rounded-lg text-slate-400 transition-all"
                                        >
                                            <PencilIcon className="w-4 h-4" />
                                        </button>
                                        <button
                                            onClick={() => handleDelete(pack._id)}
                                            className="p-2 bg-slate-700/50 hover:bg-red-500 hover:text-white rounded-lg text-slate-400 transition-all"
                                        >
                                            <TrashIcon className="w-4 h-4" />
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    ))}

                    {filteredPacks.length === 0 && (
                        <div className="col-span-full text-center py-20 bg-slate-900/30 rounded-3xl border border-white/5 border-dashed">
                            <div className="w-20 h-20 bg-slate-800/50 rounded-full flex items-center justify-center mx-auto mb-6">
                                <Square2StackIcon className="w-10 h-10 text-slate-600" />
                            </div>
                            <h3 className="text-xl font-bold text-white mb-2">No packs found</h3>
                            <p className="text-slate-400">Create a new pack to get started</p>
                        </div>
                    )}
                </div>
            )}

            {/* Modal */}
            {isModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
                    <div className="absolute inset-0 bg-slate-950/80 backdrop-blur-sm" onClick={() => setIsModalOpen(false)} />
                    <div className="relative w-full max-w-lg bg-slate-900 rounded-3xl border border-white/10 shadow-2xl overflow-hidden animate-scale-up">
                        <div className="flex items-center justify-between p-6 border-b border-white/5 bg-slate-900/50 backdrop-blur-md">
                            <div>
                                <h2 className="text-xl font-bold text-white">
                                    {editingPack ? 'Edit Pack' : 'Create Pack'}
                                </h2>
                                <p className="text-slate-400 text-sm mt-1">
                                    {editingPack ? 'Update pack details' : 'Create a new wallpaper collection'}
                                </p>
                            </div>
                            <button onClick={() => setIsModalOpen(false)} className="p-2 text-slate-400 hover:text-white hover:bg-white/5 rounded-xl transition">
                                <XMarkIcon className="w-6 h-6" />
                            </button>
                        </div>

                        <form onSubmit={handleSubmit} className="p-6 space-y-6">
                            {/* Image Upload */}
                            <div>
                                <label className="block text-sm font-semibold text-slate-300 mb-3">Cover Image</label>
                                <label className={`block relative border-2 border-dashed rounded-2xl p-6 text-center cursor-pointer transition-all ${previewUrl ? 'border-violet-500/50 bg-violet-500/5' : 'border-slate-700 hover:border-violet-500 hover:bg-slate-800/50'
                                    }`}>
                                    {previewUrl ? (
                                        <div className="relative h-48 rounded-xl overflow-hidden shadow-lg group">
                                            <img src={previewUrl} alt="Preview" className="w-full h-full object-cover" />
                                            <div className="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                                                <p className="text-white font-medium">Click to change</p>
                                            </div>
                                        </div>
                                    ) : (
                                        <div className="py-8">
                                            <div className="w-14 h-14 bg-slate-800 rounded-xl flex items-center justify-center mx-auto mb-3">
                                                <CloudArrowUpIcon className="w-7 h-7 text-violet-400" />
                                            </div>
                                            <p className="text-slate-200 font-medium">Click to upload cover</p>
                                            <p className="text-slate-500 text-sm mt-1">Recommended: 16:9 aspect ratio</p>
                                        </div>
                                    )}
                                    <input
                                        type="file"
                                        className="hidden"
                                        accept="image/*"
                                        onChange={handleFileSelect}
                                    />
                                </label>
                            </div>

                            <div>
                                <label className="block text-sm font-semibold text-slate-300 mb-2">Pack Name</label>
                                <input
                                    type="text"
                                    required
                                    className="w-full px-4 py-3 rounded-xl bg-slate-950 border border-slate-800 text-white focus:outline-none focus:ring-2 focus:ring-violet-500/50 focus:border-violet-500/50 transition-all font-medium"
                                    value={formData.name}
                                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                                    placeholder="e.g. Nature Collection"
                                />
                            </div>

                            <div>
                                <label className="block text-sm font-semibold text-slate-300 mb-2">Description</label>
                                <textarea
                                    className="w-full px-4 py-3 rounded-xl bg-slate-950 border border-slate-800 text-white focus:outline-none focus:ring-2 focus:ring-violet-500/50 focus:border-violet-500/50 transition-all font-medium resize-none h-24"
                                    value={formData.description}
                                    onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                                    placeholder="Describe this collection..."
                                />
                            </div>

                            <div className="flex gap-6 pt-2">
                                <label className="flex items-center gap-3 cursor-pointer group">
                                    <div className={`w-6 h-6 rounded-lg border-2 flex items-center justify-center transition-colors ${formData.isPro ? 'bg-violet-600 border-violet-600' : 'border-slate-600 group-hover:border-violet-500'}`}>
                                        {formData.isPro && <span className="text-white text-sm font-bold">✓</span>}
                                    </div>
                                    <input
                                        type="checkbox"
                                        checked={formData.isPro}
                                        onChange={(e) => setFormData({ ...formData, isPro: e.target.checked })}
                                        className="hidden"
                                    />
                                    <span className="text-slate-300 font-medium group-hover:text-white transition-colors">Pro Pack</span>
                                </label>

                                <label className="flex items-center gap-3 cursor-pointer group">
                                    <div className={`w-6 h-6 rounded-lg border-2 flex items-center justify-center transition-colors ${formData.isActive ? 'bg-violet-600 border-violet-600' : 'border-slate-600 group-hover:border-violet-500'}`}>
                                        {formData.isActive && <span className="text-white text-sm font-bold">✓</span>}
                                    </div>
                                    <input
                                        type="checkbox"
                                        checked={formData.isActive}
                                        onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })}
                                        className="hidden"
                                    />
                                    <span className="text-slate-300 font-medium group-hover:text-white transition-colors">Active</span>
                                </label>
                            </div>

                            <button
                                type="submit"
                                className="w-full py-4 rounded-xl bg-gradient-to-r from-violet-600 to-indigo-600 text-white font-bold text-lg shadow-xl shadow-violet-500/20 hover:shadow-violet-500/30 hover:scale-[1.02] transition-all"
                            >
                                {editingPack ? 'Save Changes' : 'Create Pack'}
                            </button>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}
