import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import axios from 'axios';
import {
  Button,
  Modal,
  TextArea,
  TextInput,
} from '@carbon/react';
import { Add, Edit, LogoPinterest, Renew, TrashCan } from '@carbon/icons-react';
import { categoriesApi, wallpapersApi } from '../services/api';
import { AdminPage, AdminPanel, EmptyState, StatusTag } from '../components/admin/AdminPage';

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
          <Button kind="secondary" renderIcon={LogoPinterest} onClick={() => setShowImportModal(true)}>
            Import Pinterest board
          </Button>
          <Button renderIcon={Add} onClick={() => setShowModal(true)}>
            Add category
          </Button>
        </>
      }
    >
      <AdminPanel title="Category library" description="Each category tracks its own inventory footprint and source state.">
        {isLoading ? (
          <p>Loading categories...</p>
        ) : categories.length === 0 ? (
          <EmptyState
            title="No categories yet"
            message="Create your first category or import a Pinterest board to populate the library."
            actionLabel="Add category"
            onAction={() => setShowModal(true)}
          />
        ) : (
          <div className="admin-grid admin-grid--cards">
            {categories.map((category) => (
              <AdminPanel
                key={category.id}
                title={`${category.icon || '📁'} ${category.name}`}
                description={category.description || 'No description provided.'}
                actions={
                  <div className="admin-inline-actions">
                    <Button
                      kind="ghost"
                      size="sm"
                      renderIcon={Edit}
                      iconDescription="Edit category"
                      hasIconOnly
                      onClick={() => void handleEdit(category)}
                    />
                    <Button
                      kind="ghost"
                      size="sm"
                      renderIcon={TrashCan}
                      iconDescription="Delete category"
                      hasIconOnly
                      onClick={() => void handleDelete(category.id)}
                    />
                  </div>
                }
              >
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

                {editingCategory?.id === category.id && (
                  <div style={{ marginTop: '1rem' }}>
                    <h3 style={{ marginBottom: '0.75rem' }}>Recent wallpapers in this category</h3>
                    {isWallpapersLoading ? (
                      <p>Loading wallpapers...</p>
                    ) : categoryWallpapers.length === 0 ? (
                      <p className="admin-authors">No wallpapers found in this category.</p>
                    ) : (
                      <div className="admin-preview-grid">
                        {categoryWallpapers.slice(0, 6).map((wallpaper) => (
                          <div key={wallpaper.id} className="admin-preview-card">
                            <img src={wallpaper.thumbnailUrl || wallpaper.imageUrl} alt={wallpaper.title} />
                            <span className="admin-authors">{wallpaper.title}</span>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                )}

                {category.sourceUrl?.includes('pinterest.com') ? (
                  <div style={{ marginTop: '1rem' }}>
                    <Button
                      kind="ghost"
                      size="sm"
                      renderIcon={Renew}
                      disabled={refetchingId === category.id}
                      onClick={() => void handleRefetch(category.id)}
                    >
                      {refetchingId === category.id ? 'Refetching...' : 'Refetch board'}
                    </Button>
                  </div>
                ) : null}
              </AdminPanel>
            ))}
          </div>
        )}
      </AdminPanel>

      <Modal
        open={showModal}
        modalHeading={editingCategory ? 'Edit category' : 'Create category'}
        primaryButtonText={isSubmitting ? 'Saving...' : editingCategory ? 'Save changes' : 'Create category'}
        secondaryButtonText="Cancel"
        onRequestClose={() => {
          setShowModal(false);
          resetForm();
        }}
        onRequestSubmit={() => void handleSubmit()}
        primaryButtonDisabled={isSubmitting || !formData.name.trim()}
      >
        <div className="admin-grid">
          <TextInput
            id="category-name"
            labelText="Name"
            value={formData.name}
            onChange={(event) => setFormData((current) => ({ ...current, name: event.target.value }))}
          />
          <TextInput
            id="category-icon"
            labelText="Emoji"
            value={formData.icon}
            onChange={(event) => setFormData((current) => ({ ...current, icon: event.target.value }))}
          />
          <TextArea
            id="category-description"
            labelText="Description"
            value={formData.description}
            onChange={(event) => setFormData((current) => ({ ...current, description: event.target.value }))}
          />
        </div>
      </Modal>

      <Modal
        open={showImportModal}
        modalHeading="Import Pinterest board"
        primaryButtonText={isImporting ? 'Importing...' : 'Start import'}
        secondaryButtonText="Cancel"
        onRequestClose={() => {
          setShowImportModal(false);
          setImportUrl('');
        }}
        onRequestSubmit={() => void handleImport()}
        primaryButtonDisabled={isImporting || !importUrl.trim()}
      >
        <TextInput
          id="pinterest-url"
          labelText="Pinterest board URL"
          placeholder="https://www.pinterest.com/username/boardname/"
          value={importUrl}
          onChange={(event) => setImportUrl(event.target.value)}
        />
      </Modal>
    </AdminPage>
  );
}
