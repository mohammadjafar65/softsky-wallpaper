import { useEffect, useMemo, useRef, useState } from 'react';
import axios from 'axios';
import {
  BookmarkPlus,
  Check,
  FolderKanban,
  Image as ImageIcon,
  Loader2,
  Plus,
  RefreshCw,
  Send,
  Sparkles,
  Trash2,
  Upload,
} from 'lucide-react';
import { notificationsApi, usersApi, type NotificationTemplate } from '../services/api';
import { AdminPage, AdminPanel, StatTile } from '../components/admin/AdminPage';
import { AdminModal } from '../components/admin/AdminModal';
import { Button } from '../components/ui/button';

interface User {
  id: string;
  email: string;
  displayName: string;
  hasFcmToken: boolean;
}

type TargetType = 'all' | 'user' | 'test';
type ResultType = 'success' | 'warning' | 'error';
type ImageMode = 'upload' | 'url';

interface NotificationStatus {
  initialized: boolean;
  projectId?: string | null;
  hasClientEmail: boolean;
  hasPrivateKey: boolean;
  hasServiceAccountPath: boolean;
}

const TEMPLATE_CATEGORIES = [
  { value: 'drop', label: 'New Drop' },
  { value: 'trending', label: 'Trending' },
  { value: 'promo', label: 'Promotion / Pro' },
  { value: 'featured', label: 'Featured / AMOLED' },
  { value: 'community', label: 'Community' },
  { value: 'update', label: 'App Update' },
  { value: 'general', label: 'General Announcement' },
];

