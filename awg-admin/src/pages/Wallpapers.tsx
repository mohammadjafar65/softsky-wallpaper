import { useEffect, useState, useRef } from 'react';
import { wallpapersApi, categoriesApi, packsApi } from '../services/api';
import toast from 'react-hot-toast';
import {
    PlusIcon,
    MagnifyingGlassIcon,
    TrashIcon,
    XMarkIcon,
    PhotoIcon,
    CloudArrowUpIcon,
    ArrowDownTrayIcon,
} from '@heroicons/react/24/outline';

interface Wallpaper {
    id: string;
    title: string;
    imageUrl: string;
    thumbnailUrl: string;
    category: { name: string; slug: string };
    isPro: boolean;
    downloads: number;
}

interface Category {
    id: string;
    name: string;
    slug: string;
}

interface Pack {
    _id: string;
    name: string;
}

export default function Wallpapers() {
    const [wallpapers, setWallpapers] = useState<Wallpaper[]>([]);
    const [categories, setCategories] = useState<Category[]>([]);
    const [packs, setPacks] = useState<Pack[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [searchQuery, setSearchQuery] = useState('');
    const [selectedCategory, setSelectedCategory] = useState('all');
    const [page, setPage] = useState(1);
    const [totalPages, setTotalPages] = useState(1);

    // Form state
    const [formData, setFormData] = useState({
        title: '',
        category: '',
        tags: '',
        isPro: false,
        isWide: false,
        packId: '',
    });
    const [selectedFile, setSelectedFile] = useState<File | null>(null);
    const [previewUrl, setPreviewUrl] = useState<string>('');
    const [isSubmitting, setIsSubmitting] = useState(false);
    const fileInputRef = useRef<HTMLInputElement>(null);

    useEffect(() => {
        fetchCategories();
        fetchPacks();
    }, []);

    useEffect(() => {
        fetchWallpapers();
    }, [page, selectedCategory]);

    const fetchCategories = async () => {
        try {
            const response = await categoriesApi.getAll();
            setCategories(response.data.categories || []);
        } catch (error) {
            console.error('Failed to fetch categories:', error);
        }
    };

    const fetchPacks = async () => {
        try {
            const response = await packsApi.getAll();
            setPacks(response.data.packs || []);
        } catch (error) {
            console.error('Failed to fetch packs:', error);
        }
    };

    const fetchWallpapers = async () => {
        setIsLoading(true);
        try {
            const params: any = { page, limit: 12 };
            if (selectedCategory !== 'all') params.category = selectedCategory;

            const response = await wallpapersApi.getAll(params);
            setWallpapers(response.data.wallpapers || []);
            setTotalPages(response.data.pagination?.pages || 1);
        } catch (error) {
            console.error('Failed to fetch wallpapers:', error);
        } finally {
            setIsLoading(false);
        }
    };

    const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (file) {
            setSelectedFile(file);
            setPreviewUrl(URL.createObjectURL(file));
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!selectedFile || !formData.title || !formData.category) {
            toast.error('Please fill all required fields');
            return;
        }

        setIsSubmitting(true);
        try {
            const data = new FormData();
            data.append('image', selectedFile);
            data.append('title', formData.title);
            data.append('category', formData.category);
            data.append('tags', formData.tags);
            data.append('isPro', formData.isPro.toString());
            data.append('isWide', formData.isWide.toString());
            if (formData.packId) data.append('packId', formData.packId);

            await wallpapersApi.create(data);
            toast.success('Wallpaper uploaded successfully!');
            setShowModal(false);
            resetForm();
            fetchWallpapers();
        } catch (error: any) {
            toast.error(error.response?.data?.error || 'Failed to upload wallpaper');
        } finally {
            setIsSubmitting(false);
        }
    };

    const handleDelete = async (id: string) => {
        if (!confirm('Are you sure you want to delete this wallpaper?')) return;

        try {
            await wallpapersApi.delete(id);
            toast.success('Wallpaper deleted successfully!');
            fetchWallpapers();
        } catch (error) {
            toast.error('Failed to delete wallpaper');
        }
    };

    const resetForm = () => {
        setFormData({ title: '', category: '', tags: '', isPro: false, isWide: false, packId: '' });
        setSelectedFile(null);
        setPreviewUrl('');
    };

    return (
        <div className="space-y-8">
            {/* Header */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                    <h1 className="text-3xl font-bold text-white tracking-tight">Wallpapers</h1>
                    <p className="text-slate-400 mt-2">Manage your wallpaper collection</p>
                </div>
                <button
                    onClick={() => setShowModal(true)}
                    className="flex items-center gap-2 px-6 py-3 rounded-xl bg-violet-600 hover:bg-violet-700 text-white font-medium shadow-lg shadow-violet-500/25 transition-all transform hover:scale-105"
                >
                    <PlusIcon className="w-5 h-5" />
                    Upload New
                </button>
            </div>

            {/* Filters Bar */}
            <div className="flex flex-col md:flex-row items-center gap-4 p-4 bg-slate-900/40 backdrop-blur-md border border-white/5 rounded-2xl">
                <div className="relative flex-1 w-full">
                    <MagnifyingGlassIcon className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
                    <input
                        type="text"
                        placeholder="Search wallpapers..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        className="w-full pl-11 pr-4 py-2.5 rounded-xl bg-slate-900/50 border border-slate-700/50 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-violet-500/50 focus:border-violet-500/50 transition-all font-medium"
                    />
                </div>
                <select
                    value={selectedCategory}
                    onChange={(e) => setSelectedCategory(e.target.value)}
                    className="w-full md:w-auto px-4 py-2.5 rounded-xl bg-slate-900/50 border border-slate-700/50 text-white focus:outline-none focus:ring-2 focus:ring-violet-500/50 focus:border-violet-500/50 transition-all font-medium appearance-none min-w-[180px]"
                >
                    <option value="all">All Categories</option>
                    {categories.map((cat) => (
                        <option key={cat.id} value={cat.slug}>{cat.name}</option>
                    ))}
                </select>
            </div>

            {/* Grid */}
            {isLoading ? (
                <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
                    {[...Array(8)].map((_, i) => (
                        <div key={i} className="aspect-[9/16] bg-slate-800/50 rounded-2xl animate-pulse border border-white/5" />
                    ))}
                </div>
            ) : wallpapers.length === 0 ? (
                <div className="text-center py-20 bg-slate-900/30 rounded-3xl border border-white/5 border-dashed">
                    <div className="w-20 h-20 bg-slate-800/50 rounded-full flex items-center justify-center mx-auto mb-6">
                        <PhotoIcon className="w-10 h-10 text-slate-600" />
                    </div>
                    <h3 className="text-xl font-bold text-white mb-2">No wallpapers found</h3>
                    <p className="text-slate-400">Upload your first wallpaper to get started</p>
                </div>
            ) : (
                <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
                    {wallpapers.map((wallpaper) => (
                        <div
                            key={wallpaper.id}
                            className="group relative aspect-[9/16] rounded-2xl overflow-hidden bg-slate-800 shadow-2xl transition-all duration-300 hover:shadow-violet-500/10 hover:-translate-y-1"
                        >
                            <img
                                src={wallpaper.thumbnailUrl}
                                alt={wallpaper.title}
                                className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-110"
                            />
                            {/* Overlay */}
                            <div className="absolute inset-0 bg-gradient-to-t from-slate-950 via-slate-950/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300">
                                <div className="absolute bottom-0 left-0 right-0 p-5 transform translate-y-4 group-hover:translate-y-0 transition-transform duration-300">
                                    <h3 className="text-white font-bold truncate text-lg shadow-sm">{wallpaper.title}</h3>
                                    <div className="flex items-center justify-between mt-2">
                                        <span className="text-slate-300 text-sm font-medium bg-black/30 px-2 py-0.5 rounded-lg backdrop-blur-sm">
                                            {wallpaper.category?.name}
                                        </span>
                                        {wallpaper.isPro && (
                                            <span className="px-2 py-0.5 text-xs font-bold bg-amber-500 text-black rounded-md shadow-lg shadow-amber-500/20">PRO</span>
                                        )}
                                    </div>
                                    <div className="flex items-center gap-2 mt-3 text-slate-400 text-xs font-medium">
                                        <ArrowDownTrayIcon className="w-3.5 h-3.5" />
                                        <span>{wallpaper.downloads} downloads</span>
                                    </div>
                                </div>
                                <div className="absolute top-4 right-4 flex gap-2 transform -translate-y-4 group-hover:translate-y-0 transition-transform duration-300 delay-75">
                                    <button
                                        onClick={() => handleDelete(wallpaper.id)}
                                        className="p-2.5 bg-red-500/90 backdrop-blur-md rounded-xl text-white hover:bg-red-600 transition shadow-lg shadow-red-500/20"
                                    >
                                        <TrashIcon className="w-4 h-4" />
                                    </button>
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            )}

            {/* Pagination */}
            {totalPages > 1 && (
                <div className="flex items-center justify-center gap-2 mt-8">
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

            {/* Upload Modal */}
            {showModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
                    <div className="absolute inset-0 bg-slate-950/80 backdrop-blur-sm" onClick={() => setShowModal(false)} />
                    <div className="relative w-full max-w-2xl bg-slate-900 rounded-3xl border border-white/10 shadow-2xl overflow-hidden max-h-[90vh] flex flex-col animate-scale-up">
                        <div className="flex items-center justify-between p-6 border-b border-white/5 bg-slate-900/50 backdrop-blur-md">
                            <div>
                                <h2 className="text-xl font-bold text-white">Upload Wallpaper</h2>
                                <p className="text-slate-400 text-sm mt-1">Add a new wallpaper to your collection</p>
                            </div>
                            <button onClick={() => { setShowModal(false); resetForm(); }} className="p-2 text-slate-400 hover:text-white hover:bg-white/5 rounded-xl transition">
                                <XMarkIcon className="w-6 h-6" />
                            </button>
                        </div>

                        <div className="overflow-y-auto p-8">
                            <form onSubmit={handleSubmit} className="space-y-6">
                                {/* Image Upload */}
                                <div>
                                    <label className="block text-sm font-semibold text-slate-300 mb-3">Wallpaper Image</label>
                                    <div
                                        onClick={() => fileInputRef.current?.click()}
                                        className={`group relative border-2 border-dashed rounded-2xl p-8 text-center cursor-pointer transition-all ${previewUrl ? 'border-violet-500/50 bg-violet-500/5' : 'border-slate-700 hover:border-violet-500 hover:bg-slate-800/50'
                                            }`}
                                    >
                                        {previewUrl ? (
                                            <div className="relative max-w-sm mx-auto">
                                                <img src={previewUrl} alt="Preview" className="rounded-xl shadow-2xl" />
                                                <div className="absolute inset-0 flex items-center justify-center bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity rounded-xl">
                                                    <p className="text-white font-medium">Click to change</p>
                                                </div>
                                            </div>
                                        ) : (
                                            <div className="py-8">
                                                <div className="w-16 h-16 bg-slate-800 rounded-2xl flex items-center justify-center mx-auto mb-4 group-hover:scale-110 transition-transform duration-300">
                                                    <CloudArrowUpIcon className="w-8 h-8 text-violet-400" />
                                                </div>
                                                <p className="text-slate-200 font-medium text-lg">Click to upload</p>
                                                <p className="text-slate-500 text-sm mt-1">SVG, PNG, JPG or GIF (max. 10MB)</p>
                                            </div>
                                        )}
                                    </div>
                                    <input ref={fileInputRef} type="file" accept="image/*" onChange={handleFileSelect} className="hidden" />
                                </div>

                                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                                    <div>
                                        <label className="block text-sm font-semibold text-slate-300 mb-2">Title</label>
                                        <input
                                            type="text"
                                            value={formData.title}
                                            onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                                            className="w-full px-4 py-3 rounded-xl bg-slate-950 border border-slate-800 text-white focus:outline-none focus:ring-2 focus:ring-violet-500/50 focus:border-violet-500/50 transition-all font-medium"
                                            placeholder="e.g. Abstract Waves"
                                            required
                                        />
                                    </div>

                                    <div>
                                        <label className="block text-sm font-semibold text-slate-300 mb-2">Category</label>
                                        <select
                                            value={formData.category}
                                            onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                                            className="w-full px-4 py-3 rounded-xl bg-slate-950 border border-slate-800 text-white focus:outline-none focus:ring-2 focus:ring-violet-500/50 focus:border-violet-500/50 transition-all font-medium appearance-none"
                                            required
                                        >
                                            <option value="">Select category</option>
                                            {categories.map((cat) => (
                                                <option key={cat.id} value={cat.id}>{cat.name}</option>
                                            ))}
                                        </select>
                                    </div>
                                </div>

                                <div>
                                    <label className="block text-sm font-semibold text-slate-300 mb-2">Tags</label>
                                    <input
                                        type="text"
                                        value={formData.tags}
                                        onChange={(e) => setFormData({ ...formData, tags: e.target.value })}
                                        className="w-full px-4 py-3 rounded-xl bg-slate-950 border border-slate-800 text-white focus:outline-none focus:ring-2 focus:ring-violet-500/50 focus:border-violet-500/50 transition-all font-medium"
                                        placeholder="nature, landscape, sunset (comma separated)"
                                    />
                                </div>

                                <div>
                                    <label className="block text-sm font-semibold text-slate-300 mb-2">Assign to Pack (Optional)</label>
                                    <select
                                        value={formData.packId}
                                        onChange={(e) => setFormData({ ...formData, packId: e.target.value })}
                                        className="w-full px-4 py-3 rounded-xl bg-slate-950 border border-slate-800 text-white focus:outline-none focus:ring-2 focus:ring-violet-500/50 focus:border-violet-500/50 transition-all font-medium appearance-none"
                                    >
                                        <option value="">None</option>
                                        {packs.map((pack) => (
                                            <option key={pack._id} value={pack._id}>{pack.name}</option>
                                        ))}
                                    </select>
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
                                        <span className="text-slate-300 font-medium group-hover:text-white transition-colors">Pro Only</span>
                                    </label>

                                    <label className="flex items-center gap-3 cursor-pointer group">
                                        <div className={`w-6 h-6 rounded-lg border-2 flex items-center justify-center transition-colors ${formData.isWide ? 'bg-violet-600 border-violet-600' : 'border-slate-600 group-hover:border-violet-500'}`}>
                                            {formData.isWide && <span className="text-white text-sm font-bold">✓</span>}
                                        </div>
                                        <input
                                            type="checkbox"
                                            checked={formData.isWide}
                                            onChange={(e) => setFormData({ ...formData, isWide: e.target.checked })}
                                            className="hidden"
                                        />
                                        <span className="text-slate-300 font-medium group-hover:text-white transition-colors">Wide (Desktop)</span>
                                    </label>
                                </div>
                            </form>
                        </div>

                        <div className="p-6 border-t border-white/5 bg-slate-900/50 backdrop-blur-md">
                            <button
                                onClick={handleSubmit}
                                disabled={isSubmitting}
                                className="w-full py-4 rounded-xl bg-gradient-to-r from-violet-600 to-indigo-600 text-white font-bold text-lg shadow-xl shadow-violet-500/20 hover:shadow-violet-500/30 hover:scale-[1.02] transition-all disabled:opacity-50 disabled:hover:scale-100"
                            >
                                {isSubmitting ? 'Uploading...' : 'Upload Wallpaper'}
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
