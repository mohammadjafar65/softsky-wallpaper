import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import {
  Button,
  Checkbox,
  Modal,
  Search,
  TextArea,
  TextInput,
} from '@carbon/react';
import { Add, Edit, TrashCan } from '@carbon/icons-react';
import { format } from 'date-fns';
import { packsApi } from '../services/api';
import { AdminPage, AdminPanel, EmptyState, StatusTag } from '../components/admin/AdminPage';
import { FilePicker } from '../components/admin/FilePicker';

interface Pack {
  id: string;
  name: string;
  description: string;
  coverImage: string;
  isPro: boolean;
  isActive: boolean;
  createdAt: string;
  wallpaperCount?: number;
}

export default function Packs() {
  const [packs, setPacks] = useState<Pack[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingPack, setEditingPack] = useState<Pack | null>(null);
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    coverImage: null as File | null,
    isPro: false,
    isActive: true,
  });
  const [previewUrl, setPreviewUrl] = useState('');

  useEffect(() => {
    void fetchPacks();
  }, []);

  useEffect(() => {
    return () => {
      if (previewUrl.startsWith('blob:')) {
        URL.revokeObjectURL(previewUrl);
      }
    };
  }, [previewUrl]);

  const fetchPacks = async () => {
    try {
      setIsLoading(true);
      const response = await packsApi.getAll();
      setPacks(response.data.packs || []);
    } catch (error) {
      toast.error('Failed to load packs');
      console.error(error);
    } finally {
      setIsLoading(false);
    }
  };

  const resetForm = () => {
    setFormData({
      name: '',
      description: '',
      coverImage: null,
      isPro: false,
      isActive: true,
    });
    if (previewUrl.startsWith('blob:')) {
      URL.revokeObjectURL(previewUrl);
    }
    setPreviewUrl('');
    setEditingPack(null);
  };

  const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) {
      return;
    }

    setFormData((current) => ({ ...current, coverImage: file }));
    if (previewUrl.startsWith('blob:')) {
      URL.revokeObjectURL(previewUrl);
    }
    setPreviewUrl(URL.createObjectURL(file));
  };

  const handleSubmit = async () => {
    if (!formData.name.trim()) {
      toast.error('Name is required');
      return;
    }

    if (!editingPack && !formData.coverImage) {
      toast.error('Cover image is required');
      return;
    }

    try {
      const data = new FormData();
      data.append('name', formData.name);
      data.append('description', formData.description);
      data.append('isPro', String(formData.isPro));
      data.append('isActive', String(formData.isActive));

      if (formData.coverImage) {
        data.append('coverImage', formData.coverImage);
      }

      if (editingPack) {
        await packsApi.update(editingPack.id, {
          name: formData.name,
          description: formData.description,
          isPro: formData.isPro,
          isActive: formData.isActive,
        });
        toast.success('Pack updated');
      } else {
        await packsApi.create(data);
        toast.success('Pack created');
      }

      setIsModalOpen(false);
      resetForm();
      await fetchPacks();
    } catch (error) {
      console.error(error);
      toast.error('Failed to save pack');
    }
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm('Are you sure? This will remove the pack but keep the wallpapers.')) {
      return;
    }

    try {
      await packsApi.delete(id);
      toast.success('Pack deleted');
      await fetchPacks();
    } catch {
      toast.error('Failed to delete pack');
    }
  };

  const filteredPacks = packs.filter((pack) =>
    pack.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <AdminPage
      title="Wallpaper packs"
      subtitle="Maintain curated collections, premium bundles, and release-ready cover art."
      actions={
        <Button
          renderIcon={Add}
          onClick={() => {
            resetForm();
            setIsModalOpen(true);
          }}
        >
          Create pack
        </Button>
      }
    >
      <AdminPanel title="Pack filters" description="Search across your curated collection library.">
          <Search
            id="pack-search"
            labelText="Search packs"
            placeholder="Search packs"
            value={searchQuery}
            onChange={(event) => setSearchQuery(event.target.value)}
          />
      </AdminPanel>

      <AdminPanel title="Pack library" description="A polished gallery for published and draft bundles.">
        {isLoading ? (
          <p>Loading packs...</p>
        ) : filteredPacks.length === 0 ? (
          <EmptyState
            title="No packs found"
            message="Create a new pack or widen your search terms."
            actionLabel="Create pack"
            onAction={() => setIsModalOpen(true)}
          />
        ) : (
          <div className="admin-grid admin-grid--cards">
            {filteredPacks.map((pack) => (
              <AdminPanel
                key={pack.id}
                title={pack.name}
                description={pack.description || 'No description provided.'}
                actions={
                  <div className="admin-inline-actions">
                    <Button
                      kind="ghost"
                      size="sm"
                      renderIcon={Edit}
                      iconDescription="Edit pack"
                      hasIconOnly
                      onClick={() => {
                        setEditingPack(pack);
                        setFormData({
                          name: pack.name,
                          description: pack.description,
                          coverImage: null,
                          isPro: pack.isPro,
                          isActive: pack.isActive,
                        });
                        setPreviewUrl(pack.coverImage);
                        setIsModalOpen(true);
                      }}
                    />
                    <Button
                      kind="ghost"
                      size="sm"
                      renderIcon={TrashCan}
                      iconDescription="Delete pack"
                      hasIconOnly
                      onClick={() => void handleDelete(pack.id)}
                    />
                  </div>
                }
              >
                {pack.coverImage ? (
                  <img
                    src={pack.coverImage}
                    alt={pack.name}
                    style={{ width: '100%', height: '14rem', objectFit: 'cover', marginBottom: '1rem' }}
                  />
                ) : null}

                <div className="admin-chip-row">
                  <StatusTag type={pack.isPro ? 'purple' : 'cool-gray'}>
                    {pack.isPro ? 'Pro pack' : 'Free pack'}
                  </StatusTag>
                  <StatusTag type={pack.isActive ? 'green' : 'red'}>
                    {pack.isActive ? 'Active' : 'Inactive'}
                  </StatusTag>
                </div>

                <div className="admin-info-list" style={{ marginTop: '1rem' }}>
                  <div className="admin-info-row">
                    <span>Created</span>
                    <span>{format(new Date(pack.createdAt), 'MMM d, yyyy')}</span>
                  </div>
                  <div className="admin-info-row">
                    <span>Wallpapers</span>
                    <span>{pack.wallpaperCount ?? 'Not tracked'}</span>
                  </div>
                </div>
              </AdminPanel>
            ))}
          </div>
        )}
      </AdminPanel>

      <Modal
        open={isModalOpen}
        modalHeading={editingPack ? 'Edit pack' : 'Create pack'}
        primaryButtonText={editingPack ? 'Save changes' : 'Create pack'}
        secondaryButtonText="Cancel"
        onRequestClose={() => {
          setIsModalOpen(false);
          resetForm();
        }}
        onRequestSubmit={() => void handleSubmit()}
      >
        <div className="admin-grid">
          <FilePicker
            label="Cover image"
            helperText="Recommended: wide cover image for collection cards."
            accept="image/*"
            onChange={handleFileSelect}
          />

          {previewUrl ? (
            <img
              src={previewUrl}
              alt="Pack preview"
              style={{ width: '100%', height: '12rem', objectFit: 'cover' }}
            />
          ) : null}

          <TextInput
            id="pack-name"
            labelText="Pack name"
            value={formData.name}
            onChange={(event) => setFormData((current) => ({ ...current, name: event.target.value }))}
          />

          <TextArea
            id="pack-description"
            labelText="Description"
            value={formData.description}
            onChange={(event) => setFormData((current) => ({ ...current, description: event.target.value }))}
          />

          <Checkbox
            id="pack-pro"
            labelText="Pro pack"
            checked={formData.isPro}
            onChange={(_, { checked }) => setFormData((current) => ({ ...current, isPro: Boolean(checked) }))}
          />

          <Checkbox
            id="pack-active"
            labelText="Pack is active"
            checked={formData.isActive}
            onChange={(_, { checked }) => setFormData((current) => ({ ...current, isActive: Boolean(checked) }))}
          />
        </div>
      </Modal>
    </AdminPage>
  );
}
