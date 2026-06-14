import { useEffect, useMemo, useRef, useState } from 'react';
import toast from 'react-hot-toast';
import { Edit, Grid2X2, List, Search, Star, Trash2, Upload } from 'lucide-react';
import { categoriesApi, packsApi, wallpapersApi } from '../services/api';
import { AdminPage, AdminPanel, EmptyState, StatusTag } from '../components/admin/AdminPage';
import { AdminModal } from '../components/admin/AdminModal';
import { Button } from '../components/ui/button';

interface Wallpaper {
  id: string;
  title: string;
  imageUrl: string;
  thumbnailUrl: string;
  category: { name: string; slug: string; id: string };
  isPro: boolean;
  isWide?: boolean;
  tags?: string[];
  downloads: number;
}

interface Category {
  id: string;
  name: string;
  slug: string;
}

interface Pack {
  id: string;
  name: string;
}

const ADJECTIVES = ['Abstract', 'Vibrant', 'Dark', 'Neon', 'Minimal', 'Colorful', 'Dreamy', 'Mystic', 'Modern', 'Retro', 'Cosmic', 'Epic', 'Cinematic', 'Elegant', 'Wild', 'Urban'];
const NOUNS = ['Vibes', 'Art', 'Concept', 'Design', 'Vision', 'Scene', 'World', 'Zone', 'Style', 'Mood', 'Essence', 'View', 'Horizon', 'Scape'];

const generateRandomTitle = (categoryName: string) => {
  const randomSuffix = Math.floor(Math.random() * 1000) + 1;
  if (Math.random() > 0.5) {
    const adjective = ADJECTIVES[Math.floor(Math.random() * ADJECTIVES.length)];
    return `${adjective} ${categoryName} ${randomSuffix}`;
  }

  const noun = NOUNS[Math.floor(Math.random() * NOUNS.length)];
  return `${categoryName} ${noun} ${randomSuffix}`;
};

