import React from 'react';
import { cn } from "../../lib/utils";

const FileUpload = React.forwardRef(({ className, accept, onChange, ...props }, ref) => {
  const inputRef = React.useRef(null);
  const [fileName, setFileName] = React.useState('');
  
  const handleChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setFileName(file.name);
      if (onChange) onChange(e);
    }
  };

  const handleClick = () => {
    inputRef.current.click();
  };

  return (
    <div className={cn("flex flex-col gap-2", className)}>
      <div
        onClick={handleClick}
        className="border-2 border-dashed border-gray-300 rounded-lg p-6 cursor-pointer hover:border-gray-400 transition-all"
      >
        <div className="flex flex-col items-center justify-center space-y-2">
          <div className="text-4xl text-gray-400">
            <svg 
              xmlns="http://www.w3.org/2000/svg" 
              width="24" 
              height="24" 
              viewBox="0 0 24 24" 
              fill="none" 
              stroke="currentColor" 
              strokeWidth="2" 
              strokeLinecap="round" 
              strokeLinejoin="round"
            >
              <path d="M4 14.899A7 7 0 1 1 15.71 8h1.79a4.5 4.5 0 0 1 2.5 8.242"/>
              <path d="M12 12v9"/>
              <path d="m16 16-4-4-4 4"/>
            </svg>
          </div>
          <p className="text-sm font-medium text-gray-600">
            {fileName ? `File selected: ${fileName}` : 'Click to upload or drag and drop'}
          </p>
          <p className="text-xs text-gray-400">
            {accept === '.xml' ? 'XML files only' : accept || 'Supported file types'}
          </p>
        </div>
      </div>
      <input
        type="file"
        className="hidden"
        ref={inputRef}
        accept={accept}
        onChange={handleChange}
        {...props}
      />
    </div>
  );
});

FileUpload.displayName = "FileUpload";

export { FileUpload };
