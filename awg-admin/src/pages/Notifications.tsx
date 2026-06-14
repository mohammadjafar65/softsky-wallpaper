import { useEffect, useState } from 'react';
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
import { notificationsApi, usersApi } from '../services/api';
import { AdminPage, AdminPanel, StatusTag } from '../components/admin/AdminPage';

interface User {
  id: string;
  email: string;
  displayName: string;
}

export default function Notifications() {
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [imageUrl, setImageUrl] = useState('');
  const [targetType, setTargetType] = useState<'all' | 'user'>('all');
  const [selectedUserId, setSelectedUserId] = useState('');
  const [users, setUsers] = useState<User[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [loadingUsers, setLoadingUsers] = useState(false);
  const [result, setResult] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  useEffect(() => {
    if (targetType === 'user') {
      void fetchUsers();
    }
  }, [targetType]);

  const fetchUsers = async () => {
    try {
      setLoadingUsers(true);
      const response = await usersApi.getAll({ limit: 1000 });
      setUsers(response.data.users || []);
    } catch (error) {
      console.error('Failed to fetch users:', error);
    } finally {
      setLoadingUsers(false);
    }
  };

  const handleSend = async () => {
    if (!title.trim() || !message.trim()) {
      setResult({ type: 'error', message: 'Please fill in both title and message.' });
      return;
    }

    if (targetType === 'user' && !selectedUserId) {
      setResult({ type: 'error', message: 'Please select a target user.' });
      return;
    }

    try {
      setIsLoading(true);
      setResult(null);

      if (targetType === 'all') {
        const response = await notificationsApi.sendToAll({
          title,
          message,
          ...(imageUrl.trim() && { imageUrl: imageUrl.trim() }),
        });
        setResult({
          type: 'success',
          message: `Notification sent to ${response.data.successCount} users. ${response.data.failureCount} failed.`,
        });
      } else {
        await notificationsApi.sendToUser({
          userId: selectedUserId,
          title,
          message,
          ...(imageUrl.trim() && { imageUrl: imageUrl.trim() }),
        });
        setResult({ type: 'success', message: 'Notification sent successfully.' });
      }

      setTitle('');
      setMessage('');
      setImageUrl('');
      setSelectedUserId('');
    } catch (error: unknown) {
      const messageText = axios.isAxiosError<{ error?: string }>(error)
        ? error.response?.data?.error
        : undefined;
      setResult({
        type: 'error',
        message: messageText || 'Failed to send notification',
      });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <AdminPage
      title="Push notifications"
      subtitle="Broadcast release notes, campaigns, and targeted prompts to your app audience."
    >
      <div className="admin-grid admin-grid--cards">
        <AdminPanel title="Compose notification" description="Messaging controls for broadcast and one-to-one sends.">
          <div className="admin-grid">
            <RadioButtonGroup
              legendText="Target audience"
              name="targetType"
              valueSelected={targetType}
              onChange={(value) => setTargetType(value as 'all' | 'user')}
            >
              <RadioButton id="target-all" labelText="All users" value="all" />
              <RadioButton id="target-user" labelText="Specific user" value="user" />
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
                  <SelectItem key={user.id} value={user.id} text={`${user.displayName} (${user.email})`} />
                ))}
              </Select>
            ) : null}

            <TextInput
              id="notification-title"
              labelText="Title"
              value={title}
              onChange={(event) => setTitle(event.target.value)}
              helperText={`${title.length}/50 characters`}
            />

            <TextArea
              id="notification-message"
              labelText="Message"
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
              <StatusTag type={result.type === 'success' ? 'green' : 'red'}>{result.message}</StatusTag>
            ) : null}

            <Button onClick={() => void handleSend()} disabled={isLoading || !title.trim() || !message.trim()}>
              {isLoading ? 'Sending...' : 'Send notification'}
            </Button>
          </div>
        </AdminPanel>

        <AdminPanel title="Delivery guidance" description="A few operating notes for safer notification campaigns.">
          <div className="admin-grid">
            <div className="admin-panel">
              <h3 style={{ marginTop: 0 }}>Tips</h3>
              <p className="admin-authors">Keep titles short, write a clear action, and test with your own account first.</p>
            </div>
            <div className="admin-panel">
              <h3 style={{ marginTop: 0 }}>Constraints</h3>
              <p className="admin-authors">Delivery depends on app install state, permission status, and token validity.</p>
            </div>
          </div>
        </AdminPanel>
      </div>
    </AdminPage>
  );
}
