import { useState } from "react";
import { createFileRoute, Link, useNavigate } from "@tanstack/react-router";
import { Loader2, Store } from "lucide-react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { lovable } from "@/integrations/lovable/index";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";

export const Route = createFileRoute("/auth")({
  head: () => ({
    meta: [
      { title: "Sign in — Store App" },
      { name: "description", content: "Sign in or create your Store App account as a shopkeeper or customer." },
      { property: "og:title", content: "Sign in — Store App" },
      { property: "og:description", content: "Sign in or create your Store App account." },
    ],
  }),
  component: AuthPage,
});

function AuthPage() {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [fullName, setFullName] = useState("");
  const [phone, setPhone] = useState("");
  const [role, setRole] = useState<"owner" | "customer">("owner");

  const routeAfterLogin = async () => {
    const { data } = await supabase.auth.getUser();
    if (!data.user) return;
    const { data: roleRow } = await supabase
      .from("user_roles")
      .select("role")
      .eq("user_id", data.user.id)
      .limit(1)
      .maybeSingle();
    navigate({ to: roleRow?.role === "owner" ? "/owner/dashboard" : "/my/dashboard" });
  };

  const handleSignIn = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    setLoading(false);
    if (error) {
      toast.error(error.message);
      return;
    }
    toast.success("Welcome back!");
    await routeAfterLogin();
  };

  const handleSignUp = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        emailRedirectTo: window.location.origin,
        data: { full_name: fullName, phone, role },
      },
    });
    setLoading(false);
    if (error) {
      toast.error(error.message);
      return;
    }
    if (!data.session) {
      toast.success("Check your email to confirm your account.");
      return;
    }
    toast.success("Account created!");
    await routeAfterLogin();
  };

  const handleGoogle = async () => {
    setLoading(true);
    const result = await lovable.auth.signInWithOAuth("google", { redirect_uri: window.location.origin });
    if (result.error) {
      setLoading(false);
      toast.error("Google sign-in failed. Please try again.");
      return;
    }
    if (result.redirected) return;
    await routeAfterLogin();
  };

  const handleReset = async () => {
    if (!email) {
      toast.error("Enter your email first.");
      return;
    }
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/reset-password`,
    });
    if (error) toast.error(error.message);
    else toast.success("Password reset link sent.");
  };

  return (
    <div className="grid min-h-screen lg:grid-cols-2">
      <div className="hidden flex-col justify-between bg-brand-gradient p-12 text-primary-foreground lg:flex">
        <Link to="/" className="flex items-center gap-2 font-display text-lg font-semibold">
          <Store className="h-6 w-6" aria-hidden />
          Store App
        </Link>
        <div>
          <h2 className="max-w-sm font-display text-4xl leading-tight font-semibold">
            Your shop, your stock, your udhar — all in one place.
          </h2>
          <p className="mt-4 max-w-md text-primary-foreground/85">
            Built for kiryana stores and small retail shops. Track products, prices, customers and pending balances
            from any phone.
          </p>
        </div>
        <p className="text-sm text-primary-foreground/70">Multi-shop ready · Private per shop · Works offline-friendly</p>
      </div>

      <div className="flex items-center justify-center px-4 py-12">
        <Card className="w-full max-w-md p-6">
          <div className="mb-6 text-center lg:hidden">
            <h1 className="font-display text-2xl font-semibold">Store App</h1>
          </div>

          <Tabs defaultValue="signin">
            <TabsList className="grid w-full grid-cols-2">
              <TabsTrigger value="signin">Sign in</TabsTrigger>
              <TabsTrigger value="signup">Create account</TabsTrigger>
            </TabsList>

            <TabsContent value="signin" className="mt-6">
              <form onSubmit={handleSignIn} className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="email">Email</Label>
                  <Input id="email" type="email" required value={email} onChange={(e) => setEmail(e.target.value)} />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="password">Password</Label>
                  <Input
                    id="password"
                    type="password"
                    required
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                  />
                </div>
                <Button type="submit" className="w-full" disabled={loading}>
                  {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : "Sign in"}
                </Button>
                <button type="button" onClick={handleReset} className="w-full text-sm text-muted-foreground underline">
                  Forgot password?
                </button>
              </form>
            </TabsContent>

            <TabsContent value="signup" className="mt-6">
              <form onSubmit={handleSignUp} className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="name">Full name</Label>
                  <Input id="name" required value={fullName} onChange={(e) => setFullName(e.target.value)} />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="signup-email">Email</Label>
                  <Input
                    id="signup-email"
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="phone">Phone</Label>
                  <Input id="phone" value={phone} onChange={(e) => setPhone(e.target.value)} />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="signup-password">Password</Label>
                  <Input
                    id="signup-password"
                    type="password"
                    required
                    minLength={6}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                  />
                </div>
                <div className="space-y-2">
                  <Label>I am a</Label>
                  <RadioGroup
                    value={role}
                    onValueChange={(v) => setRole(v as "owner" | "customer")}
                    className="grid grid-cols-2 gap-3"
                  >
                    <Label
                      htmlFor="role-owner"
                      className="flex cursor-pointer items-center gap-2 rounded-lg border border-border p-3 text-sm has-[:checked]:border-primary has-[:checked]:bg-primary/5"
                    >
                      <RadioGroupItem value="owner" id="role-owner" />
                      Shopkeeper
                    </Label>
                    <Label
                      htmlFor="role-customer"
                      className="flex cursor-pointer items-center gap-2 rounded-lg border border-border p-3 text-sm has-[:checked]:border-primary has-[:checked]:bg-primary/5"
                    >
                      <RadioGroupItem value="customer" id="role-customer" />
                      Customer
                    </Label>
                  </RadioGroup>
                </div>
                <Button type="submit" className="w-full" disabled={loading}>
                  {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : "Create account"}
                </Button>
              </form>
            </TabsContent>
          </Tabs>

          <div className="my-6 flex items-center gap-3 text-xs text-muted-foreground">
            <span className="h-px flex-1 bg-border" />
            OR
            <span className="h-px flex-1 bg-border" />
          </div>

          <Button variant="outline" className="w-full" onClick={handleGoogle} disabled={loading}>
            Continue with Google
          </Button>

          <p className="mt-6 text-center text-sm text-muted-foreground">
            <Link to="/browse" className="underline">
              Browse products without an account
            </Link>
          </p>
        </Card>
      </div>
    </div>
  );
}
