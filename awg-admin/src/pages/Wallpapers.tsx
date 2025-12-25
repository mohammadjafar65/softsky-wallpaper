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
    CheckCircleIcon,
    PencilIcon,
} from '@heroicons/react/24/outline';
import { CheckCircleIcon as CheckCircleIconSolid } from '@heroicons/react/24/solid';

interface Wallpaper {
    id: string;
    title: string;
    imageUrl: string;
    thumbnailUrl: string;
    category: { name: string; slug: string; id: string };
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
    const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());

    // Edit Mode State
    const [editingWallpaper, setEditingWallpaper] = useState<Wallpaper | null>(null);
    const [showEditModal, setShowEditModal] = useState(false);

    // Form state
    const [formData, setFormData] = useState({
        title: '',
        categories: [] as string[],
        tags: '',
        isPro: false,
        isWide: false,
        packId: '',
    });
    // Changed from selectedFile to selectedFiles
    const [selectedFiles, setSelectedFiles] = useState<File[]>([]);
    const [previewUrls, setPreviewUrls] = useState<string[]>([]);
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [uploadProgress, setUploadProgress] = useState(0);
    const fileInputRef = useRef<HTMLInputElement>(null);

    useEffect(() => {
        fetchCategories();
        fetchPacks();
    }, []);

    useEffect(() => {
        fetchWallpapers();
    }, [page, selectedCategory]);

    // Clean up object URLs to avoid memory leaks
    useEffect(() => {
        return () => {
            previewUrls.forEach(url => URL.revokeObjectURL(url));
        };
    }, [previewUrls]);

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
        const files = Array.from(e.target.files || []);
        if (files.length > 0) {
            setSelectedFiles(prev => [...prev, ...files]);
            const newUrls = files.map(file => URL.createObjectURL(file));
            setPreviewUrls(prev => [...prev, ...newUrls]);
        }
    };

    const removeFile = (index: number) => {
        setSelectedFiles(prev => prev.filter((_, i) => i !== index));
        setPreviewUrls(prev => {
            URL.revokeObjectURL(prev[index]);
            return prev.filter((_, i) => i !== index);
        });
    };

    const toggleCategorySelection = (catId: string) => {
        setFormData(prev => {
            if (prev.categories.includes(catId)) {
                return { ...prev, categories: prev.categories.filter(id => id !== catId) };
            } else {
                return { ...prev, categories: [...prev.categories, catId] };
            }
        });
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (selectedFiles.length === 0 || !formData.title || formData.categories.length === 0) {
            toast.error('Please fill all required fields, select at least one category, and one file');
            return;
        }

        setIsSubmitting(true);
        setUploadProgress(0);
        let successCount = 0;
        let failCount = 0;
        const totalOperations = selectedFiles.length * formData.categories.length;
        let completedOperations = 0;

        try {
            for (let i = 0; i < selectedFiles.length; i++) {
                const file = selectedFiles[i];

                // For each selected category, upload the wallpaper
                for (const catId of formData.categories) {
                    const data = new FormData();
                    data.append('image', file);

                    // Generate title: "Title" or "Title 1", "Title 2"...
                    const titleBase = selectedFiles.length > 1
                        ? `${formData.title} ${i + 1}`
                        : formData.title;

                    data.append('title', titleBase);
                    data.append('category', catId); // Upload for this specific category
                    data.append('tags', formData.tags);
                    data.append('isPro', formData.isPro.toString());
                    data.append('isWide', formData.isWide.toString());
                    if (formData.packId) data.append('packId', formData.packId);

                    try {
                        await wallpapersApi.create(data);
                        successCount++;
                    } catch (error: any) {
                        console.error(`Failed to upload ${file.name} to category ${catId}`, error.response?.data || error);
                        failCount++;
                    }

                    completedOperations++;
                    setUploadProgress(Math.round((completedOperations / totalOperations) * 100));
                }
            }

            if (successCount > 0) {
                toast.success(`Successfully uploaded ${successCount} wallpaper${successCount !== 1 ? 's' : ''}!`);
                if (failCount > 0) {
                    toast.error(`Failed to upload ${failCount} wallpapers.`);
                }
                setShowModal(false);
                resetForm();
                fetchWallpapers();
            } else {
                toast.error('Failed to upload wallpapers');
            }
        } catch (error: any) {
            toast.error('An unexpected error occurred');
        } finally {
            setIsSubmitting(false);
            setUploadProgress(0);
        }
    };

    const handleDelete = async (id: string) => {
        if (!confirm('Are you sure you want to delete this wallpaper?')) return;

        try {
            await wallpapersApi.delete(id);
            toast.success('Wallpaper deleted successfully!');
            fetchWallpapers();
            // Remove from selection if present
            if (selectedIds.has(id)) {
                const newSet = new Set(selectedIds);
                newSet.delete(id);
                setSelectedIds(newSet);
            }
        } catch (error) {
            toast.error('Failed to delete wallpaper');
        }
    };

    const handleBulkDelete = async () => {
        if (selectedIds.size === 0) return;
        if (!confirm(`Are you sure you want to delete ${selectedIds.size} wallpapers?`)) return;

        let deletedCount = 0;
        for (const id of selectedIds) {
            try {
                await wallpapersApi.delete(id);
                deletedCount++;
            } catch (error) {
                console.error(`Failed to delete ${id}`, error);
            }
        }

        toast.success(`Deleted ${deletedCount} wallpapers`);
        setSelectedIds(new Set());
        fetchWallpapers();
    }

    const toggleSelection = (id: string, multiSelect: boolean) => {
        const newSet = new Set(multiSelect ? selectedIds : []);
        if (newSet.has(id)) {
            newSet.delete(id);
        } else {
            newSet.add(id);
        }
        setSelectedIds(newSet);
    };

    const handleEditClick = (wallpaper: Wallpaper) => {
        setEditingWallpaper(wallpaper);
        setFormData({
            title: wallpaper.title,
            categories: [wallpaper.category.id], // Pre-select existing category
            tags: '',
            isPro: wallpaper.isPro,
            isWide: false,
            packId: '',
        });
        setShowEditModal(true);
    };

    const handleEditSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!editingWallpaper) return;

        try {
            await wallpapersApi.update(editingWallpaper.id, {
                title: formData.title,
            });
            toast.success("Wallpaper updated");
            setShowEditModal(false);
            setEditingWallpaper(null);
            fetchWallpapers();
        } catch (e) {
            toast.error("Failed to update");
        }
    };

    const resetForm = () => {
        setFormData({ title: '', categories: [], tags: '', isPro: false, isWide: false, packId: '' });
        setSelectedFiles([]);
        setPreviewUrls([]);
    };

    return (
        <div className="space-y-8 pb-20 md:pb-0">
            {/* Header */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                    <h1 className="text-2xl md:text-3xl font-bold text-white tracking-tight">Wallpapers</h1>
                    <p className="text-slate-400 mt-2 text-sm md:text-base">Manage your wallpaper collection</p>
                </div>
                <div className="flex gap-2">
                    {selectedIds.size > 0 && (
                        <button
                            onClick={handleBulkDelete}
                            className="flex items-center gap-2 px-4 py-2 md:px-6 md:py-3 rounded-xl bg-red-500/10 hover:bg-red-500/20 text-red-500 border border-red-500/20 font-medium transition-all"
                        >
                            <TrashIcon className="w-5 h-5" />
                            <span className="hidden md:inline">Delete ({selectedIds.size})</span>
                            <span className="md:hidden">({selectedIds.size})</span>
                        </button>
                    )}
                    <button
                        onClick={() => setShowModal(true)}
                        className="flex items-center gap-2 px-4 py-2 md:px-6 md:py-3 rounded-xl bg-violet-600 hover:bg-violet-700 text-white font-medium shadow-lg shadow-violet-500/25 transition-all transform hover:scale-105"
                    >
                        <PlusIcon className="w-5 h-5" />
                        <span className="hidden md:inline">Upload New</span>
                        <span className="md:hidden">New</span>
                    </button>
                </div>
            </div>

            {/* Filters Bar */}
            <div className="flex flex-col md:flex-row items-stretch md:items-center gap-4 p-4 bg-slate-900/40 backdrop-blur-md border border-white/5 rounded-2xl">
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
                <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4 md:gap-6">
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
                <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4 md:gap-6">
                    {wallpapers.map((wallpaper) => (
                        <div
                            key={wallpaper.id}
                            className={`group relative aspect-[9/16] rounded-2xl overflow-hidden bg-slate-800 shadow-2xl transition-all duration-300 hover:shadow-violet-500/10 ${selectedIds.has(wallpaper.id) ? 'ring-2 ring-violet-500' : ''}`}
                        >
                            {/* Selection Checkbox Area */}
                            <div
                                className="absolute top-2 left-2 z-20 cursor-pointer p-2 -ml-2 -mt-2"
                                onClick={(e) => {
                                    e.stopPropagation();
                                    toggleSelection(wallpaper.id, true);
                                }}
                            >
                                {selectedIds.has(wallpaper.id) ? (
                                    <CheckCircleIconSolid className="w-6 h-6 text-violet-500 bg-white rounded-full" />
                                ) : (
                                    <CheckCircleIcon className="w-6 h-6 text-white/70 hover:text-white drop-shadow-md" />
                                )}
                            </div>

                            <img
                                src={wallpaper.thumbnailUrl}
                                alt={wallpaper.title}
                                className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-110"
                            />
                            {/* Overlay */}
                            <div className="absolute inset-0 bg-gradient-to-t from-slate-950 via-slate-950/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300">
                                <div className="absolute bottom-0 left-0 right-0 p-3 md:p-5 transform translate-y-4 group-hover:translate-y-0 transition-transform duration-300">
                                    <h3 className="text-white font-bold truncate text-sm md:text-lg shadow-sm">{wallpaper.title}</h3>
                                    <div className="flex items-center justify-between mt-2">
                                        <span className="text-slate-300 text-xs font-medium bg-black/30 px-2 py-0.5 rounded-lg backdrop-blur-sm">
                                            {wallpaper.category?.name}
                                        </span>
                                        {wallpaper.isPro && (
                                            <span className="px-2 py-0.5 text-[10px] uppercase font-bold bg-amber-500 text-black rounded-md shadow-lg shadow-amber-500/20">PRO</span>
                                        )}
                                    </div>
                                    <div className="flex items-center gap-2 mt-3 text-slate-400 text-xs font-medium">
                                        <ArrowDownTrayIcon className="w-3.5 h-3.5" />
                                        <span>{wallpaper.downloads}</span>
                                    </div>
                                </div>
                                <div className="absolute top-2 right-2 flex gap-2 transform -translate-y-4 group-hover:translate-y-0 transition-transform duration-300 delay-75">
                                    <button
                                        onClick={(e) => {
                                            e.stopPropagation();
                                            handleEditClick(wallpaper);
                                        }}
                                        className="p-2 bg-blue-500/90 backdrop-blur-md rounded-xl text-white hover:bg-blue-600 transition shadow-lg shadow-blue-500/20"
                                    >
                                        <PencilIcon className="w-4 h-4" />
                                    </button>
                                    <button
                                        onClick={(e) => {
                                            e.stopPropagation();
                                            handleDelete(wallpaper.id);
                                        }}
                                        className="p-2 bg-red-500/90 backdrop-blur-md rounded-xl text-white hover:bg-red-600 transition shadow-lg shadow-red-500/20"
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
                    <div className="hidden md:flex gap-1">
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
                    {/* Mobile friendly simple pagination */}
                    <span className="md:hidden text-slate-400 text-sm">
                        Page {page} of {totalPages}
                    </span>
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
                                <p className="text-slate-400 text-sm mt-1">Add new wallpapers to your collection</p>
                            </div>
                            <button onClick={() => { setShowModal(false); resetForm(); }} className="p-2 text-slate-400 hover:text-white hover:bg-white/5 rounded-xl transition">
                                <XMarkIcon className="w-6 h-6" />
                            </button>
                        </div>

                        <div className="overflow-y-auto p-8">
                            <form onSubmit={handleSubmit} className="space-y-6">
                                {/* Image Upload */}
                                <div>
                                    <label className="block text-sm font-semibold text-slate-300 mb-3">Wallpaper Images</label>
                                    <div className="space-y-4">
                                        <div
                                            onClick={() => fileInputRef.current?.click()}
                                            className={`group relative border-2 border-dashed rounded-2xl p-8 text-center cursor-pointer transition-all ${previewUrls.length > 0 ? 'border-violet-500/30 bg-violet-500/5' : 'border-slate-700 hover:border-violet-500 hover:bg-slate-800/50'
                                                }`}
                                        >
                                            <div className="py-2">
                                                <div className="w-16 h-16 bg-slate-800 rounded-2xl flex items-center justify-center mx-auto mb-4 group-hover:scale-110 transition-transform duration-300">
                                                    <CloudArrowUpIcon className="w-8 h-8 text-violet-400" />
                                                </div>
                                                <p className="text-slate-200 font-medium text-lg">Click to upload files</p>
                                                <p className="text-slate-500 text-sm mt-1">Select one or multiple files (max. 10MB each)</p>
                                            </div>
                                        </div>

                                        {/* Previews Grid */}
                                        {previewUrls.length > 0 && (
                                            <div className="grid grid-cols-3 sm:grid-cols-4 gap-4 mt-4">
                                                {previewUrls.map((url, index) => (
                                                    <div key={url} className="relative group aspect-[9/16] rounded-xl overflow-hidden bg-slate-800 border border-white/10">
                                                        <img src={url} alt={`Preview ${index + 1}`} className="w-full h-full object-cover" />
                                                        <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                                                            <button
                                                                type="button"
                                                                onClick={() => removeFile(index)}
                                                                className="p-1.5 bg-red-500 rounded-lg text-white hover:bg-red-600 transition"
                                                            >
                                                                <XMarkIcon className="w-4 h-4" />
                                                            </button>
                                                        </div>
                                                        <div className="absolute top-1 left-1 bg-black/60 px-1.5 py-0.5 rounded text-[10px] text-white font-medium">
                                                            #{index + 1}
                                                        </div>
                                                    </div>
                                                ))}
                                            </div>
                                        )}
                                    </div>
                                    <input
                                        ref={fileInputRef}
                                        type="file"
                                        accept="image/*"
                                        multiple // Enable multiple file selection
                                        onChange={handleFileSelect}
                                        className="hidden"
                                    />
                                </div>

                                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                                    <div>
                                        <label className="block text-sm font-semibold text-slate-300 mb-2">Title {selectedFiles.length > 1 && '(Base Title)'}</label>
                                        <input
                                            type="text"
                                            value={formData.title}
                                            onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                                            className="w-full px-4 py-3 rounded-xl bg-slate-950 border border-slate-800 text-white focus:outline-none focus:ring-2 focus:ring-violet-500/50 focus:border-violet-500/50 transition-all font-medium"
                                            placeholder={selectedFiles.length > 1 ? "e.g. Nature Pack (will become Nature Pack 1, 2...)" : "e.g. Abstract Waves"}
                                            required
                                        />
                                    </div>

                                    <div>
                                        <label className="block text-sm font-semibold text-slate-300 mb-2">Categories</label>
                                        <div className="w-full h-32 overflow-y-auto px-4 py-3 rounded-xl bg-slate-950 border border-slate-800 scrollbar-thin scrollbar-thumb-slate-700">
                                            <div className="space-y-2">
                                                {categories.map((cat) => (
                                                    <label key={cat.id} className="flex items-center gap-3 cursor-pointer group">
                                                        <div className={`w-5 h-5 rounded border flex items-center justify-center transition-colors ${formData.categories.includes(cat.id) ? 'bg-violet-600 border-violet-600' : 'border-slate-600 group-hover:border-violet-500'}`}>
                                                            {formData.categories.includes(cat.id) && <span className="text-white text-xs font-bold">✓</span>}
                                                        </div>
                                                        <input
                                                            type="checkbox"
                                                            className="hidden"
                                                            checked={formData.categories.includes(cat.id)}
                                                            onChange={() => toggleCategorySelection(cat.id)}
                                                        />
                                                        <span className={`text-sm ${formData.categories.includes(cat.id) ? 'text-white' : 'text-slate-400 group-hover:text-slate-200'}`}>{cat.name}</span>
                                                    </label>
                                                ))}
                                            </div>
                                        </div>
                                        <p className="text-xs text-slate-500 mt-1">Select multiple to upload copies to each</p>
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
                                className="w-full py-4 rounded-xl bg-gradient-to-r from-violet-600 to-indigo-600 text-white font-bold text-lg shadow-xl shadow-violet-500/20 hover:shadow-violet-500/30 hover:scale-[1.02] transition-all disabled:opacity-50 disabled:hover:scale-100 relative overflow-hidden"
                            >
                                <span className="relative z-10">
                                    {isSubmitting
                                        ? `Uploading... ${uploadProgress}%`
                                        : `Upload ${selectedFiles.length > 0 ? `${selectedFiles.length * (formData.categories.length || 1)} Wallpapers` : 'Wallpaper'}`
                                    }
                                </span>
                                {isSubmitting && (
                                    <div
                                        className="absolute inset-0 bg-white/20 transition-all duration-300 ease-out"
                                        style={{ width: `${uploadProgress}%` }}
                                    />
                                )}
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {/* Edit Modal */}
            {showEditModal && editingWallpaper && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
                    <div className="absolute inset-0 bg-slate-950/80 backdrop-blur-sm" onClick={() => setShowEditModal(false)} />
                    <div className="relative w-full max-w-md bg-slate-900 rounded-3xl border border-white/10 shadow-2xl overflow-hidden animate-scale-up">
                        <div className="flex items-center justify-between p-6 border-b border-white/5 bg-slate-900/50 backdrop-blur-md">
                            <h2 className="text-xl font-bold text-white">Edit Wallpaper</h2>
                            <button onClick={() => setShowEditModal(false)} className="p-2 text-slate-400 hover:text-white hover:bg-white/5 rounded-xl transition">
                                <XMarkIcon className="w-6 h-6" />
                            </button>
                        </div>
                        <div className="p-8">
                            <form onSubmit={handleEditSubmit} className="space-y-6">
                                <div>
                                    <label className="block text-sm font-semibold text-slate-300 mb-2">Title</label>
                                    <input
                                        type="text"
                                        value={formData.title}
                                        onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                                        className="w-full px-4 py-3 rounded-xl bg-slate-950 border border-slate-800 text-white focus:outline-none focus:ring-2 focus:ring-violet-500/50 focus:border-violet-500/50 transition-all font-medium"
                                        required
                                    />
                                </div>
                                <button
                                    type="submit"
                                    className="w-full py-4 rounded-xl bg-violet-600 text-white font-bold text-lg shadow-xl shadow-violet-500/20 hover:bg-violet-700 transition-all"
                                >
                                    Save Changes
                                </button>
                            </form>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}

