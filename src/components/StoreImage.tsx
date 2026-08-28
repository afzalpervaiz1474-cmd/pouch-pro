import { useEffect, useState } from "react";
import { ImageIcon } from "lucide-react";
import { resolveImageUrl } from "@/lib/images";
import { cn } from "@/lib/utils";

export function StoreImage({
  src,
  alt,
  className,
}: {
  src: string | null | undefined;
  alt: string;
  className?: string;
}) {
  const [url, setUrl] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    void resolveImageUrl(src).then((value) => {
      if (active) setUrl(value);
    });
    return () => {
      active = false;
    };
  }, [src]);

  if (!url) {
    return (
      <div className={cn("flex items-center justify-center bg-muted text-muted-foreground", className)}>
        <ImageIcon className="h-6 w-6 opacity-50" aria-hidden />
      </div>
    );
  }

  return <img src={url} alt={alt} loading="lazy" className={cn("object-cover", className)} />;
}
