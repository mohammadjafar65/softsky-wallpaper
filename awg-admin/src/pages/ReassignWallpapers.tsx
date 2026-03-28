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
            toast.error('Failed to load wallpapers');
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
            return wallpaper.title.toLowerCase().includes(query) || categoryName.includes(query);
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
                    ? `Moved to ${targetCategory.name}`
                    : `Already in ${targetCategory.name}`
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
        <div className="space-y-6 pb-20 md:pb-0">
            <div className="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
                <div className="max-w-2xl">
                    <h1 className="text-2xl font-semibold text-white md:text-3xl">Reassign Wallpapers</h1>
                    <p className="mt-2 text-sm text-slate-400">
                        Drag a wallpaper from one category and drop it into another.
                    </p>
                </div>

                <div className="w-full max-w-sm">
                    <label className="relative block">
                        <MagnifyingGlassIcon className="pointer-events-none absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-500" />
                        <input
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                            placeholder="Search wallpapers"
                            className="w-full rounded-2xl border border-slate-800 bg-slate-900 px-11 py-3 text-sm text-white outline-none transition focus:border-slate-600"
                        />
                    </label>
                </div>
            </div>

            <div className="rounded-2xl border border-slate-800 bg-slate-900/60 px-4 py-3 text-sm text-slate-400">
                <span className="text-slate-200">{filteredWallpapers.length}</span> wallpapers across{' '}
                <span className="text-slate-200">{categories.length}</span> categories
                {draggedWallpaperId ? ' • Drop on any column to move' : ''}
            </div>

            {isLoading ? (
                <div className="flex gap-4 overflow-hidden">
                    {Array.from({ length: 3 }).map((_, index) => (
                        <div key={index} className="h-[560px] w-[320px] flex-shrink-0 animate-pulse rounded-2xl bg-slate-900/60" />
                    ))}
                </div>
            ) : (
                <div className="overflow-x-auto pb-2">
                    <div className="flex min-w-max gap-4">
                        {categories.map((category) => {
                            const categoryWallpapers = wallpapersByCategory.get(category.id) || [];
                            const isDropTarget = dragOverCategoryId === category.id;

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
                                    className={`w-[320px] flex-shrink-0 rounded-2xl border transition-colors ${
                                        isDropTarget
                                            ? 'border-slate-400 bg-slate-800/80'
                                            : 'border-slate-800 bg-slate-900/60'
                                    }`}
                                >
                                    <div className="sticky top-0 z-10 rounded-t-2xl border-b border-slate-800 bg-slate-900/95 px-4 py-4 backdrop-blur">
                                        <div className="flex items-center justify-between gap-3">
                                            <div className="min-w-0 flex items-center gap-3">
                                                <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-slate-800 text-base">
                                                    {category.icon || <PhotoIcon className="h-5 w-5 text-slate-400" />}
                                                </div>
                                                <div className="min-w-0">
                                                    <h2 className="truncate text-sm font-medium text-white">{category.name}</h2>
                                                    <p className="text-xs text-slate-500">{categoryWallpapers.length} wallpapers</p>
                                                </div>
                                            </div>

                                            {isDropTarget && (
                                                <div className="rounded-full bg-slate-700 px-2 py-1 text-[11px] text-slate-200">
                                                    Drop here
                                                </div>
                                            )}
                                        </div>
                                    </div>

                                    <div className="max-h-[620px] space-y-3 overflow-y-auto p-4">
                                        {categoryWallpapers.length === 0 ? (
                                            <div className={`rounded-2xl border border-dashed px-4 py-10 text-center text-sm ${
                                                isDropTarget
                                                    ? 'border-slate-500 text-slate-200'
                                                    : 'border-slate-700 text-slate-500'
                                            }`}>
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
                                                    className={`rounded-2xl border p-3 transition ${
                                                        draggedWallpaperId === wallpaper.id
                                                            ? 'border-slate-500 bg-slate-800'
                                                            : 'border-slate-800 bg-slate-950 hover:border-slate-700'
                                                    } ${movingWallpaperId === wallpaper.id ? 'opacity-50' : ''}`}
                                                >
                                                    <div className="flex items-center gap-3">
                                                        <img
                                                            src={wallpaper.thumbnailUrl || wallpaper.imageUrl}
                                                            alt={wallpaper.title}
                                                            className="h-20 w-14 rounded-xl object-cover"
                                                        />

                                                        <div className="min-w-0 flex-1">
                                                            <div className="flex items-center gap-2">
                                                                <p className="truncate text-sm font-medium text-white">{wallpaper.title}</p>
                                                                {wallpaper.isPro && (
                                                                    <span className="rounded-full bg-slate-800 px-2 py-0.5 text-[10px] text-slate-300">
                                                                        Pro
                                                                    </span>
                                                                )}
                                                            </div>
                                                            <p className="mt-1 text-xs text-slate-500">Drag to move</p>
                                                        </div>

                                                        <ArrowsRightLeftIcon className="h-4 w-4 flex-shrink-0 text-slate-500" />
                                                    </div>
                                                </article>
                                            ))
                                        )}
                                    </div>
                                </section>
                            );
                        })}
                    </div>
                </div>
            )}
        </div>
    );
}
