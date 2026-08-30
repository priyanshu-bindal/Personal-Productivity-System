import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // @ts-ignore - experimental config for local network testing
  allowedDevOrigins: ['192.168.0.152'],
};

export default nextConfig;
