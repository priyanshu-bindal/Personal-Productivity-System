import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // @ts-ignore - experimental config for local network testing
  allowedDevOrigins: [
    '172.25.9.216',
    '192.168.0.152',
    'localhost',
    '127.0.0.1',
  ],
};

export default nextConfig;
