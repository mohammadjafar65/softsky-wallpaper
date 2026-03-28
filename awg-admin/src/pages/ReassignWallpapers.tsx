import { useEffect, useMemo, useState } from 'react';
import toast from 'react-hot-toast';
import {
    ArrowsRightLeftIcon,
    MagnifyingGlassIcon,
    PhotoIcon,
} from '@heroicons/react/24/outline';
import { categoriesApi, wallpapersApi } from '../services/api';

interface Category {
    id: string;
    name: string;
    slug: string;
    icon?: string;
    wallpaperCount: number;
}

interface Wallpaper {
    id: string;
    title: string;
    imageUrl: string;
    thumbnailUrl: string;
    isPro: boolean;
    category: {
        id: string;
        name: string;
        slug: string;
    } | null;
}

export default function ReassignWallpapers() {
    const [categories, setCategories] = useState<Category[]>([]);
    const [wallpapers, setWallpapers] = useState<Wallpaper[]>([]);
    const [searchQuery, setSearchQuery] = useState('');
    const [isLoading, setIsLoading] = useState(true);
    const [draggedWallpaperId, setDraggedWallpaperId] = useState<string | null>(null);
    const [dragOverCategoryId, setDragOverCategoryId] = useState<string | null>(null);
    const [movingWallpaperId, setMovingWallpaperId] = useState<string | null>(null);

    useEffect(() => {
        void loadData();
    }, []);

    const loadData = async () => {
        setIsLoading(true);
        try {
            const [categoriesResponse, allWallpapers] = await Promise.all([
                categoriesApi.getAll(),
                fetchAllWallpapers(),
            ]);

            setCategories(categoriesResponse.data.categories || []);
            setWallpapers(allWallpapers);
        } catch (error) {
            console.error('Failed to load reassignment data:', error);
            toast.error('Failed to load wallpapers and categories');
        } finally {
            setIsLoading(false);
        }
    };

    const fetchAllWallpapers = async () => {
        const collected: Wallpaper[] = [];
        let currentPage = 1;
        let totalPages = 1;

        do {
            const response = await wallpapersApi.getAll({ page: currentPage, limit: 100 });
            const pageWallpapers = response.data.wallpapers || [];
            collected.push(...pageWallpapers);
            totalPages = response.data.pagination?.pages || 1;
            currentPage += 1;
        } while (currentPage <= totalPages);

        return collected;
    };

    const filteredWallpapers = useMemo(() => {
        const query = searchQuery.trim().toLowerCase();
        if (!query) {
            return wallpapers;
        }

        return wallpapers.filter((wallpaper) => {
            const categoryName = wallpaper.category?.name?.toLowerCase() || '';
            return (
                wallpaper.title.toLowerCase().includes(query) ||
                categoryName.includes(query)
            );
        });
    }, [searchQuery, wallpapers]);

    const wallpapersByCategory = useMemo(() => {
        const grouped = new Map<string, Wallpaper[]>();

        categories.forEach((category) => {
            grouped.set(category.id, []);
        });

        filteredWallpapers.forEach((wallpaper) => {
            const categoryId = wallpaper.category?.id;
            if (!categoryId) {
                return;
            }

            if (!grouped.has(categoryId)) {
                grouped.set(categoryId, []);
            }

            grouped.get(categoryId)?.push(wallpaper);
        });

        return grouped;
    }, [categories, filteredWallpapers]);

    const handleDrop = async (targetCategoryId: string) => {
        if (!draggedWallpaperId) {
            return;
        }

        const wallpaper = wallpapers.find((item) => item.id === draggedWallpaperId);
        if (!wallpaper || wallpaper.category?.id === targetCategoryId) {
            setDraggedWallpaperId(null);
            setDragOverCategoryId(null);
            return;
        }

        const targetCategory = categories.find((category) => category.id === targetCategoryId);
        if (!targetCategory) {
            setDraggedWallpaperId(null);
            setDragOverCategoryId(null);
            return;
        }

        const previousCategory = wallpaper.category;

        setMovingWallpaperId(wallpaper.id);
        setWallpapers((prev) =>
            prev.map((item) =>
                item.id === wallpaper.id
                    ? {
                        ...item,
                        category: {
                            id: targetCategory.id,
                            name: targetCategory.name,
                            slug: targetCategory.slug,
                        },
                    }
                    : item
            )
        );
        setCategories((prev) =>
            prev.map((category) => {
                if (category.id === targetCategory.id) {
                    return { ...category, wallpaperCount: category.wallpaperCount + 1 };
                }
                if (category.id === previousCategory?.id) {
                    return { ...category, wallpaperCount: Math.max(0, category.wallpaperCount - 1) };
                }
                return category;
            })
        );

        try {
            const response = await wallpapersApi.bulkReassign({
                wallpaperIds: [wallpaper.id],
                targetCategoryId,
            });

            toast.success(
                response.data?.movedCount > 0
                    ? `"${wallpaper.title}" moved to ${targetCategory.name}`
                    : `"${wallpaper.title}" is already in ${targetCategory.name}`
            );
        } catch (error) {
            console.error('Failed to reassign wallpaper:', error);
            setWallpapers((prev) =>
                prev.map((item) =>
                    item.id === wallpaper.id
                        ? {
                            ...item,
                            category: previousCategory,
                        }
                        : item
                )
            );
            setCategories((prev) =>
                prev.map((category) => {
                    if (category.id === targetCategory.id) {
                        return { ...category, wallpaperCount: Math.max(0, category.wallpaperCount - 1) };
                    }
                    if (category.id === previousCategory?.id) {
                        return { ...category, wallpaperCount: category.wallpaperCount + 1 };
                    }
                    return category;
                })
            );
            toast.error('Failed to move wallpaper');
        } finally {
            setDraggedWallpaperId(null);
            setDragOverCategoryId(null);
            setMovingWallpaperId(null);
        }
    };

    return (
        <div className="space-y-8 pb-20 md:pb-0">
            <div className="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
                <div>
                    <h1 className="text-2xl md:text-3xl font-bold text-white tracking-tight">Reassign Wallpapers</h1>
                    <p className="mt-2 text-sm md:text-base text-slate-400">
                        Drag a wallpaper card from one category and drop it into another to move it.
                    </p>
                </div>

                <div className="w-full lg:w-80">
                    <label className="relative block">
                        <MagnifyingGlassIcon className="pointer-events-none absolute left-4 top-1/2 h-5 w-5 -translate-y-1/2 text-slate-500" />
                        <input
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                            placeholder="Search wallpapers or categories"
                            className="w-full rounded-2xl border border-slate-800 bg-slate-900/80 py-3 pl-12 pr-4 text-white outline-none transition focus:border-violet-500/50 focus:ring-2 focus:ring-violet-500/20"
                        />
                    </label>
                </div>
            </div>

            <div className="grid gap-4 md:grid-cols-3">
                <div className="rounded-2xl border border-white/10 bg-slate-900/60 p-5">
                    <p className="text-sm text-slate-400">Categories</p>
                    <p className="mt-2 text-3xl font-bold text-white">{categories.length}</p>
                </div>
                <div className="rounded-2xl border border-white/10 bg-slate-900/60 p-5">
                    <p className="text-sm text-slate-400">Wallpapers Loaded</p>
                    <p className="mt-2 text-3xl font-bold text-white">{wallpapers.length}</p>
                </div>
                <div className="rounded-2xl border border-white/10 bg-slate-900/60 p-5">
                    <p className="text-sm text-slate-400">Filtered Results</p>
                    <p className="mt-2 text-3xl font-bold text-white">{filteredWallpapers.length}</p>
                </div>
            </div>

            {isLoading ? (
                <div className="grid gap-6 xl:grid-cols-3">
                    {Array.from({ length: 3 }).map((_, index) => (
                        <div key={index} className="h-[420px] animate-pulse rounded-3xl border border-white/5 bg-slate-900/50" />
                    ))}
                </div>
            ) : (
                <div className="grid gap-6 xl:grid-cols-2 2xl:grid-cols-3">
                    {categories.map((category) => {
                        const categoryWallpapers = wallpapersByCategory.get(category.id) || [];
                        const isActiveDropZone = dragOverCategoryId === category.id;

                        return (
                            <section
                                key={category.id}
                                onDragOver={(event) => {
                                    event.preventDefault();
                                    setDragOverCategoryId(category.id);
                                }}
                                onDragLeave={() => {
                                    setDragOverCategoryId((current) => current === category.id ? null : current);
                                }}
                                onDrop={(event) => {
                                    event.preventDefault();
                                    void handleDrop(category.id);
                                }}
                                className={`rounded-3xl border p-5 transition-all ${
                                    isActiveDropZone
                                        ? 'border-violet-400 bg-violet-500/10 shadow-lg shadow-violet-500/10'
                                        : 'border-white/10 bg-slate-900/60'
                                }`}
                            >
                                <div className="mb-5 flex items-center justify-between gap-4">
                                    <div className="min-w-0">
                                        <div className="flex items-center gap-3">
                                            <span className="text-2xl">{category.icon || '🎨'}</span>
                                            <div className="min-w-0">
                                                <h2 className="truncate text-lg font-semibold text-white">{category.name}</h2>
                                                <p className="text-xs uppercase tracking-[0.2em] text-slate-500">{category.slug}</p>
                                            </div>
                                        </div>
                                    </div>
                                    <div className="rounded-2xl border border-white/10 bg-black/20 px-3 py-2 text-right">
                                        <p className="text-xs text-slate-400">Count</p>
                                        <p className="text-lg font-bold text-white">{categoryWallpapers.length}</p>
                                    </div>
                                </div>

                                <div className="max-h-[560px] space-y-3 overflow-y-auto pr-1">
                                    {categoryWallpapers.length === 0 ? (
                                        <div className="rounded-2xl border border-dashed border-slate-700 bg-slate-950/50 px-4 py-10 text-center text-sm text-slate-500">
                                            Drop wallpaper here
                                        </div>
                                    ) : (
                                        categoryWallpapers.map((wallpaper) => (
                                            <article
                                                key={wallpaper.id}
                                                draggable={movingWallpaperId !== wallpaper.id}
                                                onDragStart={() => setDraggedWallpaperId(wallpaper.id)}
                                                onDragEnd={() => {
                                                    setDraggedWallpaperId(null);
                                                    setDragOverCategoryId(null);
                                                }}
                                                className={`group flex cursor-grab items-center gap-3 rounded-2xl border border-white/10 bg-slate-950/80 p-3 transition hover:border-violet-500/40 hover:bg-slate-950 ${
                                                    movingWallpaperId === wallpaper.id ? 'opacity-50' : ''
                                                }`}
                                            >
                                                <img
                                                    src={wallpaper.thumbnailUrl || wallpaper.imageUrl}
                                                    alt={wallpaper.title}
                                                    className="h-20 w-14 rounded-xl object-cover"
                                                />
                                                <div className="min-w-0 flex-1">
                                                    <div className="flex items-center gap-2">
                                                        <p className="truncate font-medium text-white">{wallpaper.title}</p>
                                                        {wallpaper.isPro && (
                                                            <span className="rounded-full border border-amber-500/30 bg-amber-500/10 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-amber-300">
                                                                Pro
                                                            </span>
                                                        )}
                                                    </div>
                                                    <p className="mt-1 flex items-center gap-2 text-xs text-slate-400">
                                                        <PhotoIcon className="h-4 w-4" />
                                                        Drag to move
                                                    </p>
                                                </div>
                                                <ArrowsRightLeftIcon className="h-5 w-5 flex-shrink-0 text-slate-500 transition group-hover:text-violet-300" />
                                            </article>
                                        ))
                                    )}
                                </div>
                            </section>
                        );
                    })}
                </div>
            )}
        </div>
    );
}
