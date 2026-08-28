import { supabase } from "@/integrations/supabase/client";

const BUCKET = "product-images";
const cache = new Map<string, string>();

/** Resolve a stored image reference to a displayable URL. */
export async function resolveImageUrl(ref: string | null | undefined): Promise<string | null> {
  if (!ref) return null;
  if (ref.startsWith("http")) return ref;
  const cached = cache.get(ref);
  if (cached) return cached;
  const { data } = await supabase.storage.from(BUCKET).createSignedUrl(ref, 60 * 60);
  if (!data?.signedUrl) return null;
  cache.set(ref, data.signedUrl);
  return data.signedUrl;
}

export async function uploadImage(file: File, folder: string): Promise<string> {
  const ext = file.name.split(".").pop() ?? "jpg";
  const path = `${folder}/${crypto.randomUUID()}.${ext}`;
  const { error } = await supabase.storage.from(BUCKET).upload(path, file, { upsert: false });
  if (error) throw error;
  return path;
}
