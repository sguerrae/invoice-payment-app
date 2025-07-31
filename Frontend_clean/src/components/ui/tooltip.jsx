import React from 'react';

export function Tooltip({ children }) {
  return <div className="tooltip">{children}</div>;
}

export function TooltipTrigger({ children }) {
  return <div className="tooltip-trigger">{children}</div>;
}

export function TooltipContent({ children }) {
  return <div className="tooltip-content">{children}</div>;
}
