import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
  transpilePackages: [
    '@layoutbank/cnab-engine',
    '@layoutbank/database',
    '@layoutbank/shared-types',
  ],
  experimental: {
    serverActions: {
      bodySizeLimit: '15mb',
    },
  },
}

export default nextConfig
