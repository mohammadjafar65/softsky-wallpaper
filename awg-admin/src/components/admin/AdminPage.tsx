import type { ReactNode } from 'react';
import { Loader2 } from 'lucide-react';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Card, CardContent, CardDescription, CardTitle } from '../ui/card';

interface AdminPageProps {
  title: string;
  subtitle?: string;
  actions?: ReactNode;
  children: ReactNode;
  eyebrow?: string;
}

export function AdminPage({ title, subtitle, actions, children, eyebrow = 'Admin' }: AdminPageProps) {
  return (
    <div className="admin-page">
      <div className="admin-page__header">
        <div>
          <p className="admin-page__eyebrow">{eyebrow}</p>
          <h1 className="admin-page__title">{title}</h1>
          {subtitle ? <p className="admin-page__subtitle">{subtitle}</p> : null}
        </div>
        {actions ? <div className="admin-page__actions">{actions}</div> : null}
      </div>
      {children}
    </div>
  );
}

interface AdminPanelProps {
  title?: string;
  description?: string;
  actions?: ReactNode;
  children: ReactNode;
  className?: string;
}

export function AdminPanel({ title, description, actions, children, className = '' }: AdminPanelProps) {
  return (
    <Card className={`admin-panel ${className}`.trim()}>
      {(title || description || actions) && (
        <div className="admin-panel__header">
          <div>
            {title ? <CardTitle className="admin-panel__title">{title}</CardTitle> : null}
            {description ? <CardDescription className="admin-panel__description">{description}</CardDescription> : null}
          </div>
          {actions ? <div className="admin-panel__actions">{actions}</div> : null}
        </div>
      )}
      <CardContent className="admin-panel__content">{children}</CardContent>
    </Card>
  );
}

interface StatTileProps {
  label: string;
  value: string | number;
  helper?: string;
  tone?: 'blue' | 'green' | 'purple' | 'orange' | 'red';
  loading?: boolean;
}

export function StatTile({ label, value, helper, tone = 'blue', loading = false }: StatTileProps) {
  return (
    <Card className={`admin-stat admin-stat--${tone}`}>
      <p className="admin-stat__label">{label}</p>
      <div className="admin-stat__value">
        {loading ? <Loader2 className="admin-spinner" size={24} /> : value}
      </div>
      {helper ? <p className="admin-stat__helper">{helper}</p> : null}
    </Card>
  );
}

interface EmptyStateProps {
  title: string;
  message: string;
  actionLabel?: string;
  onAction?: () => void;
}

export function EmptyState({ title, message, actionLabel, onAction }: EmptyStateProps) {
  return (
    <div className="admin-empty-state">
      <h3>{title}</h3>
      <p>{message}</p>
      {actionLabel && onAction ? (
        <Button variant="secondary" onClick={onAction}>
          {actionLabel}
        </Button>
      ) : null}
    </div>
  );
}

export function StatusTag({
  children,
  type = 'gray',
}: {
  children: ReactNode;
  type?: 'blue' | 'cool-gray' | 'cyan' | 'gray' | 'green' | 'high-contrast' | 'magenta' | 'outline' | 'purple' | 'red' | 'teal' | 'warm-gray';
}) {
  const variantByType = {
    blue: 'info',
    cyan: 'info',
    teal: 'info',
    green: 'success',
    purple: 'secondary',
    magenta: 'secondary',
    red: 'danger',
    'high-contrast': 'outline',
    outline: 'outline',
    'cool-gray': 'muted',
    gray: 'muted',
    'warm-gray': 'muted',
  } as const;

  return (
    <Badge variant={variantByType[type]} className="admin-tag">
      {children}
    </Badge>
  );
}
