import React from "react";
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { TooltipProvider } from "@/components/ui/tooltip";
import { ToastProvider } from "@/components/ui/toast-provider";
import { NavLoadingIndicator } from "@/components/layout/NavLoadingIndicator";
import { AppShell } from "@/components/layout/AppShell";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "FocusFlow - Consistency over intensity",
  description: "A modern, professional personal skill & study management web app.",
  icons: {
    icon: "/favicon.svg",
    shortcut: "/favicon.svg",
    apple: "/favicon.svg",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <body className={`${inter.className} min-h-screen bg-background antialiased w-full max-w-full overflow-x-hidden`}>
        <ToastProvider>
          <TooltipProvider>
            <NavLoadingIndicator />
            <AppShell>
              {children}
            </AppShell>
          </TooltipProvider>
        </ToastProvider>
      </body>
    </html>
  );
}
