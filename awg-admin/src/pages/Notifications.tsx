import { useEffect, useMemo, useState } from 'react';
import axios from 'axios';
import {
  Button,
  RadioButton,
  RadioButtonGroup,
  Select,
  SelectItem,
  TextArea,
  TextInput,
} from '@carbon/react';
import { Send, Renew } from '@carbon/icons-react';
import { notificationsApi, usersApi } from '../services/api';
import { AdminPage, AdminPanel, StatusTag, StatTile } from '../components/admin/AdminPage';

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
        <Button kind="secondary" renderIcon={Renew} disabled={loadingUsers} onClick={() => void fetchUsers()}>
          {loadingUsers ? 'Refreshing...' : 'Refresh users'}
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
          <div className="admin-grid">
            <RadioButtonGroup
              legendText="Target audience"
              name="targetType"
              valueSelected={targetType}
              onChange={(value) => {
                setTargetType(value as TargetType);
                setResult(null);
              }}
            >
              <RadioButton id="target-all" labelText="All push-ready users" value="all" />
              <RadioButton id="target-user" labelText="Specific user" value="user" />
              <RadioButton id="target-test" labelText="Test token" value="test" />
            </RadioButtonGroup>

            {targetType === 'user' ? (
              <Select
                id="target-user-select"
                labelText="Select user"
                value={selectedUserId}
                onChange={(event) => setSelectedUserId(event.target.value)}
                disabled={loadingUsers}
              >
                <SelectItem value="" text={loadingUsers ? 'Loading users...' : 'Choose a user'} />
                {users.map((user) => (
                  <SelectItem
                    key={user.id}
                    value={user.id}
                    text={`${user.displayName || user.email} (${user.hasFcmToken ? 'push ready' : 'no token'})`}
                  />
                ))}
              </Select>
            ) : null}

            {targetType === 'test' ? (
              <TextArea
                id="notification-test-token"
                labelText="FCM device token"
                value={testToken}
                onChange={(event) => setTestToken(event.target.value)}
                helperText="Use this to verify Firebase credentials and device delivery before a campaign."
              />
            ) : null}

            <TextInput
              id="notification-title"
              labelText="Title"
              maxLength={50}
              value={title}
              onChange={(event) => setTitle(event.target.value)}
              helperText={`${title.length}/50 characters`}
            />

            <TextArea
              id="notification-message"
              labelText="Message"
              maxLength={200}
              value={message}
              onChange={(event) => setMessage(event.target.value)}
              helperText={`${message.length}/200 characters`}
            />

            <TextInput
              id="notification-image"
              labelText="Thumbnail image URL"
              value={imageUrl}
              onChange={(event) => setImageUrl(event.target.value)}
              helperText="Optional image URL for rich notifications."
            />

            {result ? (
              <StatusTag type={result.type === 'success' ? 'green' : result.type === 'warning' ? 'warm-gray' : 'red'}>
                {result.message}
              </StatusTag>
            ) : null}

            <Button renderIcon={Send} onClick={() => void handleSend()} disabled={isLoading || !canSend}>
              {isLoading ? 'Sending...' : 'Send notification'}
            </Button>
          </div>
        </AdminPanel>

        <AdminPanel title="Campaign preview" description="Review the push copy before sending.">
          <div className="admin-grid">
            <div className="admin-preview-phone">
              <div className="admin-preview-notification">
                <strong>{title.trim() || 'Notification title'}</strong>
                <span>{message.trim() || 'Your notification message will preview here.'}</span>
                {imageUrl.trim() ? <span className="admin-authors">{imageUrl.trim()}</span> : null}
              </div>
            </div>

            <div className="admin-callout">
              <strong>Delivery readiness</strong>
              <p className="admin-authors">
                Broadcasts only reach users with a stored FCM token. If Firebase Admin credentials are missing on the backend, sends will return failures.
              </p>
            </div>

            <div className="admin-callout">
              <strong>Selected target</strong>
              <p className="admin-authors">
                {targetType === 'all'
                  ? `${reachableUsers.toLocaleString()} push-ready users`
                  : targetType === 'user'
                    ? selectedUser
                      ? `${selectedUser.displayName || selectedUser.email} ${selectedUser.hasFcmToken ? 'is push ready' : 'has no FCM token'}`
                      : 'No user selected'
                    : testToken.trim()
                      ? 'Test token ready'
                      : 'Waiting for test token'}
              </p>
            </div>
          </div>
        </AdminPanel>
      </div>
    </AdminPage>
  );
}
