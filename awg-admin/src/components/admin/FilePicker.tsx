import { Button } from '@carbon/react';

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
      <Button kind="secondary" size="md" as="span">
        Choose file{multiple ? 's' : ''}
      </Button>
      <input type="file" hidden multiple={multiple} accept={accept} onChange={onChange} />
    </label>
  );
}
