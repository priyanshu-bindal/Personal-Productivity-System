import React from "react";
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Sidebar } from "@/components/layout/Sidebar";
import { BottomNav } from "@/components/layout/BottomNav";
import { TooltipProvider } from "@/components/ui/tooltip";
import { ToastProvider } from "@/components/ui/toast-provider";
import { QuickAdd } from "@/components/QuickAdd";
import { NavLoadingIndicator } from "@/components/layout/NavLoadingIndicator";

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
      <body className={`${inter.className} min-h-screen bg-background antialiased flex w-full max-w-full overflow-x-hidden`}>
        <ToastProvider>
          <TooltipProvider>
            <NavLoadingIndicator />
            <Sidebar />
            <div className="flex-1 flex flex-col min-h-screen min-w-0 w-full max-w-full pb-16 md:pb-0">
              <main className="flex-1 min-w-0 w-full max-w-full overflow-y-auto overflow-x-hidden">
                {children}
              </main>
            </div>
            <BottomNav />
            <QuickAdd />
          </TooltipProvider>
        </ToastProvider>
      </body>
    </html>
  );
}
