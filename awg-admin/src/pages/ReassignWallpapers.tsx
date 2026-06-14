import { useEffect, useMemo, useState } from 'react';
import { Search } from 'lucide-react';
import toast from 'react-hot-toast';
import { categoriesApi, wallpapersApi } from '../services/api';
import { AdminPage, AdminPanel, EmptyState, StatusTag } from '../components/admin/AdminPage';

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
    categories.forEach((category) => grouped.set(category.id, []));

    filteredWallpapers.forEach((wallpaper) => {
      const categoryId = wallpaper.category?.id;
      if (categoryId) {
        grouped.get(categoryId)?.push(wallpaper);
      }
    });

    return grouped;
  }, [categories, filteredWallpapers]);

  const handleDrop = async (targetCategoryId: string) => {
    if (!draggedWallpaperId) {
      return;
    }

    const wallpaper = wallpapers.find((item) => item.id === draggedWallpaperId);
    const targetCategory = categories.find((category) => category.id === targetCategoryId);

    if (!wallpaper || !targetCategory || wallpaper.category?.id === targetCategoryId) {
      setDraggedWallpaperId(null);
      setDragOverCategoryId(null);
      return;
    }

    const previousCategory = wallpaper.category;

    setMovingWallpaperId(wallpaper.id);
    setWallpapers((current) =>
      current.map((item) =>
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

    try {
      const response = await wallpapersApi.bulkReassign({
        wallpaperIds: [wallpaper.id],
        targetCategoryId,
      });

      toast.success(
        response.data?.movedCount > 0 ? `Moved to ${targetCategory.name}` : `Already in ${targetCategory.name}`
      );
    } catch (error) {
      console.error('Failed to reassign wallpaper:', error);
      setWallpapers((current) =>
        current.map((item) =>
          item.id === wallpaper.id
            ? {
                ...item,
                category: previousCategory,
              }
            : item
        )
      );
      toast.error('Failed to move wallpaper');
    } finally {
      setDraggedWallpaperId(null);
      setDragOverCategoryId(null);
      setMovingWallpaperId(null);
    }
  };

  return (
    <AdminPage
      title="Reassign wallpapers"
      subtitle="Move wallpapers between categories with a drag-and-drop board built for high-volume cleanup."
    >
      <AdminPanel title="Search" description="Filter the board by title or category before dragging items between columns.">
        <div className="afield">
          <label className="afield__label">Search wallpapers</label>
          <div style={{ position: 'relative' }}>
            <Search size={13} style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', color: 'var(--admin-text-sub)' }} />
            <input className="afield__input" style={{ paddingLeft: 32 }} placeholder="Search wallpapers" value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} />
          </div>
        </div>
      </AdminPanel>

      <AdminPanel
        title="Category board"
        description={`${filteredWallpapers.length} wallpapers across ${categories.length} categories`}
      >
        {isLoading ? (
          <p>Loading reassignment board...</p>
        ) : categories.length === 0 ? (
          <EmptyState title="No categories found" message="Create categories before using bulk reassignment." />
        ) : (
          <div className="admin-grid admin-grid--cards">
            {categories.map((category) => {
              const categoryWallpapers = wallpapersByCategory.get(category.id) || [];
              const isDropTarget = dragOverCategoryId === category.id;

              return (
                <AdminPanel
                  key={category.id}
                  title={`${category.icon || '🖼️'} ${category.name}`}
                  description={`${categoryWallpapers.length} wallpapers`}
                  className={`admin-drop-column ${isDropTarget ? 'admin-drop-zone--active' : ''}`}
                >
                  <div
                    className={`admin-drop-zone ${isDropTarget ? 'admin-drop-zone--active' : ''}`}
                    onDragOver={(event) => {
                      event.preventDefault();
                      setDragOverCategoryId(category.id);
                    }}
                    onDragLeave={() => {
                      setDragOverCategoryId((current) => (current === category.id ? null : current));
                    }}
                    onDrop={(event) => {
                      event.preventDefault();
                      void handleDrop(category.id);
                    }}
                  >
                    {categoryWallpapers.length === 0 ? (
                      <p className="admin-authors">Drop wallpapers here.</p>
                    ) : (
                      <div className="admin-grid">
                        {categoryWallpapers.map((wallpaper) => (
                          <div
                            key={wallpaper.id}
                            draggable={movingWallpaperId !== wallpaper.id}
                            onDragStart={() => setDraggedWallpaperId(wallpaper.id)}
                            onDragEnd={() => {
                              setDraggedWallpaperId(null);
                              setDragOverCategoryId(null);
                            }}
                            className="admin-drop-card"
                          >
                            <div className="admin-media-object">
                              <img src={wallpaper.thumbnailUrl || wallpaper.imageUrl} alt={wallpaper.title} />
                              <div>
                                <strong>{wallpaper.title}</strong>
                                <div className="admin-chip-row" style={{ marginTop: '0.5rem' }}>
                                  {wallpaper.isPro ? <StatusTag type="purple">Pro</StatusTag> : null}
                                  <StatusTag type="cool-gray">Drag to move</StatusTag>
                                </div>
                              </div>
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                </AdminPanel>
              );
            })}
          </div>
        )}
      </AdminPanel>
    </AdminPage>
  );
}
