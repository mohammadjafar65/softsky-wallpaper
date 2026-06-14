import { useEffect, useMemo, useState } from 'react';
import { RefreshCw, Save } from 'lucide-react';
import toast from 'react-hot-toast';
import { settingsApi, type AppSettings } from '../services/api';
import { AdminPage, AdminPanel, StatTile, StatusTag } from '../components/admin/AdminPage';
import { Button } from '../components/ui/button';

const defaultSettings: AppSettings = {
  appName: 'SoftSky Wallpaper',
  supportEmail: 'support@softsky.studio',
  contactEmail: 'contact@softsky.studio',
  privacyPolicyUrl: 'https://softskyadmin.softsky.studio/privacy-policy.html',
  termsUrl: 'https://softskyadmin.softsky.studio/terms',
  androidPackageName: 'com.awg.awg_wallpaper',
  minAppVersion: '1.0.0',
  latestAppVersion: '1.0.0',
  forceUpdate: false,
  maintenanceMode: false,
  maintenanceMessage: 'SoftSky is under maintenance. Please try again shortly.',
  freeDownloadLimitPerDay: 20,
  proDownloadLimitPerDay: 0,
  enableNotifications: true,
  enableSubscriptions: true,
  enableWideWallpapers: true,
  defaultNotificationTitle: 'Fresh wallpapers are live',
  defaultNotificationMessage: 'Open SoftSky to explore the newest collection.',
};

