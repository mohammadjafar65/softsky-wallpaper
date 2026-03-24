import { useEffect, useState } from 'react';
import { wallpapersApi } from '../services/api';
import { categoriesApi } from '../services/api';
import toast from 'react-hot-toast';
import {
    PlusIcon,
    PencilIcon,
    TrashIcon,
    XMarkIcon,
} from '@heroicons/react/24/outline';

interface Category {
    id: string;
    name: string;
    slug: string;
    icon: string;
    description?: string;
    wallpaperCount: number;
    isActive: boolean;
    sourceUrl?: string;
}

    const [categories, setCategories] = useState<Category[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [editingCategory, setEditingCategory] = useState<Category | null>(null);
    const [formData, setFormData] = useState({ name: '', icon: '🎨', description: '' });
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [showImportModal, setShowImportModal] = useState(false);
    const [importUrl, setImportUrl] = useState('');
    const [isImporting, setIsImporting] = useState(false);
    const [refetchingId, setRefetchingId] = useState<string | null>(null);
    const [categoryWallpapers, setCategoryWallpapers] = useState<any[]>([]);
    const [isWallpapersLoading, setIsWallpapersLoading] = useState(false);

    useEffect(() => {
        fetchCategories();
    }, []);

    const fetchCategories = async () => {
        try {
            const response = await categoriesApi.getAll();
            setCategories(response.data.categories || []);
        } catch (error) {
            console.error('Failed to fetch categories:', error);
        } finally {
            setIsLoading(false);
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setIsSubmitting(true);

        try {
            if (editingCategory) {
                await categoriesApi.update(editingCategory.id, formData);
                toast.success('Category updated!');
            } else {
                await categoriesApi.create(formData);
                toast.success('Category created!');
            }
            setShowModal(false);
            resetForm();
            fetchCategories();
        } catch (error: any) {
            toast.error(error.response?.data?.error || 'Failed to save category');
        } finally {
            setIsSubmitting(false);
        }
    };

    const handleImport = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!importUrl) return;
        setIsImporting(true);
        try {
            const res = await categoriesApi.importPinterest(importUrl);
            toast.success(`Imported ${res.data.importedCount} wallpapers from Pinterest!`);
            setShowImportModal(false);
            setImportUrl('');
            fetchCategories();
        } catch (error: any) {
            toast.error(error.response?.data?.error || 'Failed to import Pinterest board');
        } finally {
            setIsImporting(false);
        }
    };

    const handleRefetch = async (id: string) => {
        setRefetchingId(id);
        try {
            const res = await categoriesApi.refetchPinterest(id);
            if (res.data.importedCount > 0) {
                toast.success(`Refetched ${res.data.importedCount} new wallpapers!`);
                fetchCategories();
            } else {
                toast.success('No new wallpapers found on this board.');
            }
        } catch (error: any) {
            toast.error(error.response?.data?.error || 'Failed to refetch Pinterest board');
        } finally {
            setRefetchingId(null);
        }
    };

    const handleEdit = async (category: Category) => {
        setEditingCategory(category);
        setFormData({ name: category.name, icon: category.icon, description: category.description || '' });
        setShowModal(true);
        setIsWallpapersLoading(true);
        try {
            const res = await wallpapersApi.getAll({ category: category.slug });
            setCategoryWallpapers(res.data.wallpapers || []);
        } catch (e) {
            setCategoryWallpapers([]);
        } finally {
            setIsWallpapersLoading(false);
        }
    };

    const handleDelete = async (id: string) => {
        if (!confirm('Are you sure you want to delete this category?')) return;

        try {
            await categoriesApi.delete(id);
            toast.success('Category deleted!');
            fetchCategories();
        } catch (error: any) {
            toast.error(error.response?.data?.error || 'Failed to delete category');
        }
    };

    const resetForm = () => {
        setFormData({ name: '', icon: '🎨', description: '' });
        setEditingCategory(null);
    };

    return (
        <div className="p-4 md:p-8">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-8">
                <div>
                    <h1 className="text-2xl md:text-3xl font-bold text-white">Categories</h1>
                    <p className="text-gray-400 mt-1">Organize your wallpapers</p>
                </div>
                <div className="flex items-center gap-2">
                    <button
                        onClick={() => setShowImportModal(true)}
                        className="flex items-center gap-2 px-4 py-2 rounded-xl bg-gray-800 text-white font-medium hover:bg-gray-700 transition border border-gray-700"
                    >
                        <span className="text-xl">📌</span>
                        Import Pinterest
                    </button>
                    <button
                        onClick={() => setShowModal(true)}
                        className="flex items-center gap-2 px-4 py-2 rounded-xl bg-gradient-to-r from-blue-500 to-purple-600 text-white font-medium hover:from-blue-600 hover:to-purple-700 transition"
                    >
                        <PlusIcon className="w-5 h-5" />
                        Add Category
                    </button>
                </div>
            </div>

            {isLoading ? (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    {[...Array(6)].map((_, i) => (
                        <div key={i} className="h-24 bg-gray-800 rounded-xl animate-pulse" />
                    ))}
                </div>
            ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    {categories.map((cat) => (
                        <div key={cat.id} className="bg-gray-800/50 rounded-xl p-4 border border-gray-700/50 flex items-center justify-between">
                            <div className="flex items-center gap-4">
                                <span className="text-3xl">{cat.icon}</span>
                                <div>
                                    <p className="text-white font-medium">{cat.name}</p>
                                    <p className="text-gray-400 text-sm">{cat.wallpaperCount} wallpapers</p>
                                </div>
                            </div>
                            <div className="flex gap-2 items-center">

                                <button onClick={() => handleEdit(cat)} className="p-2 text-gray-400 hover:text-white hover:bg-gray-700 rounded-lg transition">
                                    <PencilIcon className="w-4 h-4" />
                                </button>
                                <button onClick={() => handleDelete(cat.id)} className="p-2 text-gray-400 hover:text-red-400 hover:bg-gray-700 rounded-lg transition">
                                    <TrashIcon className="w-4 h-4" />
                                </button>
                            </div>
                        </div>
                    ))}
                </div>
            )}

            {/* Modal */}
            {showModal && (
                <div className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50 p-4">
                    <div className="bg-gray-800 rounded-2xl w-full max-w-md max-h-[90vh] overflow-y-auto">
                        <div className="flex items-center justify-between p-6 border-b border-gray-700">
                            <h2 className="text-xl font-bold text-white">
                                {editingCategory ? 'Edit Category' : 'Add Category'}
                            </h2>
                            <button onClick={() => { setShowModal(false); resetForm(); setCategoryWallpapers([]); }} className="text-gray-400 hover:text-white">
                                <XMarkIcon className="w-6 h-6" />
                            </button>
                        </div>
                        <form onSubmit={handleSubmit} className="p-6 space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-300 mb-2">Name *</label>
                                <input
                                    type="text"
                                    value={formData.name}
                                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                                    className="w-full px-4 py-2 rounded-xl bg-gray-700 border border-gray-600 text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                                    required
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-300 mb-2">Icon (Emoji)</label>
                                <input
                                    type="text"
                                    value={formData.icon}
                                    onChange={(e) => setFormData({ ...formData, icon: e.target.value })}
                                    className="w-full px-4 py-2 rounded-xl bg-gray-700 border border-gray-600 text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                                />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-gray-300 mb-2">Description</label>
                                <textarea
                                    value={formData.description}
                                    onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                                    className="w-full px-4 py-2 rounded-xl bg-gray-700 border border-gray-600 text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                                    rows={3}
                                />
                            </div>
                            {editingCategory?.sourceUrl && editingCategory.sourceUrl.includes('pinterest.com') && (
                                <div className="p-4 bg-gray-700/50 rounded-xl border border-gray-600">
                                    <label className="block text-sm font-medium text-gray-300 mb-2">Pinterest URL</label>
                                    <div className="flex gap-2 items-center">
                                        <input
                                            type="text"
                                            value={editingCategory.sourceUrl}
                                            readOnly
                                            className="w-full px-4 py-2 rounded-lg bg-gray-800 border border-gray-600 text-gray-400 truncate text-sm"
                                        />
                                        <button
                                            type="button"
                                            onClick={() => handleRefetch(editingCategory.id)}
                                            disabled={refetchingId === editingCategory.id}
                                            className="whitespace-nowrap flex flex-row items-center gap-2 px-4 py-2 bg-blue-600/20 text-blue-400 hover:bg-blue-600/30 border border-blue-500/30 rounded-lg transition disabled:opacity-50 text-sm font-medium"
                                        >
                                            {refetchingId === editingCategory.id ? (
                                                <div className="w-4 h-4 border-2 border-blue-400/30 border-t-blue-400 rounded-full animate-spin" />
                                            ) : (
                                                <span>🔄</span>
                                            )}
                                            {refetchingId === editingCategory.id ? 'Refetching...' : 'Refetch'}
                                        </button>
                                    </div>
                                    <p className="text-xs text-gray-500 mt-2">
                                        Click refetch to download new pins from this board. Duplicate wallpapers will be skipped automatically.
                                    </p>
                                </div>
                            )}
                            <button
                                type="submit"
                                disabled={isSubmitting}
                                className="w-full py-3 rounded-xl bg-gradient-to-r from-blue-500 to-purple-600 text-white font-semibold hover:from-blue-600 hover:to-purple-700 transition disabled:opacity-50"
                            >
                                {isSubmitting ? 'Saving...' : editingCategory ? 'Update Category' : 'Create Category'}
                            </button>
                        </form>
                        {/* Wallpapers of this category */}
                        {editingCategory && (
                            <div className="p-6 pt-0">
                                <h3 className="text-lg font-semibold text-white mb-2">Wallpapers in this category</h3>
                                {isWallpapersLoading ? (
                                    <div className="text-gray-400">Loading wallpapers...</div>
                                ) : categoryWallpapers.length === 0 ? (
                                    <div className="text-gray-400">No wallpapers found in this category.</div>
                                ) : (
                                    <div className="grid grid-cols-2 gap-3 max-h-60 overflow-y-auto">
                                        {categoryWallpapers.map((wp) => (
                                            <div key={wp.id} className="bg-gray-700 rounded-lg p-2 flex flex-col items-center">
                                                <img src={wp.thumbnailUrl || wp.imageUrl} alt={wp.title} className="w-full h-20 object-cover rounded mb-1" />
                                                <div className="text-xs text-white truncate w-full text-center">{wp.title}</div>
                                            </div>
                                        ))}
                                    </div>
                                )}
                            </div>
                        )}
                    </div>
                </div>
            )}

            {/* Import Pinterest Modal */}
            {showImportModal && (
                <div className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50 p-4">
                    <div className="bg-gray-800 rounded-2xl w-full max-w-md">
                        <div className="flex items-center justify-between p-6 border-b border-gray-700">
                            <h2 className="text-xl font-bold text-white flex items-center gap-2">
                                <span>📌</span> Import Pinterest Board
                            </h2>
                            <button onClick={() => { setShowImportModal(false); setImportUrl(''); }} className="text-gray-400 hover:text-white">
                                <XMarkIcon className="w-6 h-6" />
                            </button>
                        </div>
                        <form onSubmit={handleImport} className="p-6 space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-300 mb-2">Pinterest Board URL *</label>
                                <input
                                    type="url"
                                    value={importUrl}
                                    onChange={(e) => setImportUrl(e.target.value)}
                                    placeholder="https://www.pinterest.com/username/boardname/"
                                    className="w-full px-4 py-2 rounded-xl bg-gray-700 border border-gray-600 text-white focus:outline-none focus:ring-2 focus:ring-blue-500 placeholder:text-gray-500"
                                    required
                                />
                                <p className="text-xs text-gray-400 mt-2">
                                    This might take a minute as it downloads high-quality images.
                                </p>
                            </div>
                            <button
                                type="submit"
                                disabled={isImporting || !importUrl}
                                className="w-full flex items-center justify-center gap-2 py-3 rounded-xl bg-gray-700 text-white font-semibold hover:bg-gray-600 transition disabled:opacity-50"
                            >
                                {isImporting ? (
                                    <>
                                        <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                                        Importing...
                                    </>
                                ) : (
                                    'Start Import'
                                )}
                            </button>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}
