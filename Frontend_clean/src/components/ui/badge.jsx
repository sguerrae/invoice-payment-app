import { cn } from "../../lib/utils";

function Badge({ className, variant = "default", ...props }) {
  return (
    <div
      className={cn(
        "inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none",
        {
          "border-transparent bg-primary text-white hover:bg-primary/80":
            variant === "default",
          "border-transparent bg-secondary text-primary hover:bg-secondary/80":
            variant === "secondary",
          "border-transparent bg-destructive text-white hover:bg-destructive/80":
            variant === "destructive",
          "border-transparent bg-green-500 text-white hover:bg-green-500/80":
            variant === "success",
          "border-transparent bg-yellow-500 text-white hover:bg-yellow-500/80":
            variant === "warning",
        },
        className
      )}
      {...props}
    />
  );
}

export { Badge };
