import { useEffect, useState } from 'react';
import { Checkbox, DatePicker, DatePickerInput, Modal, Select, SelectItem, TextInput } from '@carbon/react';
import { usersApi } from '../services/api';

interface EditUserModalProps {
  isOpen: boolean;
  onClose: () => void;
  user: any;
  onSuccess: () => void;
}

export default function EditUserModal({ isOpen, onClose, user, onSuccess }: EditUserModalProps) {
  const [isLoading, setIsLoading] = useState(false);
  const [formData, setFormData] = useState({
    displayName: '',
    isActive: true,
    plan: 'free',
    expiryDate: '',
  });

  useEffect(() => {
    if (!user) {
      return;
    }

    setFormData({
      displayName: user.displayName || '',
      isActive: user.isActive,
      plan: user.subscription?.plan || 'free',
      expiryDate: user.subscription?.expiryDate ? new Date(user.subscription.expiryDate).toISOString().split('T')[0] : '',
    });
  }, [user]);

  const handleSubmit = async () => {
    if (!user) {
      return;
    }

    setIsLoading(true);

    try {
      await usersApi.update(user.id, {
        displayName: formData.displayName,
        isActive: formData.isActive,
        subscription: {
          plan: formData.plan,
          expiryDate: formData.expiryDate ? new Date(formData.expiryDate).toISOString() : null,
        },
      });
      onSuccess();
      onClose();
    } catch (error) {
      console.error('Failed to update user:', error);
      alert('Failed to update user');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Modal
      open={isOpen}
      modalHeading="Edit user"
      primaryButtonText={isLoading ? 'Saving...' : 'Save changes'}
      secondaryButtonText="Cancel"
      onRequestClose={onClose}
      onRequestSubmit={() => void handleSubmit()}
      primaryButtonDisabled={isLoading}
    >
      <div className="admin-grid">
        <TextInput
          id="displayName"
          labelText="Display name"
          value={formData.displayName}
          onChange={(event) => setFormData((current) => ({ ...current, displayName: event.target.value }))}
        />

        <Checkbox
          id="isActive"
          labelText="Account is active"
          checked={formData.isActive}
          onChange={(_, { checked }) => setFormData((current) => ({ ...current, isActive: Boolean(checked) }))}
        />

        <Select
          id="plan"
          labelText="Subscription plan"
          value={formData.plan}
          onChange={(event) => setFormData((current) => ({ ...current, plan: event.target.value }))}
        >
          <SelectItem value="free" text="Free" />
          <SelectItem value="monthly" text="Monthly" />
          <SelectItem value="annual" text="Annual" />
          <SelectItem value="lifetime" text="Lifetime" />
        </Select>

        {formData.plan !== 'free' && formData.plan !== 'lifetime' ? (
          <DatePicker
            datePickerType="single"
            dateFormat="Y-m-d"
            value={formData.expiryDate}
            onChange={(dates) => {
              const nextDate = dates[0];
              setFormData((current) => ({
                ...current,
                expiryDate: nextDate instanceof Date && !Number.isNaN(nextDate.valueOf()) ? nextDate.toISOString().split('T')[0] : '',
              }));
            }}
          >
            <DatePickerInput id="expiryDate" labelText="Expiry date" placeholder="yyyy-mm-dd" />
          </DatePicker>
        ) : null}
      </div>
    </Modal>
  );
}
