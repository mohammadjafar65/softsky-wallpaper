import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import axios from 'axios';
import { Edit, Plus, RefreshCw, Trash2 } from 'lucide-react';
import { categoriesApi, wallpapersApi } from '../services/api';
import { AdminPage, AdminPanel, EmptyState, StatusTag } from '../components/admin/AdminPage';
import { AdminModal } from '../components/admin/AdminModal';
import { Button } from '../components/ui/button';

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

interface CategoryWallpaper {
  id: string;
  title: string;
  imageUrl: string;
  thumbnailUrl?: string;
}

const getErrorMessage = (error: unknown, fallback: string) =>
  axios.isAxiosError<{ error?: string }>(error) ? error.response?.data?.error || fallback : fallback;

export default function Categories() {
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
  const [categoryWallpapers, setCategoryWallpapers] = useState<CategoryWallpaper[]>([]);
  const [isWallpapersLoading, setIsWallpapersLoading] = useState(false);

  useEffect(() => {
    void fetchCategories();
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

  const resetForm = () => {
    setFormData({ name: '', icon: '🎨', description: '' });
    setEditingCategory(null);
    setCategoryWallpapers([]);
  };

  const handleSubmit = async () => {
    setIsSubmitting(true);
    try {
      if (editingCategory) {
        await categoriesApi.update(editingCategory.id, formData);
        toast.success('Category updated');
      } else {
        await categoriesApi.create(formData);
        toast.success('Category created');
      }
      setShowModal(false);
      resetForm();
      await fetchCategories();
    } catch (error: unknown) {
      toast.error(getErrorMessage(error, 'Failed to save category'));
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleImport = async () => {
    if (!importUrl.trim()) {
      return;
    }

    setIsImporting(true);
    try {
      const response = await categoriesApi.importPinterest(importUrl);
      toast.success(`Imported ${response.data.importedCount} wallpapers from Pinterest`);
      setShowImportModal(false);
      setImportUrl('');
      await fetchCategories();
    } catch (error: unknown) {
      toast.error(getErrorMessage(error, 'Failed to import Pinterest board'));
    } finally {
      setIsImporting(false);
    }
  };

  const handleRefetch = async (id: string) => {
    setRefetchingId(id);
    try {
      const response = await categoriesApi.refetchPinterest(id);
      toast.success(
        response.data.importedCount > 0
          ? `Refetched ${response.data.importedCount} wallpapers`
          : 'No new wallpapers found'
      );
      await fetchCategories();
    } catch (error: unknown) {
      toast.error(getErrorMessage(error, 'Failed to refetch Pinterest board'));
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
      const response = await wallpapersApi.getAll({ category: category.slug });
      setCategoryWallpapers(response.data.wallpapers || []);
    } catch {
      setCategoryWallpapers([]);
    } finally {
      setIsWallpapersLoading(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm('Are you sure you want to delete this category?')) {
      return;
    }

    try {
      await categoriesApi.delete(id);
      toast.success('Category deleted');
      await fetchCategories();
    } catch (error: unknown) {
      toast.error(getErrorMessage(error, 'Failed to delete category'));
    }
  };

  return (
    <AdminPage
      title="Categories"
      subtitle="Organize content taxonomy, manage Pinterest imports, and inspect category health."
      actions={
        <>
          <Button variant="secondary" size="sm" onClick={() => setShowImportModal(true)}>
            Import Pinterest board
          </Button>
          <Button size="sm" onClick={() => setShowModal(true)}>
            <Plus size={14} /> Add category
          </Button>
        </>
      }
    >
      <AdminPanel title="Category library" description="Each category tracks its own inventory footprint and source state.">
        {isLoading ? (
          <p style={{ color: 'var(--admin-text-muted)', padding: '16px 0' }}>Loading categories…</p>
        ) : categories.length === 0 ? (
          <EmptyState
            title="No categories yet"
            message="Create your first category or import a Pinterest board to populate the library."
            actionLabel="Add category"
            onAction={() => setShowModal(true)}
          />
        ) : (
          <div className="category-card-grid">
            {categories.map((category) => (
              <article
                key={category.id}
                className="category-card"
              >
                <div className="category-card__header">
                  <div className="category-card__copy">
                    <h3 className="category-card__title">{category.icon || '📁'} {category.name}</h3>
                    <p className="category-card__description">{category.description || 'No description provided.'}</p>
                  </div>
                  <div className="admin-inline-actions">
                    <button className="admin-round-button" title="Edit" onClick={() => void handleEdit(category)}>
                      <Edit size={13} />
                    </button>
                    <button className="admin-round-button" title="Delete" style={{ color: 'var(--admin-red)' }} onClick={() => void handleDelete(category.id)}>
                      <Trash2 size={13} />
                    </button>
                  </div>
                </div>

                <div className="admin-info-list">
                  <div className="admin-info-row">
                    <span>Wallpapers</span>
                    <span>{category.wallpaperCount}</span>
                  </div>
                  <div className="admin-info-row">
                    <span>Status</span>
                    <StatusTag type={category.isActive ? 'green' : 'cool-gray'}>
                      {category.isActive ? 'Active' : 'Inactive'}
                    </StatusTag>
                  </div>
                  <div className="admin-info-row">
                    <span>Source</span>
                    <span>{category.sourceUrl?.includes('pinterest.com') ? 'Pinterest' : 'Manual'}</span>
                  </div>
                </div>

                {category.sourceUrl?.includes('pinterest.com') && (
                  <div style={{ marginTop: 12 }}>
                    <button
                      className="admin-sidebar__link"
                      style={{ width: 'auto', gap: 6, fontSize: 12, padding: '6px 10px', border: '1px solid var(--admin-border)', borderRadius: 8, background: 'var(--admin-panel)', color: 'var(--admin-text-muted)' }}
                      disabled={refetchingId === category.id}
                      onClick={() => void handleRefetch(category.id)}
                    >
                      <RefreshCw size={12} className={refetchingId === category.id ? 'admin-icon-spin' : ''} />
                      {refetchingId === category.id ? 'Refetching…' : 'Refetch board'}
                    </button>
                  </div>
                )}
              </article>
            ))}
          </div>
        )}
      </AdminPanel>

      {/* ── Create / Edit category modal ─────────────────── */}
      <AdminModal
        open={showModal}
        title={editingCategory ? 'Edit category' : 'Create category'}
        primaryLabel={isSubmitting ? 'Saving…' : editingCategory ? 'Save changes' : 'Create category'}
        primaryDisabled={isSubmitting || !formData.name.trim()}
        onConfirm={() => void handleSubmit()}
        onClose={() => { setShowModal(false); resetForm(); }}
      >
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          <div className="afield">
            <label className="afield__label">Name</label>
            <input className="afield__input" value={formData.name} onChange={(e) => setFormData((c) => ({ ...c, name: e.target.value }))} />
          </div>
          <div className="afield">
            <label className="afield__label">Emoji</label>
            <input className="afield__input" value={formData.icon} onChange={(e) => setFormData((c) => ({ ...c, icon: e.target.value }))} />
          </div>
          <div className="afield">
            <label className="afield__label">Description</label>
            <textarea className="afield__textarea" value={formData.description} onChange={(e) => setFormData((c) => ({ ...c, description: e.target.value }))} />
          </div>

          {editingCategory ? (
            <div className="admin-callout">
              <strong style={{ fontSize: 12 }}>Wallpapers in this category</strong>
              {isWallpapersLoading ? (
                <p style={{ fontSize: 12, color: 'var(--admin-text-muted)', margin: 0 }}>Loading wallpapers...</p>
              ) : categoryWallpapers.length > 0 ? (
                <div className="admin-preview-grid" style={{ gridTemplateColumns: 'repeat(auto-fill, minmax(84px, 1fr))' }}>
                  {categoryWallpapers.slice(0, 8).map((wallpaper) => (
                    <div key={wallpaper.id} className="admin-preview-card">
                      <img src={wallpaper.thumbnailUrl || wallpaper.imageUrl} alt={wallpaper.title} style={{ height: 96 }} />
                      <span style={{ fontSize: 11, color: 'var(--admin-text-muted)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                        {wallpaper.title}
                      </span>
                    </div>
                  ))}
                </div>
              ) : (
                <p style={{ fontSize: 12, color: 'var(--admin-text-muted)', margin: 0 }}>No wallpapers found in this category.</p>
              )}
            </div>
          ) : null}
        </div>
      </AdminModal>

      {/* ── Import Pinterest modal ───────────────────────── */}
      <AdminModal
        open={showImportModal}
        title="Import Pinterest board"
        primaryLabel={isImporting ? 'Importing…' : 'Start import'}
        primaryDisabled={isImporting || !importUrl.trim()}
        onConfirm={() => void handleImport()}
        onClose={() => { setShowImportModal(false); setImportUrl(''); }}
        size="sm"
      >
        <div className="afield">
          <label className="afield__label">Pinterest board URL</label>
          <input
            className="afield__input"
            placeholder="https://www.pinterest.com/username/boardname/"
            value={importUrl}
            onChange={(e) => setImportUrl(e.target.value)}
          />
        </div>
      </AdminModal>
    </AdminPage>
  );
}
