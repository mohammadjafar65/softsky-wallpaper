import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import { usersApi } from '../services/api';
import { AdminModal } from './admin/AdminModal';

interface EditableUser {
  id: string;
  displayName?: string;
  role?: string;
  isCreator?: boolean;
  isActive: boolean;
  subscription?: {
    plan?: string;
    expiryDate?: string;
  };
}

interface EditUserModalProps {
  isOpen: boolean;
  onClose: () => void;
  user: EditableUser | null;
  onSuccess: () => void;
}

export default function EditUserModal({ isOpen, onClose, user, onSuccess }: EditUserModalProps) {
  const [isLoading, setIsLoading] = useState(false);
  const [formData, setFormData] = useState({
    displayName: '',
    role: 'user',
    isCreator: false,
    isActive: true,
    plan: 'free',
    expiryDate: '',
  });

  useEffect(() => {
    if (!user) return;
    setFormData({
      displayName: user.displayName || '',
      role: user.role || 'user',
      isCreator: Boolean(user.isCreator),
      isActive: user.isActive,
      plan: user.subscription?.plan || 'free',
      expiryDate: user.subscription?.expiryDate
        ? new Date(user.subscription.expiryDate).toISOString().split('T')[0]
        : '',
    });
  }, [user]);

  const handleSubmit = async () => {
    if (!user) return;
    setIsLoading(true);
    try {
      await usersApi.update(user.id, {
        displayName: formData.displayName,
        role: formData.role,
        isCreator: formData.isCreator,
        isActive: formData.isActive,
        subscription: {
          plan: formData.plan,
          expiryDate: formData.expiryDate ? new Date(formData.expiryDate).toISOString() : null,
        },
      });
      toast.success('User updated');
      onSuccess();
      onClose();
    } catch (error) {
      console.error('Failed to update user:', error);
      toast.error('Failed to update user');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <AdminModal
      open={isOpen}
      title="Edit user"
      primaryLabel={isLoading ? 'Saving…' : 'Save changes'}
      primaryDisabled={isLoading}
      onConfirm={() => void handleSubmit()}
      onClose={onClose}
      size="sm"
    >
      <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
        <div className="afield">
          <label className="afield__label">Display name</label>
          <input
            className="afield__input"
            value={formData.displayName}
            onChange={(e) => setFormData((c) => ({ ...c, displayName: e.target.value }))}
          />
        </div>

        <div className="afield">
          <label className="afield__label">System Role</label>
          <select
            className="afield__select"
            value={formData.role}
            onChange={(e) => setFormData((c) => ({ ...c, role: e.target.value }))}
          >
            <option value="user">Regular User</option>
            <option value="admin">Administrator</option>
          </select>
        </div>

        <label className="afield__checkbox-row">
          <input
            type="checkbox"
            checked={formData.isCreator}
            onChange={(e) => setFormData((c) => ({ ...c, isCreator: e.target.checked }))}
          />
          <span>Creator Privileges (Creator Studio & Verified Badge)</span>
        </label>

        <label className="afield__checkbox-row">
          <input
            type="checkbox"
            checked={formData.isActive}
            onChange={(e) => setFormData((c) => ({ ...c, isActive: e.target.checked }))}
          />
          <span>Account is active (Uncheck to ban)</span>
        </label>

        <div className="afield">
          <label className="afield__label">Subscription plan</label>
          <select
            className="afield__select"
            value={formData.plan}
            onChange={(e) => setFormData((c) => ({ ...c, plan: e.target.value }))}
          >
            <option value="free">Free</option>
            <option value="monthly">Monthly</option>
            <option value="annual">Annual</option>
            <option value="lifetime">Lifetime</option>
          </select>
        </div>

        {formData.plan !== 'free' && formData.plan !== 'lifetime' ? (
          <div className="afield">
            <label className="afield__label">Expiry date</label>
            <input
              type="date"
              className="afield__input"
              value={formData.expiryDate}
              onChange={(e) => setFormData((c) => ({ ...c, expiryDate: e.target.value }))}
            />
          </div>
        ) : null}
      </div>
    </AdminModal>
  );
}