export default function Notifications() {
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [imageUrl, setImageUrl] = useState('');
  const [imageMode, setImageMode] = useState<ImageMode>('upload');
  const [isUploadingImage, setIsUploadingImage] = useState(false);
  const [imageUploadError, setImageUploadError] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [testToken, setTestToken] = useState('');
  const [targetType, setTargetType] = useState<TargetType>('all');
  const [selectedUserId, setSelectedUserId] = useState('');
  const [users, setUsers] = useState<User[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [loadingUsers, setLoadingUsers] = useState(true);
  const [notificationStatus, setNotificationStatus] = useState<NotificationStatus | null>(null);
  const [result, setResult] = useState<{ type: ResultType; message: string } | null>(null);

  // Template states
  const [templates, setTemplates] = useState<NotificationTemplate[]>([]);
  const [loadingTemplates, setLoadingTemplates] = useState(true);
  const [selectedTemplateId, setSelectedTemplateId] = useState('');
  const [showTemplateModal, setShowTemplateModal] = useState(false);
  const [templateModalTab, setTemplateModalTab] = useState<'list' | 'create'>('list');

  // New template form states
  const [tplName, setTplName] = useState('');
  const [tplTitle, setTplTitle] = useState('');
  const [tplMessage, setTplMessage] = useState('');
  const [tplImageUrl, setTplImageUrl] = useState('');
  const [tplCategory, setTplCategory] = useState('general');
  const [isSavingTemplate, setIsSavingTemplate] = useState(false);
  const [isUploadingTplImage, setIsUploadingTplImage] = useState(false);
  const [deletingTemplateId, setDeletingTemplateId] = useState<number | null>(null);
  const tplFileInputRef = useRef<HTMLInputElement>(null);

  const fetchUsers = async () => {
    try {
      setLoadingUsers(true);
      const response = await usersApi.getAll({ page: 1, limit: 1000 });
      setUsers(response.data.users || []);
    } catch (error) {
      console.error('Failed to fetch users:', error);
      setResult({ type: 'error', message: 'Could not load users for notification targeting.' });
    } finally {
      setLoadingUsers(false);
    }
  };

  const fetchNotificationStatus = async () => {
    try {
      const response = await notificationsApi.getStatus();
      setNotificationStatus(response.data.firebase || null);
    } catch (error) {
      console.error('Failed to fetch notification status:', error);
    }
  };

  const fetchTemplates = async () => {
    try {
      setLoadingTemplates(true);
      const response = await notificationsApi.getTemplates();
      setTemplates(response.data.templates || []);
    } catch (error) {
      console.error('Failed to fetch templates:', error);
    } finally {
      setLoadingTemplates(false);
    }
  };

  useEffect(() => {
    void fetchUsers();
    void fetchNotificationStatus();
    void fetchTemplates();
  }, []);

  const handleApplyTemplate = (tpl: NotificationTemplate) => {
    setTitle(tpl.title);
    setMessage(tpl.message);
    setImageUrl(tpl.imageUrl || '');
    setSelectedTemplateId(String(tpl.id));
    setResult(null);
  };

  const handleTemplateSelectChange = (id: string) => {
    setSelectedTemplateId(id);
    if (!id) return;
    const found = templates.find((t) => String(t.id) === id);
    if (found) {
      handleApplyTemplate(found);
    }
  };

  const handleOpenSaveAsTemplate = () => {
    setTplName(title ? `${title.slice(0, 24)} Template` : 'Custom Template');
    setTplTitle(title);
    setTplMessage(message);
    setTplImageUrl(imageUrl);
    setTplCategory('general');
    setTemplateModalTab('create');
    setShowTemplateModal(true);
  };

  const handleImageFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (!file.type.startsWith('image/')) {
      setImageUploadError('Please select a valid image file (PNG, JPG, WebP, etc.).');
      return;
    }

    try {
      setIsUploadingImage(true);
      setImageUploadError(null);
      const res = await notificationsApi.uploadImage(file);
      if (res.data.url) {
        setImageUrl(res.data.url);
      }
    } catch (err: unknown) {
      console.error('Failed to upload thumbnail:', err);
      setImageUploadError(getErrorMessage(err, 'Failed to upload thumbnail image.'));
    } finally {
      setIsUploadingImage(false);
      if (fileInputRef.current) fileInputRef.current.value = '';
    }
  };

  const handleTplImageFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    try {
      setIsUploadingTplImage(true);
      const res = await notificationsApi.uploadImage(file);
      if (res.data.url) {
        setTplImageUrl(res.data.url);
      }
    } catch (err: unknown) {
      console.error('Failed to upload template image:', err);
      alert(getErrorMessage(err, 'Failed to upload template thumbnail'));
    } finally {
      setIsUploadingTplImage(false);
      if (tplFileInputRef.current) tplFileInputRef.current.value = '';
    }
  };

  const handleCreateTemplate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!tplName.trim() || !tplTitle.trim() || !tplMessage.trim()) {
      alert('Template Name, Title, and Message are required.');
      return;
    }

    try {
      setIsSavingTemplate(true);
      const res = await notificationsApi.createTemplate({
        name: tplName.trim(),
        title: tplTitle.trim(),
        message: tplMessage.trim(),
        imageUrl: tplImageUrl.trim() || undefined,
        category: tplCategory,
      });

      if (res.data.template) {
        setTemplates((prev) => [res.data.template, ...prev]);
        setTplName('');
        setTplTitle('');
        setTplMessage('');
        setTplImageUrl('');
        setTemplateModalTab('list');
      }
    } catch (err: unknown) {
      console.error('Failed to save template:', err);
      alert(getErrorMessage(err, 'Failed to save template.'));
    } finally {
      setIsSavingTemplate(false);
    }
  };

  const handleDeleteTemplate = async (id: number) => {
    if (!confirm('Are you sure you want to delete this template?')) return;
    try {
      setDeletingTemplateId(id);
      await notificationsApi.deleteTemplate(id);
      setTemplates((prev) => prev.filter((t) => t.id !== id));
      if (selectedTemplateId === String(id)) {
        setSelectedTemplateId('');
      }
    } catch (err: unknown) {
      console.error('Failed to delete template:', err);
      alert(getErrorMessage(err, 'Failed to delete template.'));
    } finally {
      setDeletingTemplateId(null);
    }
  };

  const selectedUser = useMemo(
    () => users.find((user) => String(user.id) === String(selectedUserId)),
    [selectedUserId, users]
  );

  const reachableUsers = users.filter((user) => user.hasFcmToken).length;
  const canSend =
    title.trim().length > 0 &&
    message.trim().length > 0 &&
    (targetType === 'all' ||
      (targetType === 'user' && Boolean(selectedUserId)) ||
      (targetType === 'test' && Boolean(testToken.trim())));

  const getErrorMessage = (error: unknown, fallback: string) => {
    if (!axios.isAxiosError<{ error?: string; details?: string }>(error)) {
      return fallback;
    }

    return error.response?.data?.error || error.response?.data?.details || fallback;
  };

  const handleSend = async () => {
    if (!title.trim() || !message.trim()) {
      setResult({ type: 'error', message: 'Title and message are required.' });
      return;
    }

    if (targetType === 'user' && !selectedUserId) {
      setResult({ type: 'error', message: 'Choose a target user before sending.' });
      return;
    }

    if (targetType === 'user' && selectedUser && !selectedUser.hasFcmToken) {
      setResult({ type: 'warning', message: 'This user has no FCM token, so the device cannot receive push yet.' });
      return;
    }

    if (targetType === 'test' && !testToken.trim()) {
      setResult({ type: 'error', message: 'Paste an FCM token before sending a test notification.' });
      return;
    }

    const payload = {
      title: title.trim(),
      message: message.trim(),
      ...(imageUrl.trim() && { imageUrl: imageUrl.trim() }),
    };

    try {
      setIsLoading(true);
      setResult(null);

      if (targetType === 'all') {
        const response = await notificationsApi.sendToAll(payload);
        const successCount = response.data.successCount || 0;
        const failureCount = response.data.failureCount || 0;
        const totalUsers = response.data.totalUsers || 0;

        setResult({
          type: successCount > 0 ? 'success' : 'warning',
          message:
            totalUsers === 0
              ? 'No users currently have FCM tokens. Ask users to open the app so tokens can sync.'
              : `Sent to ${successCount} devices. ${failureCount} failed.`,
        });
      } else if (targetType === 'user') {
        await notificationsApi.sendToUser({
          userId: selectedUserId,
          ...payload,
        });
        setResult({ type: 'success', message: `Notification sent to ${selectedUser?.displayName || 'selected user'}.` });
      } else {
        await notificationsApi.sendTest({
          token: testToken.trim(),
          ...payload,
        });
        setResult({ type: 'success', message: 'Test notification sent successfully.' });
      }

      setTitle('');
      setMessage('');
      setImageUrl('');
      setTestToken('');
      setSelectedUserId('');
    } catch (error: unknown) {
      setResult({
        type: 'error',
        message: getErrorMessage(error, 'Failed to send notification'),
      });
    } finally {
      setIsLoading(false);
    }
  };

  const premadeTemplates = useMemo(() => templates.filter((t) => t.isPremade), [templates]);
  const customTemplates = useMemo(() => templates.filter((t) => !t.isPremade), [templates]);

  return (
    <AdminPage
      title="Push notifications"
      subtitle="Send broadcast, targeted, and test push campaigns with templates and rich media."
      actions={
        <div style={{ display: 'flex', gap: 8 }}>
          <Button
            variant="secondary"
            size="sm"
            onClick={() => {
              setTemplateModalTab('list');
              setShowTemplateModal(true);
            }}
          >
            <FolderKanban size={13} />
            Templates ({templates.length})
          </Button>
          <Button
            variant="secondary"
            size="sm"
            disabled={loadingUsers}
            onClick={() => {
              void fetchUsers();
              void fetchNotificationStatus();
              void fetchTemplates();
            }}
          >
            <RefreshCw size={13} className={loadingUsers ? 'admin-icon-spin' : ''} />
            {loadingUsers ? 'Refreshing…' : 'Refresh'}
          </Button>
        </div>
      }
    >
      <div className="admin-grid admin-grid--stats">
        <StatTile label="Loaded users" value={users.length.toLocaleString()} helper="Available targets" tone="blue" loading={loadingUsers} />
        <StatTile label="Push ready" value={reachableUsers.toLocaleString()} helper="Users with FCM token" tone="green" loading={loadingUsers} />
        <StatTile label="Missing token" value={(users.length - reachableUsers).toLocaleString()} helper="Open app to sync" tone="orange" loading={loadingUsers} />
        <StatTile label="Templates" value={templates.length.toString()} helper={`${premadeTemplates.length} premade, ${customTemplates.length} custom`} tone="purple" loading={loadingTemplates} />
      </div>

      <div className="admin-grid admin-grid--cards">
        <AdminPanel title="Compose notification" description="Choose a template or write custom push copy with an optional rich thumbnail image.">
          <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            {/* ── Notification Templates Row ── */}
            <div style={{
              background: 'var(--admin-bg)',
              border: '1px solid var(--admin-border)',
              borderRadius: 10,
              padding: '12px 14px',
              display: 'flex',
              flexDirection: 'column',
              gap: 8,
            }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontWeight: 600, fontSize: 13 }}>
                  <Sparkles size={14} style={{ color: 'var(--admin-accent)' }} />
                  <span>Preset Templates</span>
                </div>
                <div style={{ display: 'flex', gap: 6 }}>
                  <button
                    type="button"
                    onClick={handleOpenSaveAsTemplate}
                    disabled={!title.trim() && !message.trim()}
                    style={{
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: 4,
                      fontSize: 11,
                      padding: '3px 8px',
                      background: 'var(--admin-panel)',
                      border: '1px solid var(--admin-border)',
                      borderRadius: 6,
                      cursor: (!title.trim() && !message.trim()) ? 'not-allowed' : 'pointer',
                      opacity: (!title.trim() && !message.trim()) ? 0.5 : 1,
                      color: 'var(--admin-text)',
                    }}
                  >
                    <BookmarkPlus size={11} />
                    Save as template
                  </button>
                  <button
                    type="button"
                    onClick={() => {
                      setTemplateModalTab('list');
                      setShowTemplateModal(true);
                    }}
                    style={{
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: 4,
                      fontSize: 11,
                      padding: '3px 8px',
                      background: 'var(--admin-panel)',
                      border: '1px solid var(--admin-border)',
                      borderRadius: 6,
                      cursor: 'pointer',
                      color: 'var(--admin-text)',
                    }}
                  >
                    <FolderKanban size={11} />
                    Manage
                  </button>
                </div>
              </div>

              <select
                className="afield__select"
                value={selectedTemplateId}
                onChange={(e) => handleTemplateSelectChange(e.target.value)}
                style={{ fontSize: 13, height: 36 }}
              >
                <option value="">Choose a premade or custom template to populate…</option>
                {premadeTemplates.length > 0 && (
                  <optgroup label="🌟 Premade Templates">
                    {premadeTemplates.map((t) => (
                      <option key={t.id} value={t.id}>
                        {t.name} — {t.title}
                      </option>
                    ))}
                  </optgroup>
                )}
                {customTemplates.length > 0 && (
                  <optgroup label="📁 Custom Saved Templates">
                    {customTemplates.map((t) => (
                      <option key={t.id} value={t.id}>
                        {t.name} — {t.title}
                      </option>
                    ))}
                  </optgroup>
                )}
              </select>
            </div>

            {/* Target Audience */}
            <div className="afield">
              <label className="afield__label">Target audience</label>
              <div className="afield__radio-group">
                {(['all', 'user', 'test'] as const).map((v) => (
                  <label key={v} className="afield__radio-row">
                    <input type="radio" name="targetType" value={v} checked={targetType === v} onChange={() => { setTargetType(v); setResult(null); }} />
                    <span>{{ all: 'All push-ready users', user: 'Specific user', test: 'Test token' }[v]}</span>
                  </label>
                ))}
              </div>
            </div>

            {targetType === 'user' ? (
              <div className="afield">
                <label className="afield__label">Select user</label>
                <select className="afield__select" value={selectedUserId} onChange={(e) => setSelectedUserId(e.target.value)} disabled={loadingUsers}>
                  <option value="">{loadingUsers ? 'Loading users…' : 'Choose a user'}</option>
                  {users.map((u) => (
                    <option key={u.id} value={u.id}>
                      {u.displayName || u.email} ({u.hasFcmToken ? 'push ready' : 'no token'})
                    </option>
                  ))}
                </select>
              </div>
            ) : null}

            {targetType === 'test' ? (
              <div className="afield">
                <label className="afield__label">FCM device token</label>
                <textarea className="afield__textarea" value={testToken} onChange={(e) => setTestToken(e.target.value)} placeholder="Paste device FCM token here" />
                <span className="afield__helper">Use this to verify Firebase credentials and device delivery before a campaign.</span>
              </div>
            ) : null}

            <div className="afield">
              <label className="afield__label">Title</label>
              <input className="afield__input" maxLength={50} value={title} onChange={(e) => setTitle(e.target.value)} placeholder="e.g. Fresh 4K Wallpapers Just Dropped! ✨" />
              <span className="afield__helper">{title.length}/50 characters</span>
            </div>

            <div className="afield">
              <label className="afield__label">Message</label>
              <textarea className="afield__textarea" maxLength={200} value={message} onChange={(e) => setMessage(e.target.value)} placeholder="e.g. Elevate your home screen with breathtaking AMOLED & Minimal wallpapers." />
              <span className="afield__helper">{message.length}/200 characters</span>
            </div>

            {/* ── Notification Thumbnail Upload / URL ── */}
            <div className="afield">
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 6 }}>
                <label className="afield__label" style={{ margin: 0 }}>Notification Thumbnail (Optional)</label>
                <div style={{ display: 'flex', gap: 4, background: 'var(--admin-bg)', padding: 2, borderRadius: 6, border: '1px solid var(--admin-border)' }}>
                  <button
                    type="button"
                    onClick={() => setImageMode('upload')}
                    style={{
                      border: 'none',
                      background: imageMode === 'upload' ? 'var(--admin-panel)' : 'transparent',
                      padding: '2px 8px',
                      borderRadius: 4,
                      fontSize: 11,
                      fontWeight: imageMode === 'upload' ? 600 : 400,
                      cursor: 'pointer',
                      color: 'var(--admin-text)',
                      boxShadow: imageMode === 'upload' ? '0 1px 2px rgba(0,0,0,0.05)' : 'none',
                    }}
                  >
                    Upload File
                  </button>
                  <button
                    type="button"
                    onClick={() => setImageMode('url')}
                    style={{
                      border: 'none',
                      background: imageMode === 'url' ? 'var(--admin-panel)' : 'transparent',
                      padding: '2px 8px',
                      borderRadius: 4,
                      fontSize: 11,
                      fontWeight: imageMode === 'url' ? 600 : 400,
                      cursor: 'pointer',
                      color: 'var(--admin-text)',
                      boxShadow: imageMode === 'url' ? '0 1px 2px rgba(0,0,0,0.05)' : 'none',
                    }}
                  >
                    Paste URL
                  </button>
                </div>
              </div>

              {imageMode === 'upload' ? (
                <div>
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/png,image/jpeg,image/webp,image/jpg"
                    style={{ display: 'none' }}
                    onChange={(e) => void handleImageFileChange(e)}
                  />

                  {!imageUrl ? (
                    <div
                      onClick={() => !isUploadingImage && fileInputRef.current?.click()}
                      style={{
                        border: '1.5px dashed var(--admin-border-strong)',
                        borderRadius: 8,
                        padding: '20px 16px',
                        textAlign: 'center',
                        cursor: isUploadingImage ? 'wait' : 'pointer',
                        background: 'var(--admin-bg)',
                        transition: 'border-color 0.2s',
                        display: 'flex',
                        flexDirection: 'column',
                        alignItems: 'center',
                        justifyContent: 'center',
                        gap: 6,
                      }}
                    >
                      {isUploadingImage ? (
                        <>
                          <Loader2 size={24} className="admin-icon-spin" style={{ color: 'var(--admin-accent)' }} />
                          <span style={{ fontSize: 13, fontWeight: 500 }}>Uploading image to Cloudinary…</span>
                        </>
                      ) : (
                        <>
                          <div style={{
                            width: 36,
                            height: 36,
                            borderRadius: '50%',
                            background: 'var(--admin-accent-soft)',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            color: 'var(--admin-accent)',
                          }}>
                            <Upload size={18} />
                          </div>
                          <span style={{ fontSize: 13, fontWeight: 600 }}>Click to upload notification thumbnail</span>
                          <span style={{ fontSize: 11, color: 'var(--admin-text-muted)' }}>PNG, JPG or WebP (recommended 1024x512 or 16:9)</span>
                        </>
                      )}
                    </div>
                  ) : (
                    <div style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: 12,
                      padding: 10,
                      background: 'var(--admin-panel)',
                      border: '1px solid var(--admin-border)',
                      borderRadius: 8,
                    }}>
                      <img
                        src={imageUrl}
                        alt="Thumbnail preview"
                        style={{ width: 72, height: 48, objectFit: 'cover', borderRadius: 6, border: '1px solid var(--admin-border)' }}
                      />
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{ fontSize: 12, fontWeight: 600, color: 'var(--admin-text)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                          Thumbnail attached
                        </div>
                        <div style={{ fontSize: 11, color: 'var(--admin-text-muted)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                          {imageUrl}
                        </div>
                      </div>
                      <div style={{ display: 'flex', gap: 6 }}>
                        <button
                          type="button"
                          onClick={() => fileInputRef.current?.click()}
                          style={{
                            border: '1px solid var(--admin-border)',
                            background: 'var(--admin-bg)',
                            padding: '4px 8px',
                            borderRadius: 6,
                            fontSize: 11,
                            cursor: 'pointer',
                          }}
                        >
                          Change
                        </button>
                        <button
                          type="button"
                          onClick={() => setImageUrl('')}
                          style={{
                            border: '1px solid rgba(220,38,38,0.2)',
                            background: 'var(--admin-red-soft)',
                            color: 'var(--admin-red)',
                            padding: '4px 8px',
                            borderRadius: 6,
                            fontSize: 11,
                            cursor: 'pointer',
                          }}
                        >
                          Remove
                        </button>
                      </div>
                    </div>
                  )}
                  {imageUploadError && (
                    <span style={{ fontSize: 12, color: 'var(--admin-red)', marginTop: 4, display: 'block' }}>
                      {imageUploadError}
                    </span>
                  )}
                </div>
              ) : (
                <div>
                  <div style={{ display: 'flex', gap: 8 }}>
                    <input
                      className="afield__input"
                      value={imageUrl}
                      onChange={(e) => setImageUrl(e.target.value)}
                      placeholder="https://images.unsplash.com/…"
                    />
                    {imageUrl && (
                      <Button variant="secondary" size="sm" onClick={() => setImageUrl('')}>
                        Clear
                      </Button>
                    )}
                  </div>
                  {imageUrl && (
                    <div style={{ marginTop: 8, display: 'flex', alignItems: 'center', gap: 10 }}>
                      <img
                        src={imageUrl}
                        alt="Preview"
                        onError={() => setImageUploadError('Invalid image URL')}
                        style={{ width: 64, height: 40, objectFit: 'cover', borderRadius: 4, border: '1px solid var(--admin-border)' }}
                      />
                      <span style={{ fontSize: 11, color: 'var(--admin-green)' }}>✓ Valid preview</span>
                    </div>
                  )}
                </div>
              )}
              <span className="afield__helper">Thumbnails show as expanded rich cards on Android and iOS lockscreeens.</span>
            </div>

            {result ? (
              <div style={{ padding: '10px 14px', borderRadius: 8, fontSize: 13, background: result.type === 'success' ? 'var(--admin-green-soft)' : result.type === 'warning' ? 'var(--admin-yellow-soft)' : 'var(--admin-red-soft)', color: result.type === 'success' ? 'var(--admin-green)' : result.type === 'warning' ? 'var(--admin-yellow)' : 'var(--admin-red)', border: `1px solid ${result.type === 'success' ? 'rgba(22,163,74,0.2)' : result.type === 'warning' ? 'rgba(217,119,6,0.2)' : 'rgba(220,38,38,0.2)'}` }}>
                {result.message}
              </div>
            ) : null}

            <div style={{ display: 'flex', gap: 10, marginTop: 4 }}>
              <Button size="sm" onClick={() => void handleSend()} disabled={isLoading || !canSend} style={{ flex: 1 }}>
                <Send size={13} /> {isLoading ? 'Sending…' : 'Send notification'}
              </Button>
              <Button
                variant="secondary"
                size="sm"
                type="button"
                onClick={handleOpenSaveAsTemplate}
                disabled={!title.trim() && !message.trim()}
              >
                <BookmarkPlus size={13} /> Save Template
              </Button>
            </div>
          </div>
        </AdminPanel>

        {/* ── Preview & Status Panel ── */}
        <AdminPanel title="Campaign preview" description="Review how your push notification looks on modern mobile screens.">
          <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            <div className="admin-preview-phone">
              <div className="admin-preview-notification" style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', borderBottom: '1px solid rgba(255,255,255,0.08)', paddingBottom: 4 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                    <div style={{ width: 14, height: 14, borderRadius: 3, background: 'var(--admin-accent)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 9, color: '#fff', fontWeight: 800 }}>
                      S
                    </div>
                    <span style={{ fontSize: 11, opacity: 0.8, letterSpacing: 0.2 }}>SOFTSKY WALLPAPER</span>
                  </div>
                  <span style={{ fontSize: 10, opacity: 0.6 }}>now</span>
                </div>

                <div>
                  <strong style={{ display: 'block', fontSize: 13, lineHeight: 1.3 }}>{title.trim() || 'Notification title'}</strong>
                  <span style={{ fontSize: 12, marginTop: 2, display: 'block', opacity: 0.85, lineHeight: 1.4 }}>
                    {message.trim() || 'Your notification message will preview here.'}
                  </span>
                </div>

                {imageUrl && (
                  <div style={{
                    width: '100%',
                    height: 120,
                    borderRadius: 8,
                    overflow: 'hidden',
                    background: '#000',
                    border: '1px solid rgba(255,255,255,0.12)',
                    marginTop: 2,
                  }}>
                    <img
                      src={imageUrl}
                      alt="Notification rich preview"
                      style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                      onError={(e) => {
                        (e.target as HTMLElement).style.display = 'none';
                      }}
                    />
                  </div>
                )}
              </div>
            </div>

            <div className="admin-callout">
              <strong style={{ fontSize: 12 }}>Delivery readiness</strong>
              <p style={{ fontSize: 12, color: 'var(--admin-text-muted)', margin: 0 }}>
                {notificationStatus?.initialized
                  ? `Firebase Admin is initialized${notificationStatus.projectId ? ` for ${notificationStatus.projectId}` : ''}. Broadcasts only reach users with a stored FCM token.`
                  : 'Firebase Admin is not initialized. Add Firebase credentials on the backend before production sends.'}
              </p>
            </div>

            <div className="admin-callout">
              <strong style={{ fontSize: 12 }}>Selected target</strong>
              <p style={{ fontSize: 12, color: 'var(--admin-text-muted)', margin: 0 }}>
                {targetType === 'all'
                  ? `${reachableUsers.toLocaleString()} push-ready users`
                  : targetType === 'user'
                    ? selectedUser
                      ? `${selectedUser.displayName || selectedUser.email} ${selectedUser.hasFcmToken ? 'is push ready' : 'has no FCM token'}`
                      : 'No user selected'
                    : testToken.trim() ? 'Test token ready' : 'Waiting for test token'}
              </p>
            </div>
          </div>
        </AdminPanel>
      </div>

      {/* ── Notification Templates Manager Modal ── */}
      <AdminModal
        open={showTemplateModal}
        title="Notification Templates"
        size="lg"
        onClose={() => setShowTemplateModal(false)}
        noFooter
      >
        <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
          {/* Tabs */}
          <div style={{ display: 'flex', borderBottom: '1px solid var(--admin-border)', gap: 16 }}>
            <button
              type="button"
              onClick={() => setTemplateModalTab('list')}
              style={{
                background: 'none',
                border: 'none',
                borderBottom: templateModalTab === 'list' ? '2px solid var(--admin-accent)' : '2px solid transparent',
                padding: '8px 12px',
                fontWeight: templateModalTab === 'list' ? 600 : 400,
                color: templateModalTab === 'list' ? 'var(--admin-accent)' : 'var(--admin-text-muted)',
                cursor: 'pointer',
                fontSize: 13,
                display: 'flex',
                alignItems: 'center',
                gap: 6,
              }}
            >
              <FolderKanban size={14} />
              Saved Templates ({templates.length})
            </button>
            <button
              type="button"
              onClick={() => setTemplateModalTab('create')}
              style={{
                background: 'none',
                border: 'none',
                borderBottom: templateModalTab === 'create' ? '2px solid var(--admin-accent)' : '2px solid transparent',
                padding: '8px 12px',
                fontWeight: templateModalTab === 'create' ? 600 : 400,
                color: templateModalTab === 'create' ? 'var(--admin-accent)' : 'var(--admin-text-muted)',
                cursor: 'pointer',
                fontSize: 13,
                display: 'flex',
                alignItems: 'center',
                gap: 6,
              }}
            >
              <Plus size={14} />
              Create New Template
            </button>
          </div>

          {/* Tab 1: Template List */}
          {templateModalTab === 'list' ? (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12, maxHeight: 460, overflowY: 'auto', paddingRight: 4 }}>
              {templates.length === 0 ? (
                <div style={{ textAlign: 'center', padding: '32px 16px', color: 'var(--admin-text-muted)' }}>
                  No notification templates found. Click "Create New Template" to add one.
                </div>
              ) : (
                templates.map((tpl) => (
                  <div
                    key={tpl.id}
                    style={{
                      display: 'flex',
                      alignItems: 'flex-start',
                      justifyContent: 'space-between',
                      gap: 14,
                      padding: 14,
                      borderRadius: 10,
                      border: '1px solid var(--admin-border)',
                      background: 'var(--admin-panel)',
                    }}
                  >
                    {tpl.imageUrl ? (
                      <img
                        src={tpl.imageUrl}
                        alt=""
                        style={{ width: 60, height: 60, borderRadius: 8, objectFit: 'cover', border: '1px solid var(--admin-border)', flexShrink: 0 }}
                      />
                    ) : (
                      <div style={{ width: 60, height: 60, borderRadius: 8, background: 'var(--admin-bg)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, color: 'var(--admin-text-sub)' }}>
                        <ImageIcon size={20} />
                      </div>
                    )}

                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4, flexWrap: 'wrap' }}>
                        <span style={{ fontWeight: 600, fontSize: 13, color: 'var(--admin-text)' }}>{tpl.name}</span>
                        <span style={{
                          fontSize: 10,
                          padding: '1px 6px',
                          borderRadius: 4,
                          fontWeight: 600,
                          background: tpl.isPremade ? 'var(--admin-accent-soft)' : 'var(--admin-blue-soft)',
                          color: tpl.isPremade ? 'var(--admin-accent)' : 'var(--admin-blue)',
                        }}>
                          {tpl.isPremade ? 'Premade' : 'Custom'}
                        </span>
                        {tpl.category && (
                          <span style={{ fontSize: 10, padding: '1px 6px', borderRadius: 4, background: 'var(--admin-bg)', color: 'var(--admin-text-muted)' }}>
                            {tpl.category}
                          </span>
                        )}
                      </div>
                      <div style={{ fontSize: 12, fontWeight: 500, color: 'var(--admin-text)', marginBottom: 2 }}>
                        {tpl.title}
                      </div>
                      <div style={{ fontSize: 11, color: 'var(--admin-text-muted)', lineHeight: 1.4 }}>
                        {tpl.message}
                      </div>
                    </div>

                    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                      <Button
                        size="sm"
                        variant="secondary"
                        onClick={() => {
                          handleApplyTemplate(tpl);
                          setShowTemplateModal(false);
                        }}
                      >
                        <Check size={12} /> Apply
                      </Button>
                      {!tpl.isPremade && (
                        <button
                          type="button"
                          disabled={deletingTemplateId === tpl.id}
                          onClick={() => void handleDeleteTemplate(tpl.id)}
                          style={{
                            background: 'none',
                            border: '1px solid rgba(220,38,38,0.2)',
                            borderRadius: 6,
                            padding: 6,
                            color: 'var(--admin-red)',
                            cursor: 'pointer',
                          }}
                          title="Delete template"
                        >
                          <Trash2 size={13} />
                        </button>
                      )}
                    </div>
                  </div>
                ))
              )}
            </div>
          ) : (
            /* Tab 2: Create Template */
            <form onSubmit={(e) => void handleCreateTemplate(e)} style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              <div className="afield">
                <label className="afield__label">Template Name (Label)</label>
                <input
                  className="afield__input"
                  value={tplName}
                  onChange={(e) => setTplName(e.target.value)}
                  placeholder="e.g. AMOLED Weekend Drop"
                  required
                />
                <span className="afield__helper">Name used to identify this template in the selector.</span>
              </div>

              <div className="afield">
                <label className="afield__label">Category</label>
                <select className="afield__select" value={tplCategory} onChange={(e) => setTplCategory(e.target.value)}>
                  {TEMPLATE_CATEGORIES.map((cat) => (
                    <option key={cat.value} value={cat.value}>{cat.label}</option>
                  ))}
                </select>
              </div>

              <div className="afield">
                <label className="afield__label">Notification Title</label>
                <input
                  className="afield__input"
                  value={tplTitle}
                  onChange={(e) => setTplTitle(e.target.value)}
                  placeholder="e.g. Deep AMOLED Collection Is Live 🖤"
                  required
                />
              </div>

              <div className="afield">
                <label className="afield__label">Notification Message</label>
                <textarea
                  className="afield__textarea"
                  value={tplMessage}
                  onChange={(e) => setTplMessage(e.target.value)}
                  placeholder="e.g. Save battery and make your screen pop with our new hand-crafted OLED wallpapers."
                  required
                />
              </div>

              <div className="afield">
                <label className="afield__label">Thumbnail Image (Optional)</label>
                <div style={{ display: 'flex', gap: 8, marginBottom: 6 }}>
                  <input
                    className="afield__input"
                    value={tplImageUrl}
                    onChange={(e) => setTplImageUrl(e.target.value)}
                    placeholder="https://… or upload below"
                  />
                  <input
                    ref={tplFileInputRef}
                    type="file"
                    accept="image/*"
                    style={{ display: 'none' }}
                    onChange={(e) => void handleTplImageFileChange(e)}
                  />
                  <Button
                    type="button"
                    variant="secondary"
                    size="sm"
                    disabled={isUploadingTplImage}
                    onClick={() => tplFileInputRef.current?.click()}
                  >
                    {isUploadingTplImage ? <Loader2 size={13} className="admin-icon-spin" /> : <Upload size={13} />}
                    {isUploadingTplImage ? 'Uploading…' : 'Upload'}
                  </Button>
                </div>
                {tplImageUrl && (
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 4 }}>
                    <img
                      src={tplImageUrl}
                      alt="Preview"
                      style={{ width: 60, height: 40, objectFit: 'cover', borderRadius: 4, border: '1px solid var(--admin-border)' }}
                    />
                    <button
                      type="button"
                      onClick={() => setTplImageUrl('')}
                      style={{ background: 'none', border: 'none', color: 'var(--admin-red)', fontSize: 12, cursor: 'pointer' }}
                    >
                      Remove
                    </button>
                  </div>
                )}
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10, marginTop: 8 }}>
                <Button type="button" variant="secondary" onClick={() => setTemplateModalTab('list')}>
                  Cancel
                </Button>
                <Button type="submit" disabled={isSavingTemplate}>
                  {isSavingTemplate ? 'Saving…' : 'Create Template'}
                </Button>
              </div>
            </form>
          )}
        </div>
      </AdminModal>
    </AdminPage>
  );
}
