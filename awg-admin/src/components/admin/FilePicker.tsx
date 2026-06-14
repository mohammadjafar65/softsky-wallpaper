import { Upload } from 'lucide-react';
import { buttonVariants } from '../ui/button-variants';

interface FilePickerProps {
  label: string;
  helperText?: string;
  multiple?: boolean;
  accept?: string;
  onChange: (event: React.ChangeEvent<HTMLInputElement>) => void;
}

export function FilePicker({ label, helperText, multiple = false, accept, onChange }: FilePickerProps) {
  return (
    <label className="admin-file-picker">
      <span className="admin-file-picker__label">{label}</span>
      {helperText ? <span className="admin-file-picker__helper">{helperText}</span> : null}
      <span className={buttonVariants({ variant: 'secondary' })}>
        <Upload size={16} />
        Choose file{multiple ? 's' : ''}
      </span>
      <input type="file" hidden multiple={multiple} accept={accept} onChange={onChange} />
    </label>
  );
}
