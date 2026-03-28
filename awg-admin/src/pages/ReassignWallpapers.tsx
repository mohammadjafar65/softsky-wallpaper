import { useEffect, useMemo, useState } from 'react';
import toast from 'react-hot-toast';
import {
    ArrowPathIcon,
    ArrowsRightLeftIcon,
    CursorArrowRaysIcon,
    MagnifyingGlassIcon,
    PhotoIcon,
    QueueListIcon,
    SparklesIcon,
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
    const [isRefreshing, setIsRefreshing] = useState(false);
    const [draggedWallpaperId, setDraggedWallpaperId] = useState<string | null>(null);
    const [dragOverCategoryId, setDragOverCategoryId] = useState<string | null>(null);
    const [movingWallpaperId, setMovingWallpaperId] = useState<string | null>(null);

    useEffect(() => {
        void loadData();
    }, []);

    const loadData = async (refresh = false) => {
        if (refresh) {
            setIsRefreshing(true);
        } else {
            setIsLoading(true);
        }

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
            setIsRefreshing(false);
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

            if (!grouped.has(categoryId)) {
                grouped.set(categoryId, []);
            }

            grouped.get(categoryId)?.push(wallpaper);
        });

        return grouped;
    }, [categories, filteredWallpapers]);

    const draggedWallpaper = useMemo(
        () => wallpapers.find((item) => item.id === draggedWallpaperId) || null,
        [draggedWallpaperId, wallpapers]
    );

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
            <section className="relative overflow-hidden rounded-[2rem] border border-white/10 bg-slate-900/70 shadow-2xl shadow-slate-950/40">
                <div className="absolute inset-0 bg-[radial-gradient(circle_at_top_left,rgba(14,165,233,0.18),transparent_32%),radial-gradient(circle_at_bottom_right,rgba(168,85,247,0.18),transparent_28%)]" />
                <div className="relative grid gap-6 p-6 md:p-8 xl:grid-cols-[1.25fr_0.95fr]">
                    <div className="space-y-6">
                        <div className="inline-flex items-center gap-2 rounded-full border border-sky-400/20 bg-sky-400/10 px-3 py-1 text-xs font-semibold uppercase tracking-[0.24em] text-sky-300">
                            <SparklesIcon className="h-4 w-4" />
                            Reassignment Studio
                        </div>

                        <div className="max-w-2xl">
                            <h1 className="text-3xl font-bold tracking-tight text-white md:text-4xl">
                                Move wallpapers between categories with a cleaner drag-and-drop board.
                            </h1>
                            <p className="mt-3 text-sm leading-6 text-slate-300 md:text-base">
                                Search what you need, pick up a wallpaper card, and drop it into the category lane where it belongs.
                                The board updates counts instantly so you can reorganize faster.
                            </p>
                        </div>

                        <div className="grid gap-4 sm:grid-cols-3">
                            <div className="rounded-2xl border border-white/10 bg-black/20 p-4 backdrop-blur-sm">
                                <p className="text-xs uppercase tracking-[0.2em] text-slate-400">Categories</p>
                                <p className="mt-3 text-3xl font-bold text-white">{categories.length}</p>
                            </div>
                            <div className="rounded-2xl border border-white/10 bg-black/20 p-4 backdrop-blur-sm">
                                <p className="text-xs uppercase tracking-[0.2em] text-slate-400">Loaded</p>
                                <p className="mt-3 text-3xl font-bold text-white">{wallpapers.length}</p>
                            </div>
                            <div className="rounded-2xl border border-white/10 bg-black/20 p-4 backdrop-blur-sm">
                                <p className="text-xs uppercase tracking-[0.2em] text-slate-400">Visible</p>
                                <p className="mt-3 text-3xl font-bold text-white">{filteredWallpapers.length}</p>
                            </div>
                        </div>
                    </div>

                    <div className="rounded-[1.75rem] border border-white/10 bg-slate-950/60 p-5 backdrop-blur-sm">
                        <div className="flex items-center justify-between gap-3">
                            <div>
                                <p className="text-sm font-semibold text-white">Current Drag Session</p>
                                <p className="mt-1 text-sm text-slate-400">
                                    {draggedWallpaper
                                        ? `Moving "${draggedWallpaper.title}"`
                                        : 'Start dragging any wallpaper card to reveal a target lane.'}
                                </p>
                            </div>
                            <div className="rounded-2xl border border-violet-500/20 bg-violet-500/10 p-3 text-violet-300">
                                <ArrowsRightLeftIcon className="h-6 w-6" />
                            </div>
                        </div>

                        <div className="mt-5 space-y-3">
                            <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
                                <div className="flex items-start gap-3">
                                    <CursorArrowRaysIcon className="mt-0.5 h-5 w-5 text-sky-300" />
                                    <div>
                                        <p className="font-medium text-white">Drag from any lane</p>
                                        <p className="mt-1 text-sm text-slate-400">Pick a wallpaper card and hold it while moving across the board.</p>
                                    </div>
                                </div>
                            </div>
                            <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
                                <div className="flex items-start gap-3">
                                    <QueueListIcon className="mt-0.5 h-5 w-5 text-violet-300" />
                                    <div>
                                        <p className="font-medium text-white">Drop into a highlighted lane</p>
                                        <p className="mt-1 text-sm text-slate-400">The target category glows so it is clear where the wallpaper will land.</p>
                                    </div>
                                </div>
                            </div>
                            <button
                                type="button"
                                onClick={() => void loadData(true)}
                                disabled={isRefreshing}
                                className="flex w-full items-center justify-center gap-2 rounded-2xl border border-slate-700 bg-slate-900 px-4 py-3 text-sm font-medium text-slate-200 transition hover:border-sky-500/40 hover:bg-slate-800 disabled:cursor-not-allowed disabled:opacity-60"
                            >
                                <ArrowPathIcon className={`h-4 w-4 ${isRefreshing ? 'animate-spin' : ''}`} />
                                {isRefreshing ? 'Refreshing board...' : 'Refresh Board'}
                            </button>
                        </div>
                    </div>
                </div>
            </section>

            <section className="rounded-[2rem] border border-white/10 bg-slate-900/50 p-5 md:p-6">
                <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
                    <div>
                        <p className="text-sm font-semibold text-white">Category Lanes</p>
                        <p className="mt-1 text-sm text-slate-400">
                            A board layout works better here because you can compare categories side by side before dropping.
                        </p>
                    </div>

                    <div className="w-full max-w-md">
                        <label className="relative block">
                            <MagnifyingGlassIcon className="pointer-events-none absolute left-4 top-1/2 h-5 w-5 -translate-y-1/2 text-slate-500" />
                            <input
                                value={searchQuery}
                                onChange={(e) => setSearchQuery(e.target.value)}
                                placeholder="Search wallpapers or categories"
                                className="w-full rounded-2xl border border-slate-800 bg-slate-950/90 py-3 pl-12 pr-4 text-white outline-none transition focus:border-sky-500/50 focus:ring-2 focus:ring-sky-500/20"
                            />
                        </label>
                    </div>
                </div>
            </section>

            {isLoading ? (
                <div className="grid gap-6 xl:grid-cols-3">
                    {Array.from({ length: 3 }).map((_, index) => (
                        <div key={index} className="h-[560px] animate-pulse rounded-[2rem] border border-white/5 bg-slate-900/50" />
                    ))}
                </div>
            ) : categories.length === 0 ? (
                <div className="rounded-[2rem] border border-dashed border-slate-700 bg-slate-900/40 px-6 py-20 text-center">
                    <p className="text-lg font-semibold text-white">No categories found</p>
                    <p className="mt-2 text-sm text-slate-400">Create categories first, then you can move wallpapers between them here.</p>
                </div>
            ) : (
                <div className="overflow-x-auto pb-2">
                    <div className="flex min-w-max gap-6">
                        {categories.map((category) => {
                            const categoryWallpapers = wallpapersByCategory.get(category.id) || [];
                            const isActiveDropZone = dragOverCategoryId === category.id;
                            const isDraggingAnother = draggedWallpaperId !== null && draggedWallpaper?.category?.id !== category.id;

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
                                    className={`w-[360px] flex-shrink-0 rounded-[2rem] border transition-all duration-200 ${
                                        isActiveDropZone
                                            ? 'border-sky-400 bg-sky-500/10 shadow-2xl shadow-sky-500/10'
                                            : isDraggingAnother
                                                ? 'border-violet-500/20 bg-violet-500/5'
                                                : 'border-white/10 bg-slate-900/65'
                                    }`}
                                >
                                    <div className="border-b border-white/10 p-5">
                                        <div className="flex items-start justify-between gap-4">
                                            <div className="min-w-0">
                                                <div className="flex items-center gap-3">
                                                    <div className="flex h-12 w-12 items-center justify-center rounded-2xl border border-white/10 bg-white/5 text-xl">
                                                        {category.icon || <PhotoIcon className="h-6 w-6 text-slate-300" />}
                                                    </div>
                                                    <div className="min-w-0">
                                                        <h2 className="truncate text-lg font-semibold text-white">{category.name}</h2>
                                                        <p className="truncate text-xs uppercase tracking-[0.2em] text-slate-500">{category.slug}</p>
                                                    </div>
                                                </div>
                                            </div>

                                            <div className="rounded-2xl border border-white/10 bg-black/20 px-3 py-2 text-right">
                                                <p className="text-[11px] uppercase tracking-[0.2em] text-slate-400">Visible</p>
                                                <p className="mt-1 text-xl font-bold text-white">{categoryWallpapers.length}</p>
                                            </div>
                                        </div>

                                        <div className="mt-4 flex items-center justify-between text-xs text-slate-400">
                                            <span>Total in category: {category.wallpaperCount}</span>
                                            <span>{isActiveDropZone ? 'Release to move here' : 'Drag target ready'}</span>
                                        </div>
                                    </div>

                                    <div className="max-h-[620px] space-y-3 overflow-y-auto p-4">
                                        {categoryWallpapers.length === 0 ? (
                                            <div className={`rounded-[1.5rem] border border-dashed px-5 py-14 text-center transition-all ${
                                                isActiveDropZone
                                                    ? 'border-sky-400/60 bg-sky-500/10 text-sky-200'
                                                    : 'border-slate-700 bg-slate-950/50 text-slate-500'
                                            }`}>
                                                <p className="font-medium">Drop wallpaper here</p>
                                                <p className="mt-1 text-sm">
                                                    {searchQuery ? 'No matching wallpapers in this lane right now.' : 'This category is ready to receive wallpapers.'}
                                                </p>
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
                                                    className={`group rounded-[1.5rem] border p-3 transition-all ${
                                                        movingWallpaperId === wallpaper.id
                                                            ? 'border-sky-400/30 bg-sky-500/10 opacity-50'
                                                            : draggedWallpaperId === wallpaper.id
                                                                ? 'border-violet-400/50 bg-violet-500/10 shadow-lg shadow-violet-500/10'
                                                                : 'border-white/10 bg-slate-950/85 hover:border-sky-500/30 hover:bg-slate-950'
                                                    }`}
                                                >
                                                    <div className="flex items-center gap-3">
                                                        <img
                                                            src={wallpaper.thumbnailUrl || wallpaper.imageUrl}
                                                            alt={wallpaper.title}
                                                            className="h-24 w-16 rounded-2xl object-cover shadow-lg shadow-black/30"
                                                        />

                                                        <div className="min-w-0 flex-1">
                                                            <div className="flex items-center gap-2">
                                                                <p className="truncate text-sm font-semibold text-white">{wallpaper.title}</p>
                                                                {wallpaper.isPro && (
                                                                    <span className="rounded-full border border-amber-500/30 bg-amber-500/10 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-amber-300">
                                                                        Pro
                                                                    </span>
                                                                )}
                                                            </div>
                                                            <p className="mt-2 text-xs text-slate-400">
                                                                Drag this card into another category lane to reassign it.
                                                            </p>
                                                        </div>

                                                        <div className="rounded-2xl border border-white/10 bg-white/5 p-2 text-slate-400 transition group-hover:text-sky-300">
                                                            <ArrowsRightLeftIcon className="h-5 w-5" />
                                                        </div>
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
