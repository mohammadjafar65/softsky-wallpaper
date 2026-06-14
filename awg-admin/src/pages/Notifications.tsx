import { useEffect, useMemo, useState } from 'react';
import axios from 'axios';
import { RefreshCw, Send } from 'lucide-react';
import { notificationsApi, usersApi } from '../services/api';
import { AdminPage, AdminPanel, StatusTag, StatTile } from '../components/admin/AdminPage';
import { Button } from '../components/ui/button';

interface User {
  id: string;
  email: string;
  displayName: string;
  hasFcmToken: boolean;
}

type TargetType = 'all' | 'user' | 'test';
type ResultType = 'success' | 'warning' | 'error';

export default function Notifications() {
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [imageUrl, setImageUrl] = useState('');
  const [testToken, setTestToken] = useState('');
  const [targetType, setTargetType] = useState<TargetType>('all');
  const [selectedUserId, setSelectedUserId] = useState('');
  const [users, setUsers] = useState<User[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [loadingUsers, setLoadingUsers] = useState(true);
  const [result, setResult] = useState<{ type: ResultType; message: string } | null>(null);

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

  useEffect(() => {
    void fetchUsers();
  }, []);

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

  return (
    <AdminPage
      title="Push notifications"
      subtitle="Send broadcast, targeted, and test push campaigns with clear delivery readiness."
      actions={
        <Button variant="secondary" size="sm" disabled={loadingUsers} onClick={() => void fetchUsers()}>
          <RefreshCw size={13} className={loadingUsers ? 'admin-icon-spin' : ''} />
          {loadingUsers ? 'Refreshing…' : 'Refresh users'}
        </Button>
      }
    >
      <div className="admin-grid admin-grid--stats">
        <StatTile label="Loaded users" value={users.length.toLocaleString()} helper="Available targets" tone="blue" loading={loadingUsers} />
        <StatTile label="Push ready" value={reachableUsers.toLocaleString()} helper="Users with FCM token" tone="green" loading={loadingUsers} />
        <StatTile label="Missing token" value={(users.length - reachableUsers).toLocaleString()} helper="Open app to sync" tone="orange" loading={loadingUsers} />
      </div>

      <div className="admin-grid admin-grid--cards">
        <AdminPanel title="Compose notification" description="Choose an audience, write the message, then send through the backend FCM service.">
          <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
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
              <input className="afield__input" maxLength={50} value={title} onChange={(e) => setTitle(e.target.value)} />
              <span className="afield__helper">{title.length}/50 characters</span>
            </div>

            <div className="afield">
              <label className="afield__label">Message</label>
              <textarea className="afield__textarea" maxLength={200} value={message} onChange={(e) => setMessage(e.target.value)} />
              <span className="afield__helper">{message.length}/200 characters</span>
            </div>

            <div className="afield">
              <label className="afield__label">Thumbnail image URL</label>
              <input className="afield__input" value={imageUrl} onChange={(e) => setImageUrl(e.target.value)} placeholder="https://…" />
              <span className="afield__helper">Optional image URL for rich notifications.</span>
            </div>

            {result ? (
              <div style={{ padding: '10px 14px', borderRadius: 8, fontSize: 13, background: result.type === 'success' ? 'var(--admin-green-soft)' : result.type === 'warning' ? 'var(--admin-yellow-soft)' : 'var(--admin-red-soft)', color: result.type === 'success' ? 'var(--admin-green)' : result.type === 'warning' ? 'var(--admin-yellow)' : 'var(--admin-red)', border: `1px solid ${result.type === 'success' ? 'rgba(22,163,74,0.2)' : result.type === 'warning' ? 'rgba(217,119,6,0.2)' : 'rgba(220,38,38,0.2)'}` }}>
                {result.message}
              </div>
            ) : null}

            <Button size="sm" onClick={() => void handleSend()} disabled={isLoading || !canSend}>
              <Send size={13} /> {isLoading ? 'Sending…' : 'Send notification'}
            </Button>
          </div>
        </AdminPanel>

        <AdminPanel title="Campaign preview" description="Review the push copy before sending.">
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <div className="admin-preview-phone">
              <div className="admin-preview-notification">
                <strong>{title.trim() || 'Notification title'}</strong>
                <span style={{ fontSize: 12, marginTop: 2 }}>{message.trim() || 'Your notification message will preview here.'}</span>
              </div>
            </div>

            <div className="admin-callout">
              <strong style={{ fontSize: 12 }}>Delivery readiness</strong>
              <p style={{ fontSize: 12, color: 'var(--admin-text-muted)', margin: 0 }}>
                Broadcasts only reach users with a stored FCM token. If Firebase Admin credentials are missing on the backend, sends will return failures.
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
    </AdminPage>
  );
}