export default function Settings() {
  const [settings, setSettings] = useState<AppSettings>(defaultSettings);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);

  const loadSettings = async () => {
    try {
      setIsLoading(true);
      const response = await settingsApi.get();
      setSettings({ ...defaultSettings, ...(response.data.settings || {}) });
    } catch (error) {
      console.error('Failed to load settings:', error);
      toast.error('Failed to load settings');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    void loadSettings();
  }, []);

  const updateField = <K extends keyof AppSettings>(field: K, value: AppSettings[K]) => {
    setSettings((current) => ({ ...current, [field]: value }));
  };

  const handleSave = async () => {
    if (!settings.appName.trim()) {
      toast.error('App name is required');
      return;
    }

    try {
      setIsSaving(true);
      const response = await settingsApi.update(settings);
      setSettings({ ...defaultSettings, ...(response.data.settings || {}) });
      toast.success('Settings saved');
    } catch (error) {
      console.error('Failed to save settings:', error);
      toast.error('Failed to save settings');
    } finally {
      setIsSaving(false);
    }
  };

  const enabledFeatures = useMemo(
    () =>
      [
        settings.enableNotifications,
        settings.enableSubscriptions,
        settings.enableWideWallpapers,
      ].filter(Boolean).length,
    [settings]
  );

  return (
    <AdminPage
      title="Settings"
      subtitle="Manage app metadata, version gates, download limits, and operational switches."
      actions={
        <>
          <Button variant="secondary" size="sm" disabled={isLoading || isSaving} onClick={() => void loadSettings()}>
            <RefreshCw size={13} className={isLoading ? 'admin-icon-spin' : ''} /> Refresh
          </Button>
          <Button size="sm" disabled={isLoading || isSaving} onClick={() => void handleSave()}>
            <Save size={13} /> {isSaving ? 'Saving...' : 'Save settings'}
          </Button>
        </>
      }
    >
      <div className="admin-grid admin-grid--stats">
        <StatTile label="Maintenance" value={settings.maintenanceMode ? 'On' : 'Off'} helper={settings.maintenanceMode ? 'App access limited' : 'Normal access'} tone={settings.maintenanceMode ? 'red' : 'green'} loading={isLoading} />
        <StatTile label="Force update" value={settings.forceUpdate ? 'On' : 'Off'} helper={`Minimum ${settings.minAppVersion}`} tone={settings.forceUpdate ? 'orange' : 'blue'} loading={isLoading} />
        <StatTile label="Features" value={`${enabledFeatures}/3`} helper="Enabled modules" tone="purple" loading={isLoading} />
        <StatTile label="Free limit" value={settings.freeDownloadLimitPerDay} helper="Downloads per day" tone="blue" loading={isLoading} />
      </div>

      <div className="admin-grid admin-grid--cards">
        <AdminPanel title="App identity" description="Core brand, package, and support details surfaced to the app and policies.">
          <div className="admin-form-grid">
            <div className="afield">
              <label className="afield__label">App name</label>
              <input className="afield__input" value={settings.appName} onChange={(e) => updateField('appName', e.target.value)} />
            </div>
            <div className="afield">
              <label className="afield__label">Android package name</label>
              <input className="afield__input" value={settings.androidPackageName} onChange={(e) => updateField('androidPackageName', e.target.value)} />
            </div>
            <div className="afield">
              <label className="afield__label">Support email</label>
              <input className="afield__input" type="email" value={settings.supportEmail} onChange={(e) => updateField('supportEmail', e.target.value)} />
            </div>
            <div className="afield">
              <label className="afield__label">Contact email</label>
              <input className="afield__input" type="email" value={settings.contactEmail} onChange={(e) => updateField('contactEmail', e.target.value)} />
            </div>
            <div className="afield">
              <label className="afield__label">Privacy policy URL</label>
              <input className="afield__input" value={settings.privacyPolicyUrl} onChange={(e) => updateField('privacyPolicyUrl', e.target.value)} />
            </div>
            <div className="afield">
              <label className="afield__label">Terms URL</label>
              <input className="afield__input" value={settings.termsUrl} onChange={(e) => updateField('termsUrl', e.target.value)} />
            </div>
          </div>
        </AdminPanel>

        <AdminPanel title="Version and access" description="Control app version gates, maintenance state, and daily download rules.">
          <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            <div className="admin-form-grid">
              <div className="afield">
                <label className="afield__label">Minimum app version</label>
                <input className="afield__input" value={settings.minAppVersion} onChange={(e) => updateField('minAppVersion', e.target.value)} />
              </div>
              <div className="afield">
                <label className="afield__label">Latest app version</label>
                <input className="afield__input" value={settings.latestAppVersion} onChange={(e) => updateField('latestAppVersion', e.target.value)} />
              </div>
              <div className="afield">
                <label className="afield__label">Free download limit per day</label>
                <input className="afield__input" type="number" min={0} value={settings.freeDownloadLimitPerDay} onChange={(e) => updateField('freeDownloadLimitPerDay', Number(e.target.value))} />
              </div>
              <div className="afield">
                <label className="afield__label">Pro download limit per day</label>
                <input className="afield__input" type="number" min={0} value={settings.proDownloadLimitPerDay} onChange={(e) => updateField('proDownloadLimitPerDay', Number(e.target.value))} />
                <span className="afield__helper">Use 0 for unlimited.</span>
              </div>
            </div>

            <label className="afield__checkbox-row">
              <input type="checkbox" checked={settings.forceUpdate} onChange={(e) => updateField('forceUpdate', e.target.checked)} />
              <span>Force users below minimum version to update</span>
            </label>
            <label className="afield__checkbox-row">
              <input type="checkbox" checked={settings.maintenanceMode} onChange={(e) => updateField('maintenanceMode', e.target.checked)} />
              <span>Enable maintenance mode</span>
            </label>
            <div className="afield">
              <label className="afield__label">Maintenance message</label>
              <textarea className="afield__textarea" value={settings.maintenanceMessage} onChange={(e) => updateField('maintenanceMessage', e.target.value)} />
            </div>
          </div>
        </AdminPanel>
      </div>

      <div className="admin-grid admin-grid--cards">
        <AdminPanel title="Feature switches" description="Turn major app modules on or off from one operational panel.">
          <div className="settings-switch-list">
            {[
              ['enableNotifications', 'Push notifications'],
              ['enableSubscriptions', 'Subscriptions'],
              ['enableWideWallpapers', 'Wide wallpapers'],
            ].map(([key, label]) => (
              <label key={key} className="settings-switch-row">
                <span>
                  <strong>{label}</strong>
                  <StatusTag type={settings[key as keyof AppSettings] ? 'green' : 'cool-gray'}>
                    {settings[key as keyof AppSettings] ? 'Enabled' : 'Disabled'}
                  </StatusTag>
                </span>
                <input
                  type="checkbox"
                  checked={Boolean(settings[key as keyof AppSettings])}
                  onChange={(e) => updateField(key as keyof AppSettings, e.target.checked as never)}
                />
              </label>
            ))}
          </div>
        </AdminPanel>

        <AdminPanel title="Notification defaults" description="Reusable copy for quick campaign composition and app-triggered messages.">
          <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            <div className="afield">
              <label className="afield__label">Default title</label>
              <input className="afield__input" maxLength={50} value={settings.defaultNotificationTitle} onChange={(e) => updateField('defaultNotificationTitle', e.target.value)} />
            </div>
            <div className="afield">
              <label className="afield__label">Default message</label>
              <textarea className="afield__textarea" maxLength={200} value={settings.defaultNotificationMessage} onChange={(e) => updateField('defaultNotificationMessage', e.target.value)} />
            </div>
            {settings.updatedAt ? (
              <div className="admin-callout">
                <strong style={{ fontSize: 12 }}>Last saved</strong>
                <p style={{ fontSize: 12, color: 'var(--admin-text-muted)', margin: 0 }}>{new Date(settings.updatedAt).toLocaleString()}</p>
              </div>
            ) : null}
          </div>
        </AdminPanel>
      </div>
    </AdminPage>
  );
}
