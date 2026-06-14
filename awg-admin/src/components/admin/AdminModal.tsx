import { type ReactNode, useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import { X } from 'lucide-react';

interface AdminModalProps {
  open: boolean;
  title: string;
  children: ReactNode;
  primaryLabel?: string;
  secondaryLabel?: string;
  primaryDisabled?: boolean;
  onConfirm?: () => void;
  onClose: () => void;
  /** 'sm' | 'md' | 'lg' — default 'md' */
  size?: 'sm' | 'md' | 'lg';
  /** Hide the default footer entirely */
  noFooter?: boolean;
}

const sizeMap = { sm: 480, md: 600, lg: 860 };

export function AdminModal({
  open,
  title,
  children,
  primaryLabel = 'Save',
  secondaryLabel = 'Cancel',
  primaryDisabled = false,
  onConfirm,
  onClose,
  size = 'md',
  noFooter = false,
}: AdminModalProps) {
  const overlayRef = useRef<HTMLDivElement>(null);

  // Close on Escape
  useEffect(() => {
    if (!open) return;
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    document.addEventListener('keydown', handler);
    return () => document.removeEventListener('keydown', handler);
  }, [open, onClose]);

  // Lock body scroll
  useEffect(() => {
    if (open) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = '';
    }
    return () => { document.body.style.overflow = ''; };
  }, [open]);

  if (!open) return null;

  return createPortal(
    <div
      ref={overlayRef}
      className="amodal-overlay"
      onMouseDown={(e) => {
        if (e.target === overlayRef.current) onClose();
      }}
    >
      <div
        className="amodal-container"
        role="dialog"
        aria-modal="true"
        aria-labelledby="amodal-title"
        style={{ maxWidth: sizeMap[size] }}
      >
        {/* Header */}
        <div className="amodal-header">
          <h2 className="amodal-title" id="amodal-title">{title}</h2>
          <button
            type="button"
            className="amodal-close"
            aria-label="Close"
            onClick={onClose}
          >
            <X size={16} />
          </button>
        </div>

        {/* Body */}
        <div className="amodal-body">{children}</div>

        {/* Footer */}
        {!noFooter && (
          <div className="amodal-footer">
            <button type="button" className="amodal-btn amodal-btn--secondary" onClick={onClose}>
              {secondaryLabel}
            </button>
            {onConfirm && (
              <button
                type="button"
                className="amodal-btn amodal-btn--primary"
                disabled={primaryDisabled}
                onClick={onConfirm}
              >
                {primaryLabel}
              </button>
            )}
          </div>
        )}
      </div>
    </div>,
    document.body
  );
}
