import { useEffect, useRef, useState } from 'react';
import toast from 'react-hot-toast';
import { Edit, Plus, Search, Trash2, Upload } from 'lucide-react';
import { format } from 'date-fns';
import { packsApi } from '../services/api';
import { AdminPage, AdminPanel, EmptyState, StatusTag } from '../components/admin/AdminPage';
import { AdminModal } from '../components/admin/AdminModal';
import { Button } from '../components/ui/button';

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
  const fileInputRef = useRef<HTMLInputElement>(null);

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
        <Button size="sm" onClick={() => { resetForm(); setIsModalOpen(true); }}>
          <Plus size={14} /> Create pack
        </Button>
      }
    >
      <AdminPanel title="Pack filters" description="Search across your curated collection library.">
        <div style={{ position: 'relative', maxWidth: 360 }}>
          <Search size={13} style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)', color: 'var(--admin-text-sub)' }} />
          <input
            className="afield__input"
            style={{ paddingLeft: 32 }}
            placeholder="Search packs"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>
      </AdminPanel>

      <AdminPanel title="Pack library" description="A polished gallery for published and draft bundles.">
        {isLoading ? (
          <p style={{ color: 'var(--admin-text-muted)', padding: '16px 0' }}>Loading packs…</p>
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
                    <button
                      className="admin-round-button"
                      title="Edit pack"
                      onClick={() => {
                        setEditingPack(pack);
                        setFormData({ name: pack.name, description: pack.description, coverImage: null, isPro: pack.isPro, isActive: pack.isActive });
                        setPreviewUrl(pack.coverImage);
                        setIsModalOpen(true);
                      }}
                    >
                      <Edit size={13} />
                    </button>
                    <button className="admin-round-button" title="Delete pack" style={{ color: 'var(--admin-red)' }} onClick={() => void handleDelete(pack.id)}>
                      <Trash2 size={13} />
                    </button>
                  </div>
                }
              >
                {pack.coverImage ? (
                  <img src={pack.coverImage} alt={pack.name} style={{ width: '100%', height: '10rem', objectFit: 'cover', borderRadius: 8, marginBottom: 12 }} />
                ) : null}

                <div className="admin-chip-row">
                  <StatusTag type={pack.isPro ? 'purple' : 'cool-gray'}>{pack.isPro ? 'Pro pack' : 'Free pack'}</StatusTag>
                  <StatusTag type={pack.isActive ? 'green' : 'red'}>{pack.isActive ? 'Active' : 'Inactive'}</StatusTag>
                </div>

                <div className="admin-info-list" style={{ marginTop: 12 }}>
                  <div className="admin-info-row">
                    <span>Created</span>
                    <span>{format(new Date(pack.createdAt), 'MMM d, yyyy')}</span>
                  </div>
                  <div className="admin-info-row">
                    <span>Wallpapers</span>
                    <span>{pack.wallpaperCount ?? '—'}</span>
                  </div>
                </div>
              </AdminPanel>
            ))}
          </div>
        )}
      </AdminPanel>

      {/* ── Create / Edit pack modal ─────────────────────── */}
      <AdminModal
        open={isModalOpen}
        title={editingPack ? 'Edit pack' : 'Create pack'}
        primaryLabel={editingPack ? 'Save changes' : 'Create pack'}
        onConfirm={() => void handleSubmit()}
        onClose={() => { setIsModalOpen(false); resetForm(); }}
      >
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          <div className="afield">
            <label className="afield__label">Cover image</label>
            <p className="afield__helper">Recommended: wide cover image for collection cards.</p>
            <input ref={fileInputRef} type="file" accept="image/*" style={{ display: 'none' }} onChange={handleFileSelect} />
            <button className="aupload-zone" type="button" onClick={() => fileInputRef.current?.click()}>
              <Upload size={14} /> Choose file
            </button>
          </div>

          {previewUrl ? (
            <img src={previewUrl} alt="Pack preview" style={{ width: '100%', height: '9rem', objectFit: 'cover', borderRadius: 8 }} />
          ) : null}

          <div className="afield">
            <label className="afield__label">Pack name</label>
            <input className="afield__input" value={formData.name} onChange={(e) => setFormData((c) => ({ ...c, name: e.target.value }))} />
          </div>
          <div className="afield">
            <label className="afield__label">Description</label>
            <textarea className="afield__textarea" value={formData.description} onChange={(e) => setFormData((c) => ({ ...c, description: e.target.value }))} />
          </div>
          <div style={{ display: 'flex', gap: 20 }}>
            <label className="afield__checkbox-row">
              <input type="checkbox" checked={formData.isPro} onChange={(e) => setFormData((c) => ({ ...c, isPro: e.target.checked }))} />
              <span>Pro pack</span>
            </label>
            <label className="afield__checkbox-row">
              <input type="checkbox" checked={formData.isActive} onChange={(e) => setFormData((c) => ({ ...c, isActive: e.target.checked }))} />
              <span>Pack is active</span>
            </label>
          </div>
        </div>
      </AdminModal>
    </AdminPage>
  );
}
