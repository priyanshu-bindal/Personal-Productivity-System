import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Sidebar } from "@/components/layout/Sidebar";
import { BottomNav } from "@/components/layout/BottomNav";
import { TooltipProvider } from "@/components/ui/tooltip";

import { QuickAdd } from "@/components/QuickAdd";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "FocusFlow - Consistency over intensity",
  description: "A modern, professional personal skill & study management web app.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <body className={`${inter.className} min-h-screen bg-background antialiased flex`}>
        <TooltipProvider>
          <Sidebar />
          <div className="flex-1 flex flex-col min-h-screen pb-16 md:pb-0">
            <main className="flex-1 overflow-y-auto overflow-x-hidden">
              {children}
            </main>
          </div>
          <BottomNav />
          <QuickAdd />
        </TooltipProvider>
      </body>
    </html>
  );
}