export default function Wallpapers() {
  const [wallpapers, setWallpapers] = useState<Wallpaper[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [packs, setPacks] = useState<Pack[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [viewMode, setViewMode] = useState<'list' | 'grid'>('list');
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);
  const [isLoadingMore, setIsLoadingMore] = useState(false);
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [editingWallpaper, setEditingWallpaper] = useState<Wallpaper | null>(null);
  const [showEditModal, setShowEditModal] = useState(false);
  const [formData, setFormData] = useState({
    title: '',
    categories: [] as string[],
    tags: '',
    isPro: false,
    isWide: false,
    packId: '',
    newCategoryName: '',
    newCategoryEmoji: '',
  });
  const [selectedFiles, setSelectedFiles] = useState<File[]>([]);
  const [previewUrls, setPreviewUrls] = useState<string[]>([]);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);

  useEffect(() => {
    void fetchCategories();
    void fetchPacks();
  }, []);

  useEffect(() => {
    void fetchWallpapers(true);
  }, [selectedCategory]);

  useEffect(() => {
    return () => {
      previewUrls.forEach((url) => URL.revokeObjectURL(url));
    };
  }, [previewUrls]);

  const filteredWallpapers = useMemo(() => {
    if (!searchQuery.trim()) {
      return wallpapers;
    }

    const query = searchQuery.toLowerCase();
    return wallpapers.filter(
      (wallpaper) =>
        wallpaper.title.toLowerCase().includes(query) ||
        wallpaper.category?.name?.toLowerCase().includes(query)
    );
  }, [searchQuery, wallpapers]);

  const wallpaperStats = useMemo(() => {
    const total = filteredWallpapers.length;
    const pro = filteredWallpapers.filter((wallpaper) => wallpaper.isPro).length;
    const wide = filteredWallpapers.filter((wallpaper) => wallpaper.isWide).length;
    const downloads = filteredWallpapers.reduce((sum, wallpaper) => sum + wallpaper.downloads, 0);

    return { total, pro, wide, downloads };
  }, [filteredWallpapers]);

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

  const fetchWallpapers = async (reset = false) => {
    if (!reset && !hasMore) {
      return;
    }

    if (reset) {
      setIsLoading(true);
    } else {
      setIsLoadingMore(true);
    }

    try {
      const nextPage = reset ? 1 : page;
      const params: { page: number; limit: number; category?: string } = { page: nextPage, limit: 20 };
      if (selectedCategory !== 'all') {
        params.category = selectedCategory;
      }

      const response = await wallpapersApi.getAll(params);
      const nextWallpapers = response.data.wallpapers || [];
      const totalPages = response.data.pagination?.pages || 1;

      if (reset) {
        setWallpapers(nextWallpapers);
        setPage(2);
      } else {
        setWallpapers((current) => [...current, ...nextWallpapers]);
        setPage((current) => current + 1);
      }

      setHasMore(nextPage < totalPages);
      if (reset) {
        setSelectedIds(new Set());
      }
    } catch (error) {
      console.error('Failed to fetch wallpapers:', error);
    } finally {
      setIsLoading(false);
      setIsLoadingMore(false);
    }
  };

  const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(event.target.files || []);
    if (!files.length) {
      return;
    }

    setSelectedFiles((current) => [...current, ...files]);
    const nextPreviewUrls = files.map((file) => URL.createObjectURL(file));
    setPreviewUrls((current) => [...current, ...nextPreviewUrls]);
  };

  const removeFile = (index: number) => {
    setSelectedFiles((current) => current.filter((_, fileIndex) => fileIndex !== index));
    setPreviewUrls((current) => {
      URL.revokeObjectURL(current[index]);
      return current.filter((_, previewIndex) => previewIndex !== index);
    });
  };

  const toggleCategorySelection = (categoryId: string, checked: boolean) => {
    setFormData((current) => ({
      ...current,
      categories: checked
        ? [...current.categories, categoryId]
        : current.categories.filter((id) => id !== categoryId),
    }));
  };

  const resetForm = () => {
    setFormData({
      title: '',
      categories: [],
      tags: '',
      isPro: false,
      isWide: false,
      packId: '',
      newCategoryName: '',
      newCategoryEmoji: '',
    });
    setSelectedFiles([]);
    previewUrls.forEach((url) => URL.revokeObjectURL(url));
    setPreviewUrls([]);
  };

  const handleSubmit = async () => {
    if (!selectedFiles.length || (!formData.categories.length && !formData.newCategoryName.trim())) {
      toast.error('Select files and at least one category');
      return;
    }

    setIsSubmitting(true);
    setUploadProgress(0);

    let successCount = 0;
    let failCount = 0;
    const categoryOperations = formData.categories.length + (formData.newCategoryName.trim() ? 1 : 0);
    const totalOperations = Math.max(1, selectedFiles.length * categoryOperations);
    let completedOperations = 0;

    try {
      for (let index = 0; index < selectedFiles.length; index += 1) {
        const file = selectedFiles[index];

        for (const categoryId of formData.categories) {
          const data = new FormData();
          data.append('image', file);
          data.append('title', formData.title
            ? selectedFiles.length > 1 ? `${formData.title} ${index + 1}` : formData.title
            : generateRandomTitle(categories.find((category) => category.id === categoryId)?.name || 'Wallpaper'));
          data.append('category', categoryId);
          data.append('tags', formData.tags);
          data.append('isPro', String(formData.isPro));
          data.append('isWide', String(formData.isWide));
          if (formData.packId) {
            data.append('packId', formData.packId);
          }

          try {
            await wallpapersApi.create(data);
            successCount += 1;
          } catch (error) {
            console.error('Failed to upload wallpaper:', error);
            failCount += 1;
          }

          completedOperations += 1;
          setUploadProgress(Math.round((completedOperations / totalOperations) * 100));
        }

        if (formData.newCategoryName.trim()) {
          try {
            let categoryId =
              categories.find((category) => category.name.toLowerCase() === formData.newCategoryName.toLowerCase())?.id || '';

            if (!categoryId) {
              const response = await categoriesApi.create({
                name: formData.newCategoryName.trim(),
                icon: formData.newCategoryEmoji || '🎨',
              });
              categoryId = response.data.category.id;
              await fetchCategories();
            }

            const data = new FormData();
            data.append('image', file);
            data.append(
              'title',
              formData.title
                ? selectedFiles.length > 1
                  ? `${formData.title} ${index + 1}`
                  : formData.title
                : generateRandomTitle(formData.newCategoryName.trim())
            );
            data.append('category', categoryId);
            data.append('tags', formData.tags);
            data.append('isPro', String(formData.isPro));
            data.append('isWide', String(formData.isWide));
            if (formData.packId) {
              data.append('packId', formData.packId);
            }

            await wallpapersApi.create(data);
            successCount += 1;
          } catch (error) {
            console.error('Failed to upload wallpaper to new category:', error);
            failCount += 1;
          }

          completedOperations += 1;
          setUploadProgress(Math.round((completedOperations / totalOperations) * 100));
        }
      }

      if (successCount > 0) {
        toast.success(`Uploaded ${successCount} wallpaper${successCount !== 1 ? 's' : ''}`);
        if (failCount > 0) {
          toast.error(`${failCount} uploads failed`);
        }
        setShowModal(false);
        resetForm();
        await fetchWallpapers(true);
      } else {
        toast.error('Failed to upload wallpapers');
      }
    } finally {
      setIsSubmitting(false);
      setUploadProgress(0);
    }
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm('Are you sure you want to delete this wallpaper?')) {
      return;
    }

    try {
      await wallpapersApi.delete(id);
      toast.success('Wallpaper deleted');
      await fetchWallpapers(true);
      setSelectedIds((current) => {
        const next = new Set(current);
        next.delete(id);
        return next;
      });
    } catch {
      toast.error('Failed to delete wallpaper');
    }
  };

  const handleBulkDelete = async () => {
    if (!selectedIds.size || !window.confirm(`Delete ${selectedIds.size} selected wallpapers?`)) {
      return;
    }

    let deletedCount = 0;
    for (const id of selectedIds) {
      try {
        await wallpapersApi.delete(id);
        deletedCount += 1;
      } catch (error) {
        console.error(`Failed to delete ${id}`, error);
      }
    }

    toast.success(`Deleted ${deletedCount} wallpapers`);
    setSelectedIds(new Set());
    await fetchWallpapers(true);
  };

  const handleBulkSetPro = async (isPro: boolean) => {
    if (!selectedIds.size || !window.confirm(`Mark ${selectedIds.size} wallpapers as ${isPro ? 'Pro' : 'Free'}?`)) {
      return;
    }

    let updatedCount = 0;
    for (const id of selectedIds) {
      try {
        await wallpapersApi.update(id, { isPro });
        updatedCount += 1;
      } catch (error) {
        console.error(`Failed to update ${id}`, error);
      }
    }

    toast.success(`Updated ${updatedCount} wallpapers`);
    setSelectedIds(new Set());
    await fetchWallpapers(true);
  };

  const handleTogglePro = async (wallpaper: Wallpaper) => {
    const nextValue = !wallpaper.isPro;

    setWallpapers((current) =>
      current.map((item) => (item.id === wallpaper.id ? { ...item, isPro: nextValue } : item))
    );

    try {
      await wallpapersApi.update(wallpaper.id, { isPro: nextValue });
      toast.success(`Wallpaper marked as ${nextValue ? 'Pro' : 'Free'}`);
    } catch {
      setWallpapers((current) =>
        current.map((item) => (item.id === wallpaper.id ? { ...item, isPro: wallpaper.isPro } : item))
      );
      toast.error('Failed to update wallpaper status');
    }
  };

  const handleEditSubmit = async () => {
    if (!editingWallpaper) {
      return;
    }

    try {
      await wallpapersApi.update(editingWallpaper.id, {
        title: formData.title,
        category: formData.categories[0] || editingWallpaper.category.id,
        tags: formData.tags,
        isPro: formData.isPro,
        isWide: formData.isWide,
        packId: formData.packId,
      });
      toast.success('Wallpaper updated');
      setShowEditModal(false);
      setEditingWallpaper(null);
      await fetchWallpapers(true);
    } catch {
      toast.error('Failed to update wallpaper');
    }
  };

  const startEditWallpaper = (wallpaper: Wallpaper) => {
    setEditingWallpaper(wallpaper);
    setFormData((current) => ({
      ...current,
      title: wallpaper.title,
      categories: wallpaper.category?.id ? [wallpaper.category.id] : [],
      tags: wallpaper.tags?.join(', ') || '',
      isPro: wallpaper.isPro,
      isWide: Boolean(wallpaper.isWide),
      packId: '',
    }));
    setShowEditModal(true);
  };

  const fileInputRef = useRef<HTMLInputElement>(null);

  const visibleSelected = filteredWallpapers.filter((wallpaper) => selectedIds.has(wallpaper.id)).length;
  const allVisibleSelected = filteredWallpapers.length > 0 && visibleSelected === filteredWallpapers.length;

  return (
    <AdminPage
      title="Wallpapers"
      subtitle="Run the core content workflow: upload, classify, edit, promote, and clean up wallpaper inventory."
      actions={
        <>
          {selectedIds.size > 0 ? (
            <>
              <Button variant="secondary" size="sm" onClick={() => void handleBulkSetPro(true)}>
                <Star size={14} /> Mark Pro
              </Button>
              <Button variant="secondary" size="sm" onClick={() => void handleBulkSetPro(false)}>
                Mark Free
              </Button>
              <Button variant="destructive" size="sm" onClick={() => void handleBulkDelete()}>
                <Trash2 size={14} /> Delete ({selectedIds.size})
              </Button>
            </>
          ) : null}
          <Button size="sm" onClick={() => setShowModal(true)}>
            <Upload size={14} /> Upload wallpapers
          </Button>
        </>
      }
    >
      <div className="admin-grid admin-grid--stats">
        <AdminPanel title="Loaded" description="Currently visible wallpapers after filters.">
          <div className="admin-stat__value">{wallpaperStats.total}</div>
        </AdminPanel>
        <AdminPanel title="Pro items" description="Premium wallpapers in the current result set.">
          <div className="admin-stat__value">{wallpaperStats.pro}</div>
        </AdminPanel>
        <AdminPanel title="Wide items" description="Desktop or wide-format wallpapers loaded here.">
          <div className="admin-stat__value">{wallpaperStats.wide}</div>
        </AdminPanel>
        <AdminPanel title="Downloads" description="Combined downloads for the loaded result set.">
          <div className="admin-stat__value">{wallpaperStats.downloads}</div>
        </AdminPanel>
      </div>

      <AdminPanel title="Filters" description="Search the loaded inventory and narrow the feed by category.">
        <div className="admin-form-grid">
          <div className="afield">
            <label className="afield__label">Search wallpapers</label>
            <div style={{ position: 'relative' }}>
              <Search size={13} style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', color: 'var(--admin-text-sub)' }} />
              <input
                className="afield__input"
                style={{ paddingLeft: 32 }}
                placeholder="Search by title or category"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>
          </div>
          <div className="afield">
            <label className="afield__label">Category</label>
            <select
              className="afield__select"
              value={selectedCategory}
              onChange={(e) => { setSelectedCategory(e.target.value); setPage(1); setHasMore(true); }}
            >
              <option value="all">All categories</option>
              {categories.map((c) => <option key={c.id} value={c.slug || c.id}>{c.name}</option>)}
            </select>
          </div>
        </div>
      </AdminPanel>

      <AdminPanel
        title="Wallpaper inventory"
        description={`${filteredWallpapers.length} loaded wallpapers${selectedIds.size ? `, ${visibleSelected} selected` : ''}`}
        actions={
          <div className="admin-view-toggle" aria-label="Wallpaper inventory view">
            <button
              type="button"
              className={`admin-view-toggle__button ${viewMode === 'list' ? 'admin-view-toggle__button--active' : ''}`}
              title="List view"
              aria-pressed={viewMode === 'list'}
              onClick={() => setViewMode('list')}
            >
              <List size={14} />
            </button>
            <button
              type="button"
              className={`admin-view-toggle__button ${viewMode === 'grid' ? 'admin-view-toggle__button--active' : ''}`}
              title="Grid view"
              aria-pressed={viewMode === 'grid'}
              onClick={() => setViewMode('grid')}
            >
              <Grid2X2 size={14} />
            </button>
          </div>
        }
      >
        {isLoading ? (
          <p style={{ color: 'var(--admin-text-muted)', padding: '16px 0' }}>Loading wallpapers…</p>
        ) : filteredWallpapers.length === 0 ? (
          <EmptyState
            title="No wallpapers found"
            message="Adjust the filters or upload new content to populate the library."
            actionLabel="Upload wallpapers"
            onAction={() => setShowModal(true)}
          />
        ) : (
          <div className="admin-grid">
            {viewMode === 'list' ? (
              <div style={{ overflowX: 'auto' }}>
                <table className="admin-table">
                  <thead>
                    <tr>
                      <th><input type="checkbox" checked={allVisibleSelected} onChange={(e) => {
                        if (e.target.checked) setSelectedIds(new Set(filteredWallpapers.map((w) => w.id)));
                        else setSelectedIds(new Set());
                      }} /></th>
                      <th>Wallpaper</th>
                      <th>Category</th>
                      <th>Downloads</th>
                      <th>Access</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredWallpapers.map((wallpaper) => (
                      <tr key={wallpaper.id}>
                        <td>
                          <input
                            type="checkbox"
                            checked={selectedIds.has(wallpaper.id)}
                            onChange={(e) => setSelectedIds((cur) => {
                              const next = new Set(cur);
                              if (e.target.checked) next.add(wallpaper.id);
                              else next.delete(wallpaper.id);
                              return next;
                            })}
                          />
                        </td>
                        <td>
                          <div className="admin-media-object">
                            <img src={wallpaper.thumbnailUrl || wallpaper.imageUrl} alt={wallpaper.title} />
                            <div>
                              <strong style={{ fontSize: 13 }}>{wallpaper.title}</strong>
                              <div style={{ fontSize: 11, color: 'var(--admin-text-sub)', marginTop: 2 }}>{wallpaper.id}</div>
                            </div>
                          </div>
                        </td>
                        <td>{wallpaper.category?.name || 'Unassigned'}</td>
                        <td>{wallpaper.downloads}</td>
                        <td>
                          <StatusTag type={wallpaper.isPro ? 'purple' : 'cool-gray'}>
                            {wallpaper.isPro ? 'Pro' : 'Free'}
                          </StatusTag>
                        </td>
                        <td>
                          <div className="admin-inline-actions">
                            <button
                              className="admin-round-button"
                              title="Edit wallpaper"
                              onClick={() => startEditWallpaper(wallpaper)}
                            >
                              <Edit size={13} />
                            </button>
                            <button
                              className="admin-round-button"
                              title="Toggle pro"
                              onClick={() => void handleTogglePro(wallpaper)}
                            >
                              <Star size={13} />
                            </button>
                            <button
                              className="admin-round-button"
                              title="Delete"
                              style={{ color: 'var(--admin-red)' }}
                              onClick={() => void handleDelete(wallpaper.id)}
                            >
                              <Trash2 size={13} />
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : (
              <div className="wallpaper-grid-view">
                <label className="wallpaper-grid-select-all">
                  <input
                    type="checkbox"
                    checked={allVisibleSelected}
                    onChange={(e) => {
                      if (e.target.checked) setSelectedIds(new Set(filteredWallpapers.map((w) => w.id)));
                      else setSelectedIds(new Set());
                    }}
                  />
                  <span>Select visible</span>
                </label>

                <div className="wallpaper-card-grid">
                  {filteredWallpapers.map((wallpaper) => (
                    <article
                      key={wallpaper.id}
                      className={`wallpaper-card ${selectedIds.has(wallpaper.id) ? 'wallpaper-card--selected' : ''}`}
                    >
                      <label className="wallpaper-card__check" title="Select wallpaper">
                        <input
                          type="checkbox"
                          checked={selectedIds.has(wallpaper.id)}
                          onChange={(e) => setSelectedIds((cur) => {
                            const next = new Set(cur);
                            if (e.target.checked) next.add(wallpaper.id);
                            else next.delete(wallpaper.id);
                            return next;
                          })}
                        />
                      </label>
                      <div className="wallpaper-card__image">
                        <img src={wallpaper.thumbnailUrl || wallpaper.imageUrl} alt={wallpaper.title} />
                      </div>
                      <div className="wallpaper-card__body">
                        <div className="wallpaper-card__meta">
                          <h3>{wallpaper.title}</h3>
                          <span>{wallpaper.id}</span>
                        </div>
                        <div className="wallpaper-card__facts">
                          <span>{wallpaper.category?.name || 'Unassigned'}</span>
                          <span>{wallpaper.downloads} downloads</span>
                        </div>
                        <div className="wallpaper-card__footer">
                          <StatusTag type={wallpaper.isPro ? 'purple' : 'cool-gray'}>
                            {wallpaper.isPro ? 'Pro' : 'Free'}
                          </StatusTag>
                          <div className="admin-inline-actions">
                            <button className="admin-round-button" title="Edit wallpaper" onClick={() => startEditWallpaper(wallpaper)}>
                              <Edit size={13} />
                            </button>
                            <button className="admin-round-button" title="Toggle pro" onClick={() => void handleTogglePro(wallpaper)}>
                              <Star size={13} />
                            </button>
                            <button className="admin-round-button" title="Delete" style={{ color: 'var(--admin-red)' }} onClick={() => void handleDelete(wallpaper.id)}>
                              <Trash2 size={13} />
                            </button>
                          </div>
                        </div>
                      </div>
                    </article>
                  ))}
                </div>
              </div>
            )}

            {hasMore ? (
              <Button variant="secondary" size="sm" onClick={() => void fetchWallpapers(false)} disabled={isLoadingMore}>
                {isLoadingMore ? 'Loading more…' : 'Load more'}
              </Button>
            ) : null}
          </div>
        )}
      </AdminPanel>

      {/* ── Upload modal ─────────────────────────────────── */}
      <AdminModal
        open={showModal}
        title="Upload wallpapers"
        primaryLabel={isSubmitting ? `Uploading… ${uploadProgress}%` : 'Start upload'}
        primaryDisabled={isSubmitting}
        onConfirm={() => void handleSubmit()}
        onClose={() => { setShowModal(false); resetForm(); }}
        size="lg"
      >
        <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
          {/* File picker */}
          <div className="afield">
            <label className="afield__label">Wallpaper images</label>
            <p className="afield__helper">Choose one or more files. Uploads can target multiple categories at once.</p>
            <input ref={fileInputRef} type="file" accept="image/*" multiple style={{ display: 'none' }} onChange={handleFileSelect} />
            <button className="aupload-zone" type="button" onClick={() => fileInputRef.current?.click()}>
              <Upload size={16} /> Choose files
            </button>
          </div>

          {previewUrls.length > 0 && (
            <div className="admin-preview-grid">
              {previewUrls.map((url, index) => (
                <div key={url} className="admin-preview-card">
                  <img src={url} alt={`Preview ${index + 1}`} />
                  <button type="button" style={{ fontSize: 11, color: 'var(--admin-red)', background: 'none', border: 'none', cursor: 'pointer' }} onClick={() => removeFile(index)}>Remove</button>
                </div>
              ))}
            </div>
          )}

          {isSubmitting && (
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6, fontSize: 12 }}>
                <span style={{ color: 'var(--admin-text-muted)' }}>Upload progress</span>
                <span style={{ fontWeight: 600 }}>{uploadProgress}%</span>
              </div>
              <div className="admin-progress-track"><div className="admin-progress-bar" style={{ width: `${uploadProgress}%` }} /></div>
            </div>
          )}

          <div className="admin-form-grid">
            <div className="afield">
              <label className="afield__label">{selectedFiles.length > 1 ? 'Base title' : 'Title'}</label>
              <input className="afield__input" placeholder="Leave empty to auto-generate from category" value={formData.title} onChange={(e) => setFormData((c) => ({ ...c, title: e.target.value }))} />
              <span className="afield__helper">Leave empty to auto-generate titles from the category name.</span>
            </div>
            <div className="afield">
              <label className="afield__label">Tags</label>
              <input className="afield__input" placeholder="Comma separated tags" value={formData.tags} onChange={(e) => setFormData((c) => ({ ...c, tags: e.target.value }))} />
              <span className="afield__helper">Comma separated tags.</span>
            </div>
            <div className="afield">
              <label className="afield__label">Assign to pack</label>
              <select className="afield__select" value={formData.packId} onChange={(e) => setFormData((c) => ({ ...c, packId: e.target.value }))}>
                <option value="">No pack</option>
                {packs.map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}
              </select>
            </div>
            <div className="afield">
              <label className="afield__label">Create new category</label>
              <input className="afield__input" placeholder="Category name" value={formData.newCategoryName} onChange={(e) => setFormData((c) => ({ ...c, newCategoryName: e.target.value }))} />
              <span className="afield__helper">Optional. If set, uploads will also create/use this category.</span>
            </div>
            <div className="afield">
              <label className="afield__label">New category emoji</label>
              <input className="afield__input" value={formData.newCategoryEmoji} onChange={(e) => setFormData((c) => ({ ...c, newCategoryEmoji: e.target.value }))} />
            </div>
          </div>

          <div>
            <strong style={{ display: 'block', fontSize: 13, marginBottom: 10 }}>Assign to existing categories</strong>
            <div className="acat-grid">
              {categories.map((cat) => (
                <label
                  key={cat.id}
                  className={`acat-item ${formData.categories.includes(cat.id) ? 'acat-item--selected' : ''}`}
                >
                  <input
                    type="checkbox"
                    checked={formData.categories.includes(cat.id)}
                    onChange={(e) => toggleCategorySelection(cat.id, e.target.checked)}
                  />
                  <span>{cat.name}</span>
                </label>
              ))}
            </div>
          </div>

          <div style={{ display: 'flex', gap: 20 }}>
            <label className="afield__checkbox-row">
              <input type="checkbox" checked={formData.isPro} onChange={(e) => setFormData((c) => ({ ...c, isPro: e.target.checked }))} />
              <span>Pro only</span>
            </label>
            <label className="afield__checkbox-row">
              <input type="checkbox" checked={formData.isWide} onChange={(e) => setFormData((c) => ({ ...c, isWide: e.target.checked }))} />
              <span>Wide desktop wallpaper</span>
            </label>
          </div>
        </div>
      </AdminModal>

      {/* ── Edit modal ───────────────────────────────────── */}
      <AdminModal
        open={showEditModal}
        title="Edit wallpaper"
        primaryLabel="Save changes"
        onConfirm={() => void handleEditSubmit()}
        onClose={() => { setShowEditModal(false); setEditingWallpaper(null); }}
      >
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          <div className="afield">
            <label className="afield__label">Title</label>
            <input className="afield__input" value={formData.title} onChange={(e) => setFormData((c) => ({ ...c, title: e.target.value }))} />
          </div>
          <div className="afield">
            <label className="afield__label">Tags</label>
            <input className="afield__input" placeholder="Comma separated tags" value={formData.tags} onChange={(e) => setFormData((c) => ({ ...c, tags: e.target.value }))} />
            <span className="afield__helper">Comma separated tags.</span>
          </div>
          <div className="afield">
            <label className="afield__label">Category</label>
            <select className="afield__select" value={formData.categories[0] || ''} onChange={(e) => setFormData((c) => ({ ...c, categories: e.target.value ? [e.target.value] : [] }))}>
              <option value="">Select category</option>
              {categories.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
            </select>
          </div>
          <div className="afield">
            <label className="afield__label">Pack</label>
            <select className="afield__select" value={formData.packId} onChange={(e) => setFormData((c) => ({ ...c, packId: e.target.value }))}>
              <option value="">No pack</option>
              {packs.map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}
            </select>
          </div>
          <div style={{ display: 'flex', gap: 20 }}>
            <label className="afield__checkbox-row">
              <input type="checkbox" checked={formData.isPro} onChange={(e) => setFormData((c) => ({ ...c, isPro: e.target.checked }))} />
              <span>Pro only</span>
            </label>
            <label className="afield__checkbox-row">
              <input type="checkbox" checked={formData.isWide} onChange={(e) => setFormData((c) => ({ ...c, isWide: e.target.checked }))} />
              <span>Wide desktop wallpaper</span>
            </label>
          </div>
        </div>
      </AdminModal>
    </AdminPage>
  );
}
